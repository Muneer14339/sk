import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';
import '../common/common_delete_dilogue.dart';
import '../common/dialog_widgets.dart';

class AddLoadoutForm extends StatefulWidget {
  final String userId;
  const AddLoadoutForm({super.key, required this.userId});

  @override
  State createState() => _AddLoadoutFormState();
}

class _AddLoadoutFormState extends State<AddLoadoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String? _selectedFirearmId;
  String? _selectedAmmunitionId;
  List<String> _selectedGearIds = [];
  List<String> _selectedToolIds = [];
  List<String> _selectedMaintenanceIds = [];

  @override
  void initState() {
    super.initState();
    _controllers['name'] = TextEditingController();
    _controllers['notes'] = TextEditingController();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is ArmoryActionSuccess) {
          context.read<ArmoryBloc>().add(const HideFormEvent());
        }
      },
      builder: (context, state) {
        // FIX: Show form also for ShowingAddForm with tabType loadouts!
        if (!(state is ArmoryDataLoaded || (state is ShowingAddForm && state.tabType == ArmoryTabType.loadouts))) {
          return const Center(child: CircularProgressIndicator());
        }

        // Extract data from current state
        final firearms = (state is ArmoryDataLoaded) ? state.firearms : (state as ShowingAddForm).firearms;
        final ammunition = (state is ArmoryDataLoaded) ? state.ammunition : (state as ShowingAddForm).ammunition;
        final gear = (state is ArmoryDataLoaded) ? state.gear : (state as ShowingAddForm).gear;
        final tools = (state is ArmoryDataLoaded) ? state.tools : (state as ShowingAddForm).tools;
        final loadouts = (state is ArmoryDataLoaded) ? state.loadouts : (state as ShowingAddForm).loadouts;
        final maintenance = (state is ArmoryDataLoaded) ? state.maintenance : (state as ShowingAddForm).maintenance;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: _buildForm(firearms, ammunition, gear, tools, loadouts, maintenance)),
            _buildActions(state, firearms, ammunition, gear, tools, loadouts, maintenance),
          ],
        );
      },
    );
  }

  Widget _buildActions(
      ArmoryState state,
      List firearms,
      List ammunition,
      List gear,
      List tools,
      List loadouts,
      List maintenance,
      ) {
    return Container(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: state is ArmoryLoadingAction ? null : () => _saveLoadout(firearms, ammunition, gear, tools, loadouts, maintenance),
            child: state is ArmoryLoadingAction
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary(context)))
                : const Text('Save Loadout'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
      List firearms,
      List ammunition,
      List gear,
      List tools,
      List loadouts,
      List maintenance,
      ) {
    final firearmOptions = firearms.map((f) => DropdownOption(value: f.id!, label: '${f.nickname} (${f.make} ${f.model})')).toList();
    final ammunitionOptions = _selectedFirearmId != null
        ? ammunition.where((a) {
      final firearm = firearms.firstWhere((f) => f.id == _selectedFirearmId);
      return a.caliber.toLowerCase() == firearm.caliber.toLowerCase();
    }).map((a) => DropdownOption(value: a.id!, label: '${a.brand} ${a.caliber} ${a.bullet} (${a.quantity} rds)')).toList()
        : [];
    final gearOptions = gear.map((g) => DropdownOption(value: g.id!, label: g.model)).toList();
    final toolOptions = tools.map((t) => DropdownOption(value: t.id!, label: t.name)).toList();
    final maintenanceOptions = maintenance.map((m) => DropdownOption(value: m.id!, label: m.maintenanceType)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DialogWidgets.buildTextField(
              context: context,
              label: 'Loadout Name *',
              controller: _controllers['name']!,
              isRequired: true,
              maxLength: 25,
              hintText: 'e.g., Precision .308',
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),
            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Firearm *',
              value: _selectedFirearmId,
              options: firearmOptions,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedFirearmId = value;
                    _selectedAmmunitionId = null;
                  });
                }
              },
              isRequired: true,
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),
            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Ammunition *',
              value: _selectedAmmunitionId,
              options: ammunitionOptions.cast(),
              onChanged: (value) {
                if (mounted) setState(() => _selectedAmmunitionId = value);
              },
              enabled: ammunitionOptions.isNotEmpty,
              isRequired: true,
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),
            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Gear',
              value: null,
              options: gearOptions,
              onChanged: (value) {
                if (value != null && !_selectedGearIds.contains(value) && mounted) setState(() => _selectedGearIds.add(value));
              },
            ),
            if (_selectedGearIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildChips(_selectedGearIds, gearOptions, (id) {
                if (mounted) setState(() => _selectedGearIds.remove(id));
              }),
            ],
            const SizedBox(height: ArmoryConstants.fieldSpacing),
            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Tools',
              value: null,
              options: toolOptions,
              onChanged: (value) {
                if (value != null && !_selectedToolIds.contains(value) && mounted) setState(() => _selectedToolIds.add(value));
              },
            ),
            if (_selectedToolIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildChips(_selectedToolIds, toolOptions, (id) {
                if (mounted) setState(() => _selectedToolIds.remove(id));
              }),
            ],
            const SizedBox(height: ArmoryConstants.fieldSpacing),
            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Maintenance',
              value: null,
              options: maintenanceOptions,
              onChanged: (value) {
                if (value != null && !_selectedMaintenanceIds.contains(value) && mounted) setState(() => _selectedMaintenanceIds.add(value));
              },
            ),
            if (_selectedMaintenanceIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildChips(_selectedMaintenanceIds, maintenanceOptions, (id) {
                if (mounted) setState(() => _selectedMaintenanceIds.remove(id));
              }),
            ],
            const SizedBox(height: ArmoryConstants.fieldSpacing),
            DialogWidgets.buildTextField(
              context: context,
              label: 'Notes',
              controller: _controllers['notes']!,
              maxLines: 3,
              maxLength: 200,
              hintText: 'Purpose, conditions, special setup notes, etc.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips(List<String> ids, List<DropdownOption> options, Function(String) onDelete) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ids.map((id) {
          final label = options.firstWhere((o) => o.value == id).label;
          return Chip(
            label: Text(label, style: AppTheme.labelMedium(context).copyWith(fontSize: 13)),
            backgroundColor: AppTheme.surfaceVariant(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.cardBorderRadius),
              side: BorderSide(color: AppTheme.border(context)),
            ),
            deleteIcon: Icon(Icons.close, size: 18, color: AppTheme.textSecondary(context)),
            onDeleted: () => onDelete(id),
          );
        }).toList(),
      ),
    );
  }

  void _saveLoadout(
      List firearms,
      List ammunition,
      List gear,
      List tools,
      List loadouts,
      List maintenance,
      ) {
    if (!_formKey.currentState!.validate()) return;
    final name = _controllers['name']?.text.trim() ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Loadout name is required'), backgroundColor: AppTheme.error(context)));
      return;
    }
    final loadout = ArmoryLoadout(
      name: name,
      firearmId: _selectedFirearmId,
      ammunitionId: _selectedAmmunitionId,
      gearIds: _selectedGearIds,
      toolIds: _selectedToolIds,
      maintenanceIds: _selectedMaintenanceIds,
      notes: _controllers['notes']?.text.trim(),
      dateAdded: DateTime.now(),
    );
    context.read<ArmoryBloc>().add(AddLoadoutEvent(userId: widget.userId, loadout: loadout));
  }
}
