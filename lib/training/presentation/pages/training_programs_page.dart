import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../armory/domain/entities/armory_loadout.dart';
import '../../../armory/presentation/bloc/armory_bloc.dart';
import '../../../armory/presentation/bloc/armory_event.dart';
import '../../../armory/presentation/bloc/armory_state.dart';
import '../../../core/services/prefs.dart';
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
  const TrainingSessionSetupPage({Key? key}) : super(key: key);

  @override
  State<TrainingSessionSetupPage> createState() => _TrainingSessionSetupPageState();
}

class _TrainingSessionSetupPageState extends State<TrainingSessionSetupPage> {
  bool _connectionCompleted = false;
  bool _loadoutCompleted = false;
  bool _alertsCompleted = false;
  bool _drillCompleted = false;

  String? _connectedDeviceName;
  ArmoryLoadout? _selectedLoadout;

  // Alerts (audio only)
  String _audioType = 'Off'; // Off, Beep, Voice
  String _alertsSettings = 'Default settings';

  // Drill settings
  String _drillName = 'Open Practice';
  String _sensitivity = 'Advanced';
  String _distance = '7';
  String _time = '10';
  String _environment = 'Indoor';
  String _drillInfo = 'Open practice';

  BluetoothDevice? _connectedDevice;

  bool get _canContinue => _connectionCompleted && _loadoutCompleted;

