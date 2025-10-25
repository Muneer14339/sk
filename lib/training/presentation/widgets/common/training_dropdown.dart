// lib/training/presentation/widgets/common/training_dropdown.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrainingDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const TrainingDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelLarge(context).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: AppTheme.inputDecoration(context),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: AppTheme.bodyMedium(context)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}