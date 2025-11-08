import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BleManager {
  final String serviceUuid = "0000b3a0-0000-1000-8000-00805f9b34fb";
  final String notifyUuid = "0000b3a1-0000-1000-8000-00805f9b34fb";
  final String writeUuid = "0000b3a2-0000-1000-8000-00805f9b34fb";
  final String debugUuid = "0000b3a3-0000-1000-8000-00805f9b34fb";

  StreamController<List<int>> dataStreamController =
      StreamController.broadcast();
  StreamSubscription? _notifySubscription;
  StreamSubscription? _debugSubscription;

  Stream<List<int>> get dataStream => dataStreamController.stream;

  Future<List<fbp.ScanResult>> scanForDevices(
      {int scanTimeoutSeconds = 15}) async {
    // Ensure any previous scan is stopped
    await fbp.FlutterBluePlus.stopScan();

    List<fbp.ScanResult> discoveredDevices = [];

    // Start scanning
    await fbp.FlutterBluePlus.startScan(
        timeout: Duration(seconds: scanTimeoutSeconds),
      withNames: ["GMSync", "SK", "RA"],
    );

    // Listen to scan results
    var subscription = fbp.FlutterBluePlus.scanResults.listen((results) {
      print("BleManager: Found ${results.length} devices");
      discoveredDevices = results;
    });

    // Wait for the scan timeout
    await Future.delayed(Duration(seconds: scanTimeoutSeconds));

    // Clean up
    subscription.cancel();
    await fbp.FlutterBluePlus.stopScan();

    print(
        "BleManager: Scan complete, found ${discoveredDevices.length} devices");
    return discoveredDevices;
  }

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    print("BleManager: Connecting to device ${device.platformName}");

    // Reset the stream controller if it's closed
    if (dataStreamController.isClosed) {
      print("BleManager: Stream controller was closed, creating new one");
      dataStreamController = StreamController.broadcast();
    }

    // Ensure device is null to start fresh
    print("BleManager: Device was not null, disconnecting first");
    try {
      await device.disconnect();
    } catch (e) {
      print("BleManager: Error disconnecting old device: $e");
    }
    // Add a delay to ensure disconnect completes
    await Future.delayed(const Duration(milliseconds: 500));

    device = device;
    await device.connect(
        autoConnect: false, timeout: const Duration(seconds: 10));
    print("BleManager: Connected to device ${device.platformName}");
  }

  Future<void> disconnect(fbp.BluetoothDevice device) async {
    try {
      stopBatteryMonitoring(); // ✅ ADD THIS LINE
      // Disable sensors before disconnecting
      await disableSensors(device);

      await device.disconnect();
      print("Disconnected from device");
    } catch (e) {
      print("Error during disconnect: $e");
    }
    if (!dataStreamController.isClosed) {
      await dataStreamController.close();
      // Create new controller for future connections
      dataStreamController = StreamController.broadcast();
    }
  }

  // ✅ NEW: Track last data received time
  DateTime? _lastDataReceivedTime;

  // ✅ NEW: Check if stream is healthy
  bool get isStreamHealthy {
    if (_lastDataReceivedTime == null) return false;
    final now = DateTime.now();
    return now.difference(_lastDataReceivedTime!).inSeconds < 3;
  }

  // ✅ NEW: Track if sensor is ready
  bool _sensorInitialized = false;
  late Completer<bool> _sensorReadyCompleter = Completer<bool>();

  Future<void> enableSensors(fbp.BluetoothDevice device) async {
    // ✅ Reset state
    _sensorInitialized = false;
    _lastDataReceivedTime = null;
    _sensorReadyCompleter = Completer(); // re-init for every start

    // ✅ Ensure fresh stream
    if (dataStreamController.isClosed) {
      dataStreamController = StreamController.broadcast();
      print("✅ BleManager: New stream controller created");
    }

    List<fbp.BluetoothService> services = await device.discoverServices();
    String normalizeUuid(String uuid) => uuid.toLowerCase().replaceAll('-', '');

    fbp.BluetoothService? targetService;
    String targetUuidNormalized = normalizeUuid(serviceUuid);

    for (var service in services) {
      String serviceUuidStr = normalizeUuid(service.serviceUuid.toString());
      if (serviceUuidStr == targetUuidNormalized || serviceUuidStr == "b3a0") {
        targetService = service;
        break;
      }
    }
    if (targetService == null)
      throw Exception("Service $serviceUuid not found");

    fbp.BluetoothCharacteristic? notifyChar;
    fbp.BluetoothCharacteristic? debugChar;
    fbp.BluetoothCharacteristic? writeChar;

    String notifyUuidNormalized = normalizeUuid(notifyUuid);
    String debugUuidNormalized = normalizeUuid(debugUuid);
    String writeUuidNormalized = normalizeUuid(writeUuid);

    for (var char in targetService.characteristics) {
      String charUuidStr = normalizeUuid(char.characteristicUuid.toString());
      if (charUuidStr == notifyUuidNormalized || charUuidStr == "b3a1") {
        notifyChar = char;
      } else if (charUuidStr == debugUuidNormalized || charUuidStr == "b3a3") {
        debugChar = char;
      } else if (charUuidStr == writeUuidNormalized || charUuidStr == "b3a2") {
        writeChar = char;
      }
    }

    // ✅ Subscribe to notifications (main data)
    if (notifyChar != null) {
      _notifySubscription?.cancel();
      await notifyChar.setNotifyValue(true);
      print("✅ Notifications enabled");
      await Future.delayed(const Duration(milliseconds: 200)); // allow enabling

      _notifySubscription = notifyChar.onValueReceived.listen(
        (data) {
          _lastDataReceivedTime = DateTime.now();

          // first data packet → sensor is alive
          if (!_sensorInitialized && data.isNotEmpty) {
            _sensorInitialized = true;
            if (!_sensorReadyCompleter.isCompleted) {
              _sensorReadyCompleter.complete(true);
            }
            print("🎉 First sensor data received!");
          }

          if (!dataStreamController.isClosed) {
            dataStreamController.add(data);
          }
        },
        onError: (e) => print("❌ Notify error: $e"),
      );
    }

    // ✅ Debug notifications
    if (debugChar != null) {
      await debugChar.setNotifyValue(true);
      _debugSubscription?.cancel();
      _debugSubscription = debugChar.onValueReceived.listen(
        (data) {
          //print("🔍 Debug: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}");
        },
        onError: (e) => print("❌ Debug error: $e"),
      );
    }

    if (writeChar == null)
      throw Exception("Write characteristic $writeUuid not found");

    // ✅ Helper to send command and wait for ack/data
    Future<void> sendCommand(List<int> command, String stepName,
        {Duration timeout = const Duration(seconds: 2)}) async {
      print("📤 Sending $stepName...");
      final ackCompleter = Completer();

      // temp listener for debug/data as ack
      late StreamSubscription sub;
      sub = notifyChar!.onValueReceived.listen((data) {
        if (data.isNotEmpty) {
          if (!ackCompleter.isCompleted) {
            ackCompleter.complete(true);
          }
          sub.cancel();
        }
      });

      await writeChar?.write(command, withoutResponse: false);

      try {
        await ackCompleter.future.timeout(timeout);
        print("✅ $stepName acknowledged");
      } catch (e) {
        print("❌ $stepName timed out");
        rethrow;
      }
    }

    // ✅ Step 1: Reset
    await sendCommand([0x55, 0xAA, 0xF0, 0x00], "Reset");

    // ✅ Step 2: Gyro config
    List<int> setGyro833Hz = [0x55, 0xAA, 0x11, 0x02, 0x00, 0x02];
    await sendCommand(setGyro833Hz, "Gyro Config");

    // ✅ Step 3: Enable Gyro
    await sendCommand([0x55, 0xAA, 0x0A, 0x00], "Enable Gyro");

    // ✅ Step 4: Enable Accelerometer
    await sendCommand([0x55, 0xAA, 0x08, 0x00], "Enable Accel");

    // ✅ Step 6: Enable Haptic Motor (CRITICAL - aapke code mein missing hai)
    await sendCommand([0x55, 0xAA, 0x06, 0x00], "Enable Haptic");

    // ✅ Step 5: Confirm streaming
    print("⏳ Waiting for first sensor packet...");
    try {
      await _sensorReadyCompleter.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception("Sensor did not stream data after initialization");
        },
      );
      print("🎉 Sensor initialization COMPLETE - streaming data!");
    } catch (e) {
      print("❌ Sensor failed to start: $e");
      rethrow;
    }
  }

  Future<void> disableSensors(fbp.BluetoothDevice device) async {
    try {
      _sensorInitialized = false;
      if (!_sensorReadyCompleter.isCompleted) {
        _sensorReadyCompleter.complete(false);
      }
      if (!dataStreamController.isClosed) {
        await dataStreamController.close();
        print('BleManager: dataStreamController closed');
      }
      print('debug session bleManager 1');
      List<fbp.BluetoothService> services = await device.discoverServices();
      print('debug session bleManager 2');

      String normalizeUuid(String uuid) =>
          uuid.toLowerCase().replaceAll('-', '');
      fbp.BluetoothCharacteristic? writeChar;
      fbp.BluetoothCharacteristic? notifyChar;

      for (var service in services) {
        String serviceUuidStr = normalizeUuid(service.serviceUuid.toString());
        if (serviceUuidStr == normalizeUuid(serviceUuid) ||
            serviceUuidStr == "b3a0") {
          for (var char in service.characteristics) {
            String charUuidStr =
                normalizeUuid(char.characteristicUuid.toString());
            if (charUuidStr == normalizeUuid(writeUuid) ||
                charUuidStr == "b3a2") {
              writeChar = char;
            } else if (charUuidStr == normalizeUuid(notifyUuid) ||
                charUuidStr == "b3a1") {
              notifyChar = char;
            }
          }
          break;
        }
      }

      // Stop sensors
      if (writeChar != null) {
        await writeChar.write([0x55, 0xAA, 0xF0, 0x00], withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 500));
        print("Sensors stopped");
      }

      // Disable notifications
      if (notifyChar != null) {
        await notifyChar.setNotifyValue(false);
        _notifySubscription?.cancel();
        _notifySubscription = null;
        print("Notify subscription canceled");
      }
    } catch (e) {
      print('debug session bleManager 3');
      print("Error during disableSensors: $e");
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo(fbp.BluetoothDevice device) async {
    int batteryLevel = 85; // Defaults
    String firmwareVersion = 'v2.1.3';
    String signalStrength = 'Strong';
    try {
      List<fbp.BluetoothService> services = await device.discoverServices();
      try {
        final batteryService = services.firstWhere(
          (s) => s.serviceUuid.toString().toLowerCase().contains('180f'),
        );
        final batteryLevelChar = batteryService.characteristics.firstWhere(
          (c) => c.characteristicUuid.toString().toLowerCase().contains('2a19'),
        );
        final value = await batteryLevelChar.read();
        batteryLevel = value.isNotEmpty ? value[0] : batteryLevel;
      } catch (e) {
        print(
            "⚠️ Battery level read failed, using default ($batteryLevel%) → $e");
      }
      try {
        final infoService = services.firstWhere(
          (s) => s.serviceUuid.toString().toLowerCase().contains('180a'),
        );
        final firmwareChar = infoService.characteristics.firstWhere(
          (c) => c.characteristicUuid.toString().toLowerCase().contains('2a26'),
        );
        final value = await firmwareChar.read();
        firmwareVersion = String.fromCharCodes(value);
      } catch (e) {
        print(
            "⚠️ Firmware version read failed, using default ($firmwareVersion) → $e");
      }
      try {
        final rssi = await device.readRssi();
        signalStrength = mapRssiToSignalStrength(rssi);
      } catch (e) {
        print(
            "⚠️ Signal strength read failed, using default ($signalStrength) → $e");
      }
    } catch (e) {
      print("❗ Error discovering services or reading device info: $e");
    }

    return {
      'batteryLevel': batteryLevel,
      'firmwareVersion': firmwareVersion,
      'signalStrength': signalStrength,
    };
  }

  String mapRssiToSignalStrength(int rssi) {
    if (rssi >= -50) {
      return 'Strong'; // 📶📶📶
    } else if (rssi >= -70) {
      return 'Good'; // 📶📶⬜
    } else {
      return 'Weak'; // 📶⬜⬜
    }
  }

  Future<void> sendcommand(
      int ditCommand,
      int dvcCommand,
      int swdCommand,
      int swbdCommand,
      int avdCommand,
      int avdtCommand,
      int hapticCommand,
      fbp.BluetoothDevice device) async {
    print(
        "Command Recieved : $ditCommand,$dvcCommand,$swdCommand,$swbdCommand");
    List<int> ditC;
    List<int> dvcC;
    List<int> swdC;
    List<int> swbdC;
    List<int> avtC;
    List<int> avdtC;
    List<int> hapticC;

    // 1=1g
    // 2=1.5g
    // 3=2g
    // 4=2.5g
    // 5=3g
    // 6=3.5g
    // 7=4g
    // 8=5g
    // 9=7g
    // 10=8g
    // 11=9g
    // 12=10g

    switch (ditCommand) {
      case 1:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x08, 0x00];
        break;
      case 2:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x0C, 0x00];
        break;
      case 3:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x10, 0x00];
        break;
      case 4:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x14, 0x00];
        break;
      case 5:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x18, 0x00];
        break;
      case 6:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x1C, 0x00];
        break;
      case 7:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x20, 0x00];
        break;
      case 8:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x28, 0x00];
        break;
      case 9:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x30, 0x00];
        break;
      case 10:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x38, 0x00];
        break;
      case 11:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x40, 0x00];
        break;
      case 12:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x48, 0x00];
        break;
      default:
        ditC = [0x55, 0xAA, 0x02, 0x02, 0x18, 0x00];
        break;
    }

    switch (dvcCommand) {
      case 1:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0x01];
        break;
      case 2:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0x02];
        break;
      case 3:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0X03];
        break;
      case 4:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0X04];
        break;
      case 5:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0X05];
        break;
      case 6:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0X06];
        break;
      default:
        dvcC = [0x55, 0xAA, 0x03, 0x01, 0x07];
        break;
    }

    switch (swdCommand) {
      case 1:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0x05];
        break;
      case 2:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0x04];
        break;
      case 3:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0X03];
        break;
      case 4:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0X02];
        break;
      case 5:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0X01];
        break;
      case 6:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0X00];
        break;
      default:
        swdC = [0x55, 0xAA, 0x04, 0x01, 0x01];
        break;
    }

    switch (swbdCommand) {
      case 1:
        swbdC = [0x55, 0xAA, 0x05, 0x01, 0x01];
        break;
      case 2:
        swbdC = [0x55, 0xAA, 0x05, 0x01, 0x02];
        break;
      case 3:
        swbdC = [0x55, 0xAA, 0x05, 0x01, 0X03];
        break;
      case 4:
        swbdC = [0x55, 0xAA, 0x05, 0x01, 0X04];
        break;
      case 5:
        swbdC = [0x55, 0xAA, 0x05, 0x01, 0X05];
        break;
      default:
        swbdC = [0x55, 0xAA, 0x05, 0x01, 0x01];
        break;
    }

    switch (avdCommand) {
      case 1:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x00, 0x32];
        break;
      case 2:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x00, 0x4B];
        break;
      case 3:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x00, 0x64];
        break;
      case 4:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x00, 0x96];
        break;
      case 5:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x00, 0xC8];
        break;
      case 6:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x00, 0xFA];
        break;
      case 7:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x01, 0x2C];
        break;
      case 8:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x01, 0x5E];
        break;
      case 9:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x01, 0x90];
        break;
      case 10:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x01, 0xC2];
        break;
      case 11:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x01, 0xF4];
        break;
      default:
        avtC = [0x55, 0xAA, 0x07, 0x02, 0x01, 0x32];
        break;
    }

    //-----------------------------------------------------------------

    switch (avdtCommand) {
      case 0:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0x00];
        break;
      case 1:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0x01];
        break;
      case 2:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0x02];
        break;
      case 3:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X03];
        break;
      case 4:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X04];
        break;
      case 5:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X05];
        break;
      case 6:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X06];
        break;
      case 7:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X07];
        break;
      case 8:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X08];
        break;
      case 9:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0X09];
        break;
      default:
        avdtC = [0x55, 0xAA, 0x08, 0x01, 0x01];
        break;
    }

    // ---------------------------------------------

    switch (hapticCommand) {
      case 0:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x00]; // OFF ✅
      case 1:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x0A]; // 10%
        break;
      case 2:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x14]; // 20%
        break;
      case 3:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x1E]; // 30%
        break;
      case 4:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x28]; // 40%
        break;
      case 5:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x32]; // 50%
        break;
      case 6:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x3C]; // 60%
        break;
      case 7:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x46]; // 70%
        break;
      case 8:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x50]; // 80%
        break;
      case 9:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x5A]; // 90%
        break;
      case 10:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x64]; // 100%
        break;
      default:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x00]; // OFF
        break;
    }

    // The rest of your code
    List<fbp.BluetoothService> services = await device.discoverServices();
    String normalizeUuid(String uuid) => uuid.toLowerCase().replaceAll('-', '');
    fbp.BluetoothCharacteristic? writeChar;
    fbp.BluetoothCharacteristic? notifyChar;

    for (var service in services) {
      String serviceUuidStr = normalizeUuid(service.serviceUuid.toString());
      if (serviceUuidStr == normalizeUuid(serviceUuid) ||
          serviceUuidStr == "b3a0") {
        for (var char in service.characteristics) {
          String charUuidStr =
              normalizeUuid(char.characteristicUuid.toString());
          if (charUuidStr == normalizeUuid(writeUuid) ||
              charUuidStr == "b3a2") {
            writeChar = char;
          } else if (charUuidStr == normalizeUuid(notifyUuid) ||
              charUuidStr == "b3a1") {
            notifyChar = char;
          }
        }
        break;
      }
    }

    if (writeChar != null) {
      print("Characteristic found: ${writeChar.uuid}");
      final sendCharacteristic = writeChar;

      // Check if the characteristic is writable
      if (sendCharacteristic.properties.write ?? false) {
        // Write the new command to the characteristic
        await sendCharacteristic.write(ditC);
        var v = await sendCharacteristic.write(dvcC);
        await sendCharacteristic.write(swdC);
        await sendCharacteristic.write(swbdC);
        //
        await sendCharacteristic.write(avtC);
        //
        await sendCharacteristic.write(avdtC);
        //
        await sendCharacteristic.write(hapticC);
      } else {
        print('Characteristic is not writable.');
      }

      // Check if the characteristic is readable
      // if (receiveCharacteristic?.properties.notify ?? false) {
      //   //Notify
      //   List<int> response = [];
      //   receiveCharacteristic?.lastValueStream.listen((value) {
      //     response = value;
      //     print("Value is pbtained0");
      //     print("Value is check uis $value");
      //     print('Command notified successfully for all ');
      //   });
      //   print("After reading the characteristic");
      // }
    }
  }

  // lib/features/training/data/datasources/ble_manager.dart

