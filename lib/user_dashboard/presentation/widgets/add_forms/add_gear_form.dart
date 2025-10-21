// lib/user_dashboard/presentation/widgets/add_ammunition_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
import '../common/dialog_widgets.dart';

class AddGearForm extends StatefulWidget {
  final String userId;

  const AddGearForm({super.key, required this.userId});

  @override
  State<AddGearForm> createState() => _AddGearFormState();
}

class _AddGearFormState extends State<AddGearForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String? _category;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final fields = ['model', 'serial', 'quantity', 'notes'];
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
    _controllers['quantity']?.text = '1';
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
        if (state is ArmoryActionSuccess) {
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
            onPressed: state is ArmoryLoadingAction ? null : _saveGear,
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
                : const Text('Save Gear'),
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
            CommonDialogWidgets.buildDropdownField(
              label: 'Category *',
              value: _category,
              options: [
                const DropdownOption(value: 'optics', label: 'Optics'),
                const DropdownOption(value: 'supports', label: 'Supports'),
                const DropdownOption(value: 'attachments', label: 'Attachments'),
                const DropdownOption(value: 'sensors', label: 'Sensors'),
                const DropdownOption(value: 'misc', label: 'Miscellaneous'),
              ],
              onChanged: (value) => setState(() => _category = value),
              isRequired: true,
            ),
            const SizedBox(height: AppSizes.fieldSpacing),

            CommonDialogWidgets.buildTextField(
              label: 'Model/Name *',
              controller: _controllers['model']!,
              isRequired: true,
              maxLength: 30, // Add this
              hintText: 'e.g., Vortex Razor HD',
            ),
            const SizedBox(height: AppSizes.fieldSpacing),

            CommonDialogWidgets.buildResponsiveRow([
              CommonDialogWidgets.buildTextField(
                label: 'Serial Number',
                controller: _controllers['serial']!,
                maxLength: 20, // Add this
                hintText: 'Optional',
              ),

              CommonDialogWidgets.buildTextField(
                label: 'Quantity',
                controller: _controllers['quantity']!,
                keyboardType: TextInputType.number,
              ),
            ]),
            const SizedBox(height: AppSizes.fieldSpacing),

            CommonDialogWidgets.buildTextField(
              label: 'Notes',
              controller: _controllers['notes']!,
              maxLines: 3,
              maxLength: 200, // Add this
              hintText: 'Details about this gear',
            ),
          ],
        ),
      ),
    );
  }

  void _saveGear() {
    if (!_formKey.currentState!.validate()) return;

    final gear = ArmoryGear(
      category: _category!,
      model: _controllers['model']?.text.trim() ?? '',
      serial: _controllers['serial']?.text.trim(),
      quantity: int.tryParse(_controllers['quantity']?.text.trim() ?? '1') ?? 1,
      notes: _controllers['notes']?.text.trim(),
      dateAdded: DateTime.now(),
    );

    context.read<ArmoryBloc>().add(
      AddGearEvent(userId: widget.userId, gear: gear),
    );
  }
}