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
        timeout: Duration(seconds: scanTimeoutSeconds));

    // Listen to scan results
    var subscription = fbp.FlutterBluePlus.scanResults.listen((results) {
      print("BleManager: Found ${results.length} devices");
      discoveredDevices = results
          .where((result) => result.device.platformName == 'GMSync')
          .toList();
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
    await Future.delayed(const Duration(milliseconds: 1500));

    device = device;
    await device.connect(
        autoConnect: false, timeout: const Duration(seconds: 10));
    print("BleManager: Connected to device ${device.platformName}");
  }

  Future<void> disconnect(fbp.BluetoothDevice device) async {
    try {
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

  Future<void> enableSensors(fbp.BluetoothDevice device) async {
    // Ensure dataStreamController is open
    if (dataStreamController.isClosed) {
      print(
          "BleManager: Stream controller was closed, creating new one (enableSensors)");
      dataStreamController = StreamController.broadcast();
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

    if (targetService == null) {
      throw Exception("Service $serviceUuid not found");
    }

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

    if (notifyChar != null) {
      await notifyChar.setNotifyValue(true);
      _notifySubscription?.cancel(); // Cancel any existing subscription
      _notifySubscription = notifyChar.onValueReceived.listen((data) {
        // Stream raw sensor data to processor
        if (!dataStreamController.isClosed) {
          dataStreamController.add(data);
        }
      });
    }

    if (debugChar != null) {
      await debugChar.setNotifyValue(true);
      _debugSubscription?.cancel(); // Cancel any existing subscription
      // _debugSubscription = debugChar.onValueReceived.listen((data) {
      //   String ascii = String.fromCharCodes(data);
      //   print("Debug data: $ascii");
      // });
    }

    if (writeChar != null) {
      await writeChar.write([0x55, 0xAA, 0xF0, 0x00], withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ Setting Gyroscope to 833Hz (2ms interval)
      List<int> setGyro833Hz = [0x55, 0xAA, 0x11, 0x02, 0x00, 0x02];
      await writeChar.write(setGyro833Hz, withoutResponse: true);
      print(
          "Sent command to set gyro to 833Hz: ${setGyro833Hz.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}");
      await Future.delayed(const Duration(milliseconds: 500));

      await writeChar.write([0x55, 0xAA, 0x0A, 0x00], withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 500));

      await writeChar.write([0x55, 0xAA, 0x08, 0x00], withoutResponse: true);
      print("All configuration commands sent.");
    } else {
      throw Exception("Write characteristic $writeUuid not found");
    }
  }

  Future<void> disableSensors(fbp.BluetoothDevice device) async {
    try {
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

  // Check if device is connected
  // bool get isConnected => device != null;

  // Get device name
  // String? get deviceName => device?.platformName;

  Future<Map<String, dynamic>> getDeviceInfo(fbp.BluetoothDevice device) async {
    // if (device == null) {
    //   return {
    //     'batteryLevel': 85, // Default value
    //     'firmwareVersion': 'v2.1.3',
    //     'signalStrength': 'Strong',
    //   };
    // }

    int batteryLevel = 85; // Defaults
    String firmwareVersion = 'v2.1.3';
    String signalStrength = 'Strong';

    try {
      List<fbp.BluetoothService> services = await device.discoverServices();

      // Battery Level (Service 180F → Characteristic 2A19)
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

      // Firmware Version (Service 180A → Characteristic 2A26)
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

      // Signal Strength (RSSI)
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
      fbp.BluetoothDevice device) async {
    print(
        "Command Recieved : $ditCommand,$dvcCommand,$swdCommand,$swbdCommand");
    List<int> ditC;
    List<int> dvcC;
    List<int> swdC;
    List<int> swbdC;
    List<int> avtC;
    List<int> avdtC;

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
}
