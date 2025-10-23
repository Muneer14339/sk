import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../armory/domain/entities/armory_loadout.dart';
import '../../../armory/presentation/bloc/armory_bloc.dart';
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
  String _sensitivity = 'Beginner';
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
  String tempSensitivity = 'Beginner';
  String tempDistance = '7';
  String tempTime = '10';
  String tempEnvironment = 'Indoor';
  bool showCustomTime = false;
  final customTimeController = TextEditingController();

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
                            child: Text(title, style: AppTheme.titleLarge(context)),
                          ),
                          if (isRequired && !isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.error(context).withOpacity(0.15),
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
                            Icon(Icons.check_circle,
                                color: AppTheme.success(context), size: 24),
                          if (!isCompleted && !isRequired)
                            Icon(Icons.radio_button_unchecked,
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

  void _showAlertsDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved haptic value (default: 'Off' = 0)
    int savedHaptic = prefs.getInt(hapticCustomSettingsKey) ?? 0;
    String tempHaptic = savedHaptic == 0 ? 'Off' : (savedHaptic == 1 ? 'Low' : 'High');
    String tempAudio = _audioType;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppTheme.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.border(context), width: 1.5),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  const SizedBox(height: 20),

                  // Haptic Feedback Section
                  Text(
                    'Haptic Feedback',
                    style: AppTheme.titleMedium(context),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border(context)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAlertButton(
                            'Off',
                            tempHaptic == 'Off',
                                () => setDialogState(() => tempHaptic = 'Off'),
                          ),
                        ),
                        Expanded(
                          child: _buildAlertButton(
                            'Low',
                            tempHaptic == 'Low',
                                () => setDialogState(() => tempHaptic = 'Low'),
                          ),
                        ),
                        Expanded(
                          child: _buildAlertButton(
                            'High',
                            tempHaptic == 'High',
                                () => setDialogState(() => tempHaptic = 'High'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Audio Alerts Section
                  Text(
                    'Audio Alerts',
                    style: AppTheme.titleMedium(context),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border(context)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAlertButton(
                            'Off',
                            tempAudio == 'Off',
                                () => setDialogState(() => tempAudio = 'Off'),
                          ),
                        ),
                        Expanded(
                          child: _buildAlertButton(
                            'Beep',
                            tempAudio == 'Beep',
                                () => setDialogState(() => tempAudio = 'Beep'),
                          ),
                        ),
                        Expanded(
                          child: _buildAlertButton(
                            'Voice',
                            tempAudio == 'Voice',
                                () => setDialogState(() => tempAudio = 'Voice'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppTheme.border(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.button(context).copyWith(
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Convert haptic value to int
                            int hapticValue = tempHaptic == 'Off'
                                ? 0
                                : (tempHaptic == 'Low' ? 1 : 3);

                            // Save to SharedPreferences
                            await prefs.setInt(
                              hapticCustomSettingsKey,
                              hapticValue,
                            );

                            setState(() {
                              _audioType = tempAudio;
                              _alertsCompleted = true;
                              _alertsSettings =
                              'Haptic: $tempHaptic • Audio: $tempAudio';
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
          );
        },
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
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text('Select Drill',
                          style: AppTheme.headingMedium(context))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close,
                          color: AppTheme.textPrimary(context))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildDrillItem(
                    name: 'Open Practice',
                    details: 'Default • No structure • Untimed'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCustomDrillDialog();
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text('Create Custom Drill'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- CUSTOM DRILL DIALOG: AppTheme UI ---
  void _showCustomDrillDialog() {
    bool showCustomTime = false;
    final customTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppTheme.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.border(context).withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('Create Custom Drill', style: AppTheme.headingMedium(context))),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(controller: nameController, label: 'Drill Name (Optional)', hint: 'Name your drill'),
                        const SizedBox(height: 16),
                        _buildTextField(controller: shotCountController, label: 'Number of Shots', hint: 'Enter shot count', keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildToggleSection(
                          label: 'Fire Type',
                          options: ['Dry Fire', 'Live Fire'],
                          selected: tempFireType,
                          onChanged: (val) => setDialogState(() => tempFireType = val),
                        ),
                        const SizedBox(height: 16),
                        _buildChipSection(
                          label: 'Sensitivity Level',
                          options: ['Beginner', 'Intermediate', 'Advanced'],
                          selected: tempSensitivity,
                          onChanged: (val) => setDialogState(() => tempSensitivity = val),
                        ),
                        const SizedBox(height: 16),
                        _buildChipSection(
                          label: 'Distance (Yards)',
                          options: ['7', '10', '15', '20', '25'],
                          selected: tempDistance,
                          onChanged: (val) => setDialogState(() => tempDistance = val),
                        ),
                        const SizedBox(height: 16),
                        _buildChipSection(
                          label: 'Time',
                          options: ['10s', '15s', '30s', 'Custom'],
                          selected: tempTime == 'Custom' ? 'Custom' : '${tempTime}s',
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == 'Custom') {
                                tempTime = 'Custom';
                                showCustomTime = true;
                              } else {
                                tempTime = val.replaceAll('s', '');
                                showCustomTime = false;
                              }
                            });
                          },
                        ),
                        if (showCustomTime) ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: customTimeController,
                            label: 'Custom Time (seconds)',
                            hint: 'Enter seconds',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildToggleSection(
                          label: 'Environment',
                          options: ['Indoor', 'Outdoor'],
                          selected: tempEnvironment,
                          onChanged: (val) => setDialogState(() => tempEnvironment = val),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: notesController,
                          label: 'Notes (Optional)',
                          hint: 'Add any additional notes...',
                          maxLines: 3,
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
                                child: Text('Cancel', style: AppTheme.button(context)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final shotCount = int.tryParse(shotCountController.text) ?? 10;
                                  String finalTime = tempTime;
                                  if (tempTime == 'Custom' && customTimeController.text.isNotEmpty) {
                                    finalTime = customTimeController.text;
                                  }
                                  String drillName = nameController.text.trim().isEmpty
                                      ? 'Custom Drill'
                                      : nameController.text.trim();
                                  setState(() {
                                    _drillCompleted = true;
                                    _drillName = drillName;
                                    _sensitivity = tempSensitivity;
                                    _distance = tempDistance;
                                    _time = finalTime;
                                    _environment = tempEnvironment;
                                    _drillInfo = '$drillName • $shotCount shots • ${tempDistance}yd • ${finalTime}s';
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
                                  'Save & Add',
                                  style: AppTheme.button(context).copyWith(color: Colors.white),
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
        },
      ),
    );
  }

  Widget _buildLoadoutItem(ArmoryLoadout loadout) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loadoutCompleted = true;
          _selectedLoadout = loadout;
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
            color: AppTheme.border(context).withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loadout.name,
              style: AppTheme.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (loadout.firearmId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed,
                          size: 14, color: AppTheme.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Firearm',
                        style: AppTheme.bodySmall(context)
                            .copyWith(color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                if (loadout.ammunitionId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 14, color: AppTheme.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Ammo',
                        style: AppTheme.bodySmall(context)
                            .copyWith(color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                if (loadout.gearIds.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build,
                          size: 14, color: AppTheme.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        '${loadout.gearIds.length} Gear',
                        style: AppTheme.bodySmall(context)
                            .copyWith(color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary(context).withOpacity(0.15)
              : AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary(context)
                : AppTheme.border(context).withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.bodyMedium(context).copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? AppTheme.primary(context)
                  : AppTheme.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrillItem({required String name, required String details}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _drillCompleted = true;
          _drillName = name;
          _drillInfo = '$name • $details';
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border(context).withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(name, style: AppTheme.titleMedium(context).copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(details, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
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