// lib/training/presentation/pages/training_session_setup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../data/model/programs_model.dart';
import '../bloc/ble_scan/ble_scan_bloc.dart';
import '../bloc/ble_scan/ble_scan_event.dart';
import '../bloc/ble_scan/ble_scan_state.dart';
import '../bloc/training_session/training_session_bloc.dart';
import '../bloc/training_session/training_session_event.dart';
import '../widgets/device_calibration_dialog.dart';
import 'training_program_builder.dart';

class TrainingSessionSetupPage extends StatefulWidget {
  const TrainingSessionSetupPage({super.key});

  @override
  State<TrainingSessionSetupPage> createState() => _TrainingSessionSetupPageState();
}

class _TrainingSessionSetupPageState extends State<TrainingSessionSetupPage> {
  bool _connectionCompleted = false;
  bool _loadoutCompleted = false;
  bool _alertsCompleted = false;
  bool _drillCompleted = false;

  String? _connectedDeviceName;
  String? _selectedLoadout;
  String _alertsSettings = 'Default settings';
  String _drillInfo = 'Open practice';

  BluetoothDevice? _connectedDevice;

  bool get _canContinue => _connectionCompleted && _loadoutCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Training Session',
                style: AppTheme.headingLarge(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure your training setup',
                style: AppTheme.bodyMedium(context).copyWith(
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'REQUIRED SETUP',
                style: AppTheme.labelSmall(context),
              ),
              const SizedBox(height: 12),
              _buildSetupCard(
                icon: '📡',
                title: 'Connection',
                description: 'Connect to your device via Bluetooth',
                value: _connectedDeviceName ?? 'Not connected',
                isCompleted: _connectionCompleted,
                isRequired: true,
                onTap: _showConnectionDialog,
              ),
              const SizedBox(height: 16),
              _buildSetupCard(
                icon: '🔫',
                title: 'Loadout',
                description: 'Select your firearm and ammunition',
                value: _selectedLoadout ?? 'No loadout selected',
                isCompleted: _loadoutCompleted,
                isRequired: true,
                onTap: _showLoadoutDialog,
              ),
              const SizedBox(height: 24),
              Text(
                'OPTIONAL SETUP',
                style: AppTheme.labelSmall(context),
              ),
              const SizedBox(height: 12),
              _buildSetupCard(
                icon: '🔔',
                title: 'Alerts',
                description: 'Configure haptics and audio feedback',
                value: _alertsSettings,
                isCompleted: _alertsCompleted,
                isRequired: false,
                onTap: _showAlertsDialog,
              ),
              const SizedBox(height: 16),
              _buildSetupCard(
                icon: '🎯',
                title: 'Drill',
                description: 'Choose a training drill or practice freely',
                value: _drillInfo,
                isCompleted: _drillCompleted,
                isRequired: false,
                onTap: _showDrillDialog,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background(context).withValues(alpha: 0),
              AppTheme.background(context),
            ],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinue ? _continueToPreview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canContinue
                    ? AppTheme.primary(context)
                    : AppTheme.textSecondary(context).withValues(alpha: 0.3),
                foregroundColor: _canContinue
                    ? Colors.white
                    : AppTheme.textSecondary(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Preview',
                    style: AppTheme.button(context).copyWith(
                      color: _canContinue
                          ? Colors.white
                          : AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: _canContinue
                        ? Colors.white
                        : AppTheme.textSecondary(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupCard({
    required String icon,
    required String title,
    required String description,
    required String value,
    required bool isCompleted,
    required bool isRequired,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? AppTheme.success(context).withValues(alpha: 0.5)
                : isRequired
                ? AppTheme.error(context).withValues(alpha: 0.5)
                : AppTheme.border(context).withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.titleLarge(context),
                            ),
                          ),
                          if (isRequired && !isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error(context)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'REQUIRED',
                                style: AppTheme.labelSmall(context).copyWith(
                                  color: AppTheme.error(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.success(context),
                              size: 24,
                            ),
                          if (!isCompleted && !isRequired)
                            Icon(
                              Icons.radio_button_unchecked,
                              color: AppTheme.textSecondary(context),
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTheme.bodySmall(context).copyWith(
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: AppTheme.bodyMedium(context).copyWith(
                  color: AppTheme.primary(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionDialog() {
    context.read<BleScanBloc>().add(const StartBleScan());
    showDialog(
      context: context,
      builder: (_) => BlocConsumer<BleScanBloc, BleScanState>(
        listener: (ctx, state) {
          if (state.isConnected && state.needsCalibration) {
            Navigator.of(context).pop();
            _showCalibrationDialog(state.connectedDevice!);
          } else if (state.isConnected) {
            Navigator.of(context).pop();
            setState(() {
              _connectionCompleted = true;
              _connectedDeviceName = state.connectedDeviceName;
              _connectedDevice = state.connectedDevice;
            });
          }
        },
        builder: (__, state) => ModernCustomDialog(
          title: 'Select Device',
          onItemSelected: (device) {
            if (mounted) {
              context.read<BleScanBloc>().add(const StopBleScan());
              context.read<BleScanBloc>().add(ConnectToDevice(device: device));
            }
          },
          state: state,
        ),
      ),
    );
  }

  void _showCalibrationDialog(BluetoothDevice device) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeviceCalibrationDialog(
        onStartCalibration: () async {
          context.read<TrainingSessionBloc>().add(EnableSensors(device: device));
          await Future.delayed(const Duration(seconds: 6));
          context.read<BleScanBloc>().add(const MarkCalibrationComplete());
          Navigator.of(context).pop();
          setState(() {
            _connectionCompleted = true;
            _connectedDeviceName = device.platformName;
            _connectedDevice = device;
          });
        },
        onFactoryReset: () async {
          await context.read<TrainingSessionBloc>().bleRepository.factoryReset(device);
        },
      ),
    );
  }

  void _showLoadoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border(context).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Loadout',
                      style: AppTheme.headingMedium(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLoadoutItem('Primary EDC', 'Glock 19 • Federal HST • 124gr'),
                  _buildLoadoutItem('Competition Setup', 'CZ Shadow 2 • S&B 124gr • Red Dot'),
                  _buildLoadoutItem('Practice Loadout', 'Glock 17 • Winchester • 115gr'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadoutItem(String name, String details) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loadoutCompleted = true;
          _selectedLoadout = '$name • $details';
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border(context).withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTheme.titleMedium(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: AppTheme.bodySmall(context).copyWith(
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border(context).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Alert Settings',
                      style: AppTheme.headingMedium(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haptic Feedback',
                    style: AppTheme.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAlertOption('Off', 'haptic')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAlertOption('Low', 'haptic')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAlertOption('High', 'haptic')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Audio Alerts',
                    style: AppTheme.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAlertOption('Off', 'audio')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAlertOption('Beep', 'audio')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAlertOption('Voice', 'audio')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.surfaceVariant(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.button(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _alertsCompleted = true;
                              _alertsSettings = 'Haptic: Low • Audio: Beep';
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save Settings',
                            style: AppTheme.button(context).copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertOption(String label, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.border(context).withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTheme.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showDrillDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border(context).withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Drill',
                      style: AppTheme.headingMedium(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDrillItem('Open Practice', 'No structure • Untimed'),
                  _buildDrillItem('Bill Drill', '6 rounds @ 7yd • Par 2.5s'),
                  _buildDrillItem('El Presidente', '12 rounds @ 10yd • Par 10s'),
                  _buildDrillItem('Mozambique Drill', '3 rounds @ 7yd • Par 2.5s'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrillItem(String name, String details) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _drillCompleted = true;
          _drillInfo = '$name • $details';
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border(context).withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTheme.titleMedium(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: AppTheme.bodySmall(context).copyWith(
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToPreview() {
    final program = ProgramsModel(
      programName: 'Custom Training Session',
      noOfShots: 10,
      trainingType: 'Live Fire',
      difficultyLevel: 'Intermediate',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionPreviewPage(
          program: program,
          connectedDevice: _connectedDevice!,
          loadoutInfo: _selectedLoadout!,
          alertsInfo: _alertsSettings,
          drillInfo: _drillInfo,
        ),
      ),
    );
  }
}