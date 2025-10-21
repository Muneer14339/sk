// lib/user_dashboard/presentation/widgets/common/dialog_widgets.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../core/theme/user_app_theme.dart';

class CommonDialogWidgets {
  static Widget buildHeader({
    required String title,
    String? badge,
    VoidCallback? onClose,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.dialogPadding),
      decoration: AppDecorations.headerBorderDecoration,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.dialogTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: AppDecorations.accentBadgeDecoration,
                    child: Text(
                      badge,
                      style: AppTextStyles.badgeText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose ?? () {},
            icon: const Icon(Icons.close, color: AppColors.primaryText),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // Update this method in dialog_widgets.dart
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    int maxLines = 1,
    int? maxLength, // Add this parameter
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  })
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength, // Add this line
          keyboardType: keyboardType,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? AppColors.primaryText : AppColors.primaryText.withOpacity(0.5),
            fontSize: 14,
          ),
          decoration: AppInputDecorations.getInputDecoration(
            hintText: hintText,
            enabled: enabled,
          ),
          // Add this line to hide the character counter
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          validator: validator ?? (isRequired
              ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '${label.replaceAll('*', '').trim()} is required';
            }
            // Add length validation
            if (maxLength != null && value.trim().length > maxLength) {
              return '${label.replaceAll('*', '').trim()} must be ${maxLength} characters or less';
            }
            return null;
          }
              : maxLength != null ? (value) {
            if (value != null && value.trim().length > maxLength) {
              return '${label.replaceAll('*', '').trim()} must be ${maxLength} characters or less';
            }
            return null;
          } : null),
          onChanged: onChanged,
        ),
      ],
    );
  }
  static Widget buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownOption> options,
    required void Function(String?) onChanged,
    bool isRequired = false,
    bool isLoading = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true, // This prevents overflow
          decoration: AppInputDecorations.getInputDecoration(
            enabled: enabled,
            isLoading: isLoading,
          ),
          dropdownColor: AppColors.cardBackground,
          style: TextStyle(
            color: enabled ? AppColors.primaryText : AppColors.primaryText.withOpacity(0.5),
            fontSize: 14,
          ),
          items: !enabled
              ? [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Select required field first...',
                style: TextStyle(color: AppColors.secondaryText.withOpacity(0.6)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]
              : [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                isLoading
                    ? 'Loading...'
                    : 'Select ${label.replaceAll('*', '').trim().toLowerCase()}...',
                style: TextStyle(color: AppColors.secondaryText.withOpacity(0.6)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...options.map((option) => DropdownMenuItem<String>(
              value: option.value.startsWith('---') ? null : option.value,
              enabled: !option.value.startsWith('---'),
              child: Text(
                option.label,
                style: option.value.startsWith('---')
                    ? TextStyle(color: AppColors.secondaryText.withOpacity(0.7))
                    : null,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
          onChanged: !enabled || isLoading ? null : onChanged,
          validator: validator ?? (isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return '${label.replaceAll('*', '').trim()} is required';
            }
            return null;
          }
              : null),
        ),
      ],
    );
  }

  static Widget buildResponsiveRow(List<Widget> children, {double breakpoint = AppBreakpoints.tablet}) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        if (screenWidth > breakpoint) {
          // Desktop/Tablet layout - use Row with proper flex
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                children.length * 2 - 1,
                    (index) {
                  if (index.isEven) {
                    return Expanded(
                      child: children[index ~/ 2],
                    );
                  } else {
                    return const SizedBox(width: 10);
                  }
                },
              ),
            ),
          );
        } else {
          // Mobile layout - use Column
          return Column(
            children: List.generate(
              children.length * 2 - 1,
                  (index) {
                if (index.isEven) {
                  return children[index ~/ 2];
                } else {
                  return const SizedBox(height: AppSizes.fieldSpacing);
                }
              },
            ),
          );
        }
      },
    );
  }

  static Widget buildActions({
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required String saveButtonText,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.dialogPadding),
      decoration: AppDecorations.footerBorderDecoration,
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;

          if (screenWidth < 300) {
            // Very small screens - stack buttons
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  style: AppButtonStyles.primaryButtonStyle,
                  child: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.buttonText,
                    ),
                  )
                      : Text(saveButtonText),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  style: AppButtonStyles.cancelButtonStyle,
                  child: const Text('Cancel'),
                ),
              ],
            );
          } else {
            // Normal layout
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  style: AppButtonStyles.cancelButtonStyle,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  style: AppButtonStyles.primaryButtonStyle,
                  child: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.buttonText,
                    ),
                  )
                      : Text(saveButtonText),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  static Widget buildDialogWrapper({
    required Widget child,
    double? maxWidth,
  }) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? (screenWidth > 600 ? 600 : screenWidth * 0.95),
              maxHeight: screenHeight * 0.9,
            ),
            child: child,
          );
        },
      ),
    );
  }
}