// Add this method to BleManager class
  Future<Map<String, int>> readDeviceSettings(
      fbp.BluetoothDevice device) async {
    print("📖 Reading device settings...");

    List<fbp.BluetoothService> services = await device.discoverServices();
    String normalizeUuid(String uuid) => uuid.toLowerCase().replaceAll('-', '');

    fbp.BluetoothCharacteristic? writeChar;
    fbp.BluetoothCharacteristic? notifyChar;

    // Find characteristics
    for (var service in services) {
      String serviceUuidStr = normalizeUuid(service.serviceUuid.toString());
      if (serviceUuidStr == normalizeUuid(serviceUuid) ||
          serviceUuidStr == "b3a0") {
        for (var char in service.characteristics) {
          String charUuidStr =
              normalizeUuid(char.characteristicUuid.toString());
          if (charUuidStr == normalizeUuid(writeUuid) ||
              charUuidStr == "b3a2") {
            writeChar = char;
          } else if (charUuidStr == normalizeUuid(notifyUuid) ||
              charUuidStr == "b3a1") {
            notifyChar = char;
          }
        }
        break;
      }
    }

    if (writeChar == null || notifyChar == null) {
      throw Exception("Required characteristics not found");
    }

    // Enable notifications
    await notifyChar.setNotifyValue(true);

    // Read each parameter
    final settings = <String, int>{};
    final params = {
      'pfi': 0x02, // Detection threshold
      'ppf': 0x03, // Detection valid coefficient
      'pwd': 0x04, // Vibration waveform duration
      'spi': 0x05, // Pre-stable waveform duration
    };

    for (var entry in params.entries) {
      final completer = Completer<int>();

      // Listen for response
      final subscription = notifyChar.onValueReceived.listen((data) {
        if (data.length >= 5 &&
            data[0] == 0x55 &&
            data[1] == 0xAA &&
            data[2] == 0x00) {
          // Parse response: 55 AA 00 [length] [param_type] [value...]
          if (data[4] == entry.value) {
            int value;
            if (entry.key == 'pfi') {
              // Threshold is 2 bytes
              value = (data[5] << 8) | data[6];
              // Convert hex value to index (1-12 range)
              value = _convertThresholdToIndex(value);
            } else {
              // Other params are 1 byte
              value = data[5];
            }
            if (!completer.isCompleted) completer.complete(value);
          }
        }
      });

      try {
        // Send read command: 55 AA 00 01 [param_type]
        await writeChar.write([0x55, 0xAA, 0x00, 0x01, entry.value]);

        // Wait for response with timeout
        final value = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw Exception('Timeout reading ${entry.key}'),
        );

        settings[entry.key] = value;
        print("✅ ${entry.key}: $value");
      } finally {
        await subscription.cancel();
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Disable notifications
    await notifyChar.setNotifyValue(false);

    return settings;
  }

// Helper method to convert threshold hex to index
  int _convertThresholdToIndex(int hexValue) {
    const thresholds = {
      0x0800: 1, // 1g
      0x0C00: 2, // 1.5g
      0x1000: 3, // 2g
      0x1400: 4, // 2.5g
      0x1800: 5, // 3g
      0x1C00: 6, // 3.5g
      0x2000: 7, // 4g
      0x2800: 8, // 5g
      0x3800: 9, // 7g
      0x4000: 10, // 8g
      0x4800: 11, // 9g
      0x5000: 12, // 10g
    };
    return thresholds[hexValue] ?? 5; // Default to 3g
  }

  // lib/features/training/data/datasources/ble_manager.dart
// Add this single method after sendcommand method

  Future<void> sendHapticCommand(int hapticIntensity, fbp.BluetoothDevice device) async {
    List<int> hapticC;

    switch (hapticIntensity) {
      case 0:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x00]; // OFF
        break;
      case 1:
        //hapticC = [0x55, 0xAA, 0x10, 0x01, 0x0A]; // 10%
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x0F]; // 15%
        break;
      case 2:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x14]; // 20%
        break;
      case 3:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x1E]; // 30%
        break;
      case 4:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x28]; // 40%
        break;
      case 5:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x32]; // 50%
        break;
      case 6:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x3C]; // 60%
        break;
      case 7:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x46]; // 70%
        break;
      case 8:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x50]; // 80%
        break;
      case 9:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x5A]; // 90%
        break;
      case 10:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x64]; // 100%
        break;
      default:
        hapticC = [0x55, 0xAA, 0x10, 0x01, 0x00]; // OFF
    }

    List<fbp.BluetoothService> services = await device.discoverServices();
    String normalizeUuid(String uuid) => uuid.toLowerCase().replaceAll('-', '');
    fbp.BluetoothCharacteristic? writeChar;

    for (var service in services) {
      String serviceUuidStr = normalizeUuid(service.serviceUuid.toString());
      if (serviceUuidStr == normalizeUuid(serviceUuid) || serviceUuidStr == "b3a0") {
        for (var char in service.characteristics) {
          String charUuidStr = normalizeUuid(char.characteristicUuid.toString());
          if (charUuidStr == normalizeUuid(writeUuid) || charUuidStr == "b3a2") {
            writeChar = char;
            break;
          }
        }
        break;
      }
    }

    if (writeChar != null && (writeChar.properties.write ?? false)) {
      await writeChar.write(hapticC);
    }
  }

  // lib/features/training/data/datasources/ble_manager.dart
