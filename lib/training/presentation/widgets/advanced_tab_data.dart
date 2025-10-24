import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../armory/presentation/bloc/armory_bloc.dart';
import '../../../armory/presentation/bloc/armory_state.dart';
import '../../../armory/domain/entities/armory_loadout.dart';
import '../../data/model/programs_model.dart';
import '../../data/model/drill_model.dart';

extension StringCasingExtension on String {
  String toCapitalized() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

class AdvancedTabContent extends StatefulWidget {
  const AdvancedTabContent({
    super.key,
    required this.onProgramNameChanged,
    required this.programsModel,
  });
  final void Function(ProgramsModel?) onProgramNameChanged;
  final ProgramsModel programsModel;

  @override
  State<AdvancedTabContent> createState() => _AdvancedTabContentState();
}

class _AdvancedTabContentState extends State<AdvancedTabContent> {
  // Program-level
  final TextEditingController programNameController = TextEditingController();
  final TextEditingController programDescriptionController = TextEditingController();
  final TextEditingController successCriteriaController = TextEditingController();

  // Drill-level UI controllers
  final TextEditingController shotCountController = TextEditingController();
  final TextEditingController timeLimitSecondsController = TextEditingController();

  // Local state
  ArmoryLoadout? selectedWeaponProfile;
  String selectedDistance = '15-25'; // will be stored into drill.distanceYards as string
  String selectedTrainingType = 'Dry Fire';
  String selectedDifficulty = 'Intermediate';
  double successThreshold = 75.0;

  List<Map<String, dynamic>> metrics = [];
  List<PerformanceMetrics> performanceMetrics = [];

  ProgramsModel programsModel = ProgramsModel();
  DrillModel _drill = DrillModel.openPractice();

  @override
  void initState() {
    super.initState();

    // Base program
    programsModel = widget.programsModel;

    // Seed UI from existing program
    programNameController.text = programsModel.programName ?? '';
    programDescriptionController.text = programsModel.programDescription ?? '';
    successCriteriaController.text = programsModel.successCriteria ?? '';
    successThreshold = double.tryParse(programsModel.successThreshold ?? '75.0') ?? 75.0;

    // Load existing drill or defaults
    _drill = programsModel.drill ?? DrillModel.openPractice();

    // Map drill to UI
    selectedTrainingType = _drill.fireType;         // "Dry Fire" | "Live Fire"
    selectedDifficulty   = _drill.sensitivity;      // "Beginner" | "Intermediate" | "Advanced"
    selectedDistance     = _drill.distanceYards;    // we'll accept ranges as plain string too
    shotCountController.text = (_drill.plannedRounds ?? 0) == 0
        ? ''
        : _drill.plannedRounds.toString();
    // Convert timer => text field (simple mapping)
    if (_drill.timer == 'Par' && _drill.customTimeSeconds != null) {
      timeLimitSecondsController.text = _drill.customTimeSeconds!.toString();
    } else {
      timeLimitSecondsController.text = '';
    }

    // Loadout (program-level)
    selectedWeaponProfile = programsModel.loadout;

    // Metrics
    metrics = programsModel.performanceMetrics?.map((metric) {
      return {'type': metric.stability, 'target': metric.target, 'unit': metric.unit};
    }).toList() ??
        [];
    performanceMetrics = programsModel.performanceMetrics ?? [];

    // Ensure initial propagate up
    _emit();
  }

  @override
  void dispose() {
    programNameController.dispose();
    programDescriptionController.dispose();
    successCriteriaController.dispose();
    shotCountController.dispose();
    timeLimitSecondsController.dispose();
    super.dispose();
  }

  void _emit() {
    // keep programsModel updated with nested drill + loadout + program fields
    programsModel = programsModel.copyWith(
      programName: programNameController.text,
      programDescription: programDescriptionController.text,
      successCriteria: successCriteriaController.text,
      successThreshold: successThreshold.toString(),
      performanceMetrics: performanceMetrics,
      // loadout stays as-is from selectedWeaponProfile (repo can resolve ID if needed)
      badge: programsModel.badge,
      badgeColor: programsModel.badgeColor,
      drill: _drill, // ✅ nested
    );
    widget.onProgramNameChanged(programsModel);
  }

