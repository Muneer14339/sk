// lib/features/training/data/repositories/ble_repository_impl.dart - Packet Count Based Traceline
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulse_skadi/core/errors/exceptions.dart';
import 'package:pulse_skadi/features/training/data/datasources/ble_manager.dart';
import 'package:pulse_skadi/features/training/data/datasources/sensor_processor.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';
import 'package:pulse_skadi/features/training/data/model/shot_trace_model.dart';
import 'package:pulse_skadi/features/training/domain/repositories/ble_repository.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ UPDATED: Filter configuration with packet count limit
class SmoothingConfig {
  static const int movingAverageWindow = 200; // Average last 200 points
  static const double exponentialAlpha = 0.3; // For exponential moving average
  static const int decimationFactor = 3; // Only add every 3rd point to trace
  static const double noiseThreshold = 0.3; // Minimum movement to register
  static const int maxTracelinePackets = 250; // ✅ Maximum packets in traceline
}

class TraceSmoothing {
  final Queue<Point3D> _rollBuffer = Queue();
  final Queue<Point3D> _pitchBuffer = Queue();
  final Queue<Point3D> _yawBuffer = Queue();
  Point3D? _lastSmoothedPoint;
  int _pointCounter = 0;

  // Exponential moving average values
  double? _emaRoll;
  double? _emaPitch;
  double? _emaYaw;

  Point3D smoothPoint(double roll, double pitch, double yaw) {
    _pointCounter++;

    // Method 1: Moving Average Smoothing
    Point3D smoothedPoint = _applyMovingAverage(roll, pitch, yaw);

    // Method 2: Exponential Moving Average (alternative)
    // Point3D smoothedPoint = _applyExponentialMovingAverage(roll, pitch, yaw);

    // Method 3: Noise filtering
    smoothedPoint = _applyNoiseFilter(smoothedPoint);

    _lastSmoothedPoint = smoothedPoint;
    return smoothedPoint;
  }

  Point3D _applyMovingAverage(double roll, double pitch, double yaw) {
    // Add new points to buffer
    _rollBuffer.add(Point3D(roll, 0, 0));
    _pitchBuffer.add(Point3D(pitch, 0, 0));
    _yawBuffer.add(Point3D(yaw, 0, 0));

    // Maintain buffer size
    if (_rollBuffer.length > SmoothingConfig.movingAverageWindow) {
      _rollBuffer.removeFirst();
      _pitchBuffer.removeFirst();
      _yawBuffer.removeFirst();
    }

    // Calculate average
    double avgRoll = _rollBuffer.map((p) => p.x).reduce((a, b) => a + b) /
        _rollBuffer.length;
    double avgPitch = _pitchBuffer.map((p) => p.x).reduce((a, b) => a + b) /
        _pitchBuffer.length;
    double avgYaw =
        _yawBuffer.map((p) => p.x).reduce((a, b) => a + b) / _yawBuffer.length;

    return Point3D(avgRoll, avgPitch, avgYaw);
  }

  Point3D _applyExponentialMovingAverage(
      double roll, double pitch, double yaw) {
    if (_emaRoll == null || _emaPitch == null || _emaYaw == null) {
      _emaRoll = roll;
      _emaPitch = pitch;
      _emaYaw = yaw;
    } else {
      _emaRoll = SmoothingConfig.exponentialAlpha * roll +
          (1 - SmoothingConfig.exponentialAlpha) * _emaRoll!;
      _emaPitch = SmoothingConfig.exponentialAlpha * pitch +
          (1 - SmoothingConfig.exponentialAlpha) * _emaPitch!;
      _emaYaw = SmoothingConfig.exponentialAlpha * yaw +
          (1 - SmoothingConfig.exponentialAlpha) * _emaYaw!;
    }

    return Point3D(_emaRoll!, _emaPitch!, _emaYaw!);
  }

  Point3D _applyNoiseFilter(Point3D point) {
    if (_lastSmoothedPoint == null) return point;

    double distance = sqrt(pow(point.x - _lastSmoothedPoint!.x, 2) +
        pow(point.y - _lastSmoothedPoint!.y, 2) +
        pow(point.z - _lastSmoothedPoint!.z, 2));

    // If movement is too small, keep previous point
    if (distance < SmoothingConfig.noiseThreshold) {
      return _lastSmoothedPoint!;
    }

    return point;
  }

