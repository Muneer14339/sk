import 'package:flutter/material.dart';

import 'custom_textfield.dart';

class DropdownCustom extends StatefulWidget {
  final String hint;
  final String? selectedValue;
  final VoidCallback onTap;
  final bool dropDownOpen;
  final bool? noPadding;
  final TextEditingController controller;

  const DropdownCustom({
    super.key,
    this.selectedValue,
    this.noPadding,
    required this.hint,
    required this.onTap,
    required this.controller,
    required this.dropDownOpen,
  });

  @override
  State<DropdownCustom> createState() => _DropdownCustomState();
}

class _DropdownCustomState extends State<DropdownCustom> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: widget.noPadding == true ? 0 : 24),
      child: InkWell(
        onTap: () {
          widget.onTap();
          // context.read<TextFieldCubit>().validate(widget.controller.text);
        },
        child: CustomTextField(
          controller: widget.controller,
          hintText: 'Select ${widget.hint}',
          isReadOnly: true,
          onTap: widget.onTap,
          suffixIcon:
              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
        ),
      ),
    );
  }
}
