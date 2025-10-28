// lib/armory/presentation/widgets/add_forms/add_ammunition_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../../utils/caliber_calculator.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../bloc/dropdown/dropdown_bloc.dart';
import '../../bloc/dropdown/dropdown_event.dart';
import '../../bloc/dropdown/dropdown_state.dart';
import '../common/armory_constants.dart';
import '../common/common_widgets.dart';
import '../common/dialog_widgets.dart';

class AddAmmunitionForm extends StatefulWidget {
  final String userId;

  const AddAmmunitionForm({super.key, required this.userId});

  @override
  State<AddAmmunitionForm> createState() => _AddAmmunitionFormState();
}

class _AddAmmunitionFormState extends State<AddAmmunitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dropdownValues = <String, String?>{};

  List<DropdownOption> _ammunitionBrands = [];
  List<DropdownOption> _calibers = [];
  List<DropdownOption> _bulletTypes = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    final fields = ['line', 'bullet', 'quantity', 'lot', 'notes'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }

    _dropdownValues['status'] = 'available';
    _controllers['quantity']?.text = '20';
  }

  void _loadInitialData() {
    context.read<DropdownBloc>().add(
      const LoadDropdownEvent(
        key: 'ammunition_calibers',
        type: DropdownType.ammunitionCaliber,
      ),
    );
  }

  void _loadBrandForCalibers(String caliber) {
    setState(() {
      _ammunitionBrands.clear();
      _bulletTypes.clear();
      _dropdownValues['brand'] = null;
      _dropdownValues['bulletType'] = null;
    });

    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'ammunition_brands',
        type: DropdownType.ammunitionBrands,
        filterValue: caliber,
      ),
    );
  }

  void _generateBulletTypesForBrand(String brand) {
    setState(() {
      _bulletTypes.clear();
      _dropdownValues['bulletType'] = null;
    });

    final filterBrand = DialogWidgets.isCustomValue(brand) ? '' : brand;

    context.read<DropdownBloc>().add(
      LoadDropdownEvent(
        key: 'ammunition_bullet_types',
        type: DropdownType.bulletTypes,
        filterValue: filterBrand,
      ),
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DropdownBloc, DropdownState>(
          listener: (context, state) {
            if (state is DropdownLoaded) {
              _handleDropdownOptionsLoaded(state.key, state.options);
            }
          },
        ),
      ],
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
            onPressed: state is ArmoryLoadingAction ? null : _saveAmmunition,
            child: state is ArmoryLoadingAction
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary(context),
              ),
            )
                : const Text('Save Ammunition'),
          ),
        ],
      ),
    );
  }

  void _handleDropdownOptionsLoaded(String key, List<DropdownOption> options) {
    setState(() {
      switch (key) {
        case 'ammunition_calibers':
          _calibers = options;
          break;
        case 'ammunition_brands':
          _ammunitionBrands = options;
          break;
        case 'ammunition_bullet_types':
          _bulletTypes = options;
          break;
      }
    });
  }

  bool get _shouldUseGridLayout {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      child: Form(
        key: _formKey,
        child: CommonWidgets.buildResponsiveLayout(context, [
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'ammunition_calibers';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Caliber *',
                value: _dropdownValues['caliber'],
                options: _calibers,
                onChanged: (value) {
                  setState(() => _dropdownValues['caliber'] = value);
                  final diameter = CaliberCalculator.calculateBulletDiameter(value, null);
                  if (diameter != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bullet Diameter: $diameter"'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No diameter Found'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }

                  if (value != null) _loadBrandForCalibers(value);
                },
                customFieldLabel: 'Caliber',
                customHintText: 'e.g., .300 WinMag, 6.5 PRC',
                isRequired: true,
                isLoading: isLoading,
              );
            },
          ),
          BlocBuilder<DropdownBloc, DropdownState>(
            builder: (context, dropdownState) {
              final isLoading = dropdownState is DropdownLoading &&
                  dropdownState.loadingKey == 'ammunition_brands';
              return DialogWidgets.buildDropdownFieldWithCustom(
                context: context,
                label: 'Brand *',
                value: _dropdownValues['brand'],
                options: _ammunitionBrands,
                onChanged: (value) {
                  setState(() => _dropdownValues['brand'] = value);
                  if (value != null) _generateBulletTypesForBrand(value);
                },
                customFieldLabel: 'Brand',
                customHintText: 'e.g., Custom Ammo Maker',
                isRequired: true,
                isLoading: isLoading,
                enabled: _dropdownValues['caliber'] != null,
              );
            },
          ),
          DialogWidgets.buildTextField(
            context: context,
            label: 'Product Line',
            controller: _controllers['line']!,
            maxLength: 20,
            hintText: 'e.g., Gold Medal Match, V-Max',
          ),
          if (_dropdownValues['caliber'] != null)
            BlocBuilder<DropdownBloc, DropdownState>(
              builder: (context, dropdownState) {
                final isLoading = dropdownState is DropdownLoading &&
                    dropdownState.loadingKey == 'ammunition_bullet_types';
                return DialogWidgets.buildDropdownFieldWithCustom(
                  context: context,
                  label: 'Bullet Weight & Type *',
                  value: _dropdownValues['bulletType'],
                  options: _bulletTypes,
                  onChanged: (value) {
                    setState(() => _dropdownValues['bulletType'] = value);
                    if (value != null) {
                      _controllers['bullet']?.text = DialogWidgets.getDisplayValue(value);
                    }
                  },
                  customFieldLabel: 'Bullet Type',
                  customHintText: 'e.g., 77gr TMK, 168gr ELD-M',
                  isRequired: true,
                  isLoading: isLoading,
                  enabled: _dropdownValues['caliber'] != null,
                );
              },
            ),
          DialogWidgets.buildResponsiveRow(context, [
            DialogWidgets.buildTextField(
              context: context,
              label: 'Quantity (rounds) *',
              controller: _controllers['quantity']!,
              isRequired: true,
              keyboardType: TextInputType.number,
              hintText: '20',
            ),
            DialogWidgets.buildDropdownField(
              context: context,
              label: 'Status *',
              value: _dropdownValues['status'],
              options: const [
                DropdownOption(value: 'available', label: 'Available'),
                DropdownOption(value: 'low-stock', label: 'Low Stock'),
                DropdownOption(value: 'out-of-stock', label: 'Out of Stock'),
              ],
              onChanged: (value) => setState(() => _dropdownValues['status'] = value),
              isRequired: true,
            ),
          ]),
          DialogWidgets.buildTextField(
            context: context,
            label: 'Lot Number',
            controller: _controllers['lot']!,
            maxLength: 15,
            hintText: 'ABC1234',
          ),
          DialogWidgets.buildTextField(
            context: context,
            label: 'Notes',
            controller: _controllers['notes']!,
            maxLines: 3,
            maxLength: 200,
            hintText: 'Performance notes, accuracy data, etc.',
          ),
        ], _shouldUseGridLayout),
      ),
    );
  }

  void _saveAmmunition() {
    if (!_formKey.currentState!.validate()) return;

    final ammunition = ArmoryAmmunition(
      brand: DialogWidgets.getDisplayValue(_dropdownValues['brand']),
      line: _controllers['line']?.text.trim(),
      caliber: DialogWidgets.getDisplayValue(_dropdownValues['caliber']),
      bullet: _controllers['bullet']?.text.trim() ?? '',
      quantity: int.tryParse(_controllers['quantity']?.text.trim() ?? '0') ?? 0,
      status: _dropdownValues['status']!,
      lot: _controllers['lot']?.text.trim(),
      notes: _controllers['notes']?.text.trim(),
      dateAdded: DateTime.now(),
    );

    context.read<ArmoryBloc>().add(
      AddAmmunitionEvent(userId: widget.userId, ammunition: ammunition),
    );
  }
}
