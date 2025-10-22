import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'armory_constants.dart';


// ===== inline_form_wrapper.dart =====
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
        Container(
          padding: const EdgeInsets.all(ArmoryConstants.dialogPadding),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border(context))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTheme.titleLarge(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary(context).withOpacity(0.1),
                          border: Border.all(color: AppTheme.primary(context).withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(ArmoryConstants.badgeBorderRadius),
                        ),
                        child: Text(
                          badge!,
                          style: AppTheme.labelMedium(context).copyWith(
                            color: AppTheme.primary(context),
                          ),
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
        child,
      ],
    );
  }
}