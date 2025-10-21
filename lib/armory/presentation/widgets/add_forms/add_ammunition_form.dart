// lib/user_dashboard/presentation/widgets/add_ammunition_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../../utils/caliber_calculator.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
import '../common/common_widgets.dart';
import '../common/dialog_widgets.dart';
import '../common/enhanced_dialog_widgets.dart';

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

  // Dropdown options
  List<DropdownOption> _ammunitionBrands = [];
  List<DropdownOption> _calibers = [];
  List<DropdownOption> _bulletTypes = [];

  // Loading states
  bool _loadingBrands = false;
  bool _loadingCalibers = false;
  bool _loadingBulletTypes = false;

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
    setState(() => _loadingCalibers = true);
    context.read<ArmoryBloc>().add(
      const LoadDropdownOptionsEvent(type: DropdownType.ammunitionCaliber),
    );
  }

  void _loadBrandForCalibers(String caliber) {
    setState(() {
      _loadingBrands = true;
      _ammunitionBrands.clear();
      _bulletTypes.clear();
      _dropdownValues['brands'] = null;
    });

    context.read<ArmoryBloc>().add(
      LoadDropdownOptionsEvent(
        type: DropdownType.ammunitionBrands,
        filterValue: caliber,
      ),
    );
  }

  void _generateBulletTypesForBrand(String brand) {
    setState(() {
      _loadingBulletTypes = true;
      _bulletTypes.clear();
      _dropdownValues['bulletType'] = null;
    });

    // Check if caliber is custom - pass empty string to show all bullet types
    final filterBrand = EnhancedDialogWidgets.isCustomValue(brand) ? '' : brand;

    context.read<ArmoryBloc>().add(
      LoadDropdownOptionsEvent(
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
    return BlocListener<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is DropdownOptionsLoaded) {
          _handleDropdownOptionsLoaded(state.options);
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
            onPressed: state is ArmoryLoadingAction ? null : _saveAmmunition,
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
                : const Text('Save Ammunition'),
          ),
        ],
      ),
    );
  }

  void _handleDropdownOptionsLoaded(List<DropdownOption> options) {
    if (_loadingCalibers) {
      setState(() {
        _calibers = options;
        _loadingCalibers = false;
      });
    }
    else if (_loadingBrands) {
      setState(() {
        _ammunitionBrands = options;
         _loadingBrands= false;
      });
    }
    else if (_loadingBulletTypes) {  // Add this condition
      setState(() {
        _bulletTypes = options;
        _loadingBulletTypes = false;
      });
    }
  }

  // Helper method to determine if we should use grid layout
  bool get _shouldUseGridLayout {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.dialogPadding),
      child: Form(
        key: _formKey,
        child: CommonWidgets.buildResponsiveLayout(  [

          EnhancedDialogWidgets.buildDropdownFieldWithCustom(
            label: 'Caliber *',
            value: _dropdownValues['caliber'],
            options: _calibers,
            onChanged: (value) {
              setState(() => _dropdownValues['caliber'] = value);

              // ADD THIS BLOCK - Easy to remove later
              final diameter = CaliberCalculator.calculateBulletDiameter(value, null);
              if (diameter != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bullet Diameter: $diameter"'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              else{
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No diameter Found'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              // END BLOCK

              if (value != null) _loadBrandForCalibers(value);
            },
            customFieldLabel: 'Caliber',
            customHintText: 'e.g., .300 WinMag, 6.5 PRC',
            isRequired: true,
            isLoading: _loadingCalibers,
          ),


          // Brand - with custom option
          EnhancedDialogWidgets.buildDropdownFieldWithCustom(
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
            isLoading: _loadingBrands,
            enabled: _dropdownValues['caliber'] != null,
          ),

          // Product Line
          CommonDialogWidgets.buildTextField(
            label: 'Product Line',
            controller: _controllers['line']!,
            maxLength: 20, // Add this
            hintText: 'e.g., Gold Medal Match, V-Max',
          ),


          // Bullet Type - suggestions based on caliber
          if (_dropdownValues['caliber'] != null) ...[
            EnhancedDialogWidgets.buildDropdownFieldWithCustom(
              label: 'Bullet Weight & Type *',
              value: _dropdownValues['bulletType'],
              options: _bulletTypes,
              onChanged: (value) {
                setState(() => _dropdownValues['bulletType'] = value);
                if (value != null) {
                  _controllers['bullet']?.text = EnhancedDialogWidgets.getDisplayValue(value);
                }
              },
              customFieldLabel: 'Bullet Type',
              customHintText: 'e.g., 77gr TMK, 168gr ELD-M',
              isRequired: true,
              isLoading: _loadingBulletTypes,
              enabled: _dropdownValues['caliber'] != null,
            ),
          ],


          // Quantity and Status
          CommonDialogWidgets.buildResponsiveRow([
            CommonDialogWidgets.buildTextField(
              label: 'Quantity (rounds) *',
              controller: _controllers['quantity']!,
              isRequired: true,
              keyboardType: TextInputType.number,
              hintText: '20',
            ),
            CommonDialogWidgets.buildDropdownField(
              label: 'Status *',
              value: _dropdownValues['status'],
              options: [
                const DropdownOption(value: 'available', label: 'Available'),
                const DropdownOption(value: 'low-stock', label: 'Low Stock'),
                const DropdownOption(value: 'out-of-stock', label: 'Out of Stock'),
              ],
              onChanged: (value) => setState(() => _dropdownValues['status'] = value),
              isRequired: true,
            ),
          ]),

          // Lot Number
          CommonDialogWidgets.buildTextField(
            label: 'Lot Number',
            controller: _controllers['lot']!,
            maxLength: 15, // Add this
            hintText: 'ABC1234',
          ),

          // Notes
          CommonDialogWidgets.buildTextField(
            label: 'Notes',
            controller: _controllers['notes']!,
            maxLines: 3,
            maxLength: 200, // Add this
            hintText: 'Performance notes, accuracy data, etc.',
          ),
        ], _shouldUseGridLayout),
      ),
    );
  }

  void _saveAmmunition() {
    if (!_formKey.currentState!.validate()) return;

    final ammunition = ArmoryAmmunition(
      brand: EnhancedDialogWidgets.getDisplayValue(_dropdownValues['brand']),
      line: _controllers['line']?.text.trim(),
      caliber: EnhancedDialogWidgets.getDisplayValue(_dropdownValues['caliber']),
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