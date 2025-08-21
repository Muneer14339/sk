// sensor_processor.dart - Updated to call BleRepository recalibration

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
    if (dt <= 0) {
      return angle;
    }
    angle =
        alpha * (angle + gyroRate * dt * pi / 180.0) + (1 - alpha) * accelAngle;
    return angle;
  }

  void reset() {
    angle = 0.0;
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

  // Public getters for current orientation
  double get roll => _roll;
  double get pitch => _pitch;

  List<double> rollList = [];
  List<double> pitchList = [];

  // ✅ NEW: Shot Analysis Variables
  final List<SensorReading> _stabilityBuffer = [];
  DateTime? _lastShotTime;
  int _shotCounter = 0;
  static const int _minTimeBetweenShots = 3000; // 3 seconds in milliseconds

  final StreamController<ShotDetectedEvent> _shotDetectionController =
  StreamController<ShotDetectedEvent>.broadcast();
  Stream<ShotDetectedEvent> get shotDetectionStream =>
      _shotDetectionController.stream;

  final List<Orientation> _preShotOrientationBuffer = [];
  static const int _preShotBufferSize = 100;
  static const double _preShotStabilityThreshold = 0.05;
  Orientation? _currentShotDynamicZero;

  // ✅ NEW: Callback for BleRepository recalibration
  Function()? _onRecalibrateCallback;

  // ✅ NEW: Set recalibration callback from BleRepositoryImpl
  void setRecalibrationCallback(Function() callback) {
    _onRecalibrateCallback = callback;
    print('SensorProcessor: 🔗 Recalibration callback set');
  }

  // Calibration offsets
  double gyroXOffset = 0.0, gyroYOffset = 0.0;
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

  ComplementaryFilter rollFilter = ComplementaryFilter(alpha);
  ComplementaryFilter pitchFilter = ComplementaryFilter(alpha);

  double gyroSumX = 0.0, gyroSumY = 0.0, gyroSumZ = 0.0;
  double accelSumX = 0.0, accelSumY = 0.0, accelSumZ = 0.0;
  int gyroCalibrationCount = 0;
  int accelCalibrationCount = 0;

  static const int samplesToSkip = 10;
  static const int maxBufferSize = 50;
  DateTime? lastShotTime;
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
      0,
      false,
      DateTime.now().millisecondsSinceEpoch,
    );

    _preShotOrientationBuffer.add(currentOrientation);

    // Keep only the last N readings (maintain buffer size)
    if (_preShotOrientationBuffer.length > _preShotBufferSize) {
      _preShotOrientationBuffer.removeAt(0);
    }
  }

  // ✅ NEW: Calculate dynamic zero point from pre-shot orientation (MantisX style)
  Orientation? _calculateDynamicZeroPoint() {
    if (_preShotOrientationBuffer.length < 20)
      return null; // Need at least 200ms of data

    // Get the last 0.5-1.5 seconds of data (last 50-150 readings at ~100Hz)
    final recentData = _preShotOrientationBuffer.length >= 100
        ? _preShotOrientationBuffer
        .sublist(_preShotOrientationBuffer.length - 100)
        : _preShotOrientationBuffer
        .sublist(_preShotOrientationBuffer.length - 50);

    // Check if the pre-shot period is stable (shooter is aiming steadily)
    if (!_isPreShotPeriodStable(recentData)) {
      return null; // Not stable enough for accurate zero point
    }

    // Calculate average orientation during stable pre-shot period
    double avgRoll = 0.0;
    double avgPitch = 0.0;

    for (final orientation in recentData) {
      avgRoll += orientation.roll;
      avgPitch += orientation.pitch;
    }

    avgRoll /= recentData.length;
    avgPitch /= recentData.length;

    // Create dynamic zero point
    final dynamicZero = Orientation(
      avgRoll,
      avgPitch,
      0, // yaw not used
      false,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (debug) {
      print(
          '🎯 Dynamic Zero Point Calculated: Roll=${avgRoll.toStringAsFixed(4)}, Pitch=${avgPitch.toStringAsFixed(4)}');
      print(
          '📊 Pre-shot stability: ${recentData.length} readings, variance < $_preShotStabilityThreshold');
    }

    return dynamicZero;
  }

  // ✅ NEW: Check if pre-shot period is stable enough for accurate zero point
  bool _isPreShotPeriodStable(List<Orientation> recentData) {
    if (recentData.length < 10) return false;

    // Calculate variance for roll and pitch
    final rollValues = recentData.map((o) => o.roll).toList();
    final pitchValues = recentData.map((o) => o.pitch).toList();

    final rollAvg = rollValues.reduce((a, b) => a + b) / rollValues.length;
    final pitchAvg = pitchValues.reduce((a, b) => a + b) / pitchValues.length;

    final rollVariance =
        rollValues.map((v) => pow(v - rollAvg, 2)).reduce((a, b) => a + b) /
            rollValues.length;
    final pitchVariance =
        pitchValues.map((v) => pow(v - pitchAvg, 2)).reduce((a, b) => a + b) /
            pitchValues.length;

    // Check if both roll and pitch are stable
    final isStable = rollVariance < _preShotStabilityThreshold &&
        pitchVariance < _preShotStabilityThreshold;

    if (debug && !isStable) {
      print(
          '⚠️ Pre-shot period not stable: Roll variance=${rollVariance.toStringAsFixed(6)}, Pitch variance=${pitchVariance.toStringAsFixed(6)}');
    }

    return isStable;
  }

  // ✅ NEW: Get orientation relative to dynamic zero point
  Orientation getOrientationRelativeToDynamicZero() {
    if (_currentShotDynamicZero == null) {
      // Fall back to static calibration if no dynamic zero available
      return Orientation(_roll - rollOffset, _pitch - pitchOffset, 0, false,
          DateTime.now().millisecondsSinceEpoch);
    }

    // Calculate orientation relative to dynamic zero point
    final relativeRoll = _roll - rollOffset - _currentShotDynamicZero!.roll;
    final relativePitch = _pitch - pitchOffset - _currentShotDynamicZero!.pitch;

    return Orientation(
      relativeRoll,
      relativePitch,
      0,
      false,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ✅ NEW: Manually trigger dynamic zero point calculation (useful for testing)
  bool calculateDynamicZeroPointNow() {
    final dynamicZero = _calculateDynamicZeroPoint();
    if (dynamicZero != null) {
      _currentShotDynamicZero = dynamicZero;
      print(
          '🎯 Manual Dynamic Zero Point Set: Roll=${dynamicZero.roll.toStringAsFixed(4)}, Pitch=${dynamicZero.pitch.toStringAsFixed(4)}');
      return true;
    } else {
      print(
          '⚠️ Cannot calculate dynamic zero point - insufficient stable data');
      return false;
    }
  }

  // ✅ NEW: Get current dynamic zero point status
  Map<String, dynamic> getDynamicZeroStatus() {
    return {
      'hasDynamicZero': _currentShotDynamicZero != null,
      'dynamicZeroRoll': _currentShotDynamicZero?.roll,
      'dynamicZeroPitch': _currentShotDynamicZero?.pitch,
      'preShotBufferSize': _preShotOrientationBuffer.length,
      'isPreShotStable': _preShotOrientationBuffer.length >= 20
          ? _isPreShotPeriodStable(_preShotOrientationBuffer
          .sublist(_preShotOrientationBuffer.length - 50))
          : false,
    };
  }

  // ✅ NEW: Process accelerometer data with shot analysis
  void processAccelerometerData(
      double x, double y, double z, double cant, double tilt)
  {
    final timestamp = DateTime.now();
    final magnitude = _calculateMagnitude(x, y, z);

    final reading = SensorReading(
      timestamp: timestamp,
      x: x,
      y: y,
      z: z,
      magnitude: magnitude,
      cant: cant,
      tilt: tilt,
    );

    // Add to stability buffer
    _stabilityBuffer.add(reading);

    // Keep only last 100 readings for shot detection
    if (_stabilityBuffer.length > 100) {
      _stabilityBuffer.removeAt(0);
    }

    // Check for shot detection with 3-second minimum interval
    if (_isStabilityPeriodValid()) {
      final now = DateTime.now();

      // Check if enough time has passed since last shot
      if (_lastShotTime == null ||
          now.difference(_lastShotTime!).inMilliseconds >=
              _minTimeBetweenShots) {
        _processShotFromBuffer(3.0); // 3.0g threshold
      }
    }
  }

  // ✅ NEW: Check if stability period is valid
  bool _isStabilityPeriodValid() {
    if (_stabilityBuffer.length < 5) return false;

    final recentData = _stabilityBuffer.length >= 10
        ? _stabilityBuffer.sublist(_stabilityBuffer.length - 10)
        : _stabilityBuffer;

    final avgMagnitude =
        recentData.map((r) => r.magnitude).reduce((a, b) => a + b) /
            recentData.length;
    final variance = recentData
        .map((r) => pow(r.magnitude - avgMagnitude, 2))
        .reduce((a, b) => a + b) /
        recentData.length;

    return variance < 0.05;
  }

  // ✅ NEW: Process shot from buffer with proper analysis
  void _processShotFromBuffer(double threshold) {
    if (_stabilityBuffer.isEmpty) return;

    for (int i = 0; i < _stabilityBuffer.length; i++) {
      final current = _stabilityBuffer[i];

      if (current.magnitude > threshold) {
        // ✅ NEW: Calculate dynamic zero point before processing shot
        _currentShotDynamicZero = _calculateDynamicZeroPoint();

        // Shot detected - increment counter
        _shotCounter++;
        final shotReading = current;
        _lastShotTime = shotReading.timestamp;

        print(
            "🔫 Shot #$_shotCounter Detected: ${shotReading.magnitude.toStringAsFixed(2)}g at ${shotReading.timestamp}");

        if (_currentShotDynamicZero != null) {
          print(
              "🎯 Using Dynamic Zero: Roll=${_currentShotDynamicZero!.roll.toStringAsFixed(4)}, Pitch=${_currentShotDynamicZero!.pitch.toStringAsFixed(4)}");
        } else {
          print("⚠️ No dynamic zero available, using static calibration");
        }

        // Pre-Shot (10 readings before shot, or all available if less)
        final preShot = _stabilityBuffer.sublist((i - 10).clamp(0, i), i);

        // Post-Shot readings (until stability returns)
        List<SensorReading> postShot = [];
        int consecutiveStableCount = 0;
        bool recoveryAchieved = false;

        for (int j = i + 1; j < _stabilityBuffer.length; j++) {
          final reading = _stabilityBuffer[j];
          postShot.add(reading);

          // Check if reading is stable (under 2.0g)
          if (reading.magnitude < 2.0) {
            consecutiveStableCount++;
            // Need 3 consecutive stable readings to confirm recovery
            if (consecutiveStableCount >= 3) {
              recoveryAchieved = true;
              break;
            }
          } else {
            consecutiveStableCount = 0;
          }
        }

        // Calculate recovery time properly
        final recoveryTime = postShot.isNotEmpty && recoveryAchieved
            ? postShot.last.timestamp
            .difference(shotReading.timestamp)
            .inMilliseconds
            : (postShot.isNotEmpty
            ? postShot.last.timestamp
            .difference(shotReading.timestamp)
            .inMilliseconds
            : 1000);

        print("⏪ Pre-Shot: ${preShot.length} readings");
        print("⏩ Post-Shot: ${postShot.length} readings");
        print("⏱️ Recovery Time: ${recoveryTime}ms");

        // Generate shot analysis
        final analysis = _generateShotAnalysis(
          _shotCounter,
          shotReading,
          preShot,
          postShot,
          recoveryTime,
        );

        // Create shot detection event
        final shotEvent = ShotDetectedEvent(
          timestamp: shotReading.timestamp,
          shotNumber: _shotCounter,
          magnitude: shotReading.magnitude,
          isValidShot: true,
          reason:
          'Shot detected with ${shotReading.magnitude.toStringAsFixed(2)}g spike',
          analysis: analysis,
        );

        // Emit shot detection event
        if (!_shotDetectionController.isClosed) {
          _shotDetectionController.add(shotEvent);
        }

        // Clear buffer and break
        _stabilityBuffer.clear();
        break;
      }
    }
  }

  // ✅ NEW: Generate comprehensive shot analysis
  ShotAnalysis? _generateShotAnalysis(
      int shotNumber,
      SensorReading shotReading,
      List<SensorReading> preShotReadings,
      List<SensorReading> postShotReadings,
      int recoveryTimeMs,
      )
  {
    try {
      // Pre-Shot Phase: readings before shot detection
      final preShotMetrics = _calculatePreShotMetrics(preShotReadings);
      final preShotPhase = ShotPhase(
        startTime: preShotReadings.isNotEmpty
            ? preShotReadings.first.timestamp
            : shotReading.timestamp.subtract(const Duration(seconds: 1)),
        endTime: shotReading.timestamp,
        duration: preShotReadings.isNotEmpty
            ? shotReading.timestamp.difference(preShotReadings.first.timestamp)
            : const Duration(seconds: 1),
        readings: preShotReadings,
        metrics: preShotMetrics,
      );

      // Shot Detection Phase: single reading where shot was detected
      final shotDetectionMetrics = {
        'magnitude': shotReading.magnitude,
        'detectionTime':
        shotReading.timestamp.millisecondsSinceEpoch.toDouble(),
        'cant': shotReading.cant,
        'tilt': shotReading.tilt,
        'maxGValue': shotReading.magnitude,
      };

      final shotDetectionPhase = ShotPhase(
        startTime: shotReading.timestamp,
        endTime: shotReading.timestamp,
        duration: Duration.zero,
        readings: [shotReading],
        metrics: shotDetectionMetrics,
      );

      // Post-Shot Phase: readings after shot until recovery
      final postShotMetrics =
      _calculatePostShotMetrics(postShotReadings, recoveryTimeMs);
      final postShotPhase = ShotPhase(
        startTime: shotReading.timestamp,
        endTime: postShotReadings.isNotEmpty
            ? postShotReadings.last.timestamp
            : shotReading.timestamp.add(Duration(milliseconds: recoveryTimeMs)),
        duration: Duration(milliseconds: recoveryTimeMs),
        readings: postShotReadings,
        metrics: postShotMetrics,
      );

      // Overall metrics
      final overallMetrics = <String, dynamic>{
        'shotNumber': shotNumber,
        'timestamp': shotReading.timestamp.millisecondsSinceEpoch,
        'maxGValue': shotReading.magnitude,
        'recoveryTime': recoveryTimeMs,
        'preShotReadings': preShotReadings.length,
        'postShotReadings': postShotReadings.length,
        'detectionThreshold': 3.0,
      };

      return ShotAnalysis(
        shotNumber: shotNumber,
        shotTimestamp: shotReading.timestamp,
        preShot: preShotPhase,
        triggerEvent: shotDetectionPhase,
        postShot: postShotPhase,
        overallMetrics: overallMetrics,
        analysisNotes:
        'Shot detected at ${shotReading.magnitude.toStringAsFixed(2)}g with ${recoveryTimeMs}ms recovery time',
      );
    } catch (e) {
      print("Error generating shot analysis: $e");
      return null;
    }
  }

  // ✅ NEW: Calculate pre-shot metrics
  Map<String, double> _calculatePreShotMetrics(List<SensorReading> readings) {
    if (readings.isEmpty) return {};

    final magnitudes = readings.map((r) => r.magnitude).toList();
    final avgMagnitude = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final maxMagnitude = magnitudes.reduce(max);
    final minMagnitude = magnitudes.reduce(min);

    // Calculate stability (variance)
    final variance = magnitudes
        .map((m) => pow(m - avgMagnitude, 2))
        .reduce((a, b) => a + b) /
        magnitudes.length;

    // Calculate drift (movement from first to last reading)
    final firstReading = readings.first;
    final lastReading = readings.last;
    final drift = sqrt(pow(lastReading.cant - firstReading.cant, 2) +
        pow(lastReading.tilt - firstReading.tilt, 2));

    return {
      'avgMagnitude': avgMagnitude,
      'maxMagnitude': maxMagnitude,
      'minMagnitude': minMagnitude,
      'stability':
      (1 - sqrt(variance)) * 100, // Convert to stability percentage
      'drift': drift,
      'readingCount': readings.length.toDouble(),
      'duration': readings.length * 0.0012 * 1000, // milliseconds
    };
  }

  // ✅ NEW: Calculate post-shot metrics
  Map<String, double> _calculatePostShotMetrics(
      List<SensorReading> readings, int recoveryTimeMs)
  {
    if (readings.isEmpty) return {'recoveryTime': recoveryTimeMs.toDouble()};

    final magnitudes = readings.map((r) => r.magnitude).toList();
    final avgMagnitude = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final maxMagnitude = magnitudes.reduce(max);
    final minMagnitude = magnitudes.reduce(min);

    // Find when magnitude returns to near-baseline (under 2g)
    int stabilityIndex = readings.length;
    for (int i = 0; i < readings.length; i++) {
      if (readings[i].magnitude < 2.0) {
        stabilityIndex = i;
        break;
      }
    }

    // Calculate muzzle rise (maximum tilt change during recovery)
    double muzzleRise = 0.0;
    if (readings.isNotEmpty) {
      final tiltChanges = readings.map((r) => r.tilt.abs()).toList();
      muzzleRise = tiltChanges.reduce(max);
    }

    return {
      'recoveryTime': recoveryTimeMs.toDouble(),
      'avgMagnitude': avgMagnitude,
      'maxMagnitude': maxMagnitude,
      'minMagnitude': minMagnitude,
      'stabilityReachedAt': stabilityIndex * 0.0012 * 1000,
      'readingCount': readings.length.toDouble(),
      'overshoot': maxMagnitude > 3.0 ? maxMagnitude - 3.0 : 0.0,
      'muzzleRise': muzzleRise,
    };
  }

  // ✅ ENHANCED: Complete reset for new session start
  void resetForNewSession() {
    print('SensorProcessor: 🧹 Complete reset for new session');

    // Reset all orientation data
    _roll = 0.0;
    _pitch = 0.0;
    pitchOffset = 0.0;
    rollOffset = 0.0;
    rollFilter.reset();
    pitchFilter.reset();

    // Reset calibration data
    gyroSumX = gyroSumY = gyroSumZ = 0.0;
    accelSumX = accelSumY = accelSumZ = 0.0;
    gyroCalibrationCount = accelCalibrationCount = 0;
    gyroCalibrated = false;
    accelCalibrated = false;
    isFirstSampleAccel = true;
    filteredAccelX = 0.0;
    filteredAccelY = 0.0;
    filteredAccelZ = 0.0;

    // Reset all shot detection data
    _shotCounter = 0;
    _stabilityBuffer.clear();
    _lastShotTime = null;

    // ✅ NEW: Reset MantisX dynamic center alignment data
    _preShotOrientationBuffer.clear();
    _currentShotDynamicZero = null;

    // Clear any buffered data
    _dataBuffer.clear();

    print('SensorProcessor: ✅ Complete reset completed for new session');
  }

  // ✅ ENHANCED: Regular reset (keeps calibration for quick restart)
  void reset() {
    print('SensorProcessor: 🔄 Quick reset (keeping calibration)');
    // Reset orientation data
    _roll = 0.0;
    _pitch = 0.0;
    pitchOffset = 0.0;
    rollOffset = 0.0;
    rollFilter.reset();
    pitchFilter.reset();

    // Reset shot detection data but keep calibration
    _shotCounter = 0;
    _stabilityBuffer.clear();
    _lastShotTime = null;

    // ✅ NEW: Reset MantisX dynamic center alignment data
    _preShotOrientationBuffer.clear();
    _currentShotDynamicZero = null;

    print('SensorProcessor: ✅ Quick reset completed');
  }

  double getDeltaTime(int currentTimestamp) {
    if (lastGyroTimestamp == 0) {
      lastGyroTimestamp = currentTimestamp.toDouble();
      return 0.0;
    }
    double dt = (currentTimestamp - lastGyroTimestamp) / 1000000.0;
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
    if (!isRecalibrated && !lastCalibrated) {

      if (lastCalibratedTime == null || (now - lastCalibratedTime!) >= 1000 ) {
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

    if (currentDt > 0) {
      _roll = rollFilter.update(gyro.y, accelRoll, currentDt);
      _pitch = pitchFilter.update(gyro.x, accelPitch, currentDt);
    }
    else {
      _roll = accelRoll;
      _pitch = accelPitch;
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
    pitchList.add((_pitch - rollOffset) * 180 / pi);

    // ✅ MODIFIED: Use callback to trigger BleRepository recalibration instead of local recalibration
    Orientation orientation;
    if (isStable(rollList, 0.2) == false || isStable(pitchList, 0.2) == false) {
      orientation = Orientation(
        _roll - rollOffset,
        _pitch - pitchOffset,
        0, // yaw not used
        shotDetected,
        timestamp,
      );
      if (!orientationStreamController.isClosed) {
        orientationStreamController.add(orientation);
      }
      if(!isRecalibrated ){
        isRecalibrated = true;
        lastCalibrated = false;
      }
      if((((_roll - rollOffset) * 180 / pi).abs() > 5) || (((_pitch - pitchOffset) * 180 / pi).abs() > 5) || (now - lastCalibratedTime!) >= 3000)
      {
        if (isStableForRecalibration(rollList, 01) == true && isStableForRecalibration(pitchList, 01) == true)
        {
          isRecalibrated = false;
        }
      }

    }
    else {
      if (isRecalibrated) {
          isRecalibrated = false;
      }
    }


  }

  /// Processes raw byte data received from the sensor stream.
  void processData(List<int> newBytes) {
    _dataBuffer.addAll(newBytes);

    int currentParsePosition = 0;
    bool shotDetectedInThisPacket = false;

    double prevAccelX = filteredAccelX;
    double prevAccelY = filteredAccelY;
    double prevAccelZ = filteredAccelZ;

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
          final now = DateTime.now();
          if (lastShotTime == null ||
              now.difference(lastShotTime!).inMilliseconds >= 2000) {
            // 2 seconds have passed since last shot
            shotDetectedInThisPacket = true;
            lastShotTime = now; // update the time
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

        // Process Accelerometer Data
        if (packetType == 0x08) {
          final ax = (x / 32768.0) * -16.0;
          final ay = (y / 32768.0) * -16.0;
          final az = (z / 32768.0) * -16.0;

          if (!accelCalibrated) {
            final diffX = (ax - prevAccelX).abs();
            final diffY = (ay - prevAccelY).abs();
            final diffZ = (az - prevAccelZ).abs();
            final totalMovement = diffX + diffY + diffZ;

            prevAccelX = ax;
            prevAccelY = ay;
            prevAccelZ = az;

            if (totalMovement > 3.0) {
              accelCalibrationCount = 0;
              accelSumX = accelSumY = accelSumZ = 0.0;
              gyroSumX = gyroSumY = gyroSumZ = 0.0;
              gyroCalibrationCount = 0;
              if (debug)
                print(
                    'Accelerometer moved significantly, resetting calibration.');
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
                if (debug)
                  print(
                      "Accelerometer calibrated: X=${accelXOffset.toStringAsFixed(4)}, Y=${accelYOffset.toStringAsFixed(4)}, Z=${accelZOffset.toStringAsFixed(4)}");
              }
            }
          } else {
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

            // ✅ NEW: Process accelerometer data for shot analysis
            processAccelerometerData(filteredAccelX, filteredAccelY,
                filteredAccelZ, _roll * 180 / pi, _pitch * 180 / pi);

            latestAccelData =
                SensorData(filteredAccelX, filteredAccelY, filteredAccelZ);
            latestAccelTimestamp = packetTimestamp;
          }
        }
        // Process Gyroscope Data
        else if (packetType == 0x0A) {
          final gx = (x / 28571.0) * 500.0;
          final gy = (y / 28571.0) * 500.0;

          if (!gyroCalibrated) {
            gyroSumX += gx;
            gyroSumY += gy;
            gyroCalibrationCount++;

            if (gyroCalibrationCount >= calibrationSamples + samplesToSkip) {
              gyroXOffset = gyroSumX / calibrationSamples;
              gyroYOffset = gyroSumY / calibrationSamples;
              gyroCalibrated = true;
              if (debug)
                print(
                    "Gyroscope calibrated: X=${gyroXOffset.toStringAsFixed(4)}, Y=${gyroYOffset.toStringAsFixed(4)}");
            }
          } else {
            final cx = gx - gyroXOffset;
            final cy = gy - gyroYOffset;
            latestGyroData = SensorData(cx, cy, 0);
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
    _currentShotDynamicZero = null;

    // Clear callback
    _onRecalibrateCallback = null;

    print('SensorProcessor: Disposed');
  }

  bool isStable(List<double> history, double threshold) {
    if (history.length < 2) return false; // Compare karne ke liye kam se kam 2 values chahiye

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
    if (history.length < 2) return false; // Compare karne ke liye kam se kam 2 values chahiye

    // ✅ Sirf last 100 values consider karo
    final recentHistory = history.length > 100
        ? history.sublist(history.length - 100)
        : history;

    double firstValue = recentHistory[0];
    for (int i = 0; i < recentHistory.length - 1; i++) {
      double diff = (recentHistory[i + 1] - firstValue).abs(); // Absolute difference
      if (diff >= threshold) {
        return false; // Agar difference threshold se zyada hua → unstable
      }
    }

    return true; // Sab within threshold hain → stable
  }

}