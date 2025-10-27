// lib/training/presentation/widgets/common/info_divider.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InfoDivider extends StatelessWidget {
  const InfoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.border(context).withOpacity(0.2),
    );
  }
}