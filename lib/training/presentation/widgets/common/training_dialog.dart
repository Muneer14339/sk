// lib/training/presentation/widgets/common/training_dialog.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrainingDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const TrainingDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        side: BorderSide(color: AppTheme.border(context), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppTheme.paddingLarge,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTheme.headingMedium(context)),
                ),
                if (showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textPrimary(context)),
                  ),
              ],
            ),
          ),
          Flexible(child: content),
          if (actions != null)
            Container(
              padding: AppTheme.paddingLarge,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border(context))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}