// lib/user_dashboard/presentation/widgets/gear_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../domain/entities/armory_gear.dart';
import 'common/armory_constants.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

// ===== gear_item_card.dart =====
class GearItemCard extends StatelessWidget {
  final ArmoryGear gear;
  final String userId;

  const GearItemCard({super.key, required this.gear, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: gear,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: ArmoryConstants.itemPadding,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant(context),
          border: Border.all(color: AppTheme.border(context)),
          borderRadius: BorderRadius.circular(ArmoryConstants.itemCardBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gear.model,
                    style: AppTheme.titleMedium(context),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: ArmoryConstants.itemSpacing),
                CommonWidgets.buildTag(context, gear.category),
                GestureDetector(
                  onTap: () {
                    CommonDialogs.showDeleteDialog(
                      context: context,
                      userId: userId,
                      armoryType: ArmoryTabType.gear,
                      itemName: gear.model,
                      item: gear,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppTheme.error(context),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ArmoryConstants.smallSpacing),
            Wrap(
              spacing: 10,
              runSpacing: ArmoryConstants.smallSpacing,
              children: [
                if (gear.serial?.isNotEmpty == true)
                  Text(
                    'SN: ${gear.serial}',
                    style: AppTheme.labelMedium(context),
                  ),
                Text(
                  'Qty: ${gear.quantity}',
                  style: AppTheme.labelMedium(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