  bool shouldAddToTrace() {
    // Decimation: Only add every Nth point to reduce trace density
    return _pointCounter % SmoothingConfig.decimationFactor == 0;
  }

  void reset() {
    _rollBuffer.clear();
    _pitchBuffer.clear();
    _yawBuffer.clear();
    _lastSmoothedPoint = null;
    _pointCounter = 0;
    _emaRoll = null;
    _emaPitch = null;
    _emaYaw = null;
  }
}

// ✅ ENHANCED: Shot cycle state tracking
enum ShotCycleState {
  preShot, // Collecting pre-shot data
  shotDetected, // Shot just detected, start post-shot collection
  collectingPost, // Collecting post-shot data
  ready // Ready for next shot
}

class BleRepositoryImpl implements BleRepository {
  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController.broadcast();
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;
  final List<ScanResult> _scanResults = [];

  // ✅ NEW: Shot trace storage
  final List<ShotTraceData> _sessionShotTraces = [];
  final StreamController<List<ShotTraceData>> _shotTracesController =
      StreamController<List<ShotTraceData>>.broadcast();

  // ✅ SMOOTHING: Add smoothing filter
  final TraceSmoothing _traceSmoothing = TraceSmoothing();

  @override
  Stream<List<ShotTraceData>> get shotTracesStream =>
      _shotTracesController.stream;
  @override
  List<ShotTraceData> get sessionShotTraces =>
      List.unmodifiable(_sessionShotTraces);

  // ✅ ENHANCED: Shot cycle tracking variables
  ShotCycleState _shotCycleState = ShotCycleState.preShot;
  int _preShotPointsCount = 0;
  int _postShotPointsCount = 0;
  int _targetPostShotPoints = 0; // Equal to pre-shot points

  final BleManager bleManager = BleManager();
  final SensorProcessor sensorProcessor = SensorProcessor();
  bool isClearing = false;
  Timer? timer;

  // ✅ CONSTRUCTOR: Set up callback to sensor processor
  BleRepositoryImpl() {
    // Set callback so SensorProcessor can call our recalibrate method
    sensorProcessor.setRecalibrationCallback(() {
      recalibrate();
    });

    // timer = Timer.periodic(const Duration(milliseconds: 250), (t) async {
    //   isClearing = true;
    //
    //   // 20ms ke baad wapas normal trace show karo
    //   await Future.delayed(const Duration(milliseconds: 100));
    //   _currentShotTrace.clear();
    //   isClearing = false;
    // });
  }

  // ✅ NEW: Packet count based traceline management
  void _maintainTracelinePacketLimit() {
    // Keep only the last 250 packets in the traceline
    while (_currentShotTrace.length > SmoothingConfig.maxTracelinePackets) {
      _currentShotTrace.removeFirst();

      // Update counters based on removed points
      if (_shotCycleState == ShotCycleState.preShot) {
        _preShotPointsCount = _currentShotTrace
            .where((tp) => tp.phase == TracePhase.preShot)
            .length;
      } else if (_shotCycleState == ShotCycleState.collectingPost) {
        _preShotPointsCount = _currentShotTrace
            .where((tp) => tp.phase == TracePhase.preShot)
            .length;
        _postShotPointsCount = _currentShotTrace
            .where((tp) => tp.phase == TracePhase.postShot)
            .length;
      }
    }

    // print('📊 Traceline packets: ${_currentShotTrace.length}/${SmoothingConfig.maxTracelinePackets}');
  }

  // ✅ UPDATED: Add point to trace with packet limit
  void _addPointToTrace(TracePoint tracePoint) {
    _currentShotTrace.add(tracePoint);

    // Maintain packet limit immediately after adding
    _maintainTracelinePacketLimit();
  }

