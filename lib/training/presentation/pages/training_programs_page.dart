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
import '../../data/model/drill_model.dart';
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

  // ✅ Drill state (separate model)
  DrillModel _selectedDrill = DrillModel.openPractice(); // default
  String _drillInfo = 'Open Practice • Default • No structure • Untimed';

  BluetoothDevice? _connectedDevice;

  bool get _canContinue => _connectionCompleted && _loadoutCompleted;

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

  // ---------------- DIALOGS ----------------

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

  void _showAlertsDialog() async {
    final prefs = await SharedPreferences.getInstance();

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
                        child: Text('Alert Settings', style: AppTheme.headingMedium(context)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Haptic Feedback', style: AppTheme.titleMedium(context)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border(context)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildAlertButton('Off',  tempHaptic == 'Off',  () => setDialogState(() => tempHaptic = 'Off'))),
                        Expanded(child: _buildAlertButton('Low',  tempHaptic == 'Low',  () => setDialogState(() => tempHaptic = 'Low'))),
                        Expanded(child: _buildAlertButton('High', tempHaptic == 'High', () => setDialogState(() => tempHaptic = 'High'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Audio Alerts', style: AppTheme.titleMedium(context)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border(context)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildAlertButton('Off',   tempAudio == 'Off',   () => setDialogState(() => tempAudio = 'Off'))),
                        Expanded(child: _buildAlertButton('Beep',  tempAudio == 'Beep',  () => setDialogState(() => tempAudio = 'Beep'))),
                        Expanded(child: _buildAlertButton('Voice', tempAudio == 'Voice', () => setDialogState(() => tempAudio = 'Voice'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppTheme.border(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel', style: AppTheme.button(context).copyWith(color: AppTheme.textPrimary(context))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            int hapticValue = tempHaptic == 'Off' ? 0 : (tempHaptic == 'Low' ? 1 : 3);
                            await prefs.setInt(hapticCustomSettingsKey, hapticValue);
                            setState(() {
                              _audioType = tempAudio;
                              _alertsCompleted = true;
                              _alertsSettings = 'Haptic: $tempHaptic • Audio: $tempAudio';
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Save Settings', style: AppTheme.button(context).copyWith(color: Colors.white)),
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
                  Expanded(child: Text('Select Drill', style: AppTheme.headingMedium(context))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: AppTheme.textPrimary(context))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border(context)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildDrillPresetItem(
                  drill: DrillModel.openPractice(),
                  details: 'Default • No structure • Untimed',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCustomDrillDialog(context);
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text('Create Custom Drill'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CUSTOM DRILL DIALOG (uses DrillModel) ---
  void _showCustomDrillDialog(BuildContext context) {
    final nameController = TextEditingController();
    final shotCountController = TextEditingController(text: "10");
    final notesController = TextEditingController();
    final customTimeController = TextEditingController();

    final fireTypes = ["Dry Fire", "Live Fire"];
    final sensitivityLevels = ["Beginner", "Intermediate", "Advanced"];
    final distances = ["7", "10", "15", "20", "25"];
    final timers = ["Free", "Par", "Cadence"];
    final startSignals = ["Beep", "Voice Standby", "None"];
    final scorings = ["Time-only", "Score-only", "Time+Score"];
    final environments = ["Indoor", "Outdoor"];

    String selectedFireType = fireTypes[0];
    String selectedSensitivity = sensitivityLevels[2];
    String selectedDistance = distances[0];
    String selectedTimer = timers[0];
    String selectedStartSignal = startSignals[0];
    String selectedScoring = scorings[2];
    String selectedEnvironment = environments[0];
    bool showCustomTime = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: AppTheme.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text("Create Custom Drill", style: AppTheme.headingMedium(context))),
                        IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: AppTheme.textPrimary(context))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(controller: nameController, label: "Drill Name", hint: "Name your drill"),
                    const SizedBox(height: 16),

                    _buildTextField(controller: shotCountController, label: "Rounds Planned", hint: "Enter shot count", keyboardType: TextInputType.number),
                    const SizedBox(height: 16),

                    buildDropdownField(context: context, label: "Fire Type", value: selectedFireType, items: fireTypes, onChanged: (v) => setState(() => selectedFireType = v!)),
                    const SizedBox(height: 16),

                    buildDropdownField(context: context, label: "Sensitivity Level", value: selectedSensitivity, items: sensitivityLevels, onChanged: (v) => setState(() => selectedSensitivity = v!)),
                    const SizedBox(height: 16),

                    buildDropdownField(context: context, label: "Distance Yard", value: selectedDistance, items: distances, onChanged: (v) => setState(() => selectedDistance = v!)),
                    const SizedBox(height: 16),

                    buildDropdownField(
                      context: context,
                      label: "Timer",
                      value: selectedTimer,
                      items: timers,
                      onChanged: (val) {
                        setState(() {
                          selectedTimer = val!;
                          showCustomTime = selectedTimer != "Free";
                        });
                      },
                    ),
                    if (showCustomTime) const SizedBox(height: 12),
                    if (showCustomTime)
                      _buildTextField(
                        controller: customTimeController,
                        label: "Custom Time (seconds)",
                        hint: "Enter seconds",
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 16),

                    buildDropdownField(context: context, label: "Start Signal", value: selectedStartSignal, items: startSignals, onChanged: (v) => setState(() => selectedStartSignal = v!)),
                    const SizedBox(height: 16),

                    buildDropdownField(context: context, label: "Scoring", value: selectedScoring, items: scorings, onChanged: (v) => setState(() => selectedScoring = v!)),
                    const SizedBox(height: 16),

                    buildDropdownField(context: context, label: "Environment", value: selectedEnvironment, items: environments, onChanged: (v) => setState(() => selectedEnvironment = v!)),
                    const SizedBox(height: 16),

                    _buildTextField(controller: notesController, label: "Notes", hint: "Add any additional notes...", maxLines: 3),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppTheme.surfaceVariant(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("Cancel", style: AppTheme.button(context)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final int? customSeconds = showCustomTime
                                  ? int.tryParse(customTimeController.text)
                                  : null;

                              final DrillModel custom = DrillModel(
                                name: (nameController.text.isEmpty ? 'Custom Drill' : nameController.text).trim(),
                                fireType: selectedFireType,
                                sensitivity: selectedSensitivity,
                                distanceYards: selectedDistance,
                                timer: selectedTimer,
                                customTimeSeconds: customSeconds,
                                startSignal: selectedStartSignal,
                                scoring: selectedScoring,
                                plannedRounds: int.tryParse(shotCountController.text),
                                environment: selectedEnvironment,
                                notes: notesController.text.isEmpty ? null : notesController.text.trim(),
                              );

                              setState(() {
                                _selectedDrill = custom;
                                _drillCompleted = true;
                                _drillInfo = _prettyDrillSummary(custom);
                              });

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppTheme.primary(context),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text("Save", style: AppTheme.button(context).copyWith(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  String _prettyDrillSummary(DrillModel d) {
    final parts = <String>[
      d.name,
      '${d.fireType}',
      '${d.sensitivity}',
      '${d.distanceYards} yd',
      d.timer == 'Free'
          ? 'Untimed'
          : '${d.timer} ${d.customTimeSeconds != null ? '${d.customTimeSeconds}s' : ''}'.trim(),
      d.scoring,
      d.environment,
      if (d.plannedRounds != null) '${d.plannedRounds} rnds',
    ];
    return parts.where((e) => e.trim().isNotEmpty).join(' • ');
  }

  Widget _buildDrillPresetItem({required DrillModel drill, required String details}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDrill = drill;
          _drillCompleted = true;
          _drillInfo = '${drill.name} • $details';
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
            Text(drill.name, style: AppTheme.titleMedium(context).copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(details, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  // Reusable inputs
  Widget buildDropdownField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelLarge(context).copyWith(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: AppTheme.bodyMedium(context)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
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
            color: isSelected ? AppTheme.primary(context) : AppTheme.border(context).withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.bodyMedium(context).copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppTheme.primary(context) : AppTheme.textPrimary(context),
            ),
          ),
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
        Text(label, style: AppTheme.labelLarge(context).copyWith(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.bodyMedium(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textSecondary(context)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
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
          await context.read<TrainingSessionBloc>().bleRepository.factoryReset(device);
        },
      ),
    );
  }

  void _continueToPreview() {
    final program = ProgramsModel(
      programName: _selectedDrill.name,   // you can choose another naming scheme
      loadout: _selectedLoadout,
      drill: _selectedDrill,              // ✅ nested drill
      // keep other program-level fields if you later add them
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
