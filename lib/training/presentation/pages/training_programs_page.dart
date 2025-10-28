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
      // CHANGE: LoadLoadoutsEvent ki jagah LoadAllDataEvent
      context.read<ArmoryBloc>().add(LoadAllDataEvent(userId: userId));
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
                  color: AppTheme.primary(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title, style: AppTheme.titleMedium(context).copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          if (isCompleted)
                            Icon(Icons.check_circle, size: 18, color: AppTheme.success(context))
                          else if (isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.error(context).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('REQUIRED', style: AppTheme.labelSmall(context).copyWith(color: AppTheme.error(context), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(description, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(value, style: AppTheme.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, fontSize: 12))),
                            Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textSecondary(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Select Loadout', style: AppTheme.titleLarge(context).copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.border(context)),
                Expanded(
                  child: BlocBuilder<ArmoryBloc, ArmoryState>(
                    builder: (context, state) {
                      // CHANGE: LoadoutsLoaded ki jagah ArmoryDataLoaded
                      if (state is ArmoryDataLoaded) {
                        if (state.loadouts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textSecondary(context)),
                                const SizedBox(height: 12),
                                Text('No loadouts available', style: AppTheme.bodyLarge(context)),
                                const SizedBox(height: 8),
                                Text('Create a loadout in Armory', style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context))),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.loadouts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final loadout = state.loadouts[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLoadout = loadout;
                                  _loadoutCompleted = true;
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant(context),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  border: Border.all(
                                    color: _selectedLoadout?.id == loadout.id
                                        ? AppTheme.primary(context)
                                        : AppTheme.border(context).withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary(context).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.inventory_2, color: AppTheme.primary(context), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(loadout.name, style: AppTheme.titleMedium(context).copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    if (_selectedLoadout?.id == loadout.id)
                                      Icon(Icons.check_circle, color: AppTheme.primary(context), size: 20),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempAudioType = _audioType;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text('Audio Alerts', style: AppTheme.titleLarge(context).copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.border(context)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRadioOption(
                            'Off',
                            tempAudioType,
                                (val) => setDialogState(() => tempAudioType = val!),
                            'No audio feedback',
                          ),
                          const SizedBox(height: 10),
                          _buildRadioOption(
                            'Beep',
                            tempAudioType,
                                (val) => setDialogState(() => tempAudioType = val!),
                            'Simple beep sound',
                          ),
                          const SizedBox(height: 10),
                          _buildRadioOption(
                            'Voice',
                            tempAudioType,
                                (val) => setDialogState(() => tempAudioType = val!),
                            'Spoken instructions',
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.border(context)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
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
                              label: 'Save',
                              onPressed: () {
                                setState(() {
                                  _audioType = tempAudioType;
                                  _alertsCompleted = true;
                                  _alertsSettings = tempAudioType == 'Off' ? 'Alerts off' : '$tempAudioType alerts';
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

  Widget _buildRadioOption(String value, String groupValue, ValueChanged<String?> onChanged, String description) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary(context).withOpacity(0.1) : AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primary(context) : AppTheme.border(context).withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppTheme.primary(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: AppTheme.titleMedium(context).copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(description, style: AppTheme.bodySmall(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 11)),
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
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Select Drill', style: AppTheme.titleLarge(context).copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.border(context)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDrillPresetItem(
                        drill: DrillModel.openPractice(),
                        details: 'Default • No structure • Untimed',
                      ),
                      // const SizedBox(height: 10),
                      // _buildDrillPresetItem(
                      //   drill: DrillModel.billDrill(),
                      //   details: 'Rapid Fire • 7 yards • 6 rounds • Par time: 2.0s',
                      // ),
                      // const SizedBox(height: 10),
                      // _buildDrillPresetItem(
                      //   drill: DrillModel.elPresidente(),
                      //   details: 'Multiple Targets • 10 yards • 12 rounds',
                      // ),
                      // const SizedBox(height: 10),
                      // _buildDrillPresetItem(
                      //   drill: DrillModel.failureToDrill(),
                      //   details: 'Mozambique • 7 yards • 2 body + 1 head',
                      // ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showCustomDrillDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(color: AppTheme.primary(context), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: AppTheme.primary(context), size: 20),
                              const SizedBox(width: 12),
                              Text('Create Custom Drill', style: AppTheme.titleMedium(context).copyWith(color: AppTheme.primary(context), fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
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
  }

  void _showCustomDrillDialog() {
    final nameController = TextEditingController();
    final shotCountController = TextEditingController();
    final customTimeController = TextEditingController();
    final notesController = TextEditingController();

    String selectedFireType = 'Single Shot';
    String selectedSensitivity = 'Medium';
    String selectedDistance = '7';
    String selectedTimer = 'Free';
    String selectedStartSignal = 'Manual';
    String selectedScoring = 'None';
    String selectedEnvironment = 'Indoor';
    bool showCustomTime = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text('Custom Drill', style: AppTheme.titleLarge(context).copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.border(context)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField('Drill Name (Optional)', nameController, 'e.g., My Custom Drill'),
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Fire Type', selectedFireType, ['Single Shot', 'Double Tap', 'Controlled Pair', 'Rapid Fire'], (val) {
                              setDialogState(() => selectedFireType = val!);
                            }),
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Sensitivity', selectedSensitivity, ['Low', 'Medium', 'High'], (val) {
                              setDialogState(() => selectedSensitivity = val!);
                            }),
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Distance (Yards)', selectedDistance, ['3', '5', '7', '10', '15', '25'], (val) {
                              setDialogState(() => selectedDistance = val!);
                            }),
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Timer', selectedTimer, ['Free', 'Par Time', 'Split Time'], (val) {
                              setDialogState(() {
                                selectedTimer = val!;
                                showCustomTime = (val == 'Par Time' || val == 'Split Time');
                              });
                            }),
                            if (showCustomTime) ...[
                              const SizedBox(height: 12),
                              _buildTextField('Time (Seconds)', customTimeController, 'e.g., 2.5', keyboardType: TextInputType.number),
                            ],
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Start Signal', selectedStartSignal, ['Manual', 'Beep', 'Random Delay'], (val) {
                              setDialogState(() => selectedStartSignal = val!);
                            }),
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Scoring', selectedScoring, ['None', 'Points', 'Time', 'Points + Time'], (val) {
                              setDialogState(() => selectedScoring = val!);
                            }),
                            const SizedBox(height: 12),
                            _buildTextField('Planned Rounds (Optional)', shotCountController, 'e.g., 50', keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            _buildDropdown(context, 'Environment', selectedEnvironment, ['Indoor', 'Outdoor'], (val) {
                              setDialogState(() => selectedEnvironment = val!);
                            }),
                            const SizedBox(height: 12),
                            _buildTextField('Notes (Optional)', notesController, 'Add any additional details...', maxLines: 2),
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

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelLarge(context).copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTheme.bodyMedium(context).copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textSecondary(context), fontSize: 13),
            filled: true,
            fillColor: AppTheme.surfaceVariant(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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