  // ✅ UPDATED: Manage shot cycle with SMOOTH trace storage + packet limit (now with YAW)
  void _manageShotCycleWithTraceStorage(
      dynamic orientation, double roll, double pitch, double yaw) {
    // ✅ SMOOTHING: Apply smoothing to roll/pitch/yaw
    Point3D smoothedPoint = _traceSmoothing.smoothPoint(roll, pitch, yaw);
    double smoothedRoll = smoothedPoint.x;
    double smoothedPitch = smoothedPoint.y;
    double smoothedYaw = smoothedPoint.z;

    switch (_shotCycleState) {
      case ShotCycleState.preShot:
        // ✅ SMOOTHING: Only add to trace if decimation allows AND smoothing is applied
        if (_traceSmoothing.shouldAddToTrace()) {
          _addPointToTrace(TracePoint(
              Point3D(smoothedRoll, smoothedPitch, smoothedYaw),
              TracePhase.preShot));
          _preShotPointsCount++;
        }

        // Check for shot detection (use original data for accuracy)
        if (orientation.shotDetected && !_hasShotOccurred) {
          _hasShotOccurred = true;
          _shotDetectedTime = DateTime.now();
          _currentShotNumber++;
          _shotCycleState = ShotCycleState.shotDetected;

          // Set target post-shot points equal to pre-shot points
          _targetPostShotPoints = _preShotPointsCount;
          _postShotPointsCount = 0;

          print(
              '🎯 Target post-shot points: $_targetPostShotPoints (equal to pre-shot)');

          // Add the shot detection point (always add this critical point)
          _addPointToTrace(TracePoint(
              Point3D(smoothedRoll, smoothedPitch, smoothedYaw),
              TracePhase.shot));
        }
        break;

      case ShotCycleState.shotDetected:
        // Immediately start collecting post-shot data
        _shotCycleState = ShotCycleState.collectingPost;
        // Add this point as post-shot (always add transition point)
        _addPointToTrace(TracePoint(
            Point3D(smoothedRoll, smoothedPitch, smoothedYaw),
            TracePhase.postShot));
        _postShotPointsCount++;
        print(
            '📈 Post-shot collection started: $_postShotPointsCount/$_targetPostShotPoints');
        break;

      case ShotCycleState.collectingPost:
        // ✅ SMOOTHING: Continue collecting post-shot data with smoothing
        if (_traceSmoothing.shouldAddToTrace()) {
          _addPointToTrace(TracePoint(
              Point3D(smoothedRoll, smoothedPitch, smoothedYaw),
              TracePhase.postShot));
          _postShotPointsCount++;
        }

        // Check if we have collected enough post-shot points
        if (_postShotPointsCount >= _targetPostShotPoints) {
          print(
              '✅ Post-shot collection complete: $_postShotPointsCount/$_targetPostShotPoints');
          print('📊 Total trace points: ${_currentShotTrace.length}');

          // ✅ Process complete shot with properly balanced trace
          _processCompleteShot();

          // ✅ Reset for next shot
          _resetForNextShot(smoothedRoll, smoothedPitch, smoothedYaw);
        } else {
          // Show progress every 100 points
          if (_postShotPointsCount % 100 == 0) {
            print(
                '📈 Collecting post-shot: $_postShotPointsCount/$_targetPostShotPoints');
          }
        }
        break;

      case ShotCycleState.ready:
        // This shouldn't happen, but handle it
        _shotCycleState = ShotCycleState.preShot;
        if (_traceSmoothing.shouldAddToTrace()) {
          _addPointToTrace(TracePoint(
              Point3D(smoothedRoll, smoothedPitch, smoothedYaw),
              TracePhase.preShot));
          _preShotPointsCount = 1;
        }
        break;
    }

    // ✅ REMOVED: Old buffer size limit code (now handled by packet limit)
  }

  // ✅ NEW: Process complete shot when both pre and post data is collected
  void _processCompleteShot() {
    if (_currentShotTrace.isEmpty) return;

    // ✅ The trace already has properly categorized points from the cycle management
    Queue<TracePoint> completeTrace = Queue.from(_currentShotTrace);

    // Verify trace composition
    final preShotCount =
        completeTrace.where((tp) => tp.phase == TracePhase.preShot).length;
    final shotCount =
        completeTrace.where((tp) => tp.phase == TracePhase.shot).length;
    final postShotCount =
        completeTrace.where((tp) => tp.phase == TracePhase.postShot).length;

    print('🔍 Shot #$_currentShotNumber trace composition:');
    print('   Pre-shot: $preShotCount points');
    print('   Shot: $shotCount points');
    print('   Post-shot: $postShotCount points');
    print('   Total: ${completeTrace.length} points');

    // ✅ Create shot trace data with balanced pre/post data
    final shotTraceData = ShotTraceData(
      shotNumber: _currentShotNumber,
      timestamp: _shotDetectedTime!,
      tracePoints: completeTrace,
      maxMagnitude: _calculateMaxMagnitudeFromTrace(completeTrace),
      metrics: _calculateBalancedTraceMetrics(
          completeTrace, preShotCount, postShotCount),
      analysisNotes:
          'Balanced trace: $preShotCount pre-shot + $shotCount shot + $postShotCount post-shot points (SMOOTHED + PACKET LIMITED + 3D YAW)',
    );

    // Add to session shot traces
    _sessionShotTraces.add(shotTraceData);

    // Emit updated shot traces
    if (!_shotTracesController.isClosed) {
      _shotTracesController.add(List.from(_sessionShotTraces));
    }

    // Save current shot trace to completed shots for display
    _allShotTraces.add(Queue.from(completeTrace));

    print('✅ Shot #$_currentShotNumber smooth trace saved successfully!');
  }