  // ---------- UI helpers (unchanged structure) ----------

  Widget _buildFormSection({required String title, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              title.contains('Program Details')
                  ? '📝'
                  : title.contains('Session Parameters')
                  ? '⚙️'
                  : title.contains('Performance Metrics')
                  ? '📊'
                  : title.contains('Success Criteria')
                  ? '🎯'
                  : '',
              style: const TextStyle(fontSize: 20, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
          ]),
          const SizedBox(height: 15),
          content,
        ],
      ),
    );
  }

  Widget _buildFormGroup({
    required String label,
    required Widget inputWidget,
    bool required = false,
    String? helpText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF495057))),
          if (required) const Text(' *', style: TextStyle(color: Color(0xFFDC3545))),
        ]),
        const SizedBox(height: 8),
        inputWidget,
        if (helpText != null) ...[
          const SizedBox(height: 5),
          Text(helpText, style: const TextStyle(fontSize: 12.0, color: Color(0xFF6C757D), height: 1.3)),
        ],
      ]),
    );
  }

  Widget _buildAdvancedTrainingTypeOption({
    required String icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF28A745) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF28A745) : const Color(0xFFE9ECEF),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 24.0, color: isSelected ? Colors.white : null)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: isSelected ? Colors.white : Colors.black)),
              const SizedBox(height: 2),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.0, color: isSelected ? Colors.white70 : const Color(0xCC6C757D))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE9ECEF), width: 2)),
      child: Row(children: [
        _buildDifficultyOption('Beginner', 'Beginner'),
        _buildDifficultyOption('Intermediate', 'Intermediate'),
        _buildDifficultyOption('Advanced', 'Advanced'),
      ]),
    );
  }

  Widget _buildDifficultyOption(String label, String value) {
    final bool isSelected = selectedDifficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedDifficulty = value;
            _drill = _drill.copyWith(sensitivity: value);
          });
          _emit();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
            borderRadius: BorderRadius.horizontal(
              left: value == 'Beginner' ? const Radius.circular(6) : Radius.zero,
              right: value == 'Advanced' ? const Radius.circular(6) : Radius.zero,
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF495057))),
          ),
        ),
      ),
    );
  }

  void _addMetric() {
    setState(() {
      metrics.add({'type': 'New Metric', 'target': '', 'unit': ''});
    });
    performanceMetrics.add(PerformanceMetrics(stability: 'New Metric', target: '0', unit: '_'));
    _emit();
  }

  void _removeMetric(int index) {
    setState(() {
      metrics.removeAt(index);
      performanceMetrics.removeAt(index);
    });
    _emit();
  }

  void _updateMetric(int index, String key, dynamic value) {
    setState(() => metrics[index][key] = value);
    performanceMetrics[index] = performanceMetrics[index].copyWith(
      stability: metrics[index]['type'],
      target: metrics[index]['target'],
      unit: metrics[index]['unit'],
    );
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // -------- Program Details (program-level) --------
        _buildFormSection(
          title: 'Program Details',
          content: Column(children: [
            _buildFormGroup(
              label: 'Program Name',
              required: true,
              inputWidget: TextField(
                controller: programNameController,
                onChanged: (_) => _emit(),
                decoration: _inputDecoration(hint: 'e.g., My Precision Training'),
                maxLength: 50,
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
            _buildFormGroup(
              label: 'Training Type', // drill-level, but UX-wise shown here
              required: true,
              inputWidget: Row(children: [
                _buildAdvancedTrainingTypeOption(
                  icon: '🏠',
                  title: 'Dry Fire',
                  description: 'No ammunition\ntraining',
                  isSelected: selectedTrainingType == 'Dry Fire',
                  onTap: () {
                    setState(() {
                      selectedTrainingType = 'Dry Fire';
                      _drill = _drill.copyWith(fireType: 'Dry Fire');
                    });
                    _emit();
                  },
                ),
                const Spacer(),
                _buildAdvancedTrainingTypeOption(
                  icon: '🔥',
                  title: 'Live Fire',
                  description: 'Range with\nammunition',
                  isSelected: selectedTrainingType == 'Live Fire',
                  onTap: () {
                    setState(() {
                      selectedTrainingType = 'Live Fire';
                      _drill = _drill.copyWith(fireType: 'Live Fire');
                    });
                    _emit();
                  },
                ),
              ]),
            ),
            _buildFormGroup(
              label: 'Description',
              inputWidget: TextField(
                controller: programDescriptionController,
                onChanged: (_) => _emit(),
                maxLines: 4,
                decoration: _inputDecoration(hint: 'Describe what this program focuses on...'),
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
            _buildFormGroup(label: 'Difficulty Level', inputWidget: _buildDifficultySelector()),
          ]),
        ),

        // -------- Session Parameters (mostly drill-level) --------
        _buildFormSection(
          title: 'Session Parameters',
          content: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(children: [
                Expanded(
                  child: _buildFormGroup(
                    label: 'Shots',
                    required: true,
                    inputWidget: TextField(
                      controller: shotCountController,
                      onChanged: (value) {
                        setState(() {
                          final v = int.tryParse(value);
                          _drill = _drill.copyWith(plannedRounds: v);
                        });
                        _emit();
                      },
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(hint: '10'),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormGroup(
                    label: 'Time Limit (s)',
                    inputWidget: TextField(
                      controller: timeLimitSecondsController,
                      onChanged: (v) {
                        setState(() {
                          final secs = int.tryParse(v);
                          if (secs != null && secs > 0) {
                            _drill = _drill.copyWith(timer: 'Par', customTimeSeconds: secs);
                          } else {
                            _drill = _drill.copyWith(timer: 'Free', customTimeSeconds: null);
                          }
                        });
                        _emit();
                      },
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(hint: 'None'),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                ),
              ]),
            ),

            // Loadout (program-level)
            BlocBuilder<ArmoryBloc, ArmoryState>(
              builder: (context, state) {
                if (state is ArmoryLoading) {
                  return const Center(child: LinearProgressIndicator());
                }
                final loadouts = state is LoadoutsLoaded ? state.loadouts : <ArmoryLoadout>[];
                return _buildFormGroup(
                  label: 'Loadout',
                  inputWidget: DropdownButtonFormField<ArmoryLoadout>(
                    value: selectedWeaponProfile,
                    decoration: _inputDecoration(),
                    items: loadouts.map((l) => DropdownMenuItem(value: l, child: Text(l.name))).toList(),
                    onChanged: (value) {
                      setState(() => selectedWeaponProfile = value);
                      programsModel = programsModel.copyWith(loadout: value);
                      _emit();
                    },
                    style: const TextStyle(fontSize: 14.0, color: Colors.black),
                  ),
                );
              },
            ),

            // Distance (store directly into drill.distanceYards; we accept ranges as string)
            _buildFormGroup(
              label: 'Recommended Distance',
              inputWidget: DropdownButtonFormField<String>(
                value: selectedDistance,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(value: '3-7', child: Text('3-7 yards (Close)')),
                  DropdownMenuItem(value: '7-15', child: Text('7-15 yards (Standard)')),
                  DropdownMenuItem(value: '15-25', child: Text('15-25 yards (Intermediate)')),
                  DropdownMenuItem(value: '25-50', child: Text('25-50 yards (Long)')),
                  DropdownMenuItem(value: 'variable', child: Text('Variable Distance')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDistance = value!;
                    _drill = _drill.copyWith(distanceYards: value);
                  });
                  _emit();
                },
                style: const TextStyle(fontSize: 14.0, color: Colors.black),
              ),
            ),
          ]),
        ),

        // -------- Performance Metrics (program-level) --------
        _buildFormSection(
          title: 'Performance Metrics',
          content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 15.0),
              child: Text(
                'Define what metrics will be measured and their success thresholds.',
                style: TextStyle(fontSize: 12.0, color: Color(0xFF6C757D), height: 1.3),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDEE2E6), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                const SizedBox(height: 8),
                if (metrics.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'No metrics added yet. Click "Add Metric" to begin.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...metrics.asMap().entries.map((entry) {
                  final index = entry.key;
                  final metric = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      DropdownButtonFormField<String>(
                        value: metric['type'],
                        decoration: _inputDecoration(label: 'Metric'),
                        items: const [
                          DropdownMenuItem(value: 'Stability', child: Text('Stability')),
                          DropdownMenuItem(value: 'Trigger Control', child: Text('Trigger Control')),
                          DropdownMenuItem(value: 'Split Time', child: Text('Split Time')),
                          DropdownMenuItem(value: 'Consistency', child: Text('Consistency')),
                          DropdownMenuItem(value: 'Recoil Management', child: Text('Recoil Management')),
                          DropdownMenuItem(value: 'Target Acquisition', child: Text('Target Acquisition')),
                          DropdownMenuItem(value: 'New Metric', child: Text('New Metric')),
                        ],
                        onChanged: (v) => _updateMetric(index, 'type', v!),
                        style: const TextStyle(fontSize: 14.0, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: metric['target']),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(label: 'Target'),
                            onChanged: (v) => _updateMetric(index, 'target', v),
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: (metric['unit'] as String?)?.isEmpty == true ? null : metric['unit'],
                            decoration: _inputDecoration(label: 'Unit'),
                            items: const [
                              DropdownMenuItem(value: '%', child: Text('%')),
                              DropdownMenuItem(value: 's', child: Text('s')),
                              DropdownMenuItem(value: 'pts', child: Text('pts')),
                              DropdownMenuItem(value: 'm', child: Text('m')),
                            ],
                            onChanged: (v) => _updateMetric(index, 'unit', v!),
                            style: const TextStyle(fontSize: 14.0, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Color(0xFFDC3545)),
                          onPressed: () => _removeMetric(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(maxWidth: 12, maxHeight: 12),
                        ),
                      ]),
                      const Divider(color: Colors.blueGrey, thickness: 1),
                    ]),
                  );
                }),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _addMetric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17A2B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Metric', style: TextStyle(fontSize: 13.0)),
                  ),
                ),
              ]),
            ),
          ]),
        ),

        // -------- Success Criteria (program-level) --------
        _buildFormSection(
          title: 'Success Criteria',
          content: Column(children: [
            _buildFormGroup(
              label: 'Success Definition',
              inputWidget: TextField(
                controller: successCriteriaController,
                maxLines: 3,
                onChanged: (_) => _emit(),
                decoration: _inputDecoration(hint: 'e.g., 8/10 shots must meet 80% stability.'),
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
            _buildFormGroup(
              label: 'Success Threshold (%)',
              inputWidget: Column(children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                    activeTrackColor: const Color(0xFF2C3E50),
                    inactiveTrackColor: const Color(0xFFE9ECEF),
                    thumbColor: const Color(0xFF2C3E50),
                    overlayColor: const Color(0x1A2C3E50),
                  ),
                  child: Slider(
                    value: successThreshold,
                    min: 50,
                    max: 100,
                    divisions: 50,
                    onChanged: (value) {
                      setState(() => successThreshold = value);
                      _emit();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('50%', style: TextStyle(fontSize: 12.0, color: Color(0xFF6C757D))),
                    Text('${successThreshold.round()}%', style: const TextStyle(fontSize: 12.0, color: Color(0xFF6C757D))),
                    const Text('100%', style: TextStyle(fontSize: 12.0, color: Color(0xFF6C757D))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? label}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 2)),
      enabledBorder:
      OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE9ECEF), width: 2)),
      focusedBorder:
      OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2)),
    );
  }
}
