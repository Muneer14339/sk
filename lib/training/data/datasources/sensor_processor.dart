import 'dart:async';
import 'dart:math';

import '../../domain/entities/shot_analysis.dart';

// Provided by you, kept as is
class SensorData {
  final double x, y, z;
  SensorData(this.x, this.y, this.z);
}

// Provided by you, kept as is
class Orientation {
  final double roll, pitch, yaw;
  final bool shotDetected;
  final int timestamp;

  Orientation(
      this.roll, this.pitch, this.yaw, this.shotDetected, this.timestamp);
}

class ComplementaryFilter {
  final double alpha;
  double angle = 0.0;
  static const double pi = 3.141592653589793;

  ComplementaryFilter(this.alpha);

  double update(double gyroRate, double accelAngle, double dt) {
    // if (dt <= 0) {
    //   return angle;
    // }
    angle =
        alpha * (angle + gyroRate * dt * pi / 180.0) + (1 - alpha) * accelAngle;
    return angle;
  }

  void reset() {
    angle = 0.0;
  }
}

class YawKalmanFilter {
  double estimate = 0.0;
  double bias = 0.0;
  double p00 = 1.0;
  double p01 = 0.0;
  double p10 = 0.0;
  double p11 = 1.0;
  double processNoise = 0.001;
  double measurementNoise = 0.03;
  double biasProcessNoise = 0.0005;
  double stationaryThreshold = 0.25;

  double runningMean = 0.0;
  double runningVariance = 0.0;
  int sampleCount = 0;
  static const int varianceWindowSize = 50;
  double adaptiveMeasurementNoise = 0.03;

  void updateVarianceEstimate(double gyroRate) {
    sampleCount++;
    if (sampleCount > varianceWindowSize) {
      sampleCount = 1;
      runningMean = gyroRate.abs();
      runningVariance = 0.0;
      return;
    }

    double delta = gyroRate.abs() - runningMean;
    runningMean += delta / sampleCount;
    double delta2 = gyroRate.abs() - runningMean;
    runningVariance += delta * delta2;

    if (sampleCount > 5) {
      double variance = runningVariance / sampleCount;
      adaptiveMeasurementNoise = max(0.01, min(0.1, variance * 0.5));
    }
  }

  void update(double gyroRate, double dt) {
    updateVarianceEstimate(gyroRate);

    double absGyroRate = gyroRate.abs();
    if (absGyroRate < stationaryThreshold) {
      double stationaryRatio = 1.0 - (absGyroRate / stationaryThreshold);
      double biasLearningRate = 0.001 * stationaryRatio;
      bias = bias * (1.0 - biasLearningRate) + gyroRate * biasLearningRate;

      // ✅ FIX 1: Remove early return
      if (absGyroRate < stationaryThreshold * 0.5) {
        bias = bias * 0.999 + gyroRate * 0.001; // Bias update only
        // DON'T RETURN - let filter continue
      }
    }

    double rate = gyroRate - bias;
    estimate += rate * dt * pi / 180.0;

    p00 += dt * (dt * p11 - p01 - p10 + processNoise);
    p01 -= dt * p11;
    p10 -= dt * p11;
    p11 += biasProcessNoise * dt;

    double s = p00 + measurementNoise;
    double k0 = p00 / s;
    double k1 = p10 / s;

    double innovation = 0;
    bias += k1 * innovation;

    p00 *= (1 - k0);
    p01 *= (1 - k0);
    p10 -= k1 * p00;
    p11 -= k1 * p01;

    while (estimate > pi) {
      estimate -= 2 * pi;
    }
    while (estimate < -pi) {
      estimate += 2 * pi;
    }
  }

  void reset() {
    estimate = 0.0;
    bias = 0.0;
    p00 = 1.0;
    p01 = 0.0;
    p10 = 0.0;
    p11 = 1.0;
  }
}

class SensorProcessor {
  static const double alpha = 0.95;
  static const double lpfAlpha = 0.0392;
  static const int calibrationSamples = 500;
  static const bool debug = true;

  final List<int> _dataBuffer = [];
  SensorData? latestAccelData;
  SensorData? latestGyroData;

  int? latestAccelTimestamp;
  int? latestGyroTimestamp;

