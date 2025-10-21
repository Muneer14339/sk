// lib/user_dashboard/presentation/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

import '../core/theme/user_app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSizes.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppColors.secondaryText,
              size: AppSizes.largeIcon,
            ),
            const SizedBox(height: AppSizes.itemSpacing),
          ],
          Text(
            message,
            style: AppTextStyles.emptyStateText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
