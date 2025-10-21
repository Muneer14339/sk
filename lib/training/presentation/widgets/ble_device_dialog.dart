import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../bloc/ble_scan/ble_scan_bloc.dart';
import '../bloc/ble_scan/ble_scan_event.dart';
import '../bloc/ble_scan/ble_scan_state.dart';

class BleDeviceDialog extends StatelessWidget {
  const BleDeviceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleScanBloc, BleScanState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Available Devices'),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: state.isConnecting
                ? _buildConnecting()
                : state.isScanning
                    ? _buildDeviceList(state.discoveredDevices)
                    : _buildInitialState(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: state.isConnecting
                  ? null
                  : () {
                      if (state.isScanning) {
                        context.read<BleScanBloc>().add(const StopBleScan());
                      } else {
                        context.read<BleScanBloc>().add(const StartBleScan());
                      }
                    },
              child: Text(state.isScanning ? 'STOP SCAN' : 'SCAN'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Press SCAN to start searching for devices'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<BleScanBloc>().add(const StartBleScan());
            },
            child: const Text('SCAN'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to device...'),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<ScanResult> devices) {
    return devices.isEmpty
        ? const Center(child: Text('No devices found'))
        : ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(device.device.platformName.isNotEmpty
                    ? device.device.platformName
                    : 'Unknown Device'),
                subtitle: Text(device.device.remoteId.toString()),
                onTap: () {
                  context.read<BleScanBloc>().add(
                        ConnectToDevice(device: device.device),
                      );
                },
              );
            },
          );
  }
}