  double _roll = 0.0;
  double _pitch = 0.0;
  double _yaw = 0.0;

  // Public getters for current orientation
  double get roll => _roll;
  double get pitch => _pitch;
  double get yaw => _yaw;

  List<double> rollList = [];
  List<double> pitchList = [];

  // ✅ NEW: Shot Analysis Variables
  final List<SensorReading> _stabilityBuffer = [];

  final StreamController<ShotDetectedEvent> _shotDetectionController =
  StreamController<ShotDetectedEvent>.broadcast();
  Stream<ShotDetectedEvent> get shotDetectionStream =>
      _shotDetectionController.stream;

  final List<Orientation> _preShotOrientationBuffer = [];
  static const int _preShotBufferSize = 200;
  static const double _preShotStabilityThreshold = 0.003; // Tightened for maximum stability (approx. 1-2 deg std dev)
  // ✅ NEW: Callback for BleRepository recalibration
  Function()? _onRecalibrateCallback;

  // ✅ NEW: Set recalibration callback from BleRepositoryImpl
  void setRecalibrationCallback(Function() callback) {
    _onRecalibrateCallback = callback;
    print('SensorProcessor: 🔗 Recalibration callback set');
  }

  // Calibration offsets
  double gyroXOffset = 0.0, gyroYOffset = 0.0, gyroZOffset = 0.0;
  double accelXOffset = 0.0, accelYOffset = 0.0, accelZOffset = 0.0;
  static bool gyroCalibrated = false;
  static bool accelCalibrated = false;

  bool isFirstSampleAccel = true;
  double filteredAccelX = 0.0;
  double filteredAccelY = 0.0;
  double filteredAccelZ = 0.0;
  double lastGyroTimestamp = 0;

  double rollOffset = 0.0;
  double pitchOffset = 0.0;
  double yawOffset = 0.0;

  ComplementaryFilter rollFilter = ComplementaryFilter(alpha);
  ComplementaryFilter pitchFilter = ComplementaryFilter(alpha);
  YawKalmanFilter yawFilter = YawKalmanFilter();

  double gyroSumX = 0.0, gyroSumY = 0.0, gyroSumZ = 0.0;
  double accelSumX = 0.0, accelSumY = 0.0, accelSumZ = 0.0;
  int gyroCalibrationCount = 0;
  int accelCalibrationCount = 0;

  static const int samplesToSkip = 10;
  final StreamController<Orientation> orientationStreamController =
  StreamController.broadcast();

  Stream<Orientation> get orientationStream =>
      orientationStreamController.stream;

  double _calculateMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  void _updatePreShotOrientationBuffer() {
    final currentOrientation = Orientation(
      _roll - rollOffset,
      _pitch - pitchOffset,
      _yaw - yawOffset,
      false,
      DateTime.now().millisecondsSinceEpoch,
    );

    _preShotOrientationBuffer.add(currentOrientation);

    // Keep only the last N readings (maintain buffer size)
    if (_preShotOrientationBuffer.length > _preShotBufferSize) {
      _preShotOrientationBuffer.removeAt(0);
    }
  }

  // ✅ MODIFIED: Check if pre-shot period is stable enough for accurate zero point, now including yaw
  bool _isPreShotPeriodStable(List<Orientation> recentData) {
    if (debug) {
      print(
          '📊 Pre-shot stability check: ${recentData.length} readings, variance < $_preShotStabilityThreshold');
    }
    if (recentData.length < 10) return false;

    // Calculate variance for roll, pitch, and yaw
    final rollValues = recentData.map((o) => o.roll).toList();
    final pitchValues = recentData.map((o) => o.pitch).toList();
    final yawValues = recentData.map((o) => o.yaw).toList();

    final rollAvg = rollValues.reduce((a, b) => a + b) / rollValues.length;
    final pitchAvg = pitchValues.reduce((a, b) => a + b) / pitchValues.length;
    final yawAvg = yawValues.reduce((a, b) => a + b) / yawValues.length;

    final rollVariance =
        rollValues.map((v) => pow(v - rollAvg, 2)).reduce((a, b) => a + b) /
            rollValues.length;
    final pitchVariance =
        pitchValues.map((v) => pow(v - pitchAvg, 2)).reduce((a, b) => a + b) /
            pitchValues.length;
    final yawVariance =
        yawValues.map((v) => pow(v - yawAvg, 2)).reduce((a, b) => a + b) /
            yawValues.length;

    // Check if roll, pitch, and yaw are all stable
    final isStable = rollVariance < _preShotStabilityThreshold &&
        pitchVariance < _preShotStabilityThreshold &&
        yawVariance < _preShotStabilityThreshold;

    if (debug && !isStable) {
      print(
          '⚠️ Pre-shot not stable: Roll var=${rollVariance.toStringAsFixed(6)}, Pitch var=${pitchVariance.toStringAsFixed(6)}, Yaw var=${yawVariance.toStringAsFixed(6)}');
    } else if (debug) {
      print(
          '✅ Pre-shot stable: Roll var=${rollVariance.toStringAsFixed(6)}, Pitch var=${pitchVariance.toStringAsFixed(6)}, Yaw var=${yawVariance.toStringAsFixed(6)}');
    }

    return isStable;
  }

