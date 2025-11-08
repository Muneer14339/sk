import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../data/model/streaming_model.dart';
// This file contains the BleScanEvent classes which are part of the ble_scan_bloc.dart file.

abstract class BleScanEvent extends Equatable {
  const BleScanEvent();

  @override
  List<Object> get props => [];
}

class StartBleScan extends BleScanEvent {
  const StartBleScan();
}

class StopBleScan extends BleScanEvent {
  const StopBleScan();
}

class ConnectToDevice extends BleScanEvent {
  final BluetoothDevice device;

  const ConnectToDevice({required this.device});

  @override
  List<Object> get props => [device];
}

class GetDeviceInfo extends BleScanEvent {
  final BluetoothDevice device;

  const GetDeviceInfo({required this.device});
}

class BleDeviceDiscovered extends BleScanEvent {
  final ScanResult device;

  const BleDeviceDiscovered(this.device);

  @override
  List<Object> get props => [device];
}

class DisconnectDevice extends BleScanEvent {
  final BluetoothDevice device;

  const DisconnectDevice({required this.device});

  @override
  List<Object> get props => [device];
}

class SensorDataReceived extends BleScanEvent {
  final Stream<StreamingModel> stream;

  const SensorDataReceived(this.stream);

  @override
  List<Object> get props => [stream];
}

class MarkCalibrationComplete extends BleScanEvent {
  const MarkCalibrationComplete();
}

// Add this new event class
class CheckLowBattery extends BleScanEvent {
  const CheckLowBattery();
}

// Add this new event (around line 80)
class UpdateBatteryLevel extends BleScanEvent {
  final int batteryLevel;

  const UpdateBatteryLevel(this.batteryLevel);

  @override
  List<Object> get props => [batteryLevel];
}