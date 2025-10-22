// lib/armory/presentation/widgets/add_forms/add_maintenance_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';
import '../common/dialog_widgets.dart';

class AddMaintenanceForm extends StatefulWidget {
  final String userId;

  const AddMaintenanceForm({super.key, required this.userId});

  @override
  State<AddMaintenanceForm> createState() => _AddMaintenanceFormState();
}

class _AddMaintenanceFormState extends State<AddMaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dropdownValues = <String, String?>{};

  List<DropdownOption> _assetOptions = [];
  List<ArmoryFirearm> _allFirearms = [];
  List<ArmoryGear> _allGear = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    final fields = ['rounds', 'notes'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
    _controllers['rounds']?.text = '0';
  }

  void _loadInitialData() {
    context.read<ArmoryBloc>().add(LoadFirearmsEvent(userId: widget.userId));
    context.read<ArmoryBloc>().add(LoadGearEvent(userId: widget.userId));
  }

  void _handleAssetTypeChange(String? assetType) {
    setState(() {
      _dropdownValues['assetType'] = assetType;
      _dropdownValues['asset'] = null;
      _updateAssetOptions();
    });
  }

  void _updateAssetOptions() {
    setState(() {
      if (_dropdownValues['assetType'] == 'firearm') {
        _assetOptions = _allFirearms
            .map((firearm) => DropdownOption(
          value: firearm.id!,
          label: '${firearm.nickname} (${firearm.make} ${firearm.model})',
        ))
            .toList();
      } else if (_dropdownValues['assetType'] == 'gear') {
        _assetOptions = _allGear
            .map((gear) => DropdownOption(
          value: gear.id!,
          label: '${gear.model} (${gear.category})',
        ))
            .toList();
      } else {
        _assetOptions.clear();
      }
    });
  }

  void _handleFirearmsLoaded(List<ArmoryFirearm> firearms) {
    setState(() {
      _allFirearms = firearms;
      _updateAssetOptions();
    });
  }

  void _handleGearLoaded(List<ArmoryGear> gear) {
    setState(() {
      _allGear = gear;
      _updateAssetOptions();
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
            onPressed: state is ArmoryLoadingAction ? null : _saveMaintenance,
            child: state is ArmoryLoadingAction
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Save Maintenance'),
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
            DialogWidgets.buildResponsiveRow(context, [
              DialogWidgets.buildDropdownField(
                context: context,
                label: 'Asset Type *',
                value: _dropdownValues['assetType'],
                options: const [
                  DropdownOption(value: 'firearm', label: 'Firearm'),
                  DropdownOption(value: 'gear', label: 'Gear'),
                ],
                onChanged: _handleAssetTypeChange,
                isRequired: true,
              ),
              DialogWidgets.buildDropdownField(
                context: context,
                label: 'Asset *',
                value: _dropdownValues['asset'],
                options: _assetOptions,
                onChanged: (value) => setState(() => _dropdownValues['asset'] = value),
                isRequired: true,
                enabled: _dropdownValues['assetType'] != null && _assetOptions.isNotEmpty,
              ),
            ]),
            const SizedBox(height: ArmoryConstants.fieldSpacing),

            DialogWidgets.buildResponsiveRow(context, [
              DialogWidgets.buildDropdownField(
                context: context,
                label: 'Maintenance Type *',
                value: _dropdownValues['maintenanceType'],
                options: const [
                  DropdownOption(value: 'cleaning', label: 'Cleaning'),
                  DropdownOption(value: 'lubrication', label: 'Lubrication'),
                  DropdownOption(value: 'inspection', label: 'Inspection'),
                  DropdownOption(value: 'repair', label: 'Repair'),
                  DropdownOption(value: 'replacement', label: 'Part Replacement'),
                ],
                onChanged: (value) => setState(() => _dropdownValues['maintenanceType'] = value),
                isRequired: true,
              ),
              _buildDatePickerField(),
            ]),
            const SizedBox(height: ArmoryConstants.fieldSpacing),

            DialogWidgets.buildTextField(
              context: context,
              label: 'Rounds Fired (if applicable)',
              controller: _controllers['rounds']!,
              keyboardType: TextInputType.number,
              hintText: '0',
            ),
            const SizedBox(height: ArmoryConstants.fieldSpacing),

            DialogWidgets.buildTextField(
              context: context,
              label: 'Notes',
              controller: _controllers['notes']!,
              maxLines: 3,
              maxLength: 200,
              hintText: 'Details of maintenance performed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppTheme.primary(context),
                      surface: AppTheme.surface(context),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: AppTheme.bodyMedium(context),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.textSecondary(context),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveMaintenance() {
    if (!_formKey.currentState!.validate()) return;

    if (_dropdownValues['assetType'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asset type is required'),
          backgroundColor: AppTheme.error(context),
        ),
      );
      return;
    }

    if (_dropdownValues['asset'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asset selection is required'),
          backgroundColor: AppTheme.error(context),
        ),
      );
      return;
    }

    if (_dropdownValues['maintenanceType'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maintenance type is required'),
          backgroundColor: AppTheme.error(context),
        ),
      );
      return;
    }

    final maintenance = ArmoryMaintenance(
      assetType: _dropdownValues['assetType']!,
      assetId: _dropdownValues['asset']!,
      maintenanceType: _dropdownValues['maintenanceType']!,
      date: _selectedDate,
      roundsFired: int.tryParse(_controllers['rounds']?.text.trim() ?? '0'),
      notes: _controllers['notes']?.text.trim(),
      dateAdded: DateTime.now(),
    );

    context.read<ArmoryBloc>().add(
      AddMaintenanceEvent(userId: widget.userId, maintenance: maintenance),
    );
  }
}