  void resetForNewSession() {
    _roll = 0.0;
    _pitch = 0.0;
    _yaw = 0.0;
    pitchOffset = 0.0;
    yawOffset = 0.0;
    rollOffset = 0.0;
    rollFilter.reset();
    pitchFilter.reset();
    yawFilter.reset();

    gyroSumX = gyroSumY = gyroSumZ = 0.0;
    accelSumX = accelSumY = accelSumZ = 0.0;
    gyroCalibrationCount = accelCalibrationCount = 0;
    // gyroCalibrated = false;
    // accelCalibrated = false;
    isFirstSampleAccel = true;
    filteredAccelX = 0.0;
    filteredAccelY = 0.0;
    filteredAccelZ = 0.0;

    _stabilityBuffer.clear();
    //_lastShotTime = null;

    // ✅ NEW: Reset MantisX dynamic center alignment data
    _preShotOrientationBuffer.clear();

    // Clear any buffered data
    _dataBuffer.clear();
    _deviceOrientation = DeviceOrientation.upward; // ✅ Add this line
    _orientationDetected = false; // ✅ Add this
  }

  double getDeltaTime(int currentTimestamp) {
    double dt = (lastGyroTimestamp != 0 && currentTimestamp > lastGyroTimestamp)
        ? (currentTimestamp - lastGyroTimestamp) / 1000000.0
        : 0.0012; // Default to 400Hz if timestamp is invalid

    // Limit maximum dt to prevent jumps after pauses
    if (dt > 0.0012) dt = 0.0012;

    lastGyroTimestamp = currentTimestamp.toDouble();
    return dt;
  }

  bool isRecalibrated = true;
  bool lastCalibrated = false;

  int? lastCalibratedTime;
  void processSensorPair(
      SensorData accel, SensorData gyro, bool shotDetected, int timestamp)
  {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (!isRecalibrated && !lastCalibrated ) {
      if (lastCalibratedTime == null || (now - lastCalibratedTime!) >= 1000) {
        lastCalibrated = true;
        lastCalibratedTime = now; // ✅ update last calibrated time
        if (_onRecalibrateCallback != null) {
          _onRecalibrateCallback!();
        }
      }
    }

    // ✅ MODIFIED: Call BleRepository recalibration instead of local recalibration
    double accelPitch = atan2(accel.y, accel.z);
    double accelRoll =
    atan2(-accel.x, sqrt(accel.y * accel.y + accel.z * accel.z));

    double currentDt = getDeltaTime(timestamp);

    // ✅ Now apply sign flip
    final sign = _deviceOrientation == DeviceOrientation.upward ? 1.0 : -1.0;
    if (currentDt > 0) {
      yawFilter.update(gyro.z, currentDt);
      _roll = rollFilter.update(gyro.y, accelRoll, currentDt) *sign;
      _pitch = pitchFilter.update(gyro.x, accelPitch, currentDt)*sign;
      _yaw = yawFilter.estimate;
    }
    else {
      _roll = accelRoll*sign;
      _pitch = accelPitch*sign;
      //_yaw = yawFilter.estimate;
    }

    // ✅ NEW: Update pre-shot orientation buffer for dynamic center alignment
    _updatePreShotOrientationBuffer();

    if (rollList.length >= 2000) {
      rollList.removeAt(0);
    }
    if (pitchList.length >= 2000) {
      pitchList.removeAt(0);
    }
    rollList.add((_roll - rollOffset) * 180 / pi);
    pitchList.add((_pitch - pitchOffset) * 180 / pi);


    // ✅ MODIFIED: Use callback to trigger BleRepository recalibration instead of local recalibration
    Orientation orientation;
    if (isStable(rollList, 0.2) == false || isStable(pitchList, 0.2) == false) {
      orientation = Orientation(
        _roll - rollOffset,
        _pitch - pitchOffset,
        _yaw - yawOffset, // yaw not used
        shotDetected,
        timestamp,
      );
      if (!orientationStreamController.isClosed) {
        orientationStreamController.add(orientation);
      }
      if (!isRecalibrated) {
        isRecalibrated = true;
        lastCalibrated = false;
      }
      if ((((_roll - rollOffset) * 180 / pi).abs() > 90) ||
          (((_pitch - pitchOffset) * 180 / pi).abs() > 90) ||
          (now - (lastCalibratedTime ?? 0)) >= 3000) {
        if (isStableForRecalibration(rollList, 0.1) ==
            true && // Assuming typo, changed 01 to 0.1
            isStableForRecalibration(pitchList, 0.1) == true) {
          isRecalibrated = false;
        }
      }
    } else {
      if (isRecalibrated) {
        isRecalibrated = false;
      }
    }
  }

