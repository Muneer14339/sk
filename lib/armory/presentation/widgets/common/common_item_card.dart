import 'package:flutter/material.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../../core/theme/app_theme.dart';
import 'tappable_item_wrapper.dart';

// lib/armory/presentation/widgets/common/common_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../../core/theme/app_theme.dart';
import 'tappable_item_wrapper.dart';

class CommonItemCard extends StatelessWidget {
  final dynamic item;
  final String title;
  final String? subtitle;
  final List<CardDetailRow> details;
  final VoidCallback? onDelete;  // Make nullable
  final VoidCallback? onTap;
  final ArmoryFirearm? firearm;
  final ArmoryAmmunition? ammunition;
  final bool showDelete;  // ADD

  const CommonItemCard({
    super.key,
    required this.item,
    required this.title,
    this.subtitle,
    required this.details,
    this.onDelete,  // Make optional
    this.onTap,
    this.firearm,
    this.ammunition,
    this.showDelete = true,  // ADD - default true
  });

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: item,
      onTap: onTap,
      firearm: firearm,
      ammunition: ammunition,
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
            if (showDelete && onDelete != null) ...[  // ADD condition
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
          ],
        ),
      ),
    );
  }
}

// Rest remains same...
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
          Image.asset(
            icon,
            color: AppTheme.primary(context),
            width: 28,
            height: 28,
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