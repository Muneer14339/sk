// lib/training/presentation/pages/training_programs_page.dart
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
import '../widgets/common/training_button.dart';
import '../widgets/device_calibration_dialog.dart';
import 'sensitity_settings_page.dart';
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
  String _audioType = 'Off';
  String _alertsSettings = 'Default settings';
  DrillModel _selectedDrill = DrillModel.openPractice();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - topPadding - bottomPadding;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REQUIRED SETUP', style: AppTheme.labelSmall(context).copyWith(fontSize: 10)),
                    const SizedBox(height: 10),
                    _buildSetupCard(
                      icon: 'assets/icons/training/bluetooth.png',
                      title: 'Connection',
                      description: 'Connect to your device via Bluetooth',
                      value: _connectedDeviceName ?? 'Not connected',
                      isCompleted: _connectionCompleted,
                      isRequired: true,
                      onTap: _showConnectionDialog,
                    ),
                    const SizedBox(height: 10),
                    _buildSetupCard(
                      icon: 'assets/icons/training/firearm.png',
                      title: 'Loadout',
                      description: 'Select your firearm and ammunition',
                      value: _selectedLoadout?.name ?? 'No loadout selected',
                      isCompleted: _loadoutCompleted,
                      isRequired: true,
                      onTap: _showLoadoutDialog,
                    ),
                    const SizedBox(height: 16),
                    Text('OPTIONAL SETUP', style: AppTheme.labelSmall(context).copyWith(fontSize: 10)),
                    const SizedBox(height: 10),
                    _buildSetupCard(
                      icon: 'assets/icons/training/alert.png',
                      title: 'Alerts',
                      description: 'Configure audio feedback',
                      value: _alertsSettings,
                      isCompleted: _alertsCompleted,
                      isRequired: false,
                      onTap: _showAlertsDialog,
                    ),
                    const SizedBox(height: 10),
                    _buildSetupCard(
                      icon: 'assets/icons/training/target.png',
                      title: 'Drill',
                      description: 'Choose a training drill or practice freely',
                      value: _drillInfo,
                      isCompleted: _drillCompleted,
                      isRequired: false,
                      onTap: _showDrillDialog,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.background(context).withOpacity(0), AppTheme.background(context)],
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: TrainingButton(
                    label: 'Continue to Preview',
                    icon: Icons.arrow_forward,
                    onPressed: _canContinue ? _continueToPreview : null,
                  ),
                ),
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isCompleted
                ? AppTheme.success(context).withOpacity(0.5)
                : isRequired
                ? AppTheme.error(context).withOpacity(0.5)
                : AppTheme.border(context).withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  icon,
                  width: 28,
                  height: 28,
                  color: AppTheme.primary(context),// optional: agar color apply karna ho
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: AppTheme.titleMedium(context).copyWith(fontSize: 14, height: 1.2))),
                          if (isCompleted)
                            Icon(Icons.check_circle, color: AppTheme.success(context), size: 18)
                          else if (isRequired)
                            Icon(Icons.error_outline, color: AppTheme.textSecondary(context), size: 18),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: AppTheme.inputDecoration(context),
              child: Text(value, style: AppTheme.bodyMedium(context).copyWith(color: AppTheme.primary(context), fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

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
            if (state is LoadoutsLoaded) loadouts = state.loadouts;

            return Dialog(
              backgroundColor: AppTheme.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                side: BorderSide(color: AppTheme.border(context), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Select Loadout', style: AppTheme.headingMedium(context).copyWith(fontSize: 18))),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppTheme.textPrimary(context), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search loadouts...',
                        hintStyle: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary(context), size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border(context)),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: loadouts.isEmpty
                          ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No loadouts found.\nCreate loadouts in Armory first.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 12),
                          ),
                        ),
                      )
                          : ListView(
                        shrinkWrap: true,
                        children: loadouts.where((l) => l.name.toLowerCase().contains(searchController.text.toLowerCase())).map((l) => _buildLoadoutItem(l)).toList(),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary(context).withOpacity(0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppTheme.border(context).withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loadout.name, style: AppTheme.titleMedium(context).copyWith(color: isSelected ? AppTheme.primary(context) : AppTheme.textPrimary(context), fontSize: 13)),
                  if (loadout.notes != null) Text(loadout.notes!, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              size: isSelected ? 16 : 12,
              color: isSelected ? AppTheme.primary(context) : AppTheme.textSecondary(context),
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
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              side: BorderSide(color: AppTheme.border(context), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Alert Settings', style: AppTheme.headingMedium(context).copyWith(fontSize: 18))),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppTheme.textPrimary(context), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Haptic Feedback', style: AppTheme.titleMedium(context).copyWith(fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  _buildAlertButtons(['Off', 'Low', 'High'], tempHaptic, (val) => setDialogState(() => tempHaptic = val)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Audio Alerts', style: AppTheme.titleMedium(context).copyWith(fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                  _buildAlertButtons(['Off', 'Beep', 'Voice'], tempAudio, (val) => setDialogState(() => tempAudio = val)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TrainingButton(
                          label: 'Cancel',
                          type: ButtonType.outlined,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TrainingButton(
                          label: 'Save Settings',
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

  Widget _buildAlertButtons(List<String> options, String selected, Function(String) onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary(context).withOpacity(0.15) : AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary(context) : AppTheme.border(context).withOpacity(0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: AppTheme.bodyMedium(context).copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppTheme.primary(context) : AppTheme.textPrimary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDrillDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          side: BorderSide(color: AppTheme.border(context), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Select Drill', style: AppTheme.headingMedium(context).copyWith(fontSize: 18))),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textPrimary(context), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDrillPresetItem(
                drill: DrillModel.openPractice(),
                details: 'Default • No structure • Untimed',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TrainingButton(
                  label: 'Create Custom Drill',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.pop(context);
                    _showCustomDrillDialog();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomDrillDialog() {
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
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppTheme.surface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text("Create Custom Drill", style: AppTheme.headingMedium(context).copyWith(fontSize: 16))),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: AppTheme.textPrimary(context), size: 20),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: nameController,
                              style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: "Drill Name",
                                hintText: "Name your drill",
                                labelStyle: AppTheme.labelLarge(context).copyWith(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: shotCountController,
                              style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Rounds Planned",
                                hintText: "Enter shot count",
                                labelStyle: AppTheme.labelLarge(context).copyWith(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Fire Type", selectedFireType, fireTypes, (v) => setState(() => selectedFireType = v!)),
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Sensitivity Level", selectedSensitivity, sensitivityLevels, (v) => setState(() => selectedSensitivity = v!)),
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Distance Yard", selectedDistance, distances, (v) => setState(() => selectedDistance = v!)),
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Timer", selectedTimer, timers, (val) {
                              setState(() {
                                selectedTimer = val!;
                                showCustomTime = selectedTimer != "Free";
                              });
                            }),
                            if (showCustomTime) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: customTimeController,
                                style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Custom Time (seconds)",
                                  hintText: "Enter seconds",
                                  labelStyle: AppTheme.labelLarge(context).copyWith(fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Start Signal", selectedStartSignal, startSignals, (v) => setState(() => selectedStartSignal = v!)),
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Scoring", selectedScoring, scorings, (v) => setState(() => selectedScoring = v!)),
                            const SizedBox(height: 12),
                            _buildDropdown(context, "Environment", selectedEnvironment, environments, (v) => setState(() => selectedEnvironment = v!)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: notesController,
                              style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: "Notes",
                                hintText: "Add any additional notes...",
                                labelStyle: AppTheme.labelLarge(context).copyWith(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border(context))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TrainingButton(
                              label: "Cancel",
                              type: ButtonType.outlined,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TrainingButton(
                              label: "Save",
                              onPressed: () {
                                final int? customSeconds = showCustomTime ? int.tryParse(customTimeController.text) : null;
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
                                this.setState(() {
                                  _selectedDrill = custom;
                                  _drillCompleted = true;
                                  _drillInfo = _prettyDrillSummary(custom);
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(BuildContext context, String label, String value, List<String> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelLarge(context).copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: AppTheme.inputDecoration(context),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: AppTheme.bodyMedium(context).copyWith(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _prettyDrillSummary(DrillModel d) {
    final parts = <String>[
      d.name,
      '${d.fireType}',
      '${d.sensitivity}',
      '${d.distanceYards} yd',
      d.timer == 'Free' ? 'Untimed' : '${d.timer} ${d.customTimeSeconds != null ? '${d.customTimeSeconds}s' : ''}'.trim(),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.border(context).withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(drill.name, style: AppTheme.titleMedium(context).copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 3),
            Text(details, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 11)),
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

  void _continueToPreview() {
    final program = ProgramsModel(
      programName: _selectedDrill.name,
      loadout: _selectedLoadout,
      drill: _selectedDrill,
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