  // ✅ ENHANCED: Reset for next shot with smoothing reset (now with YAW)
  void _resetForNextShot(double roll, double pitch, double yaw) {
    print('🔄 Resetting for next shot #${_currentShotNumber + 1}');

    // Clear current trace and counters
    _currentShotTrace.clear();
    _preShotPointsCount = 0;
    _postShotPointsCount = 0;
    _targetPostShotPoints = 0;

    // Reset shot detection flags
    _hasShotOccurred = false;
    _shotDetectedTime = null;

    // ✅ SMOOTHING: Reset smoothing filter
    _traceSmoothing.reset();

    // Reset to pre-shot state
    _shotCycleState = ShotCycleState.preShot;

    // Start new pre-shot trace with current position (smoothed)
    Point3D smoothedPoint = _traceSmoothing.smoothPoint(roll, pitch, yaw);
    _addPointToTrace(TracePoint(
        Point3D(smoothedPoint.x, smoothedPoint.y, smoothedPoint.z),
        TracePhase.preShot));
    _preShotPointsCount = 1;
  }

  // ✅ ENHANCED: Recalibrate with smoothing reset
  bool _isRecalibrating = false;

  @override
  void recalibrate() {
    try {
      _isRecalibrating = true; // 🚩 block orientation stream temporarily

      _currentShotTrace.clear();
      _allShotTraces.clear();
      _sessionShotTraces.clear();

      _shotCycleState = ShotCycleState.preShot;
      _preShotPointsCount = 0;
      _postShotPointsCount = 0;
      _targetPostShotPoints = 0;
      _hasShotOccurred = false;
      _shotDetectedTime = null;
      _currentShotNumber = 0;

      // ✅ SMOOTHING: Reset smoothing filter
      _traceSmoothing.reset();

      if (!_shotTracesController.isClosed) {
        _shotTracesController.add([]);
      }

      if (_streamController != null && !_streamController!.isClosed) {
        _streamController!.add(
          StreamingModel(
            roll: 0,
            pitch: 0,
            yaw: 0,
            points: Queue<TracePoint>(),
            shotDetected: false,
          ),
        );
      }

      // Small delay to flush old orientation frames
      Future.delayed(Duration(milliseconds: 100), () {
        _isRecalibrating = false;
        sensorProcessor.recalibrate();
      });
    } catch (e) {
      print('BleRepositoryImpl: ❌ Error during recalibration: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Initialize session with smoothing reset
  void _initializeSession() async {
    _sessionStartTime = DateTime.now();
    _sessionData.clear();
    _allShotTraces.clear();
    _currentShotTrace.clear();
    _currentShotNumber = 0;

    // ✅ Reset shot cycle state
    _shotCycleState = ShotCycleState.preShot;
    _preShotPointsCount = 0;
    _postShotPointsCount = 0;
    _targetPostShotPoints = 0;
    _hasShotOccurred = false;
    _shotDetectedTime = null;

    // ✅ SMOOTHING: Reset smoothing filter
    _traceSmoothing.reset();

    // Clear session shot traces
    _sessionShotTraces.clear();
    if (!_shotTracesController.isClosed) {
      _shotTracesController.add([]);
    }

    print(
        '🔄 Session initialized - Shot cycle state: $_shotCycleState (SMOOTHING + PACKET LIMIT: ${SmoothingConfig.maxTracelinePackets} + 3D YAW)');

    try {
      // Create session file
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final sessionDir = Directory('${directory.path}/ShotTraces');
        if (!await sessionDir.exists()) {
          await sessionDir.create(recursive: true);
        }

        final timestamp = _sessionStartTime!.millisecondsSinceEpoch;
        _currentSessionFile =
            File('${sessionDir.path}/session_$timestamp.json');

        print('📁 Session file created: ${_currentSessionFile!.path}');
      }
    } catch (e) {
      print('❌ Error creating session file: $e');
    }
  }

  // ✅ NEW: Calculate metrics with balanced trace data (now includes YAW)
  Map<String, dynamic> _calculateBalancedTraceMetrics(
      Queue<TracePoint> trace, int preShotCount, int postShotCount) {
    if (trace.isEmpty) return {};

    final preShotPoints =
        trace.where((tp) => tp.phase == TracePhase.preShot).toList();
    final shotPoints =
        trace.where((tp) => tp.phase == TracePhase.shot).toList();
    final postShotPoints =
        trace.where((tp) => tp.phase == TracePhase.postShot).toList();

    return {
      'preShotCount': preShotCount,
      'shotCount': shotPoints.length,
      'postShotCount': postShotCount,
      'totalPoints': trace.length,
      'preShotStability': _calculateStability(preShotPoints),
      'postShotStability': _calculateStability(postShotPoints),
      'recoveryTime': postShotCount * 36, // Adjusted for decimation (12ms * 3)
      'maxMagnitude': _calculateMaxMagnitudeFromTrace(trace),
      'balanceRatio': postShotCount > 0 ? (preShotCount / postShotCount) : 0.0,
      'isBalanced': (preShotCount - postShotCount).abs() <= 10,
      'smoothingApplied': true,
      'packetLimited': true,
      'maxPackets': SmoothingConfig.maxTracelinePackets,
      'includesYaw': true,
      'is3D': true,
    };
  }

  // ✅ ENHANCED: Shot trace management with packet-based clearing
  final Queue<TracePoint> _currentShotTrace = Queue();
  final List<Queue<TracePoint>> _allShotTraces = [];

  final TracePhase _currentPhase = TracePhase.preShot;
  bool _hasShotOccurred = false;
  DateTime? _shotDetectedTime;
  DateTime? _sessionStartTime;

  // ✅ NEW: File saving variables
  File? _currentSessionFile;
  final List<Map<String, dynamic>> _sessionData = [];
  int _currentShotNumber = 0;

  // Rest of the implementation remains the same...
  @override
  Future<bool> isAvailable() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isOn() async {
    try {
      return await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> startScan() async {
    if (_isScanning) return;

    // Request permissions
    final locationStatus = await Permission.location.request();
    ServiceStatus serviceStatus =
        await Permission.locationWhenInUse.serviceStatus;
    if (serviceStatus != ServiceStatus.enabled) {
      throw SimpleException(
          'Please enable location service to connect to device');
    }

    if (locationStatus.isPermanentlyDenied) {
      await openAppSettings();
      throw SimpleException(
          'Location and Bluetooth permissions are permanently denied. Please enable them in app settings.');
    }

    if (!locationStatus.isGranted) {
      throw SimpleException(
          'Location and Bluetooth permissions are required to scan for devices.');
    }

    _isScanning = true;
    _scanResults.clear();
    _scanResultsController.add(_scanResults);

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults
        ..clear()
        ..addAll(results.where((result) =>
            result.device.platformName == 'GMSync' ||
            result.device.platformName == 'SK'));
      _scanResultsController.add(List.from(_scanResults));
    });

    try {
      await FlutterBluePlus.startScan();
    } catch (e) {
      _isScanning = false;
      rethrow;
    }
  }

  @override
  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await FlutterBluePlus.stopScan();
    } finally {
      _isScanning = false;
      _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  @override
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      // Ignore errors during disconnection
    }
  }

