// lib/training/presentation/widgets/common/info_row.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool showArrow;
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium(context).copyWith(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: AppTheme.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppTheme.textPrimary(context),
                  fontSize: 12,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppTheme.textSecondary(context)),
              ],
            ],
          ),
        ],
      ),
    );

    return onTap != null
        ? InkWell(onTap: onTap, child: content)
        : content;
  }
}