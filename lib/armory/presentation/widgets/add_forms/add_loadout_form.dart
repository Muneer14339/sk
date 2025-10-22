// lib/armory/presentation/widgets/add_forms/add_loadout_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';
import '../common/dialog_widgets.dart';

class AddLoadoutForm extends StatefulWidget {
  final String userId;

  const AddLoadoutForm({super.key, required this.userId});

  @override
  State<AddLoadoutForm> createState() => _AddLoadoutFormState();
}

class _AddLoadoutFormState extends State<AddLoadoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String? _selectedFirearmId;
  String? _selectedAmmunitionId;

  List<DropdownOption> _firearmOptions = [];
  List<DropdownOption> _ammunitionOptions = [];
  bool _loadingFirearms = true;
  bool _loadingAmmunition = true;

  List<DropdownOption> _gearOptions = [];
  List<String> _selectedGearIds = [];
  bool _loadingGear = true;

  List<ArmoryFirearm> _firearms = [];
  List<ArmoryAmmunition> _allAmmunition = [];
  bool _hasMatchingAmmunition = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    final fields = ['name', 'notes'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  void _loadData() {
    context.read<ArmoryBloc>().add(LoadFirearmsEvent(userId: widget.userId));
    context.read<ArmoryBloc>().add(LoadAmmunitionEvent(userId: widget.userId));
    context.read<ArmoryBloc>().add(LoadGearEvent(userId: widget.userId));
  }

  void _handleFirearmsLoaded(List<ArmoryFirearm> firearms) {
    setState(() {
      _firearms = firearms;
      _firearmOptions = firearms
          .map((firearm) => DropdownOption(
        value: firearm.id!,
        label: '${firearm.nickname} (${firearm.make} ${firearm.model})',
      ))
          .toList();
      _loadingFirearms = false;
    });
  }

  void _handleAmmunitionLoaded(List<ArmoryAmmunition> ammunition) {
    setState(() {
      _allAmmunition = ammunition;
      _loadingAmmunition = false;
    });
  }

  void _filterAmmunitionForSelectedFirearm() {
    if (_selectedFirearmId == null || _allAmmunition.isEmpty || _firearms.isEmpty) {
      _ammunitionOptions = [];
      _hasMatchingAmmunition = false;
      _showNoAmmoSnackBar();
      return;
    }

    final selectedFirearm = _firearms.firstWhere(
          (firearm) => firearm.id == _selectedFirearmId,
      orElse: () => throw StateError('Selected firearm not found'),
    );

    final matchingAmmunition = _allAmmunition
        .where((ammo) => ammo.caliber.toLowerCase() == selectedFirearm.caliber.toLowerCase())
        .toList();

    if (matchingAmmunition.isEmpty) {
      _ammunitionOptions = [];
      _hasMatchingAmmunition = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNoAmmoSnackBar();
      });
    } else {
      _ammunitionOptions = matchingAmmunition
          .map((ammo) => DropdownOption(
        value: ammo.id!,
        label: '${ammo.brand} ${ammo.caliber} ${ammo.bullet} (${ammo.quantity} rds)',
      ))
          .toList();
      _hasMatchingAmmunition = true;
    }
  }

  void _showNoAmmoSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please add ammunition for this firearm first'),
        backgroundColor: AppTheme.error(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onFirearmChanged(String? value) {
    setState(() {
      _selectedFirearmId = value;
      _selectedAmmunitionId = null;
      _filterAmmunitionForSelectedFirearm();
    });
  }

  void _handleGearLoaded(List<ArmoryGear> gear) {
    setState(() {
      _gearOptions = gear.map((g) => DropdownOption(value: g.id!, label: g.model)).toList();
      _loadingGear = false;
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is FirearmsLoaded) {
          _handleFirearmsLoaded(state.firearms);
        } else if (state is AmmunitionLoaded) {
          _handleAmmunitionLoaded(state.ammunition);
        } else if (state is GearLoaded) {
          _handleGearLoaded(state.gear);
        } else if (state is ArmoryActionSuccess) {
          context.read<ArmoryBloc>().add(const HideFormEvent());
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _buildForm()),
          BlocBuilder<ArmoryBloc, ArmoryState>(
            builder: (context, state) {
              return _buildActions(state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ArmoryState state) {
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
            onPressed: state is ArmoryLoadingAction ? null : _saveLoadout,
            child: state is ArmoryLoadingAction
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Save Loadout'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
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
              hintText: 'e.g., Precision .308, Competition Setup',
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),

            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Firearm *',
              value: _selectedFirearmId,
              options: _firearmOptions,
              onChanged: _onFirearmChanged,
              isLoading: _loadingFirearms,
              enabled: !_loadingFirearms,
              isRequired: true,
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),

            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Ammunition *',
              value: _selectedAmmunitionId,
              options: _ammunitionOptions,
              onChanged: (value) {
                if (_hasMatchingAmmunition) {
                  setState(() => _selectedAmmunitionId = value);
                } else {
                  _showNoAmmoSnackBar();
                }
              },
              isLoading: _loadingAmmunition,
              enabled: _hasMatchingAmmunition && !_loadingAmmunition,
              isRequired: true,
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),

            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Gear',
              value: null,
              options: _gearOptions,
              isLoading: _loadingGear,
              enabled: !_loadingGear,
              onChanged: (value) {
                if (value != null && !_selectedGearIds.contains(value)) {
                  setState(() => _selectedGearIds.add(value));
                }
              },
            ),

            if (_selectedGearIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedGearIds.map((id) {
                    final label = _gearOptions.firstWhere((g) => g.value == id).label;
                    return Chip(
                      label: Text(
                        label,
                        style: AppTheme.labelMedium(context).copyWith(fontSize: 13),
                      ),
                      backgroundColor: AppTheme.surfaceVariant(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ArmoryConstants.cardBorderRadius),
                        side: BorderSide(color: AppTheme.border(context)),
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.textSecondary(context),
                      ),
                      onDeleted: () {
                        setState(() => _selectedGearIds.remove(id));
                      },
                    );
                  }).toList(),
                ),
              ),
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

  void _saveLoadout() {
    if (!_formKey.currentState!.validate()) return;

    final name = _controllers['name']?.text.trim() ?? '';
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Loadout name is required'),
          backgroundColor: AppTheme.error(context),
        ),
      );
      return;
    }

    final loadout = ArmoryLoadout(
      name: name,
      firearmId: _selectedFirearmId,
      ammunitionId: _selectedAmmunitionId,
      gearIds: _selectedGearIds,
      notes: _controllers['notes']?.text.trim(),
      dateAdded: DateTime.now(),
    );

    context.read<ArmoryBloc>().add(
      AddLoadoutEvent(userId: widget.userId, loadout: loadout),
    );
  }
}