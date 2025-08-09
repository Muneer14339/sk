// lib/features/training/data/repositories/ble_repository_impl.dart - Enhanced version
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

// ✅ ENHANCED: Shot cycle state tracking
enum ShotCycleState {
  preShot,        // Collecting pre-shot data
  shotDetected,   // Shot just detected, start post-shot collection
  collectingPost, // Collecting post-shot data
  ready          // Ready for next shot
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

  Stream<List<ShotTraceData>> get shotTracesStream => _shotTracesController.stream;
  List<ShotTraceData> get sessionShotTraces => List.unmodifiable(_sessionShotTraces);

  // ✅ ENHANCED: Shot cycle tracking variables
  ShotCycleState _shotCycleState = ShotCycleState.preShot;
  int _preShotPointsCount = 0;
  int _postShotPointsCount = 0;
  int _targetPostShotPoints = 0; // Equal to pre-shot points

  // ✅ ENHANCED: Manage shot cycle with proper equal pre/post point collection
  void _manageShotCycleWithTraceStorage(dynamic orientation, double roll, double pitch) {
    final currentTime = DateTime.now();

    switch (_shotCycleState) {
      case ShotCycleState.preShot:
      // ✅ Always add current point to buffer for pre-shot tracking
        _currentShotTrace.add(TracePoint(Point(roll, pitch), TracePhase.preShot));
        _preShotPointsCount++;

        // Check for shot detection
        if (orientation.shotDetected && !_hasShotOccurred) {
          print('🔫 Shot ${_currentShotNumber + 1} detected!');
          print('📊 Pre-shot points collected: $_preShotPointsCount');

          _hasShotOccurred = true;
          _shotDetectedTime = currentTime;
          _currentShotNumber++;
          _shotCycleState = ShotCycleState.shotDetected;

          // Set target post-shot points equal to pre-shot points
          _targetPostShotPoints = _preShotPointsCount;
          _postShotPointsCount = 0;

          print('🎯 Target post-shot points: $_targetPostShotPoints (equal to pre-shot)');

          // Add the shot detection point
          _currentShotTrace.add(TracePoint(Point(roll, pitch), TracePhase.shot));
        }
        break;

      case ShotCycleState.shotDetected:
      // Immediately start collecting post-shot data
        _shotCycleState = ShotCycleState.collectingPost;
        // Add this point as post-shot
        _currentShotTrace.add(TracePoint(Point(roll, pitch), TracePhase.postShot));
        _postShotPointsCount++;
        print('📈 Post-shot collection started: $_postShotPointsCount/$_targetPostShotPoints');
        break;

      case ShotCycleState.collectingPost:
      // Continue collecting post-shot data
        _currentShotTrace.add(TracePoint(Point(roll, pitch), TracePhase.postShot));
        _postShotPointsCount++;

        // Check if we have collected enough post-shot points
        if (_postShotPointsCount >= _targetPostShotPoints) {
          print('✅ Post-shot collection complete: $_postShotPointsCount/$_targetPostShotPoints');
          print('📊 Total trace points: ${_currentShotTrace.length}');

          // ✅ Process complete shot with properly balanced trace
          _processCompleteShot();

          // ✅ Reset for next shot
          _resetForNextShot(roll, pitch);
        } else {
          // Show progress every 100 points
          if (_postShotPointsCount % 100 == 0) {
            print('📈 Collecting post-shot: $_postShotPointsCount/$_targetPostShotPoints');
          }
        }
        break;

      case ShotCycleState.ready:
      // This shouldn't happen, but handle it
        _shotCycleState = ShotCycleState.preShot;
        _currentShotTrace.add(TracePoint(Point(roll, pitch), TracePhase.preShot));
        _preShotPointsCount = 1;
        break;
    }

    // Limit buffer size to prevent memory issues (only if we're in pre-shot and buffer is too large)
    if (_shotCycleState == ShotCycleState.preShot && _currentShotTrace.length > 1500) {
      // Remove oldest points but keep track of the count
      int pointsToRemove = 500;
      for (int i = 0; i < pointsToRemove && _currentShotTrace.isNotEmpty; i++) {
        _currentShotTrace.removeFirst();
      }
      _preShotPointsCount = _currentShotTrace.length;
      print('🧹 Trimmed pre-shot buffer to $_preShotPointsCount points');
    }
  }

  // ✅ NEW: Process complete shot when both pre and post data is collected
  void _processCompleteShot() {
    if (_currentShotTrace.isEmpty) return;

    // ✅ The trace already has properly categorized points from the cycle management
    Queue<TracePoint> completeTrace = Queue.from(_currentShotTrace);

    // Verify trace composition
    final preShotCount = completeTrace.where((tp) => tp.phase == TracePhase.preShot).length;
    final shotCount = completeTrace.where((tp) => tp.phase == TracePhase.shot).length;
    final postShotCount = completeTrace.where((tp) => tp.phase == TracePhase.postShot).length;

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
      metrics: _calculateBalancedTraceMetrics(completeTrace, preShotCount, postShotCount),
      analysisNotes: 'Balanced trace: $preShotCount pre-shot + $shotCount shot + $postShotCount post-shot points',
    );

