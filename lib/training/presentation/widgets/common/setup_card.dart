// lib/training/presentation/widgets/common/setup_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SetupCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String value;
  final bool isCompleted;
  final bool isRequired;
  final VoidCallback onTap;

  const SetupCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.isCompleted,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isCompleted
                ? AppTheme.success(context).withOpacity(0.5)
                : isRequired
                ? AppTheme.error(context).withOpacity(0.5)
                : AppTheme.border(context).withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  icon,
                  style: TextStyle(
                    fontSize: 22,
                    color: AppTheme.primary(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.titleMedium(context).copyWith(
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.success(context),
                              size: 18,
                            )
                          else if (isRequired)
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.textSecondary(context),
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTheme.bodySmall(context).copyWith(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: AppTheme.inputDecoration(context),
              child: Text(
                value,
                style: AppTheme.bodyMedium(context).copyWith(
                  color: AppTheme.primary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}