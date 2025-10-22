import 'package:flutter/material.dart';

import '../theme/app_theme.dart';


class IconContainer extends StatelessWidget {
  const IconContainer({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color ?? AppTheme.primary(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: AppTheme.primary(context),
        size: 18,
      ),
    );
  }
}