    // Add to session shot traces
    _sessionShotTraces.add(shotTraceData);

    // Emit updated shot traces
    if (!_shotTracesController.isClosed) {
      _shotTracesController.add(List.from(_sessionShotTraces));
    }

    // Save current shot trace to completed shots for display
    _allShotTraces.add(Queue.from(completeTrace));

    print('✅ Shot #$_currentShotNumber trace saved successfully!');
  }

  // ✅ ENHANCED: Reset for next shot with proper state management
  void _resetForNextShot(double roll, double pitch) {
    print('🔄 Resetting for next shot #${_currentShotNumber + 1}');

    // Clear current trace and counters
    _currentShotTrace.clear();
    _preShotPointsCount = 0;
    _postShotPointsCount = 0;
    _targetPostShotPoints = 0;

    // Reset shot detection flags
    _hasShotOccurred = false;
    _shotDetectedTime = null;

    // Reset to pre-shot state
    _shotCycleState = ShotCycleState.preShot;

    // Start new pre-shot trace with current position
    _currentShotTrace.add(TracePoint(Point(roll, pitch), TracePhase.preShot));
    _preShotPointsCount = 1;

    print('✅ Ready for shot #${_currentShotNumber + 1} - Pre-shot collection started');
  }

  // ✅ NEW: Calculate metrics with balanced trace data
  Map<String, dynamic> _calculateBalancedTraceMetrics(Queue<TracePoint> trace, int preShotCount, int postShotCount) {
    if (trace.isEmpty) return {};

    final preShotPoints = trace.where((tp) => tp.phase == TracePhase.preShot).toList();
    final shotPoints = trace.where((tp) => tp.phase == TracePhase.shot).toList();
    final postShotPoints = trace.where((tp) => tp.phase == TracePhase.postShot).toList();

    return {
      'preShotCount': preShotCount,
      'shotCount': shotPoints.length,
      'postShotCount': postShotCount,
      'totalPoints': trace.length,
      'preShotStability': _calculateStability(preShotPoints),
      'postShotStability': _calculateStability(postShotPoints),
      'recoveryTime': postShotCount * 12, // Assuming 12ms per point
      'maxMagnitude': _calculateMaxMagnitudeFromTrace(trace),
      'balanceRatio': postShotCount > 0 ? (preShotCount / postShotCount) : 0.0,
      'isBalanced': (preShotCount - postShotCount).abs() <= 10, // Within 10 points is balanced
    };
  }

  // ✅ ENHANCED: Initialize session with proper state reset
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

    // Clear session shot traces
    _sessionShotTraces.clear();
    if (!_shotTracesController.isClosed) {
      _shotTracesController.add([]);
    }

    print('🔄 Session initialized - Shot cycle state: ${_shotCycleState}');

    try {
      // Create session file
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final sessionDir = Directory('${directory.path}/ShotTraces');
        if (!await sessionDir.exists()) {
          await sessionDir.create(recursive: true);
        }

        final timestamp = _sessionStartTime!.millisecondsSinceEpoch;
        _currentSessionFile = File('${sessionDir.path}/session_$timestamp.json');

        print('📁 Session file created: ${_currentSessionFile!.path}');
      }
    } catch (e) {
      print('❌ Error creating session file: $e');
    }
  }

  // ✅ ENHANCED: Recalibrate with proper state reset
  @override
  void recalibrate() {
    try {
      // Clear all trace data and reset shot cycle
      _currentShotTrace.clear();
      _allShotTraces.clear();
      _sessionShotTraces.clear();

      // ✅ Reset shot cycle state completely
      _shotCycleState = ShotCycleState.preShot;
      _preShotPointsCount = 0;
      _postShotPointsCount = 0;
      _targetPostShotPoints = 0;
      _hasShotOccurred = false;
      _shotDetectedTime = null;
      _currentShotNumber = 0;

      // Emit cleared shot traces
      if (!_shotTracesController.isClosed) {
        _shotTracesController.add([]);
      }

      sensorProcessor.recalibrate();
      print('🔄 Recalibrated - Shot cycle state reset to: ${_shotCycleState}');
    } catch (e) {
      rethrow;
    }
  }


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
        ..addAll(
            results.where((result) => result.device.platformName == 'GMSync'));
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

  final BleManager bleManager = BleManager();
  final SensorProcessor sensorProcessor = SensorProcessor();

  StreamController<StreamingModel>? _streamController;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription? _orientationSubscription;

  // ✅ ENHANCED: Shot trace management with complete trace storage
  final Queue<TracePoint> _currentShotTrace = Queue();
  final List<Queue<TracePoint>> _allShotTraces = [];

  TracePhase _currentPhase = TracePhase.preShot;
  bool _hasShotOccurred = false;
  DateTime? _shotDetectedTime;
  DateTime? _sessionStartTime;

  // ✅ NEW: File saving variables
  File? _currentSessionFile;
  List<Map<String, dynamic>> _sessionData = [];
  int _currentShotNumber = 0;

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
            final roll = orientation.roll * 180 / 3.14159;
            final pitch = orientation.pitch * 180 / 3.14159;
            final yaw = orientation.yaw * 180 / 3.14159;

            // ✅ ENHANCED: Shot cycle management with trace storage
            _manageShotCycleWithTraceStorage(orientation, roll, pitch);

            // ✅ NEW: Save data to file
            //_saveDataPoint(roll, pitch, yaw, orientation.shotDetected, orientation.timestamp);

            // Create combined trace from all shots for display
            final Queue<TracePoint> combinedTrace = Queue();

            // Add previous completed shots (yellow)
            for (var shotTrace in _allShotTraces) {
              for (var point in shotTrace) {
                combinedTrace.add(TracePoint(point.point, TracePhase.postShot)); // Previous shots as post-shot (yellow)
              }
            }

            // Add current shot trace
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


  // ✅ NEW: Categorize shot buffer properly when shot is detected
  Queue<TracePoint> _categorizeShotBuffer() {
    if (_currentShotTrace.isEmpty) return Queue<TracePoint>();

    Queue<TracePoint> categorizedTrace = Queue<TracePoint>();
    List<TracePoint> bufferList = _currentShotTrace.toList();

    // Find shot detection point (current moment)
    int shotIndex = bufferList.length - 1; // Shot detected at current moment

    // ✅ Categorize buffer points:
    for (int i = 0; i < bufferList.length; i++) {
      TracePhase newPhase;

      if (i < shotIndex - 5) {
        // Points well before shot = pre-shot
        newPhase = TracePhase.preShot;
      } else if (i >= shotIndex - 5 && i <= shotIndex + 5) {
        // Points around shot moment = shot
        newPhase = TracePhase.shot;
      } else {
        // Points after shot = post-shot
        newPhase = TracePhase.postShot;
      }

      // Create new TracePoint with correct phase
      categorizedTrace.add(TracePoint(bufferList[i].point, newPhase));
    }

    return categorizedTrace;
  }


  // ✅ NEW: Calculate max magnitude from trace
  double _calculateMaxMagnitudeFromTrace(Queue<TracePoint> trace) {
    if (trace.isEmpty) return 0.0;

    double maxMagnitude = 0.0;
    for (var tp in trace) {
      final magnitude = sqrt(tp.point.x * tp.point.x + tp.point.y * tp.point.y);
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
      }
    }
    return maxMagnitude;
  }

  // ✅ NEW: Calculate trace metrics
  Map<String, dynamic> _calculateTraceMetrics(Queue<TracePoint> trace) {
    if (trace.isEmpty) return {};

    final preShotPoints = trace.where((tp) => tp.phase == TracePhase.preShot).toList();
    final shotPoints = trace.where((tp) => tp.phase == TracePhase.shot).toList();
    final postShotPoints = trace.where((tp) => tp.phase == TracePhase.postShot).toList();

    return {
      'preShotCount': preShotPoints.length,
      'shotCount': shotPoints.length,
      'postShotCount': postShotPoints.length,
      'totalPoints': trace.length,
      'preShotStability': _calculateStability(preShotPoints),
      'recoveryTime': postShotPoints.length * 12, // Assuming 12ms per point
      'maxMagnitude': _calculateMaxMagnitudeFromTrace(trace),
    };
  }

  // ✅ NEW: Calculate stability from points
  double _calculateStability(List<TracePoint> points) {
    if (points.length < 2) return 100.0;

    double totalVariation = 0.0;
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1].point;
      final curr = points[i].point;
      final variation = sqrt(pow(curr.x - prev.x, 2) + pow(curr.y - prev.y, 2));
      totalVariation += variation;
    }

    final avgVariation = totalVariation / (points.length - 1);
    final stability = (1 - (avgVariation / 2.0)) * 100; // Normalize to percentage
    return stability.clamp(0.0, 100.0);
  }

  // // ✅ NEW: Save data point to file
  // void _saveDataPoint(double roll, double pitch, double yaw, bool shotDetected, int timestamp) {
  //   final dataPoint = {
  //     'timestamp': timestamp,
  //     'sessionTime': DateTime.now().difference(_sessionStartTime!).inMilliseconds,
  //     'roll': roll,
  //     'pitch': pitch,
  //     'yaw': yaw,
  //     'shotDetected': shotDetected,
  //     'phase': _currentPhase.toString(),
  //     'shotNumber': _currentShotNumber,
  //   };
  //
  //   _sessionData.add(dataPoint);
  //
  //
  // }


  // ✅ NEW: Get shot trace by number
  ShotTraceData? getShotTrace(int shotNumber) {
    try {
      return _sessionShotTraces.firstWhere((st) => st.shotNumber == shotNumber);
    } catch (e) {
      return null;
    }
  }

  // ✅ NEW: Load session shot traces from file
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
      BluetoothDevice device) async
  {
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
}