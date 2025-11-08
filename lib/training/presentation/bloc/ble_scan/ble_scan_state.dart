import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../data/model/streaming_model.dart';

// This file contains the BleScanState class which is part of the ble_scan_bloc.dart file.

class BleScanState extends Equatable {
  final bool isScanning;
  final bool isConnecting;
  final bool isConnected;
  final String? error;
  final String? connectedDeviceId;
  final String? connectedDeviceName;
  final List<ScanResult> discoveredDevices;
  final bool isSensorsEnabled;
  final StreamingModel? sensorStream;
  final BluetoothDevice? connectedDevice;
  final Map<String, dynamic>? deviceInfo;
  final String? sensitivity;
  final bool needsCalibration;
  // Add these fields in BleScanState class (around line 21)
  final bool lowBatteryDialogShown;

  const BleScanState({
    this.isScanning = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.error,
    this.connectedDeviceId,
    this.connectedDeviceName,
    this.discoveredDevices = const [],
    this.isSensorsEnabled = false,
    this.sensorStream,
    this.connectedDevice,
    this.deviceInfo,
    this.sensitivity,
// In constructor:
    this.needsCalibration = false,

    this.lowBatteryDialogShown = false,
  });

  // Initial state
  const BleScanState.initial() : this();

  // Copy with method for immutable updates
  BleScanState copyWith({
    bool? isScanning,
    bool? isConnecting,
    bool? isConnected,
    String? error,
    String? connectedDeviceId,
    String? connectedDeviceName,
    List<ScanResult>? discoveredDevices,
    bool? isSensorsEnabled,
    StreamingModel? sensorStream,
    BluetoothDevice? connectedDevice,
    Map<String, dynamic>? deviceInfo,
    String? sensitivity,
    // In copyWith method:
    bool? needsCalibration,
    bool? lowBatteryDialogShown,
  }) {
    return BleScanState(
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isSensorsEnabled: isSensorsEnabled ?? this.isSensorsEnabled,
      sensorStream: sensorStream ?? this.sensorStream,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      sensitivity: sensitivity ?? this.sensitivity,
      // In copyWith return:
      needsCalibration: needsCalibration ?? this.needsCalibration,
      lowBatteryDialogShown: lowBatteryDialogShown ?? this.lowBatteryDialogShown,
    );
  }

  @override
  List<Object?> get props => [
        isScanning,
        isConnecting,
        isConnected,
        error,
        connectedDeviceId,
        connectedDeviceName,
        discoveredDevices,
        isSensorsEnabled,
        sensorStream,
        connectedDevice,
        deviceInfo,
        sensitivity,
    // In props:
    needsCalibration,
    lowBatteryDialogShown,
      ];

  @override
  String toString() => 'BleScanState('
      'isScanning: $isScanning, '
      'isConnecting: $isConnecting, '
      'isConnected: $isConnected, '
      'error: $error, '
      'connectedDeviceId: $connectedDeviceId, '
      'connectedDeviceName: $connectedDeviceName, '
      'discoveredDevices: ${discoveredDevices.length} devices, '
      'isSensorsEnabled: $isSensorsEnabled, '
      'sensorStream: $sensorStream, '
      'connectedDevice: $connectedDevice, '
      'deviceInfo: $deviceInfo,'
      'sensitivity: $sensitivity)';
}
