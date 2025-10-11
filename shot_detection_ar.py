#  Works well with toy rifle but I was unsure how it will do in a real rifle
import simplepyble
import signal
import time
import struct
import sys
import numpy as np
from collections import deque
import math
running = True
def signal_handler(sig, frame):
    global running
    print("\nStopping...")
    running = False
signal.signal(signal.SIGINT, signal_handler)
class RT1Device:
    SERVICE_UUID = "0000b3a0-0000-1000-8000-00805f9b34fb"
    NOTIFY_UUID  = "0000b3a1-0000-1000-8000-00805f9b34fb"
    WRITE_UUID   = "0000b3a2-0000-1000-8000-00805f9b34fb"
    CMD_FACTORY_RESET = bytes([0x55, 0xAA, 0xFE, 0x00])
    CMD_STOP_SENSORS  = bytes([0x55, 0xAA, 0xF0, 0x00])
    CMD_SET_MAX_RATE  = bytes([0x55, 0xAA, 0x11, 0x02, 0x00, 0x02])
    CMD_ACCEL_RANGE   = bytes([0x55, 0xAA, 0x09, 0x01, 0x03])
    CMD_ENABLE_ACCEL  = bytes([0x55, 0xAA, 0x08, 0x00])
    CMD_ENABLE_GYRO   = bytes([0x55, 0xAA, 0x0A, 0x00])
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
        self.peripheral.notify(self.SERVICE_UUID, self.NOTIFY_UUID, self.handle_imu_data)
        print("Notifications enabled")
        for cmd, desc in [
            (self.CMD_FACTORY_RESET, "Factory reset"),
            (self.CMD_STOP_SENSORS, "Stop sensors"),
            (self.CMD_SET_MAX_RATE, "Set max rate"),
            (self.CMD_ACCEL_RANGE, "Set accel range"),
            (self.CMD_ENABLE_ACCEL, "Enable accelerometer"),
            (self.CMD_ENABLE_GYRO, "Enable gyroscope"),
        ]:
            self.send_command(cmd, desc)
            time.sleep(0.2)
        self.sensors_ready = True
        return True
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
            print("Failed: Refractory period")
            return False
        gyro_mag = math.sqrt(gx*gx + gy*gy + gz*gz)
        accel_mag = math.sqrt(ax*ax + ay*ay + az*az)
        if len(self.gyro_buffer) < self.buffer_size:
            print("Failed: Insufficient buffer")
            return False
        pre_mean = np.mean([math.sqrt(gx*gx + gy*gy + gz*gz) for gx,gy,gz in self.gyro_buffer])
        pre_std = np.std([math.sqrt(gx*gx + gy*gy + gz*gz) for gx,gy,gz in self.gyro_buffer])
        pre_accel_mean = np.mean([math.sqrt(ax*ax + ay*ay + az*az) for ax,ay,az in self.accel_buffer])
        # print(f"Pre: Gyro mean={pre_mean:.2f}, std={pre_std:.2f} | Accel mean={pre_accel_mean:.2f}")
        # print(f"Current: Gyro mag={gyro_mag:.2f} | Accel mag={accel_mag:.2f}")
        if gyro_mag <= pre_mean + self.K * pre_std:
            # print("Failed: Impulse test (gyro_mag <= threshold)")
            return False
        axes = [abs(gx), abs(gy), abs(gz)]
        max_axis = max(axes)
        second_axis = sorted(axes, reverse=True)[1]
        if max_axis < self.AXIS_THRESHOLD:
            print("Failed: Max axis < threshold")
            return False
        if max_axis < 2 * second_axis:
            print("Failed: Max axis < 2x second")
            return False
        if (accel_mag - pre_accel_mean) < self.MIN_ACCEL_DELTA:
            print("Failed: Accel delta too small")
            return False
        if pre_std > self.NOISE_LIMIT:
            print("Failed: Baseline noise too high")
            return False
        self.last_detection_time = now
        print(f"SHOT DETECTED at {now:.3f}s | GyroMag={gyro_mag:.1f} | Axes={axes}")
        return True
    def handle_imu_data(self, data: bytes):
        # parse packets
        for offset in range(len(data) - 9):
            if data[offset] == 0x55 and data[offset+1] == 0xAA:
                packet_type = data[offset+2]
                length = data[offset+3]
                if offset + 4 + length > len(data):
                    break
                if packet_type == 0x08 and length == 0x06:
                    x = struct.unpack(">h", data[offset+4:offset+6])[0]
                    y = struct.unpack(">h", data[offset+6:offset+8])[0]
                    z = struct.unpack(">h", data[offset+8:offset+10])[0]
                    ax = (x / 32768.0) * 16.0 - self.accel_bias[0]
                    ay = (y / 32768.0) * 16.0 - self.accel_bias[1]
                    az = (z / 32768.0) * 16.0 - self.accel_bias[2]
                    self.accel_data = (ax, ay, az)
                elif packet_type == 0x0A and length == 0x06:
                    x = struct.unpack(">h", data[offset+4:offset+6])[0]
                    y = struct.unpack(">h", data[offset+6:offset+8])[0]
                    z = struct.unpack(">h", data[offset+8:offset+10])[0]
                    gx = (x / 28571.0) * 500.0 - self.gyro_bias[0]
                    gy = (y / 28571.0) * 500.0 - self.gyro_bias[1]
                    gz = (z / 28571.0) * 500.0 - self.gyro_bias[2]
                    self.gyro_data = (gx, gy, gz)
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
            # reset
            self.accel_data = None
            self.gyro_data = None
    def send_command(self, cmd_bytes: bytes, description: str):
        self.peripheral.write_request(self.SERVICE_UUID, self.WRITE_UUID, cmd_bytes)
        print(f"{description} sent")
    def disconnect(self):
        if self.connected:
            self.peripheral.disconnect()
            self.connected = False
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
    print("Monitoring live data... (Ctrl+C to stop)")
    while running:
        time.sleep(0.01)
    device.disconnect()
if __name__ == "__main__":
    main()