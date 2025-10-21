import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../core/services/prefs.dart';
import '../../../domain/repositories/ble_repository.dart';
import '../training_session/training_session_bloc.dart';
import '../training_session/training_session_event.dart';
import 'ble_scan_event.dart';
import 'ble_scan_state.dart';

class BleScanBloc extends Bloc<BleScanEvent, BleScanState> {
  final BleRepository _bleRepository;
  StreamSubscription? _scanSubscription;
  final TrainingSessionBloc _trainingSessionBloc;

  BleScanBloc(
      {required BleRepository bleRepository,
      required TrainingSessionBloc trainingSessionBloc})
      : _bleRepository = bleRepository,
        _trainingSessionBloc = trainingSessionBloc,
        super(const BleScanState.initial()) {
    on<StartBleScan>(_onStartBleScan);
    on<StopBleScan>(_onStopBleScan);
    on<ConnectToDevice>(_onConnectToDevice);
    on<BleDeviceDiscovered>(_onBleDeviceDiscovered);
    on<DisconnectDevice>(_onDeviceDisconnected);
    on<GetDeviceInfo>(_onGetDeviceInfo);
    on<MarkCalibrationComplete>(_onMarkCalibrationComplete);
  }

  void _onMarkCalibrationComplete(
      MarkCalibrationComplete event,
      Emitter<BleScanState> emit,
      ) {
    emit(state.copyWith(needsCalibration: false));
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

  // lib/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart

// Replace _onConnectToDevice method:
  // ✅ SIMPLIFIED: Single attempt connection
  Future<void> _onConnectToDevice(
    ConnectToDevice event,
    Emitter<BleScanState> emit,
  ) async {
    emit(state.copyWith(isConnecting: true, error: null));

    try {
      await _bleRepository.connectToDevice(event.device);
      final deviceInfo = await _bleRepository.getDeviceInfo(event.device);
      String? sensitivity;

      // ✅ Try reading settings with timeout
      try {
        // await _bleRepository.sendcommand(
        //   2, // pfi (detection threshold)
        //   1, // ppf (detection valid coefficient)
        //   1, // pwd (vibration waveform duration)
        //   1, // spi (pre-stable waveform duration)
        //   1, // avt (vibration time)
        //   1, // avdt (vibration delay time)
        //   event.device,
        // );
        // // Small delay to ensure settings are written
        // await Future.delayed(const Duration(milliseconds: 500));

        final settings = await _bleRepository
            .readDeviceSettings(event.device)
            .timeout(const Duration(seconds: 10));

        // Line ~123-128 ko replace karo
        final settingsString =
            '${settings['pfi']}/${settings['ppf']}/${settings['pwd']}/${settings['spi']}/1/1/1';  // ✅ Added 7th value for haptic
        sensitivity = settingsString;
        await prefs?.setString(sensitivityKey, settingsString);
        print('✅ Settings saved: $settingsString');
      } catch (settingsError) {
        print('⚠️ Settings read failed: $settingsError');

        // ✅ SIMPLIFIED: Just set error, no retry
        await _bleRepository.disconnectFromDevice(event.device);
        emit(state.copyWith(
          isConnecting: false,
          error:
              'Failed to read device settings. Please turn sensor off/on and try again.',
        ));
        return;
      }

      // ✅ Connection successful - show calibration dialog instead of direct navigation
      emit(state.copyWith(
        isConnecting: false,
        connectedDevice: event.device,
        deviceInfo: deviceInfo,
        isConnected: true,
        connectedDeviceId: event.device.remoteId.toString(),
        connectedDeviceName: event.device.platformName,
        sensitivity: sensitivity,
        needsCalibration: true, // NEW: Add this flag
      ));

      _listenForDeviceDisconnection(event.device);
    } catch (e) {
      emit(state.copyWith(
        isConnecting: false,
        error: 'Connection failed: $e',
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
    _trainingSessionBloc.add(DisableSensors(device: event.device));
    emit(state.copyWith(
        connectedDevice: null,
        isConnecting: false,
        isConnected: false,
        connectedDeviceId: null,
        connectedDeviceName: null));

    _trainingSessionBloc.add(const StopTrainingSession());
  }

  void _listenForDeviceDisconnection(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        add(DisconnectDevice(device: device));
      }
    });
  }

  Future<void> _onGetDeviceInfo(
    GetDeviceInfo event,
    Emitter<BleScanState> emit,
  ) async {
    final deviceInfo = await _bleRepository.getDeviceInfo(event.device);
    emit(state.copyWith(deviceInfo: deviceInfo));
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    return super.close();
  }
}
