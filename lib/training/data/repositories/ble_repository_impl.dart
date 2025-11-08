// lib/features/training/data/repositories/ble_repository_impl.dart - Packet Count Based Traceline
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/error/exceptions.dart';
import '../../domain/repositories/ble_repository.dart';
import '../datasources/ble_manager.dart';
import '../datasources/sensor_processor.dart';
import '../model/shot_trace_model.dart';
import '../model/streaming_model.dart';

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

  @override
  Stream<List<ShotTraceData>> get shotTracesStream =>
      _shotTracesController.stream;
  @override
  List<ShotTraceData> get sessionShotTraces =>
      List.unmodifiable(_sessionShotTraces);

  final BleManager bleManager = BleManager();
  final SensorProcessor sensorProcessor = SensorProcessor();
  bool isClearing = false;
  Timer? timer;
  StreamSubscription<int>? _batterySubscription;
  // Add this stream getter (around line 35)
  @override
  Stream<int> get batteryUpdates => bleManager.batteryStream;

  // ✅ CONSTRUCTOR: Set up callback to sensor processor
  BleRepositoryImpl() {
    // Set callback so SensorProcessor can call our recalibrate method
    sensorProcessor.setRecalibrationCallback(() {
      recalibrate();
    });
  }

// ✅ ENHANCED: Recalibrate with smoothing reset & cooldown
  bool _isRecalibrating = false;
  int _lastRecalibrationTime = 0;

  @override
  void recalibrate() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // ✅ Prevent recalibration if last one was < 500ms ago
    if (now - _lastRecalibrationTime < 1000) {
      return;
    }

    _lastRecalibrationTime = now;

    try {
      _isRecalibrating = true; // 🚩 temporarily block orientation updates

      _currentShotTrace.clear();
      _allShotTraces.clear();
      _sessionShotTraces.clear();

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

      // ✅ Short delay to flush old orientation frames
      Future.delayed(const Duration(milliseconds: 100), () {
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

    // Clear session shot traces
    _sessionShotTraces.clear();
    if (!_shotTracesController.isClosed) {
      _shotTracesController.add([]);
    }

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

  // ✅ ENHANCED: Shot trace management with packet-based clearing
  final Queue<TracePoint> _currentShotTrace = Queue();
  final List<Queue<TracePoint>> _allShotTraces = [];

  DateTime? _sessionStartTime;

  // ✅ NEW: File saving variables
  File? _currentSessionFile;
  final List<Map<String, dynamic>> _sessionData = [];

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
      await bleManager.connectToDevice(device);
      bleManager.startBatteryMonitoring(device); // ✅ ADD THIS LINE
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      bleManager.stopBatteryMonitoring(); // ✅ ADD THIS LINE
      sensorProcessor.resetCalibrationFlags(); // NEW: Reset calibration
      await bleManager.disconnect(device);
    } catch (e) {
      // Ignore errors during disconnection
    }
  }

  StreamController<StreamingModel>? _streamController;
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription? _orientationSubscription;

  @override
  Stream<StreamingModel> enableSensors(BluetoothDevice device) async* {
    await _streamController?.close();
    _dataSubscription?.cancel();
    _orientationSubscription?.cancel();

    _streamController = StreamController<StreamingModel>.broadcast();
    _initializeSession();
    sensorProcessor.resetForNewSession();

    try {
      // ✅ NEW: Stream health timeout check
      final healthCheckTimer = Timer.periodic(
        const Duration(seconds: 2),
            (timer) {
          if (!bleManager.isStreamHealthy && !_streamController!.isClosed) {
            timer.cancel();
            _streamController!
                .addError('Sensor data stream timeout - no data received');
          }
        },
      );
      sensorProcessor.isTrainingActive = true;
      _dataSubscription = bleManager.dataStream.listen(
            (data) => sensorProcessor.processData(data),
        onError: (e) {
          healthCheckTimer.cancel();
          print('❌ BLE data error: $e');
          _streamController?.addError("BLE Error: $e");
        },
        onDone: () => healthCheckTimer.cancel(),
      );

      _orientationSubscription = sensorProcessor.orientationStream.listen(
            (orientation) {
          try {
            if (_isRecalibrating) {
              return;
            }

            final roll = orientation.roll * 180 / 3.14159;
            final pitch = orientation.pitch * 180 / 3.14159;
            final yaw = orientation.yaw * 180 / 3.14159;

            final streamingModel = StreamingModel(
              roll: roll,
              pitch: pitch,
              yaw: yaw,
              points: Queue<TracePoint>.from(_currentShotTrace),
              shotDetected: orientation.shotDetected,
            );

            if (_streamController != null && !_streamController!.isClosed) {
              _streamController!.add(streamingModel);
            }
          } catch (e) {
            print('❌ Orientation processing error: $e');
            healthCheckTimer.cancel();
            _streamController?.addError('Sensor data error: $e');
          }
        },
        onError: (e) {
          healthCheckTimer.cancel();
          print('❌ Orientation stream error: $e');
          _streamController?.addError('Sensor connection lost: $e');
        },
      );

      print('✅ Stream subscriptions setup complete');
      yield* _streamController!.stream;
    } catch (e) {
      print('❌ Enable sensors failed: $e');
      _streamController?.addError('Failed to enable sensors: $e');
      yield* _streamController!.stream;
    }
  }

  @override
  Future<void> enableBleSensorsOnly(BluetoothDevice device) async {
    try {
      await bleManager.enableSensors(device);
      print('✅ BLE sensors enabled successfully (only enable function)');
    } catch (e) {
      print('❌ Failed to enable BLE sensors: $e');
      rethrow; // propagate error to caller
    }
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
      sensorProcessor.resetCalibrationFlags();
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
      int hapticCommand,
      BluetoothDevice device) async
  {
    try {
      await bleManager.sendcommand(ditCommand, dvcCommand, swdCommand,
          swbdCommand, avdCommand, avdtCommand, hapticCommand, device);
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
    _batterySubscription?.cancel(); // ✅ ADD THIS LINE
    sensorProcessor.dispose();
  }

  // Add this method to BleRepositoryImpl class
  @override
  Future<Map<String, int>> readDeviceSettings(BluetoothDevice device) async {
    try {
      return await bleManager.readDeviceSettings(device);
    } catch (e) {
      print('❌ Error reading device settings: $e');
      rethrow;
    }
  }

  @override
  void resetShotCycleForSessionComplete() {
    // TODO: implement resetShotCycleForSessionComplete
  }

  @override
  void setTargetShotCount(int targetCount) {
    // TODO: implement setTargetShotCount
  }

  @override
  Future<void> sendHapticCommand(int hapticIntensity, BluetoothDevice device) async {
    try {
      await bleManager.sendHapticCommand(hapticIntensity, device);
    } catch (e) {
      rethrow;
    }
  }
  // lib/features/training/data/repositories/ble_repository_impl.dart
// Add this method before dispose()

  @override
  Future<void> factoryReset(BluetoothDevice device) async {
    try {
      await bleManager.factoryReset(device);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void startTrainingForSensorProcessor() {
    sensorProcessor.isTrainingActive = true;
  }

  @override
  void stopTrainingForSensorProcessor() {
    sensorProcessor.isTrainingActive = false;
  }



}