  StreamController<StreamingModel>? _streamController;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription? _orientationSubscription;

  @override
  Stream<StreamingModel> enableSensors(BluetoothDevice device) {
    // Always create a new stream controller and cancel old subscriptions
    _streamController?.close();
    _streamController = StreamController<StreamingModel>.broadcast();
    _dataSubscription?.cancel();
    _orientationSubscription?.cancel();

    // ✅ NEW: Initialize session for file saving
    _initializeSession();

    bleManager.enableSensors(device).then((_) {
      _dataSubscription = bleManager.dataStream.listen((data) {
        sensorProcessor.processData(data);
      }, onError: (e) {
        _streamController?.addError("BLE Error: $e");
      }, onDone: () {});

      _orientationSubscription =
          sensorProcessor.orientationStream.listen((orientation) {
        if (_isRecalibrating) {
          return;
        }

        final roll = orientation.roll * 180 / 3.14159;
        final pitch = orientation.pitch * 180 / 3.14159;
        final yaw = orientation.yaw * 180 / 3.14159;

        // ✅ ENHANCED: Shot cycle management with SMOOTH trace storage (now with YAW)
        //_manageShotCycleWithTraceStorage(orientation, roll, pitch, yaw);

        // Create combined trace from all shots for display
        final Queue<TracePoint> combinedTrace = Queue();

        // Add previous completed shots (yellow)
        // for (var shotTrace in _allShotTraces) {
        //   for (var point in shotTrace) {
        //     combinedTrace.add(TracePoint(point.point,
        //         TracePhase.postShot)); // Previous shots as post-shot (yellow)
        //   }
        // }

        // Add current shot trace (limited to 250 packets)
        combinedTrace.addAll(_currentShotTrace);

        final streamingModel = StreamingModel(
            roll: roll,
            pitch: pitch,
            yaw: yaw,
            points: combinedTrace,
            shotDetected: orientation.shotDetected);

        _streamController?.add(streamingModel);
      });
    }).catchError((e) {
      print('debug session repo: enableSensors error $e');
    });

    return _streamController!.stream;
  }

