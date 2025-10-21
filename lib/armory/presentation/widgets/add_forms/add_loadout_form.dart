// lib/user_dashboard/presentation/widgets/add_ammunition_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
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

  // Add these properties to store firearm data
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
    // Load user's firearms and ammunition
    context.read<ArmoryBloc>().add(LoadFirearmsEvent(userId: widget.userId));
    context.read<ArmoryBloc>().add(LoadAmmunitionEvent(userId: widget.userId));
    context.read<ArmoryBloc>().add(LoadGearEvent(userId: widget.userId));

  }

  // Modified method to handle firearms
  void _handleFirearmsLoaded(List<ArmoryFirearm> firearms) {
    setState(() {
      _firearms = firearms; // Store firearms data
      _firearmOptions = firearms.map((firearm) => DropdownOption(
        value: firearm.id!,
        label: '${firearm.nickname} (${firearm.make} ${firearm.model})',
      )).toList();
      _loadingFirearms = false;
      // _filterAmmunitionForSelectedFirearm(); // Update ammo when firearms load
    });
  }

// Modified method to handle ammunition
  void _handleAmmunitionLoaded(List<ArmoryAmmunition> ammunition) {
    setState(() {
      _allAmmunition = ammunition; // Store all ammunition
      _loadingAmmunition = false;
      //_filterAmmunitionForSelectedFirearm(); // Filter based on selected firearm
    });
  }

// Modified method to filter ammunition
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

    final matchingAmmunition = _allAmmunition.where(
          (ammo) => ammo.caliber.toLowerCase() == selectedFirearm.caliber.toLowerCase(),
    ).toList();

    if (matchingAmmunition.isEmpty) {
      _ammunitionOptions = [];
      _hasMatchingAmmunition = false;
      // Show snackbar when no matching ammunition found
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNoAmmoSnackBar();
      });
    } else {
      _ammunitionOptions = matchingAmmunition.map((ammo) => DropdownOption(
        value: ammo.id!,
        label: '${ammo.brand} ${ammo.caliber} ${ammo.bullet} (${ammo.quantity} rds)',
      )).toList();
      _hasMatchingAmmunition = true;
    }
  }

// Method to show snackbar
  void _showNoAmmoSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add ammunition for this firearm first'),
        backgroundColor: AppColors.errorColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

// Modified firearm selection handler
  void _onFirearmChanged(String? value) {
    setState(() {
      _selectedFirearmId = value;
      _selectedAmmunitionId = null; // Reset ammunition selection
      _filterAmmunitionForSelectedFirearm(); // Update ammunition options
    });
  }


  void _handleGearLoaded(List<ArmoryGear> gear) {
    setState(() {
      _gearOptions = gear
          .map((g) => DropdownOption(value: g.id!, label: g.model))
          .toList();
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
        }
        else if (state is ArmoryActionSuccess) {
          context.read<ArmoryBloc>().add(const HideFormEvent());
        }
      },
      child:  Column(
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
      padding: const EdgeInsets.all(AppSizes.dialogPadding),
      decoration: AppDecorations.footerBorderDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
            style: AppButtonStyles.cancelButtonStyle,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: state is ArmoryLoadingAction ? null : _saveLoadout,
            style: AppButtonStyles.primaryButtonStyle,
            child: state is ArmoryLoadingAction
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.buttonText,
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
      padding: const EdgeInsets.all(AppSizes.dialogPadding),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Loadout Name
            CommonDialogWidgets.buildTextField(
              label: 'Loadout Name *',
              controller: _controllers['name']!,
              isRequired: true,
              maxLength: 25, // Add this
              hintText: 'e.g., Precision .308, Competition Setup',
            ),
            const SizedBox(height: AppSizes.fieldSpacing),

            // Firearm Selection
            CommonDialogWidgets.buildDropdownField(
              label: 'Firearm *',
              value: _selectedFirearmId,
              options: _firearmOptions,
              onChanged: _onFirearmChanged, // Use new handler
              isLoading: _loadingFirearms,
              enabled: !_loadingFirearms,
              isRequired: true,
            ),
            const SizedBox(height: AppSizes.fieldSpacing),

            // Ammunition Selection
            CommonDialogWidgets.buildDropdownField(
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
              enabled: _hasMatchingAmmunition && !_loadingAmmunition, // Only enable if has matching ammo
              isRequired: true,
            ),
            const SizedBox(height: AppSizes.fieldSpacing),

            // Gear Multi-Select
            CommonDialogWidgets.buildDropdownField(
              label: 'Gear',
              value: null, // we don't bind one value because it's multi-select
              options: _gearOptions,
              isLoading: _loadingGear,
              enabled: !_loadingGear,
              onChanged: (value) {
                if (value != null && !_selectedGearIds.contains(value)) {
                  setState(() => _selectedGearIds.add(value));
                }
              },
            ),

// Show selected gear as chips
            // Show selected gear as chips
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
                        style: AppTextStyles.fieldLabel.copyWith(
                          fontSize: 13,
                          color: AppColors.primaryText,
                        ),
                      ),
                      backgroundColor: AppColors.cardBackground.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                        side: BorderSide(color: AppColors.primaryBackground),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                      onDeleted: () {
                        setState(() => _selectedGearIds.remove(id));
                      },
                    );
                  }).toList(),
                ),
              ),
            ],


            const SizedBox(height: AppSizes.fieldSpacing),


            // Notes
            CommonDialogWidgets.buildTextField(
              label: 'Notes',
              controller: _controllers['notes']!,
              maxLines: 3,
              maxLength: 200, // Add this
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
        const SnackBar(
          content: Text('Loadout name is required'),
          backgroundColor: AppColors.errorColor,
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