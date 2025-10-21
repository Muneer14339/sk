import 'package:flutter/material.dart';
import '../../core/theme/user_app_theme.dart';

class InlineFormWrapper extends StatelessWidget {
  final String title;
  final String? badge;
  final VoidCallback onCancel;
  final Widget child;

  const InlineFormWrapper({
    super.key,
    required this.title,
    this.badge,
    required this.onCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSizes.dialogPadding),
          decoration: AppDecorations.headerBorderDecoration,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: AppDecorations.accentBadgeDecoration,
                        child: Text(
                          badge!,
                          style: AppTextStyles.badgeText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Form content
        child,
      ],
    );
  }
}