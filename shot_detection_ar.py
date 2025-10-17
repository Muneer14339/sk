#  Works well with toy rifle but I was unsure how it will do in a real rifle
import simplepyble
import signal
import time
import struct
import sys
import numpy as np
from collections import deque
import math
from typing import Optional, Tuple

running = True
def signal_handler(sig, frame):
    global running
    print("\nStopping...")
    running = False
signal.signal(signal.SIGINT, signal_handler)

def clamp(n, lo, hi):
    return max(lo, min(hi, n))

def to_hex(b: bytes) -> str:
    return " ".join(f"{x:02X}" for x in b)

class RT1Device:
    # --- BLE layout (unchanged IMU service) ---
    SERVICE_UUID = "0000b3a0-0000-1000-8000-00805f9b34fb"
    NOTIFY_UUID  = "0000b3a1-0000-1000-8000-00805f9b34fb"  # IMU + (now) haptic events if fw multiplexes
    WRITE_UUID   = "0000b3a2-0000-1000-8000-00805f9b34fb"

    # --- Existing commands (keep your shape: [55 AA, opcode, len, payload...]) ---
    CMD_FACTORY_RESET = bytes([0x55, 0xAA, 0xFE, 0x00])
    CMD_STOP_SENSORS  = bytes([0x55, 0xAA, 0xF0, 0x00])
    CMD_SET_MAX_RATE  = bytes([0x55, 0xAA, 0x11, 0x02, 0x00, 0x02])
    CMD_ACCEL_RANGE   = bytes([0x55, 0xAA, 0x09, 0x01, 0x03])
    CMD_ENABLE_ACCEL  = bytes([0x55, 0xAA, 0x08, 0x00])
    CMD_ENABLE_GYRO   = bytes([0x55, 0xAA, 0x0A, 0x00])

    # --- HAPTIC opcodes (adjust if your fw uses different ones) ---
    # We follow your frame shape: [55 AA, <OP>, <LEN>, <PAYLOAD...>]
    # 0x01: set intensity (%), LEN=1, payload=[0..100]
    # 0x02: query state,     LEN=0, payload=[]
    HOP_SET_INTENSITY = 0x01
    HOP_QUERY_STATE   = 0x02

    def __init__(self, fs=833):
        self.peripheral = None
        self.connected = False
        self.sensors_ready = False

        self.accel_data = None
        self.gyro_data = None
        self.accel_bias = [0.0, 0.0, 0.0]
        self.gyro_bias = [0.0, 0.0, 0.0]
        self.calibrating = False
        self.ignore_target = 15
        self.calib_target = 150
        self.ignore_count = 0
        self.calib_samples = []

        # --- detection state ---
        self.sample_count = 0
        self.time_step = 1.0 / fs
        self.last_detection_time = -999.0
        self.buffer_size = 10
        self.gyro_buffer = deque(maxlen=self.buffer_size)
        self.accel_buffer = deque(maxlen=self.buffer_size)

        # thresholds
        self.K = 8                  # std dev multiplier
        self.AXIS_THRESHOLD = 15.0  # deg/s or sensor units
        self.MIN_ACCEL_DELTA = 0.05 # g
        self.NOISE_LIMIT = 1.0
        self.REFRACTORY = 0.010     # 10 ms

        # --- haptic event inbox (ack / state) ---
        # Each event: (evt_id, data_bytes)
        self.haptic_events = deque(maxlen=32)

    # ---------- BLE ----------
    def connect(self, device_name="GMSync"):
        adapters = simplepyble.Adapter.get_adapters()
        if not adapters:
            print("No Bluetooth adapters found")
            return False
        adapter = adapters[0]
        print(f"Scanning for {device_name}...")
        adapter.scan_for(3000)
        peripherals = adapter.scan_get_results()
        for p in peripherals:
            if device_name in p.identifier():
                print("Found device. Connecting...")
                self.peripheral = p
                self.peripheral.connect()
                self.connected = True
                print("Connected successfully!")
                return True
        print("Device not found")
        return False

    def initialize_sensors(self):
        if not self.connected:
            return False
        self.peripheral.notify(self.SERVICE_UUID, self.NOTIFY_UUID, self.handle_notify)
        print("Notifications enabled")

        for cmd, desc in [
            (self.CMD_FACTORY_RESET, "Factory reset"),
            (self.CMD_STOP_SENSORS,  "Stop sensors"),
            (self.CMD_SET_MAX_RATE,  "Set max rate"),
            (self.CMD_ACCEL_RANGE,   "Set accel range"),
            (self.CMD_ENABLE_ACCEL,  "Enable accelerometer"),
            (self.CMD_ENABLE_GYRO,   "Enable gyroscope"),
        ]:
            self.send_command(cmd, desc)
            time.sleep(0.2)

        self.sensors_ready = True
        return True

    def disconnect(self):
        if self.connected:
            self.peripheral.disconnect()
            self.connected = False

    # ---------- Command helpers ----------
    def build_cmd(self, opcode: int, payload: bytes = b"") -> bytes:
        # Outgoing matches your incoming shape (opcode, len, payload)
        return bytes([0x55, 0xAA, opcode, len(payload)]) + payload

    def send_command(self, cmd_bytes: bytes, description: str = ""):
        self.peripheral.write_request(self.SERVICE_UUID, self.WRITE_UUID, cmd_bytes)
        if description:
            print(f"{description} sent: {to_hex(cmd_bytes)}")
        else:
            print(f"TX: {to_hex(cmd_bytes)}")

    # ---------- Haptics ----------
    def level_to_percent(self, level_1to10: int) -> int:
        L = clamp(int(round(level_1to10)), 1, 10)
        return L * 10  # 10..100

    def set_haptic_level(self, level_1to10: int, wait_ack: float = 0.0):
        """Set motor intensity: user 1..10 -> 10..100%. Pass wait_ack>0 to wait for a response."""
        pct = self.level_to_percent(level_1to10)
        cmd = self.build_cmd(self.HOP_SET_INTENSITY, bytes([pct]))
        self.send_command(cmd, f"Haptic set {pct}%")

        if wait_ack > 0:
            evt = self.wait_haptic_event(timeout=wait_ack)
            if evt:
                evt_id, data = evt
                print(f"Haptic response: evt=0x{evt_id:02X}, data={to_hex(data)}")
            else:
                print("Haptic: no response within timeout")

    def stop_haptic(self, wait_ack: float = 0.0):
        """Stop motor by setting intensity 0 (common convention)."""
        cmd = self.build_cmd(self.HOP_SET_INTENSITY, bytes([0x00]))
        self.send_command(cmd, "Haptic stop")
        if wait_ack > 0:
            evt = self.wait_haptic_event(timeout=wait_ack)
            if evt:
                evt_id, data = evt
                print(f"Haptic response: evt=0x{evt_id:02X}, data={to_hex(data)}")

    def query_haptic(self, wait: float = 1.0) -> Optional[int]:
        """Ask device for current haptic intensity/state (if firmware supports opcode 0x02)."""
        cmd = self.build_cmd(self.HOP_QUERY_STATE, b"")
        self.send_command(cmd, "Haptic query")
        evt = self.wait_haptic_event(timeout=wait)
        if not evt:
            print("Haptic query: no response")
            return None
        evt_id, data = evt
        print(f"Haptic query response: evt=0x{evt_id:02X}, data={to_hex(data)}")
        # Heuristic: if device replies [55 AA, <evt>, <len>=1, <pct>]
        if len(data) >= 1:
            return int(data[0])
        return None

    def test_haptic_motor(self):
        """Quick self-test: 1→10 sweep then stop. Ctrl+C to interrupt."""
        print("Haptic self-test: sweeping 1→10 (10%→100%)")
        for lvl in range(1, 11):
            if not running: break
            self.set_haptic_level(lvl)
            time.sleep(0.25)
        self.stop_haptic()
        print("Haptic self-test complete.")

    def pulse_haptic(self, level_1to10: int, ms_on: int = 200):
        """Single pulse at given level for ms_on milliseconds."""
        self.set_haptic_level(level_1to10)
        time.sleep(ms_on / 1000.0)
        self.stop_haptic()

    def wait_haptic_event(self, timeout: float = 1.0) -> Optional[Tuple[int, bytes]]:
        """Pop first haptic event from inbox within timeout."""
        t0 = time.time()
        while time.time() - t0 < timeout:
            if self.haptic_events:
                return self.haptic_events.popleft()
            time.sleep(0.01)
        return None

    # ---------- Notifications: IMU + HAPTIC parsing ----------
    def handle_notify(self, data: bytes):
        # parse packets
        parsed_any = False
        for offset in range(len(data) - 4):  # need at least 5 bytes [55 AA, type, len, ...]
            if data[offset] == 0x55 and data[offset+1] == 0xAA:
                packet_type = data[offset+2]
                length = data[offset+3]
                end = offset + 4 + length
                if end > len(data):
                    break
                payload = data[offset+4:end]
                parsed_any = True

                # --- IMU: accel (0x08), gyro (0x0A) ---
                if packet_type == 0x08 and length == 0x06:
                    x = struct.unpack(">h", payload[0:2])[0]
                    y = struct.unpack(">h", payload[2:4])[0]
                    z = struct.unpack(">h", payload[4:6])[0]
                    ax = (x / 32768.0) * 16.0 - self.accel_bias[0]
                    ay = (y / 32768.0) * 16.0 - self.accel_bias[1]
                    az = (z / 32768.0) * 16.0 - self.accel_bias[2]
                    self.accel_data = (ax, ay, az)

                elif packet_type == 0x0A and length == 0x06:
                    x = struct.unpack(">h", payload[0:2])[0]
                    y = struct.unpack(">h", payload[2:4])[0]
                    z = struct.unpack(">h", payload[4:6])[0]
                    gx = (x / 28571.0) * 500.0 - self.gyro_bias[0]
                    gy = (y / 28571.0) * 500.0 - self.gyro_bias[1]
                    gz = (z / 28571.0) * 500.0 - self.gyro_bias[2]
                    self.gyro_data = (gx, gy, gz)

                else:
                    # --- HAPTIC (examples): 0x81=ACK, 0x10=STATE/REPORT, 0xE1=ERROR (adjust to your fw) ---
                    # We don't know your exact event IDs; we capture all non-IMU packets into the inbox.
                    # You can branch here if you know exact types.
                    self.haptic_events.append((packet_type, payload))
                    print(f"RX evt 0x{packet_type:02X}: {to_hex(payload)}")

        # Once accel+gyro are ready, run detection
        if self.accel_data and self.gyro_data:
            if self.calibrating:
                self.ignore_count += 1
                if self.ignore_count > self.ignore_target:
                    if len(self.calib_samples) < self.calib_target:
                        self.calib_samples.append((self.accel_data, self.gyro_data))
            elif self.sensors_ready:
                t = self.sample_count * self.time_step
                self.sample_count += 1
                ax, ay, az = self.accel_data
                gx, gy, gz = self.gyro_data
                # Run detection using current buffers (previous data)
                self.detect_shot(ax, ay, az, gx, gy, gz)
                # Now add current to buffers for next time
                self.gyro_buffer.append((gx, gy, gz))
                self.accel_buffer.append((ax, ay, az))
            # reset one-shot
            self.accel_data = None
            self.gyro_data = None

        if not parsed_any:
            # raw dump if not framed; helpful for debugging
            print(f"RX raw: {to_hex(data)}")

    # ---------- Calibration / Detection (unchanged) ----------
    def calibrate(self):
        self.calibrating = True
        self.ignore_count = 0
        self.calib_samples = []
        print("Calibrating... Keep device stationary.")
        while len(self.calib_samples) < self.calib_target and running:
            time.sleep(0.01)
        if not running:
            self.calibrating = False
            return False
        accel_means = np.mean([s[0] for s in self.calib_samples], axis=0)
        gyro_means = np.mean([s[1] for s in self.calib_samples], axis=0)
        self.accel_bias = accel_means.tolist()
        self.gyro_bias = gyro_means.tolist()
        print(f"Accel bias: {self.accel_bias}")
        print(f"Gyro bias: {self.gyro_bias}")
        self.calibrating = False
        print("Calibration complete.")
        return True

    def detect_shot(self, ax, ay, az, gx, gy, gz):
        now = self.sample_count * self.time_step
        if now - self.last_detection_time < self.REFRACTORY:
            # print("Failed: Refractory period")
            return False
        gyro_mag = math.sqrt(gx*gx + gy*gy + gz*gz)
        accel_mag = math.sqrt(ax*ax + ay*ay + az*az)
        if len(self.gyro_buffer) < self.buffer_size:
            # print("Failed: Insufficient buffer")
            return False
        pre_mean = np.mean([math.sqrt(a*a + b*b + c*c) for a,b,c in self.gyro_buffer])
        pre_std  = np.std ([math.sqrt(a*a + b*b + c*c) for a,b,c in self.gyro_buffer])
        pre_accel_mean = np.mean([math.sqrt(a*a + b*b + c*c) for a,b,c in self.accel_buffer])

        if gyro_mag <= pre_mean + self.K * pre_std:
            return False
        axes = [abs(gx), abs(gy), abs(gz)]
        max_axis = max(axes)
        second_axis = sorted(axes, reverse=True)[1]
        if max_axis < self.AXIS_THRESHOLD: return False
        if max_axis < 2 * second_axis:     return False
        if (accel_mag - pre_accel_mean) < self.MIN_ACCEL_DELTA: return False
        if pre_std > self.NOISE_LIMIT:                         return False

        self.last_detection_time = now
        print(f"SHOT DETECTED at {now:.3f}s | GyroMag={gyro_mag:.1f} | Axes={axes}")
        return True

# ---------- Main ----------
def main():
    device = RT1Device()
    if not device.connect():
        sys.exit(1)
    if not device.initialize_sensors():
        device.disconnect()
        sys.exit(1)
    if not device.calibrate():
        device.disconnect()
        sys.exit(1)

    # --- Haptic quick test (comment out if you don’t want it at startup) ---
    try:
        device.test_haptic_motor()
        # Example: one strong pulse at 80% for 300 ms
        device.pulse_haptic(level_1to10=8, ms_on=300)

        # Optional: confirm state (if firmware supports query)
        pct = device.query_haptic()
        if pct is not None:
            print(f"Device reports haptic intensity: {pct}%")
    except Exception as e:
        print("Haptic test error:", e)

    print("Monitoring live data... (Ctrl+C to stop)")
    while running:
        time.sleep(0.01)

    device.stop_haptic()
    device.disconnect()

if __name__ == "__main__":
    main()
