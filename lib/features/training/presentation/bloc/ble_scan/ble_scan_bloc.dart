import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pulse_skadi/features/training/domain/repositories/ble_repository.dart';
import 'ble_scan_event.dart';
import 'ble_scan_state.dart';

class BleScanBloc extends Bloc<BleScanEvent, BleScanState> {
  final BleRepository _bleRepository;
  StreamSubscription? _scanSubscription;

  BleScanBloc({required BleRepository bleRepository})
      : _bleRepository = bleRepository,
        super(const BleScanState.initial()) {
    on<StartBleScan>(_onStartBleScan);
    on<StopBleScan>(_onStopBleScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<BleDeviceDiscovered>(_onBleDeviceDiscovered);
    on<DisconnectDevice>(_onDeviceDisconnected);
  }

  Future<void> _onStartBleScan(
    StartBleScan event,
    Emitter<BleScanState> emit,
  ) async {
    emit(BleScanState.initial());
    emit(state.copyWith(
        isScanning: true,
        isConnecting: false,
        isConnected: false,
        error: null,
        discoveredDevices: []));

    try {
      await _bleRepository.startScan();
      _scanSubscription = _bleRepository.scanResults.listen((results) {
        if (results.isNotEmpty) {
          add(BleDeviceDiscovered(results.last));
        }
      });
    } on PlatformException catch (e) {
      emit(state.copyWith(isScanning: false, error: e.message ?? ''));
    } catch (e) {
      emit(
          state.copyWith(isScanning: false, error: 'Failed to start scan: $e'));
    }
  }

  Future<void> _onStopBleScan(
    StopBleScan event,
    Emitter<BleScanState> emit,
  ) async {
    emit(state.copyWith(error: null));
    try {
      await _bleRepository.stopScan();
      _scanSubscription?.cancel();
      emit(state.copyWith(isScanning: false, discoveredDevices: []));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to stop scan: $e'));
    }
  }

  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<BleScanState> emit,
  ) async {
    emit(state.copyWith(
      isConnecting: true,
      error: null,
    ));

    try {
      await _bleRepository.connectToDevice(event.device);

      emit(state.copyWith(
        isConnecting: false,
        connectedDevice: event.device,
        isConnected: true,
        connectedDeviceId: event.device.remoteId.toString(),
        connectedDeviceName: event.device.platformName,
      ));
      _listenForDeviceDisconnection(event.device);
    } catch (e) {
      emit(state.copyWith(
        isConnecting: false,
        error: 'Failed to connect: $e',
      ));
    }
  }

  void _onBleDeviceDiscovered(
    BleDeviceDiscovered event,
    Emitter<BleScanState> emit,
  ) {
    final updatedDevices = List<ScanResult>.from(state.discoveredDevices);
    if (!updatedDevices
        .any((d) => d.device.remoteId == event.device.device.remoteId)) {
      updatedDevices.add(event.device);
    }

    emit(state.copyWith(
      discoveredDevices: updatedDevices,
    ));
  }

  void _onDeviceDisconnected(
    DisconnectDevice event,
    Emitter<BleScanState> emit,
  ) {
    emit(state.copyWith(
        connectedDevice: null,
        isConnecting: false,
        isConnected: false,
        connectedDeviceId: null,
        connectedDeviceName: null));
  }

  void _listenForDeviceDisconnection(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        add(DisconnectDevice(device: device));
      }
    });
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}
