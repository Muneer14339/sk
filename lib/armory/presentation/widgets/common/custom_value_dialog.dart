// lib/user_dashboard/presentation/widgets/common/custom_value_dialog.dart
import 'package:flutter/material.dart';
import '../../core/theme/user_app_theme.dart';
import 'dialog_widgets.dart';

class CustomValueDialog extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String hintText;
  final Function(String) onSave;
  final String? Function(String?)? validator;  // NEW

  const CustomValueDialog({
    super.key,
    required this.title,
    required this.fieldLabel,
    required this.hintText,
    required this.onSave,
    this.validator,  // NEW
  });

  @override
  State<CustomValueDialog> createState() => _CustomValueDialogState();
}

class _CustomValueDialogState extends State<CustomValueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialogWidgets.buildDialogWrapper(
      maxWidth: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonDialogWidgets.buildHeader(
            title: widget.title,
            badge: 'Custom',
            onClose: () => Navigator.of(context).pop(),
          ),
          _buildForm(),
          CommonDialogWidgets.buildActions(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _saveCustomValue,
            saveButtonText: 'Add Custom',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // Update this method in custom_value_dialog.dart _buildForm method
  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.dialogPadding),
      child: Form(
        key: _formKey,
        child: CommonDialogWidgets.buildTextField(
          label: widget.fieldLabel,
          controller: _controller,
          isRequired: true,
          maxLength: 30, // Add character limit for custom values
          hintText: widget.hintText,
          validator: widget.validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return '${widget.fieldLabel} is required';
            }
            if (value.trim().length < 2) {
              return '${widget.fieldLabel} must be at least 2 characters';
            }
            if (value.trim().length > 30) {
              return '${widget.fieldLabel} must be 30 characters or less';
            }
            return null;
          },
        ),
      ),
    );
  }

  void _saveCustomValue() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customValue = _controller.text.trim();

    // Simulate saving delay
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onSave(customValue);
      Navigator.of(context).pop();
    });
  }
}