  // ✅ 2. Add class variable
  DeviceOrientation _deviceOrientation = DeviceOrientation.upward;

// ✅ 3. Replace detectDeviceOrientation with simplified version
  DeviceOrientation _detectDeviceOrientation(SensorData accel) {
    return accel.z > 0 ? DeviceOrientation.upward : DeviceOrientation.downward;
  }

// ✅ 1. Add flag to detect orientation only once
  bool _orientationDetected = false;
  bool isTrainingActive = false;
  /// Processes raw byte data received from the sensor stream.
  void processData(List<int> newBytes) {
    if (!isTrainingActive && gyroCalibrated && accelCalibrated) {
      if(_dataBuffer.isNotEmpty){
        _dataBuffer.clear();
      }
      return; // Skip processing to save resources
    }



    _dataBuffer.addAll(newBytes);

    int currentParsePosition = 0;
    bool shotDetectedInThisPacket = false;

    double prevAccelX = filteredAccelX;
    double prevAccelY = filteredAccelY;
    double prevAccelZ = filteredAccelZ;
    double prevGyroX = filteredAccelX;
    double prevGyroY = filteredAccelY;
    double prevGyroZ = filteredAccelZ;

    while (currentParsePosition + 3 < _dataBuffer.length) {
      if (_dataBuffer[currentParsePosition] == 0x55 &&
          _dataBuffer[currentParsePosition + 1] == 0xAA) {
        final packetType = _dataBuffer[currentParsePosition + 2];
        final payloadLength = _dataBuffer[currentParsePosition + 3];
        final totalPacketLength = 4 + payloadLength;

        if (currentParsePosition + totalPacketLength > _dataBuffer.length) {
          break;
        }

        if (packetType == 0x06) {
          if(_isPreShotPeriodStable(_preShotOrientationBuffer))
            {
              shotDetectedInThisPacket = true;
              print('shotDetectedInThisPacket: $shotDetectedInThisPacket');
            }else{
            print('Shot Missed Because of PreShot Not stable:');
          }
        }

        if (!((packetType == 0x08 || packetType == 0x0A) &&
            payloadLength == 0x06)) {
          currentParsePosition += totalPacketLength;
          continue;
        }

        int x = (_dataBuffer[currentParsePosition + 4] << 8) |
        _dataBuffer[currentParsePosition + 5];
        int y = (_dataBuffer[currentParsePosition + 6] << 8) |
        _dataBuffer[currentParsePosition + 7];
        int z = (_dataBuffer[currentParsePosition + 8] << 8) |
        _dataBuffer[currentParsePosition + 9];

        x = x > 32767 ? x - 65536 : x;
        y = y > 32767 ? y - 65536 : y;
        z = z > 32767 ? z - 65536 : z;

        int packetTimestamp = DateTime.now().microsecondsSinceEpoch;

        // ✅ 2. Update Accelerometer processing
        if (packetType == 0x08) {
          // ✅ Detect orientation BEFORE sign flip (raw data use karo)
          if (!_orientationDetected) {
            final rawZ = (z / 32768.0) * -16.0; // Original calculation
            _deviceOrientation = rawZ > 0
                ? DeviceOrientation.upward
                : DeviceOrientation.downward;
            _orientationDetected = true;
            print('📱 Device Orientation: ${_deviceOrientation == DeviceOrientation.upward ? "Upward" : "Downward"}');
          }

          // ✅ Now apply sign flip
          final sign = _deviceOrientation == DeviceOrientation.downward ? 1.0 : -1.0;
          final ax = (x / 32768.0) * 16.0 * sign;
          final ay = (y / 32768.0) * 16.0 * sign;
          final az = (z / 32768.0) * 16.0 * sign;

          if (!accelCalibrated) {
            // ✅ First sample ke liye previous values set karo
            if (accelCalibrationCount == 0) {
              prevAccelX = ax;
              prevAccelY = ay;
              prevAccelZ = az;
            }

            final diffX = (ax - prevAccelX).abs();
            final diffY = (ay - prevAccelY).abs();
            final diffZ = (az - prevAccelZ).abs();
            final totalMovement = diffX + diffY + diffZ;

            prevAccelX = ax;
            prevAccelY = ay;
            prevAccelZ = az;

            if (totalMovement > 2) {
              resetForNewSession();
            } else {
              if (accelCalibrationCount >= samplesToSkip) {
                accelSumX += ax;
                accelSumY += ay;
                accelSumZ += az;
              }
              accelCalibrationCount++;

              if (accelCalibrationCount >= calibrationSamples + samplesToSkip) {
                accelXOffset = accelSumX / calibrationSamples;
                accelYOffset = accelSumY / calibrationSamples;
                accelZOffset = (accelSumZ / calibrationSamples) - 1.0;
                accelCalibrated = true;
                if (debug) {
                  print("Accelerometer calibrated: X=${accelXOffset.toStringAsFixed(4)}, Y=${accelYOffset.toStringAsFixed(4)}, Z=${accelZOffset.toStringAsFixed(4)}");
                }
              }
            }
          }
          else {
            final cx = ax - accelXOffset;
            final cy = ay - accelYOffset;
            final cz = az - accelZOffset;

            if (isFirstSampleAccel) {
              filteredAccelX = cx;
              filteredAccelY = cy;
              filteredAccelZ = cz;
              isFirstSampleAccel = false;
            } else {
              filteredAccelX = lpfAlpha * cx + (1 - lpfAlpha) * filteredAccelX;
              filteredAccelY = lpfAlpha * cy + (1 - lpfAlpha) * filteredAccelY;
              filteredAccelZ = lpfAlpha * cz + (1 - lpfAlpha) * filteredAccelZ;
            }

            latestAccelData =
                SensorData(filteredAccelX, filteredAccelY, filteredAccelZ);
            latestAccelTimestamp = packetTimestamp;
          }
        }
        // ✅ 5. Update Gyroscope processing (line ~580)
        else if (packetType == 0x0A) {
          final sign = _deviceOrientation == DeviceOrientation.downward ? -1.0 : 1.0;
          final gx = (x / 28571.0) * 500.0 * sign;
          final gy = (y / 28571.0) * 500.0 * sign;
          final gz = (z / 28571.0) * 500.0 * sign;

          if (!gyroCalibrated) {
            // ✅ Movement check like accel
            final diffX = (gx - prevGyroX).abs();
            final diffY = (gy - prevGyroY).abs();
            final diffZ = (gz - prevGyroZ).abs();
            final totalMovement = diffX + diffY + diffZ;

            prevGyroX = gx;
            prevGyroY = gy;
            prevGyroZ = gz;

            if (totalMovement > 10) {
              // threshold tum adjust kar sakte ho
              resetForNewSession();
            } else {
              if (gyroCalibrationCount >= samplesToSkip) {
                gyroSumX += gx;
                gyroSumY += gy;
                gyroSumZ += gz;
              }
              gyroCalibrationCount++;

              if (gyroCalibrationCount >= calibrationSamples + samplesToSkip) {
                gyroXOffset = gyroSumX / calibrationSamples;
                gyroYOffset = gyroSumY / calibrationSamples;
                gyroZOffset = gyroSumZ / calibrationSamples;
                gyroCalibrated = true;
                yawFilter.bias = 0.0;
                if (debug) {
                  print(
                      "Gyroscope calibrated: X=${gyroXOffset.toStringAsFixed(4)}, Y=${gyroYOffset.toStringAsFixed(4)}, Z=${gyroZOffset.toStringAsFixed(4)}");
                }
              }
            }
          } else {
            final cx = gx - gyroXOffset;
            final cy = gy - gyroYOffset;
            final cz = gz - gyroZOffset;
            latestGyroData = SensorData(cx, cy, cz);
            latestGyroTimestamp = packetTimestamp;
          }
        }

        currentParsePosition += totalPacketLength;

        if (gyroCalibrated &&
            accelCalibrated &&
            latestAccelData != null &&
            latestGyroData != null &&
            latestAccelTimestamp != null &&
            latestGyroTimestamp != null) {
          int consolidatedTimestamp =
          max(latestAccelTimestamp!, latestGyroTimestamp!);

          processSensorPair(latestAccelData!, latestGyroData!,
              shotDetectedInThisPacket, consolidatedTimestamp);

          latestAccelData = null;
          latestGyroData = null;
          latestAccelTimestamp = null;
          latestGyroTimestamp = null;
          shotDetectedInThisPacket = false;
        }
      } else {
        currentParsePosition++;
        shotDetectedInThisPacket = false;
      }
    }

    if (currentParsePosition > 0) {
      _dataBuffer.removeRange(0, min(currentParsePosition, _dataBuffer.length));
    }
  }

