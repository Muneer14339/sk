// lib/user_dashboard/presentation/widgets/firearm_item_card.dart
import 'package:flutter/material.dart';
import '../../domain/entities/armory_firearm.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';

import '../../../core/theme/app_theme.dart';
import 'common/armory_constants.dart';

class FirearmItemCard extends StatelessWidget {
  final ArmoryFirearm firearm;
  final String userId;

  const FirearmItemCard({super.key, required this.firearm, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: firearm,
      child: Container(
        margin: ArmoryConstants.itemMargin,
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
                    '${firearm.make} ${firearm.model}',
                    style: AppTheme.titleMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CommonWidgets.buildTag(context, firearm.caliber),
                GestureDetector(
                  onTap: () {
                    CommonDialogs.showDeleteDialog(
                      context: context,
                      userId: userId,
                      armoryType: ArmoryTabType.firearms,
                      itemName: '${firearm.make} ${firearm.model}',
                      item: firearm,
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
                if (firearm.nickname.isNotEmpty)
                  Text(
                    '"${firearm.nickname}"',
                    style: AppTheme.labelMedium(context),
                  ),
                CommonWidgets.buildStatusChip(context, firearm.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}