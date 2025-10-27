// lib/training/presentation/widgets/common/gradient_header.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GradientHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const GradientHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary(context), AppTheme.secondary(context)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.headingLarge(context).copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTheme.bodyLarge(context).copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}