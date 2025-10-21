// lib/user_dashboard/presentation/widgets/gear_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/armory_gear.dart';
import '../core/theme/user_app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

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
        padding: AppSizes.itemPadding,
        decoration: AppDecorations.itemCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    gear.model,
                    style: AppTextStyles.itemTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: AppSizes.itemSpacing),
                CommonWidgets.buildTag(gear.category),
                // Delete icon - prevent event propagation
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
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.errorColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.smallSpacing),
            Wrap(
              spacing: 10,
              runSpacing: AppSizes.smallSpacing,
              children: [
                if (gear.serial?.isNotEmpty == true)
                  Text(
                    'SN: ${gear.serial}',
                    style: AppTextStyles.itemSubtitle,
                  ),
                Text(
                  'Qty: ${gear.quantity}',
                  style: AppTextStyles.itemSubtitle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}