  // ✅ NEW: Calculate max magnitude from trace (now includes YAW)
  double _calculateMaxMagnitudeFromTrace(Queue<TracePoint> trace) {
    if (trace.isEmpty) return 0.0;

    double maxMagnitude = 0.0;
    for (var tp in trace) {
      final magnitude = sqrt(tp.point.x * tp.point.x +
          tp.point.y * tp.point.y +
          tp.point.z * tp.point.z);
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
      }
    }
    return maxMagnitude;
  }

  // ✅ NEW: Calculate stability from points (now includes YAW)
  double _calculateStability(List<TracePoint> points) {
    if (points.length < 2) return 100.0;

    double totalVariation = 0.0;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1].point;
      final curr = points[i].point;
      final variation = sqrt(pow(curr.x - prev.x, 2) +
          pow(curr.y - prev.y, 2) +
          pow(curr.z - prev.z, 2));
      totalVariation += variation;
    }

    final avgVariation = totalVariation / (points.length - 1);
    final stability = (1 - (avgVariation / 3.0)) * 100;
    return stability.clamp(0.0, 100.0);
  }

  // ✅ NEW: Get shot trace by number
  @override
  ShotTraceData? getShotTrace(int shotNumber) {
    try {
      return _sessionShotTraces.firstWhere((st) => st.shotNumber == shotNumber);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Load session shot traces from file
  @override
  Future<List<ShotTraceData>> loadSessionShotTraces(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final sessionData = jsonDecode(content);

      final List<ShotTraceData> shotTraces = [];
      if (sessionData['shotTraces'] != null) {
        for (var traceData in sessionData['shotTraces']) {
          shotTraces.add(ShotTraceData.fromJson(traceData));
        }
      }

      return shotTraces;
    } catch (e) {
      print('❌ Error loading session shot traces: $e');
      return [];
    }
  }

  @override
  Future<void> disableSensors(BluetoothDevice device) async {
    try {
      await bleManager.disableSensors(device);
      _dataSubscription?.cancel();
      _dataSubscription = null;
      _orientationSubscription?.cancel();
      _orientationSubscription = null;
      await _streamController?.close();
      _streamController = null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo(BluetoothDevice device) async {
    try {
      return await bleManager.getDeviceInfo(device);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendcommand(
      int ditCommand,
      int dvcCommand,
      int swdCommand,
      int swbdCommand,
      int avdCommand,
      int avdtCommand,
      BluetoothDevice device) async {
    try {
      await bleManager.sendcommand(ditCommand, dvcCommand, swdCommand,
          swbdCommand, avdCommand, avdtCommand, device);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanResultsController.close();
    _dataSubscription?.cancel();
    _orientationSubscription?.cancel();
    _streamController?.close();
    _shotTracesController.close();
    sensorProcessor.dispose();
  }

  @override
  void resetShotCycleForSessionComplete() {
    // TODO: implement resetShotCycleForSessionComplete
  }

  @override
  void setTargetShotCount(int targetCount) {
    // TODO: implement setTargetShotCount
  }
}
