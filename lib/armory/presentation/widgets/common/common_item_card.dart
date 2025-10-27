// lib/armory/presentation/widgets/common/common_item_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'tappable_item_wrapper.dart';

class CommonItemCard extends StatelessWidget {
  final dynamic item;
  final String title;
  final String? subtitle;
  final List<CardDetailRow> details;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const CommonItemCard({
    super.key,
    required this.item,
    required this.title,
    this.subtitle,
    required this.details,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: item,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          border: Border.all(color: AppTheme.border(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium(context).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) const SizedBox(height: 6),
                  ...details,
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.delete_outline,
                  color: AppTheme.error(context),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardDetailRow extends StatelessWidget {
  final String icon;
  final String text;
  final String? badge;
  final String? date;

  const CardDetailRow({
    super.key,
    required this.icon,
    required this.text,
    this.badge,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primary(context),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTheme.labelMedium(context).copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 4),
            Text('•', style: AppTheme.labelMedium(context).copyWith(fontSize: 12, color: AppTheme.textSecondary(context).withOpacity(0.5))),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: AppTheme.labelSmall(context).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary(context),
                ),
              ),
            ),
          ],
          if (date != null) ...[
            const SizedBox(width: 4),
            Text('•', style: AppTheme.labelMedium(context).copyWith(fontSize: 12, color: AppTheme.textSecondary(context).withOpacity(0.5))),
            const SizedBox(width: 4),
            Text(
              date!,
              style: AppTheme.labelMedium(context).copyWith(fontSize: 11, color: AppTheme.textSecondary(context)),
            ),
          ],
        ],
      ),
    );
  }
}