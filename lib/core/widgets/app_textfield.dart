import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required TextEditingController controller,
    this.label,
    this.validator,
    this.obscureText,
    this.readOnly,
    this.onTap,
    this.prefixIcon,
    this.fillColor,
    this.suffixIcon,
  }) : _controller = controller;

  final TextEditingController _controller;
  final String? label;
  final String? Function(String?)? validator;
  final bool? obscureText;
  final bool? readOnly;
  final void Function()? onTap;
  final Widget? prefixIcon;
  final Color? fillColor;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      obscureText: obscureText ?? false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF6B35),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: fillColor ?? Colors.white.withValues(alpha: 0.05),
      ),
      validator: validator,
      readOnly: readOnly ?? false,
      onTap: onTap,
    );
  }
}