// Add this method after sendHapticCommand method

  Future<void> factoryReset(fbp.BluetoothDevice device) async {
    List<fbp.BluetoothService> services = await device.discoverServices();
    String normalizeUuid(String uuid) => uuid.toLowerCase().replaceAll('-', '');
    fbp.BluetoothCharacteristic? writeChar;

    for (var service in services) {
      String serviceUuidStr = normalizeUuid(service.serviceUuid.toString());
      if (serviceUuidStr == normalizeUuid(serviceUuid) || serviceUuidStr == "b3a0") {
        for (var char in service.characteristics) {
          String charUuidStr = normalizeUuid(char.characteristicUuid.toString());
          if (charUuidStr == normalizeUuid(writeUuid) || charUuidStr == "b3a2") {
            writeChar = char;
            break;
          }
        }
        break;
      }
    }

    if (writeChar != null && (writeChar.properties.write ?? false)) {
      await writeChar.write([0x55, 0xAA, 0xFE, 0x00]); // Factory reset command
      print('✅ Factory reset command sent');
    }
  }

  // Add these class-level variables (around line 10)
  Timer? _batteryUpdateTimer;
  final StreamController<int> _batteryStreamController = StreamController<int>.broadcast();

// Add this getter (around line 15)
  Stream<int> get batteryStream => _batteryStreamController.stream;

// Add this method (around line 600, after getDeviceInfo method)
  /// Starts periodic battery level monitoring
  void startBatteryMonitoring(fbp.BluetoothDevice device) {
    _batteryUpdateTimer?.cancel();

    _batteryUpdateTimer = Timer.periodic(
      const Duration(seconds: 30), // Update every 30 seconds
          (timer) async {
        try {
          final deviceInfo = await getDeviceInfo(device);
          final batteryLevel = deviceInfo['batteryLevel'] as int? ?? 0;

          if (!_batteryStreamController.isClosed) {
            _batteryStreamController.add(batteryLevel);
            print('🔋 Battery updated: $batteryLevel%');
          }
        } catch (e) {
          print('⚠️ Battery update failed: $e');
        }
      },
    );

    print('✅ Battery monitoring started');
  }

  /// Stops battery monitoring
  void stopBatteryMonitoring() {
    _batteryUpdateTimer?.cancel();
    _batteryUpdateTimer = null;
    print('🛑 Battery monitoring stopped');
  }
}
