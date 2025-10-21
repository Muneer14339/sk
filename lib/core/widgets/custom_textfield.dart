import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final int? maxLength;
  final TextEditingController controller;
  final bool isRequired;
  final bool? isShots;
  final bool? isReadOnly;
  final ValueChanged<String>? onChanged;
  final void Function()? onTap;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    this.hintText,
    required this.controller,
    this.isRequired = false,
    this.isReadOnly = false,
    this.maxLines,
    this.maxLength,
    this.isShots,
    this.keyboardType,
    this.onChanged,
    this.labelText,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        // initialValue: initialValue,
        keyboardType: keyboardType,
        inputFormatters: (isShots != null && true)
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ]
            : null,
        controller: controller,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Required field';
                }
                return null;
              }
            : null,
        maxLines: maxLines ?? 1,
        maxLength: maxLength,
        style: Theme.of(context).textTheme.bodyLarge,
        // TextStyle(
        //     color: AppColors.black,
        //     fontSize: 14,
        //     fontFamily: AppFontFamily.regular),
        onChanged: onChanged,
        onTap: onTap,
        readOnly: isReadOnly ?? false,
        decoration: InputDecoration(
          counterText: '',
          alignLabelWithHint: true,
          suffixIcon: suffixIcon,
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.greyTextColor,
            fontSize: 14,
          ),
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppColors.greyTextColor,
            fontSize: 14,
          ),
        ));
  }
}