  // For custom drill dialog state
  final nameController = TextEditingController();
  final shotCountController = TextEditingController(text: '10');
  final notesController = TextEditingController();
  String tempFireType = 'Dry Fire';
  String tempSensitivity = 'Advanced';
  String tempDistance = '7';
  String tempTime = '10';
  String tempEnvironment = 'Indoor';
  bool showCustomTime = false;
  final customTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleState = context.read<BleScanBloc>().state;
      if (bleState.isConnected && bleState.connectedDevice != null) {
        setState(() {
          _connectionCompleted = true;
          _connectedDeviceName = bleState.connectedDeviceName;
          _connectedDevice = bleState.connectedDevice;
        });
      }
    });
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<ArmoryBloc>().add(LoadLoadoutsEvent(userId: userId));
    }
  }

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
              Text('Training Session', style: AppTheme.headingLarge(context)),
              const SizedBox(height: 8),
              Text(
                'Configure your training setup',
                style: AppTheme.bodyMedium(context)
                    .copyWith(color: AppTheme.textSecondary(context)),
              ),
              const SizedBox(height: 24),
              Text('REQUIRED SETUP', style: AppTheme.labelSmall(context)),
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
                value: _selectedLoadout?.name ?? 'No loadout selected',
                isCompleted: _loadoutCompleted,
                isRequired: true,
                onTap: _showLoadoutDialog,
              ),
              const SizedBox(height: 24),
              Text('OPTIONAL SETUP', style: AppTheme.labelSmall(context)),
              const SizedBox(height: 12),
              _buildSetupCard(
                icon: '🔔',
                title: 'Alerts',
                description: 'Configure audio feedback',
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
              AppTheme.background(context).withOpacity(0),
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
                    : AppTheme.textSecondary(context).withOpacity(0.3),
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
                ? AppTheme.success(context).withOpacity(0.5)
                : isRequired
                ? AppTheme.error(context).withOpacity(0.5)
                : AppTheme.border(context).withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: AppTheme.titleMedium(context)),
                          ),
                          if (isCompleted)
                            Icon(Icons.check_circle,
                                color: AppTheme.success(context), size: 24)
                          else if (isRequired)
                            Icon(Icons.error_outline,
                                color: AppTheme.textSecondary(context), size: 24),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTheme.bodySmall(context)
                            .copyWith(color: AppTheme.textSecondary(context)),
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

  // DIALOGS


  void _showLoadoutDialog() {
    final searchController = TextEditingController();
    final armoryBloc = context.read<ArmoryBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: armoryBloc,
        child: BlocBuilder<ArmoryBloc, ArmoryState>(
          builder: (context, state) {
            List<ArmoryLoadout> loadouts = [];
            if (state is LoadoutsLoaded) {
              loadouts = state.loadouts;
            }
            return Dialog(
              backgroundColor: AppTheme.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.border(context), width: 1.5),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Select Loadout',
                              style: AppTheme.headingMedium(context)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close,
                              color: AppTheme.textPrimary(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search loadouts...',
                        hintStyle: AppTheme.labelMedium(context),
                        prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary(context)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primary(context), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border(context)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: loadouts.isEmpty
                          ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No loadouts found.\nCreate loadouts in Armory first.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMedium(context)
                                .copyWith(color: AppTheme.textSecondary(context)),
                          ),
                        ),
                      )
                          : ListView(
                        shrinkWrap: true,
                        children: loadouts
                            .where((l) => l.name.toLowerCase().contains(
                            searchController.text.toLowerCase()))
                            .map((l) => _buildLoadoutItem(l))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadoutItem(ArmoryLoadout loadout) {
    final isSelected = _selectedLoadout?.id == loadout.id;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _selectedLoadout = loadout;
          _loadoutCompleted = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary(context).withOpacity(0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.border(context).withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loadout.name,
                    style: AppTheme.titleMedium(context).copyWith(
                      color: isSelected
                          ? AppTheme.primary(context)
                          : AppTheme.textPrimary(context),
                    ),
                  ),
                  if (loadout.notes != null)
                    Text(
                      loadout.notes!,
                      style: AppTheme.bodySmall(context).copyWith(
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              size: isSelected ? 20 : 14,
              color: isSelected
                  ? AppTheme.primary(context)
                  : AppTheme.textSecondary(context),
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
          side: BorderSide(color: AppTheme.border(context), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Audio Feedback', style: AppTheme.headingMedium(context)),
              const SizedBox(height: 16),
              _buildAudioOption('Off', 'No audio feedback'),
              _buildAudioOption('Beep', 'Simple beep sounds'),
              _buildAudioOption('Voice', 'Voice instructions'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _alertsCompleted = true;
                      _alertsSettings = 'Audio: $_audioType';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioOption(String type, String description) {
    final isSelected = _audioType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _audioType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary(context).withOpacity(0.1)
              : AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary(context)
                : AppTheme.border(context).withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary(context) : AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: AppTheme.titleMedium(context)),
                  Text(description,
                      style: AppTheme.bodySmall(context)
                          .copyWith(color: AppTheme.textSecondary(context))),
                ],
              ),
            ),
          ],
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
          side: BorderSide(color: AppTheme.border(context), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Training Drill', style: AppTheme.headingMedium(context)),
              const SizedBox(height: 16),
              _buildDrillOption(
                'Open Practice',
                'Unrestricted practice session',
                icon: '🎯',
              ),
              _buildDrillOption(
                'Bill Drill',
                '6 rounds, 7 yards, fastest time',
                icon: '⚡',
              ),
              _buildDrillOption(
                'El Presidente',
                '12 rounds, 10 yards, 3 targets',
                icon: '🎖️',
              ),
              _buildDrillOption(
                'Custom Drill',
                'Create your own drill',
                icon: '✨',
                isCustom: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrillOption(String name, String description,
      {String icon = '🎯', bool isCustom = false}) {
    final isSelected = _drillName == name;
    return GestureDetector(
      onTap: () {
        if (isCustom) {
          Navigator.pop(context);
          _showCustomDrillDialog();
        } else {
          Navigator.pop(context);
          setState(() {
            _drillName = name;
            _drillInfo = description;
            _drillCompleted = true;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border(context).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTheme.titleMedium(context)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: AppTheme.bodySmall(context)
                          .copyWith(color: AppTheme.textSecondary(context))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: AppTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }

  void _showCustomDrillDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppTheme.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.border(context), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Custom Drill',
                              style: AppTheme.headingMedium(context)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close,
                              color: AppTheme.textPrimary(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Drill Name',
                      controller: nameController,
                      hint: 'e.g., My Custom Drill',
                    ),
                    const SizedBox(height: 16),
                    _buildToggleSection(
                      label: 'Fire Type',
                      options: ['Dry Fire', 'Live Fire'],
                      selected: tempFireType,
                      onChanged: (value) {
                        setDialogState(() {
                          tempFireType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildChipSection(
                      label: 'Sensitivity',
                      options: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
                      selected: tempSensitivity,
                      onChanged: (value) {
                        setDialogState(() {
                          tempSensitivity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Shot Count',
                      controller: shotCountController,
                      hint: '10',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildChipSection(
                      label: 'Distance (yards)',
                      options: ['3', '5', '7', '10', '15', '25'],
                      selected: tempDistance,
                      onChanged: (value) {
                        setDialogState(() {
                          tempDistance = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Limit (seconds)',
                          style: AppTheme.labelLarge(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...[
                              '5',
                              '10',
                              '15',
                              '30',
                              '60',
                              'Unlimited',
                              'Custom'
                            ].map((time) {
                              final isSelected = showCustomTime
                                  ? time == 'Custom'
                                  : tempTime == time;
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    if (time == 'Custom') {
                                      showCustomTime = true;
                                      tempTime = customTimeController.text.isEmpty
                                          ? '10'
                                          : customTimeController.text;
                                    } else {
                                      showCustomTime = false;
                                      tempTime = time;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary(context).withOpacity(0.15)
                                        : AppTheme.surfaceVariant(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary(context)
                                          : AppTheme.border(context).withOpacity(0.1),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    time,
                                    style: AppTheme.bodyMedium(context).copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.primary(context)
                                          : AppTheme.textSecondary(context),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        if (showCustomTime) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: customTimeController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setDialogState(() {
                                tempTime = value.isEmpty ? '10' : value;
                              });
                            },
                            style: AppTheme.bodyMedium(context),
                            decoration: InputDecoration(
                              hintText: 'Enter time in seconds',
                              hintStyle: AppTheme.bodyMedium(context)
                                  .copyWith(color: AppTheme.textSecondary(context)),
                              filled: true,
                              fillColor: AppTheme.surfaceVariant(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.border(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.border(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                BorderSide(color: AppTheme.primary(context), width: 2),
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildToggleSection(
                      label: 'Environment',
                      options: ['Indoor', 'Outdoor'],
                      selected: tempEnvironment,
                      onChanged: (value) {
                        setDialogState(() {
                          tempEnvironment = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Notes (Optional)',
                      controller: notesController,
                      hint: 'Any additional notes...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _drillName = nameController.text.isEmpty
                                ? 'Custom Drill'
                                : nameController.text;
                            _drillInfo =
                            '$tempFireType, $shotCountController.text shots, ${tempDistance}yds';
                            _drillCompleted = true;
                            _sensitivity = tempSensitivity;
                            _distance = tempDistance;
                            _time = tempTime;
                            _environment = tempEnvironment;
                          });
                        },
                        child: const Text('Save Drill'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.bodyMedium(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium(context)
                .copyWith(color: AppTheme.textSecondary(context)),
            filled: true,
            fillColor: AppTheme.surfaceVariant(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primary(context), width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: options.map((option) {
              final isSelected = selected == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary(context)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: AppTheme.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSection({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelLarge(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary(context).withOpacity(0.15)
                      : AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary(context)
                        : AppTheme.border(context).withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: AppTheme.bodyMedium(context).copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primary(context)
                        : AppTheme.textSecondary(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          await context
              .read<TrainingSessionBloc>()
              .bleRepository
              .factoryReset(device);
        },
      ),
    );
  }

  void _continueToPreview() {
    final program = ProgramsModel(
        programName: _drillName,
        noOfShots: int.parse(shotCountController.text),
        weaponProfile: _selectedLoadout,
        recommenedDistance: _distance,
        trainingType: tempFireType,
        timeLimit: _time,
        difficultyLevel: _sensitivity
      // add more values as per your ProgramsModel spec
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionPreviewPage(
          program: program,
          connectedDevice: _connectedDevice!,
          alertsInfo: _alertsSettings,
          drillInfo: _drillInfo,
          audioType: _audioType,
        ),
      ),
    );
  }
}