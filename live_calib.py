# LIVE REAL-TIME SHOT DETECTION (modified from your original)
import simplepyble
import signal
import time
import struct
import sys
import numpy as np
from collections import deque
from datetime import datetime
import threading

running = True

def signal_handler(sig, frame):
    global running
    print("\nStopping...")
    running = False

signal.signal(signal.SIGINT, signal_handler)

class ShotDetectedEvent:
    def __init__(self, timestamp, shot_number, magnitude, is_valid_shot, reason=""):
        self.timestamp = timestamp
        self.shot_number = shot_number
        self.magnitude = magnitude
        self.is_valid_shot = is_valid_shot
        self.reason = reason
    
    def __str__(self):
        ts = datetime.fromtimestamp(self.timestamp).strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        return (f"{ts}  Shot #{self.shot_number}: mag={self.magnitude:.2f}g, "
                f"valid={self.is_valid_shot}, reason={self.reason}")

class RT1Device:
    SERVICE_UUID = "0000b3a0-0000-1000-8000-00805f9b34fb"
    NOTIFY_UUID = "0000b3a1-0000-1000-8000-00805f9b34fb"
    WRITE_UUID = "0000b3a2-0000-1000-8000-00805f9b34fb"
    
    CMD_FACTORY_RESET = bytes([0x55, 0xAA, 0xFE, 0x00])
    CMD_STOP_SENSORS = bytes([0x55, 0xAA, 0xF0, 0x00])
    CMD_SET_MAX_RATE = bytes([0x55, 0xAA, 0x11, 0x02, 0x00, 0x02])
    CMD_ACCEL_RANGE = bytes([0x55, 0xAA, 0x09, 0x01, 0x03])
    CMD_ENABLE_ACCEL = bytes([0x55, 0xAA, 0x08, 0x00])
    CMD_ENABLE_GYRO = bytes([0x55, 0xAA, 0x0A, 0x00])
    
    def __init__(self, fs=833):
        self.fs = fs
        self.dt = 1.0 / fs
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
        
        # Shot detection parameters
        self.buffer_size = int(self.fs * 3.0)  # keep ~3 seconds of data by default
        self.accel_mag_buffer = deque(maxlen=self.buffer_size)
        self.gyro_mag_buffer = deque(maxlen=self.buffer_size)
        self.time_buffer = deque(maxlen=self.buffer_size)
        self.buffer_lock = threading.Lock()
        
        # Shot calibration state
        self.calibrating_shots = False
        self.window_samples = 80  # ~100ms (kept same as your code)
        self.trigger_characteristics = None
        self.gyro_characteristics = None
        
        # Temp collection for calibration
        self.collecting = False
        self.temp_accel_mags = []
        self.temp_gyro_mags = []
        
        # Runtime state
        self.min_time_between_shots = 1.0  # seconds
        self.last_shot_time = 0.0
        self.shot_counter = 0
        
        # Detection thread
        self._detection_thread = None
        self._detection_thread_stop = threading.Event()
        self.reported_peak_indices = set()  # to avoid double-reporting same peak (by timestamp index)
    
    # --- your existing methods (connect, initialize_sensors, calibrate_bias, etc.) ---
    # unchanged except handle_imu_data which I extend to add timestamps to buffers
    
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
        
        self.peripheral.notify(self.SERVICE_UUID, self.NOTIFY_UUID, 
                              self.handle_imu_data)
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
    
    def calibrate_bias(self):
        """Calibrate sensor biases"""
        self.calibrating = True
        self.ignore_count = 0
        self.calib_samples = []
        print("Calibrating biases... Keep device stationary.")
        
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
        print("Bias calibration complete.")
        return True
    
    def start_shot_calibration(self):
        """Calibrate shot detection by collecting 5 shots live"""
        print("\n=== Starting Shot Calibration ===")
        print("You will perform 5 dry fire shots to calibrate detection")
        
        self.calibrating_shots = True
        trigger_samples = []
        gyro_samples = []
        
        for i in range(5):
            if not running:
                break
            
            print(f"\nPrepare for shot {i+1}/5 in 5 seconds...")
            time.sleep(5)
            
            print(f"PERFORM SHOT {i+1} NOW! (collecting for 2 seconds)")
            self.collecting = True
            self.temp_accel_mags = []
            self.temp_gyro_mags = []
            
            time.sleep(2)
            self.collecting = False
            
            if not self.temp_accel_mags:
                print("No data collected, retrying...")
                i -= 1
                continue
            
            temp_accel = np.array(self.temp_accel_mags)
            temp_gyro = np.array(self.temp_gyro_mags)
            
            idx = np.argmax(temp_accel)
            if idx < self.window_samples or idx >= len(temp_accel) - self.window_samples:
                print("Peak too close to edge, retrying...")
                i -= 1
                continue
            
            accel_window = temp_accel[idx - self.window_samples : idx + self.window_samples + 1]
            gyro_window = temp_gyro[idx - self.window_samples : idx + self.window_samples + 1]
            
            trigger_samples.append(accel_window)
            gyro_samples.append(gyro_window)
            
            print(f"Collected: accel={np.max(accel_window):.2f}g, gyro={np.max(gyro_window):.2f}°/s")
        
        if len(trigger_samples) < 5:
            print("Insufficient calibration shots, aborting.")
            self.calibrating_shots = False
            return
        
        # Create templates
        trigger_template = np.mean(trigger_samples, axis=0)
        gyro_template = np.mean(gyro_samples, axis=0)
        
        # Extract characteristics for accel
        peak_amps = [np.max(s) for s in trigger_samples]
        rise_times = [self.compute_rise_time(s) for s in trigger_samples]
        fall_times = [self.compute_fall_time(s) for s in trigger_samples]
        durations = [self.compute_duration(s) for s in trigger_samples]
        
        self.trigger_characteristics = {
            'peak_amplitude': np.mean(peak_amps),
            'peak_std': np.std(peak_amps),
            'rise_time': np.mean(rise_times),
            'rise_std': np.std(rise_times),
            'fall_time': np.mean(fall_times),
            'fall_std': np.std(fall_times),
            'duration': np.mean(durations),
            'duration_std': np.std(durations),
            'shape': trigger_template
        }
        
        # For gyro
        gyro_peak_amps = [np.max(s) for s in gyro_samples]
        self.gyro_characteristics = {
            'peak_amplitude': np.mean(gyro_peak_amps),
            'peak_std': np.std(gyro_peak_amps),
            'shape': gyro_template
        }
        
        print("Trigger (accel) characteristics:")
        for k, v in self.trigger_characteristics.items():
            if k != 'shape':
                print(f"  {k}: {v:.4f}")
        
        print("Gyro characteristics:")
        for k, v in self.gyro_characteristics.items():
            if k != 'shape':
                print(f"  {k}: {v:.4f}")
        
        self.calibrating_shots = False
        # Reset buffers after calibration so calibration shots don't trigger detection
        self.accel_mag_buffer.clear()
        self.gyro_mag_buffer.clear()
        self.t = []
        print("Buffers cleared, ready for real-time detection.")
        print("\n=== Shot Calibration Complete ===\n")
    
    def compute_rise_time(self, s):
        peak_idx = np.argmax(s)
        peak_val = s[peak_idx]
        left = s[:peak_idx + 1]
        ten = 0.1 * peak_val
        ninety = 0.9 * peak_val
        start_idx = 0
        end_idx = peak_idx
        for i in range(peak_idx, -1, -1):
            if left[i] < ten:
                start_idx = i
                break
        for i in range(peak_idx, -1, -1):
            if left[i] < ninety:
                end_idx = i
                break
        return (end_idx - start_idx) * self.dt
    
    def compute_fall_time(self, s):
        peak_idx = np.argmax(s)
        peak_val = s[peak_idx]
        right = s[peak_idx:]
        ten = 0.1 * peak_val
        ninety = 0.9 * peak_val
        fall_start = 0
        fall_end = len(right) - 1
        for i in range(len(right)):
            if right[i] < ninety:
                fall_start = i
                break
        for i in range(len(right)):
            if right[i] < ten:
                fall_end = i
                break
        return (fall_end - fall_start) * self.dt
    
    def compute_duration(self, s):
        peak_idx = np.argmax(s)
        peak_val = s[peak_idx]
        half = 0.5 * peak_val
        left = s[:peak_idx + 1]
        right = s[peak_idx:]
        left_half = peak_idx
        right_half = 0
        for i in range(peak_idx, -1, -1):
            if left[i] < half:
                left_half = i
                break
        for i in range(len(right)):
            if right[i] < half:
                right_half = i
                break
        dur = (peak_idx + right_half - left_half) * self.dt
        return dur
    
    def find_peaks(self, data, min_height, min_distance):
        """Simple peak detection without SciPy"""
        peaks = []
        peak_heights = []
        min_distance_samples = int(min_distance / self.dt)
        
        i = 1
        while i < len(data) - 1:
            if data[i] > data[i-1] and data[i] > data[i+1] and data[i] >= min_height:
                peaks.append(i)
                peak_heights.append(data[i])
                i += max(1, min_distance_samples)  # Enforce minimum distance
            else:
                i += 1
        
        return np.array(peaks), np.array(peak_heights)
    
    def calculate_magnitude(self, x, y, z):
        return np.sqrt(x**2 + y**2 + z**2)
    
    def handle_imu_data(self, data: bytes):
        """Parse and process IMU packets"""
        for offset in range(len(data) - 9):
            if data[offset] == 0x55 and data[offset+1] == 0xAA:
                packet_type = data[offset+2]
                length = data[offset+3]
                
                if offset + 4 + length > len(data):
                    break
                
                if packet_type == 0x08 and length == 0x06:
                    # Accelerometer data
                    x = struct.unpack(">h", data[offset+4:offset+6])[0]
                    y = struct.unpack(">h", data[offset+6:offset+8])[0]
                    z = struct.unpack(">h", data[offset+8:offset+10])[0]
                    
                    ax = (x / 32768.0) * 16.0 - self.accel_bias[0]
                    ay = (y / 32768.0) * 16.0 - self.accel_bias[1]
                    az = (z / 32768.0) * 16.0 - self.accel_bias[2]
                    
                    self.accel_data = (ax, ay, az)
                    
                elif packet_type == 0x0A and length == 0x06:
                    # Gyroscope data
                    x = struct.unpack(">h", data[offset+4:offset+6])[0]
                    y = struct.unpack(">h", data[offset+6:offset+8])[0]
                    z = struct.unpack(">h", data[offset+8:offset+10])[0]
                    
                    gx = (x / 28571.0) * 500.0 - self.gyro_bias[0]
                    gy = (y / 28571.0) * 500.0 - self.gyro_bias[1]
                    gz = (z / 28571.0) * 500.0 - self.gyro_bias[2]
                    
                    self.gyro_data = (gx, gy, gz)
                
                # Process paired data
                if self.accel_data and self.gyro_data:
                    if self.calibrating:
                        self.ignore_count += 1
                        if self.ignore_count > self.ignore_target:
                            if len(self.calib_samples) < self.calib_target:
                                self.calib_samples.append(
                                    (self.accel_data, self.gyro_data)
                                )
                    elif self.sensors_ready:
                        # Calculate magnitudes
                        accel_mag = self.calculate_magnitude(*self.accel_data)
                        gyro_mag = self.calculate_magnitude(*self.gyro_data)
                        ts = time.time()
                        
                        # Add to buffers (thread-safe)
                        with self.buffer_lock:
                            self.accel_mag_buffer.append(accel_mag)
                            self.gyro_mag_buffer.append(gyro_mag)
                            self.time_buffer.append(ts)
                        
                        # Collect for shot calibration if active
                        if self.collecting:
                            self.temp_accel_mags.append(accel_mag)
                            self.temp_gyro_mags.append(gyro_mag)
                    
                    # Reset for next pair
                    self.accel_data = None
                    self.gyro_data = None
    
    def send_command(self, cmd_bytes: bytes, description: str):
        self.peripheral.write_request(self.SERVICE_UUID, self.WRITE_UUID, cmd_bytes)
        print(f"{description} sent")
    
    def disconnect(self):
        if self.connected:
            self.peripheral.disconnect()
            self.connected = False
    
    # --- NEW/CHANGED: realtime detection loop and helpers ---
    def start_realtime_detection(self):
        """Start a background thread that continuously scans the buffer for peaks."""
        if self.trigger_characteristics is None or self.gyro_characteristics is None:
            print("Calibration not performed. Cannot start realtime detection.")
            return False
        self._detection_thread_stop.clear()
        self._detection_thread = threading.Thread(target=self._detection_loop, daemon=True)
        self._detection_thread.start()
        print("Realtime detection started.")
        return True
    
    def stop_realtime_detection(self):
        if self._detection_thread:
            self._detection_thread_stop.set()
            self._detection_thread.join(timeout=1.0)
            self._detection_thread = None
            print("Realtime detection stopped.")
    
    def _detection_loop(self):
        """Continuously check the buffer for new candidate peaks and validate them."""
        # We will only look for peaks that have enough margin around them (window_samples)
        needed_len = 2 * self.window_samples + 1
        
        while not self._detection_thread_stop.is_set() and running:
            # copy buffers under lock to avoid blocking sensor callback for long
            with self.buffer_lock:
                accel_arr = np.array(self.accel_mag_buffer)
                gyro_arr = np.array(self.gyro_mag_buffer)
                time_arr = np.array(self.time_buffer)
            
            if len(accel_arr) >= needed_len:
                # We'll only search recent portion to save CPU (last 1.5 * buffer window)
                search_start = max(0, len(accel_arr) - int(self.fs * 2.0))  # last 2 sec
                sub_accel = accel_arr[search_start:]
                
                # compute candidate peaks in sub_accel (indexes relative to sub_accel)
                min_height = self.trigger_characteristics['peak_amplitude'] - 2 * self.trigger_characteristics['peak_std']
                min_height = max(min_height, 0.5)
                candidate_peaks, _ = self.find_peaks(sub_accel, min_height=min_height, min_distance=self.min_time_between_shots)
                
                # convert to global indices
                candidate_peaks_global = candidate_peaks + search_start
                
                for peak_idx in candidate_peaks_global:
                    # Avoid double-reporting: use the timestamp index as unique id
                    ts = time_arr[peak_idx] if peak_idx < len(time_arr) else None
                    if ts is None:
                        continue
                    # If this timestamp already reported (within reported_peak_indices) skip
                    # We'll identify by integer index in buffer to keep it simple
                    if peak_idx in self.reported_peak_indices:
                        continue
                    
                    # Check min time since last shot
                    if ts - self.last_shot_time < self.min_time_between_shots:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    
                    # Need full window around peak
                    start = peak_idx - self.window_samples
                    end = peak_idx + self.window_samples + 1
                    if start < 0 or end > len(accel_arr):
                        # Not enough data around peak yet (edge), skip this peak for now
                        continue
                    
                    accel_window = accel_arr[start:end]
                    gyro_window = gyro_arr[start:end]
                    
                    # Compute features (same checks as your offline method)
                    cand_peak = np.max(accel_window)
                    cand_rise = self.compute_rise_time(accel_window)
                    cand_fall = self.compute_fall_time(accel_window)
                    cand_duration = self.compute_duration(accel_window)
                    # protect corrcoef when constant arrays or bad shapes
                    try:
                        accel_corr = np.corrcoef(accel_window, self.trigger_characteristics['shape'])[0, 1]
                    except Exception:
                        accel_corr = 0.0
                    cand_gyro_peak = np.max(gyro_window)
                    try:
                        gyro_corr = np.corrcoef(gyro_window, self.gyro_characteristics['shape'])[0, 1]
                    except Exception:
                        gyro_corr = 0.0
                    
                    # Apply thresholds (same logic)
                    if abs(cand_peak - self.trigger_characteristics['peak_amplitude']) > 4 * self.trigger_characteristics['peak_std']:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    if abs(cand_rise - self.trigger_characteristics['rise_time']) > 4 * self.trigger_characteristics['rise_std']:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    if abs(cand_fall - self.trigger_characteristics['fall_time']) > 4 * self.trigger_characteristics['fall_std']:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    if abs(cand_duration - self.trigger_characteristics['duration']) > 4 * self.trigger_characteristics['duration_std']:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    if accel_corr < 0.4:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    if abs(cand_gyro_peak - self.gyro_characteristics['peak_amplitude']) > 4 * self.gyro_characteristics['peak_std']:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    if gyro_corr < 0.4:
                        self.reported_peak_indices.add(peak_idx)
                        continue
                    
                    # If we reach here, it's a valid shot
                    self.shot_counter += 1
                    self.last_shot_time = ts
                    self.reported_peak_indices.add(peak_idx)
                    event = ShotDetectedEvent(timestamp=ts,
                                              shot_number=self.shot_counter,
                                              magnitude=cand_peak,
                                              is_valid_shot=True,
                                              reason="Realtime match")
                    print(event)
            
            # sleep a short while - tune as needed (don't busy wait)
            time.sleep(0.01)
    
    # Keep your offline detect_shots too (optional) - uses provided arrays
    def detect_shots(self):
        """Legacy offline detector for an array assigned to self.accel_mag & self.gyro_mag"""
        if self.trigger_characteristics is None or self.gyro_characteristics is None:
            print("Calibration not performed.")
            return []
        
        accel = self.accel_mag
        gyro = self.gyro_mag
        if accel is None or gyro is None:
            return []
        
        min_height = self.trigger_characteristics['peak_amplitude'] - 2 * self.trigger_characteristics['peak_std']
        candidate_peaks, _ = self.find_peaks(
            accel,
            min_height=max(min_height, 0.5),
            min_distance=self.min_time_between_shots
        )
        
        detected = []
        shot_number = 0
        
        for peak_idx in candidate_peaks:
            start = max(0, peak_idx - self.window_samples)
            end = min(len(accel), peak_idx + self.window_samples + 1)
            
            accel_window = accel[start:end]
            gyro_window = gyro[start:end]
            
            left_pad = self.window_samples - (peak_idx - start)
            right_pad = self.window_samples - (end - peak_idx - 1)
            
            if left_pad > 0:
                accel_window = np.pad(accel_window, (left_pad, 0), 'constant')
                gyro_window = np.pad(gyro_window, (left_pad, 0), 'constant')
            if right_pad > 0:
                accel_window = np.pad(accel_window, (0, right_pad), 'constant')
                gyro_window = np.pad(gyro_window, (0, right_pad), 'constant')
            
            # Compute accel features
            cand_peak = np.max(accel_window)
            cand_rise = self.compute_rise_time(accel_window)
            cand_fall = self.compute_fall_time(accel_window)
            cand_duration = self.compute_duration(accel_window)
            accel_corr = np.corrcoef(accel_window, self.trigger_characteristics['shape'])[0, 1]
            
            # Compute gyro features
            cand_gyro_peak = np.max(gyro_window)
            gyro_corr = np.corrcoef(gyro_window, self.gyro_characteristics['shape'])[0, 1]
            
            # Check matches
            if abs(cand_peak - self.trigger_characteristics['peak_amplitude']) > 4 * self.trigger_characteristics['peak_std']:
                continue
            if abs(cand_rise - self.trigger_characteristics['rise_time']) > 4 * self.trigger_characteristics['rise_std']:
                continue
            if abs(cand_fall - self.trigger_characteristics['fall_time']) > 4 * self.trigger_characteristics['fall_std']:
                continue
            if abs(cand_duration - self.trigger_characteristics['duration']) > 4 * self.trigger_characteristics['duration_std']:
                continue
            if accel_corr < 0.4:
                continue
            
            if abs(cand_gyro_peak - self.gyro_characteristics['peak_amplitude']) > 4 * self.gyro_characteristics['peak_std']:
                continue
            if gyro_corr < 0.4:
                continue
            
            # Valid detection
            shot_number += 1
            event = ShotDetectedEvent(
                timestamp=self.t[peak_idx] if self.t is not None else time.time(),
                shot_number=shot_number,
                magnitude=cand_peak,
                is_valid_shot=True,
                reason="Trigger characteristics match"
            )
            detected.append(event)
        
        return detected

# ---------------- main() flow ----------------
def main():
    device = RT1Device()
    
    if not device.connect():
        sys.exit(1)
    
    if not device.initialize_sensors():
        device.disconnect()
        sys.exit(1)
    
    if not device.calibrate_bias():
        device.disconnect()
        sys.exit(1)
    
    # shot calibration
    print("\nReady for shot calibration.")
    input("Press Enter when ready to calibrate shot detection...")
    device.start_shot_calibration()
    
    # Start realtime detection for an open-ended test session
    print("\nStarting realtime detection session. Press Ctrl+C to stop.")
    if device.start_realtime_detection():
        try:
            # keep main thread alive while detection runs in background
            while running:
                time.sleep(0.5)
        except KeyboardInterrupt:
            pass
        finally:
            device.stop_realtime_detection()
    
    device.disconnect()

if __name__ == "__main__":
    main()
