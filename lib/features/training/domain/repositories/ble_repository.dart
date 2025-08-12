// lib/features/training/domain/repositories/ble_repository.dart - Enhanced version
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pulse_skadi/features/training/data/model/streaming_model.dart';
import 'package:pulse_skadi/features/training/data/model/shot_trace_model.dart';

abstract class BleRepository {
  // Check if Bluetooth is available
  Future<bool> isAvailable();

  // Check if Bluetooth is turned on
  Future<bool> isOn();

  // Start scanning for BLE devices
  Future<void> startScan();

  // Stop scanning for BLE devices
  Future<void> stopScan();

  // Connect to a BLE device
  Future<void> connectToDevice(BluetoothDevice device);

  // Disconnect from a BLE device
  Future<void> disconnectFromDevice(BluetoothDevice device);

  // Get the current scan results
  Stream<List<ScanResult>> get scanResults;

  // Check if currently scanning
  bool get isScanning;

  // Get the current adapter state
  Stream<BluetoothAdapterState> get adapterState;

  // Enable sensors
  Stream<StreamingModel> enableSensors(BluetoothDevice device);

  // Disable sensors
  Future<void> disableSensors(BluetoothDevice device);

  // Get Device Info
  Future<Map<String, dynamic>> getDeviceInfo(BluetoothDevice device);

  // Send command
  Future<void> sendcommand(int ditCommand, int dvcCommand, int swdCommand,
      int swbdCommand, int avdCommand, int avdtCommand, BluetoothDevice device);

  // Recalibrate
  void recalibrate();

  // ✅ NEW: Shot traces management

  // Get current session shot traces
  List<ShotTraceData> get sessionShotTraces;

  // Stream of shot traces updates
  Stream<List<ShotTraceData>> get shotTracesStream;

  // Get specific shot trace by number
  ShotTraceData? getShotTrace(int shotNumber);

  // Load shot traces from file
  Future<List<ShotTraceData>> loadSessionShotTraces(String filePath);

  // Dispose resources
  void dispose();
}