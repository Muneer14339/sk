// lib/training/presentation/widgets/common/training_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrainingCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets? padding;

  const TrainingCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: padding ?? AppTheme.paddingXLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTheme.headingSmall(context)),
            const SizedBox(height: AppTheme.spacingLarge),
          ],
          child,
        ],
      ),
    );
  }
}

class TrainingInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showArrow;
  final VoidCallback? onTap;

  const TrainingInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textSecondary(context))),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTheme.titleMedium(context).copyWith(
                    color: valueColor ?? AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary(context)),
              ],
            ],
          ),
        ],
      ),
    );

    return onTap != null
        ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppTheme.radiusSmall), child: row)
        : row;
  }
}

class TrainingDivider extends StatelessWidget {
  const TrainingDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(color: AppTheme.border(context), thickness: 1, height: 1);
  }
}