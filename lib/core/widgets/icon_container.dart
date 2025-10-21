import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class IconContainer extends StatelessWidget {
  const IconContainer({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? AppColors.kPrimaryTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: AppColors.kPrimaryTeal,
        size: 18,
      ),
    );
  }
}
