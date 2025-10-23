// lib/user_dashboard/presentation/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'armory_constants.dart';

// ===== empty_state_widget.dart =====
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
      padding: ArmoryConstants.cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: AppTheme.textSecondary(context),
              size: ArmoryConstants.largeIcon,
            ),
            const SizedBox(height: ArmoryConstants.itemSpacing),
          ],
          Text(
            message,
            style: AppTheme.bodySmall(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}