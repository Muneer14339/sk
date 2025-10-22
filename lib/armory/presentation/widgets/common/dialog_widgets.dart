import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/dropdown_option.dart';
import 'armory_constants.dart';

class DialogWidgets {
  static Widget buildHeader({
    required BuildContext context,
    required String title,
    String? badge,
    VoidCallback? onClose,
  }) {
    return Container(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: AppTheme.headingMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary(context).withOpacity(0.1),
                      border: Border.all(color: AppTheme.primary(context).withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(ArmoryConstants.badgeBorderRadius),
                    ),
                    child: Text(
                      badge,
                      style: AppTheme.labelMedium(context).copyWith(
                        color: AppTheme.primary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose ?? () {},
            icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  static Widget buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          enabled: enabled,
          style: AppTheme.bodyMedium(context).copyWith(
            color: enabled ? null : AppTheme.textPrimary(context).withOpacity(0.5),
          ),
          decoration: InputDecoration(
            hintText: enabled ? hintText : 'Select required field first...',
            hintStyle: AppTheme.labelMedium(context),
            filled: true,
            fillColor: enabled
                ? AppTheme.surfaceVariant(context)
                : AppTheme.surfaceVariant(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(
                color: enabled
                    ? AppTheme.border(context)
                    : AppTheme.border(context).withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.primary(context)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.error(context)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          validator: validator ??
              (isRequired
                  ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '${label.replaceAll('*', '').trim()} is required';
                }
                if (maxLength != null && value.trim().length > maxLength) {
                  return '${label.replaceAll('*', '').trim()} must be $maxLength characters or less';
                }
                return null;
              }
                  : maxLength != null
                  ? (value) {
                if (value != null && value.trim().length > maxLength) {
                  return '${label.replaceAll('*', '').trim()} must be $maxLength characters or less';
                }
                return null;
              }
                  : null),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static Widget buildDropdownField({
    required BuildContext context,
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
        Text(label, style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? AppTheme.surfaceVariant(context)
                : AppTheme.surfaceVariant(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(
                color: enabled
                    ? AppTheme.border(context)
                    : AppTheme.border(context).withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.primary(context)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.error(context)),
            ),
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: isLoading
                ? Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary(context),
                ),
              ),
            )
                : null,
          ),
          dropdownColor: AppTheme.surface(context),
          style: AppTheme.bodyMedium(context).copyWith(
            color: enabled ? null : AppTheme.textPrimary(context).withOpacity(0.5),
          ),
          items: !enabled
              ? [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Select required field first...',
                style: AppTheme.labelMedium(context),
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
                style: AppTheme.labelMedium(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...options.map((option) => DropdownMenuItem<String>(
              value: option.value.startsWith('---') ? null : option.value,
              enabled: !option.value.startsWith('---'),
              child: Text(
                option.label,
                style: option.value.startsWith('---')
                    ? AppTheme.labelMedium(context)
                    : null,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
          onChanged: !enabled || isLoading ? null : onChanged,
          validator: validator ??
              (isRequired
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

  static Widget buildResponsiveRow(BuildContext context, List<Widget> children, {double breakpoint = 520}) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (screenWidth > breakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                children.length * 2 - 1,
                    (index) {
                  if (index.isEven) {
                    return Expanded(child: children[index ~/ 2]);
                  } else {
                    return const SizedBox(width: 10);
                  }
                },
              ),
            ),
          );
        } else {
          return Column(
            children: List.generate(
              children.length * 2 - 1,
                  (index) {
                if (index.isEven) {
                  return children[index ~/ 2];
                } else {
                  return const SizedBox(height: ArmoryConstants.fieldSpacing);
                }
              },
            ),
          );
        }
      },
    );
  }

  static Widget buildActions({
    required BuildContext context,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required String saveButtonText,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context))),
      ),
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  child: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(saveButtonText),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  child: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ArmoryConstants.cardBorderRadius),
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

  static Widget buildDropdownFieldWithCustom({
    required BuildContext context,
    required String label,
    required String? value,
    required List<DropdownOption> options,
    required void Function(String?) onChanged,
    required String customFieldLabel,
    required String customHintText,
    bool isRequired = false,
    bool isLoading = false,
    bool enabled = true,
    bool allowCustom = true,
    String? Function(String?)? validator,
    String? Function(String)? customValueFormatter,
  })
  {
    final showSearch = options.length > 5 && enabled && !isLoading;

    return showSearch
        ? _SearchableDropdownField(
      context: context,
      label: label,
      value: value,
      options: options,
      onChanged: onChanged,
      customFieldLabel: customFieldLabel,
      customHintText: customHintText,
      isRequired: isRequired,
      isLoading: isLoading,
      enabled: enabled,
      allowCustom: allowCustom,
      validator: validator,
      customValueFormatter: customValueFormatter,
    )
        : _buildStaticDropdown(
      context: context,
      label: label,
      value: value,
      options: options,
      onChanged: onChanged,
      customFieldLabel: customFieldLabel,
      customHintText: customHintText,
      isRequired: isRequired,
      isLoading: isLoading,
      enabled: enabled,
      allowCustom: allowCustom,
      validator: validator,
      customValueFormatter: customValueFormatter,
    );
  }

  static Widget _buildStaticDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<DropdownOption> options,
    required void Function(String?) onChanged,
    required String customFieldLabel,
    required String customHintText,
    bool isRequired = false,
    bool isLoading = false,
    bool enabled = true,
    bool allowCustom = true,
    String? Function(String?)? validator,
    String? Function(String)? customValueFormatter,
  })
  {
    final allOptions = List<DropdownOption>.from(options);

    if (value != null && isCustomValue(value) && !allOptions.any((opt) => opt.value == value)) {
      allOptions.add(DropdownOption(
        value: value,
        label: getDisplayValue(value),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? AppTheme.surfaceVariant(context)
                : AppTheme.surfaceVariant(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(
                color: enabled ? AppTheme.border(context) : AppTheme.border(context).withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.primary(context)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.error(context)),
            ),
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: isLoading
                ? Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary(context),
                ),
              ),
            )
                : null,
          ),
          dropdownColor: AppTheme.surface(context),
          style: AppTheme.bodyMedium(context).copyWith(
            color: enabled ? null : AppTheme.textPrimary(context).withOpacity(0.5),
          ),
          items: !enabled
              ? [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Select required field first...',
                style: AppTheme.labelMedium(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]
              : [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                isLoading ? 'Loading...' : 'Select ${label.replaceAll('*', '').trim().toLowerCase()}...',
                style: AppTheme.labelMedium(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...allOptions.map((option) => DropdownMenuItem<String>(
              value: option.value,
              enabled: option.value != '---SEPARATOR---',
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
              ),
            )),
            if (allowCustom && !isLoading)
              DropdownMenuItem<String>(
                value: '__ADD_CUSTOM__',
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primary(context),
                      size: ArmoryConstants.smallIcon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Custom $customFieldLabel',
                      style: AppTheme.labelLarge(context).copyWith(
                        color: AppTheme.primary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
          onChanged: !enabled || isLoading
              ? null
              : (selectedValue) {
            if (selectedValue == '__ADD_CUSTOM__') {
              _showCustomDialog(
                context: context,
                label: customFieldLabel,
                hintText: customHintText,
                onSave: onChanged,
                customValueFormatter: customValueFormatter,
                validator: validator,
              );
            } else {
              onChanged(selectedValue);
            }
          },
          validator: validator ??
              (isRequired
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

  static void _showCustomDialog({
    required BuildContext context,
    required String label,
    required String hintText,
    required Function(String?) onSave,
    String? Function(String)? customValueFormatter,
    String? Function(String?)? validator,
  })
  {
    showDialog(
      context: context,
      builder: (dialogContext) => _CustomValueDialog(
        context: context,
        title: 'Add Custom $label',
        fieldLabel: label,
        hintText: hintText,
        onSave: (customValue) {
          final formattedValue = customValueFormatter != null
              ? '__CUSTOM__${customValueFormatter(customValue)}'
              : '__CUSTOM__$customValue';
          onSave(formattedValue);
        },
        validator: validator,
      ),
    );
  }

  static bool isCustomValue(String? value) {
    return value != null && value.startsWith('__CUSTOM__');
  }

  static String extractCustomValue(String? value) {
    if (isCustomValue(value)) {
      return value!.substring('__CUSTOM__'.length);
    }
    return value ?? '';
  }

  static String getDisplayValue(String? value) {
    if (isCustomValue(value)) {
      return extractCustomValue(value);
    }
    return value ?? '';
  }
}

class _SearchableDropdownField extends StatefulWidget {
  final BuildContext context;
  final String label;
  final String? value;
  final List<DropdownOption> options;
  final void Function(String?) onChanged;
  final String customFieldLabel;
  final String customHintText;
  final bool isRequired;
  final bool isLoading;
  final bool enabled;
  final bool allowCustom;
  final String? Function(String?)? validator;
  final String? Function(String)? customValueFormatter;

  const _SearchableDropdownField({
    required this.context,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.customFieldLabel,
    required this.customHintText,
    required this.isRequired,
    required this.isLoading,
    required this.enabled,
    required this.allowCustom,
    this.validator,
    this.customValueFormatter,
  });

  @override
  State<_SearchableDropdownField> createState() => _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<_SearchableDropdownField> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownOption> _filteredOptions = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _updateFilteredOptions();
  }

  @override
  void didUpdateWidget(_SearchableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _updateFilteredOptions();
    }
  }

  void _updateFilteredOptions() {
    final query = _searchController.text.toLowerCase();
    _filteredOptions = widget.options
        .where((option) => option.label.toLowerCase().contains(query))
        .toList();

    if (widget.value != null &&
        DialogWidgets.isCustomValue(widget.value!) &&
        !_filteredOptions.any((opt) => opt.value == widget.value)) {
      _filteredOptions.add(DropdownOption(
        value: widget.value!,
        label: DialogWidgets.getDisplayValue(widget.value),
      ));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTheme.labelMedium(context)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _searchController,
          enabled: widget.enabled,
          style: AppTheme.bodyMedium(context).copyWith(
            color: widget.enabled ? null : AppTheme.textPrimary(context).withOpacity(0.5),
          ),
          decoration: InputDecoration(
            hintText: widget.enabled
                ? (widget.isLoading
                ? 'Loading...'
                : 'Search ${widget.label.replaceAll('*', '').trim().toLowerCase()}...')
                : 'Select required field first...',
            filled: true,
            fillColor: widget.enabled
                ? AppTheme.surfaceVariant(context)
                : AppTheme.surfaceVariant(context).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(
                color: widget.enabled ? AppTheme.border(context) : AppTheme.border(context).withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.primary(context)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
              borderSide: BorderSide(color: AppTheme.error(context)),
            ),
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary(context),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: widget.enabled && !widget.isLoading
                      ? () => setState(() => _showDropdown = !_showDropdown)
                      : null,
                  icon: Icon(
                    _showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: widget.enabled
                        ? AppTheme.textSecondary(context)
                        : AppTheme.textSecondary(context).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          onChanged: widget.enabled && !widget.isLoading
              ? (value) {
            setState(() {
              _updateFilteredOptions();
              _showDropdown = value.isNotEmpty;
            });
          }
              : null,
          onTap: widget.enabled && !widget.isLoading ? () => setState(() => _showDropdown = true) : null,
          readOnly: false,
          validator: widget.validator ??
              (widget.isRequired
                  ? (value) {
                if (widget.value == null || widget.value!.isEmpty) {
                  return '${widget.label.replaceAll('*', '').trim()} is required';
                }
                return null;
              }
                  : null),
        ),
        if (_showDropdown && widget.enabled && !widget.isLoading) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              border: Border.all(color: AppTheme.border(context)),
              borderRadius: BorderRadius.circular(ArmoryConstants.borderRadius),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._filteredOptions.map((option) => InkWell(
                    onTap: option.value == '---SEPARATOR---'
                        ? null
                        : () {
                      widget.onChanged(option.value);
                      _searchController.text = option.label;
                      setState(() => _showDropdown = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        option.label,
                        style: AppTheme.bodyMedium(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )),
                  if (widget.allowCustom) ...[
                    Divider(color: AppTheme.border(context), height: 1),
                    InkWell(
                      onTap: () {
                        DialogWidgets._showCustomDialog(
                          context: context,
                          label: widget.customFieldLabel,
                          hintText: widget.customHintText,
                          onSave: (customValue) {
                            widget.onChanged(customValue);
                            _searchController.text = DialogWidgets.getDisplayValue(customValue);
                          },
                          customValueFormatter: widget.customValueFormatter,
                          validator: widget.validator,
                        );
                        setState(() => _showDropdown = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: AppTheme.primary(context),
                              size: ArmoryConstants.smallIcon,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add Custom ${widget.customFieldLabel}',
                              style: AppTheme.labelLarge(context).copyWith(
                                color: AppTheme.primary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_filteredOptions.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No results found',
                        style: AppTheme.bodyMedium(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CustomValueDialog extends StatefulWidget {
  final BuildContext context;
  final String title;
  final String fieldLabel;
  final String hintText;
  final Function(String) onSave;
  final String? Function(String?)? validator;

  const _CustomValueDialog({
    required this.context,
    required this.title,
    required this.fieldLabel,
    required this.hintText,
    required this.onSave,
    this.validator,
  });

  @override
  State<_CustomValueDialog> createState() => _CustomValueDialogState();
}

class _CustomValueDialogState extends State<_CustomValueDialog> {
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
    return DialogWidgets.buildDialogWrapper(
      context: context,
      maxWidth: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DialogWidgets.buildHeader(
            context: context,
            title: widget.title,
            badge: 'Custom',
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
            child: Form(
              key: _formKey,
              child: DialogWidgets.buildTextField(
                context: context,
                label: widget.fieldLabel,
                controller: _controller,
                isRequired: true,
                maxLength: 30,
                hintText: widget.hintText,
                validator: widget.validator ??
                        (value) {
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
          ),
          DialogWidgets.buildActions(
            context: context,
            onCancel: () => Navigator.of(context).pop(),
            onSave: () {
              if (!_formKey.currentState!.validate()) return;
              setState(() => _isLoading = true);
              final customValue = _controller.text.trim();
              Future.delayed(const Duration(milliseconds: 500), () {
                widget.onSave(customValue);
                Navigator.of(context).pop();
              });
            },
            saveButtonText: 'Add Custom',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}