  // ✅ LOCAL: Only for sensor data recalibration (rollOffset, pitchOffset)
  void recalibrate() {
    rollOffset = _roll;
    pitchOffset = _pitch;
    yawOffset = _yaw;
  }

  bool get isCalibrated => gyroCalibrated && accelCalibrated;

  void dispose() {
    if (!orientationStreamController.isClosed) {
      orientationStreamController.close();
    }
    if (!_shotDetectionController.isClosed) {
      _shotDetectionController.close();
    }

    // ✅ NEW: Clean up MantisX dynamic center alignment buffers
    _preShotOrientationBuffer.clear();

    // Clear callback
    _onRecalibrateCallback = null;

    print('SensorProcessor: Disposed');
  }

  bool isStable(List<double> history, double threshold) {
    if (history.length < 2)
      return false; // Compare karne ke liye kam se kam 2 values chahiye

    double firstValue = history[0];
    for (int i = 0; i < history.length - 1; i++) {
      double diff = (history[i + 1] - firstValue).abs(); // Absolute difference
      if (diff >= threshold) {
        return false; // Agar difference limit se zyada ho gaya → unstable
      }
    }

    return true; // Sab differences threshold ke andar → stable
  }

  bool isStableForRecalibration(List<double> history, double threshold) {
    if (history.length < 2)
      return false; // Compare karne ke liye kam se kam 2 values chahiye

    // ✅ Sirf last 100 values consider karo
    final recentHistory =
    history.length > 100 ? history.sublist(history.length - 100) : history;

    double firstValue = recentHistory[0];
    for (int i = 0; i < recentHistory.length - 1; i++) {
      double diff =
      (recentHistory[i + 1] - firstValue).abs(); // Absolute difference
      if (diff >= threshold) {
        return false; // Agar difference threshold se zyada hua → unstable
      }
    }

    return true; // Sab within threshold hain → stable
  }
  // Add new method for disconnect reset:
  void resetCalibrationFlags() {
    isTrainingActive = false;
    gyroCalibrated = false;
    accelCalibrated = false;
    gyroSumX = gyroSumY = gyroSumZ = 0.0;
    accelSumX = accelSumY = accelSumZ = 0.0;
    gyroCalibrationCount = accelCalibrationCount = 0;
    // Also reset orientation offsets
    rollOffset = 0.0;
    pitchOffset = 0.0;
    yawOffset = 0.0;
    print('🔄 Calibration flags reset - device disconnected');
  }
}
// ✅ 1. Add enum at top of class
enum DeviceOrientation { upward, downward }