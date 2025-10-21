// lib/user_dashboard/presentation/widgets/firearm_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/armory_firearm.dart';
import '../core/theme/user_app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

class FirearmItemCard extends StatelessWidget {
  final ArmoryFirearm firearm;
  final String userId;

  const FirearmItemCard({super.key, required this.firearm, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: firearm,
      child: Container(
        margin: AppSizes.itemMargin,
        padding: AppSizes.itemPadding,
        decoration: AppDecorations.itemCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${firearm.make} ${firearm.model}',
                    style: AppTextStyles.itemTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CommonWidgets.buildTag(firearm.caliber),
                // Delete icon - prevent event propagation
                GestureDetector(
                  onTap: () {
                    // Stop event propagation to parent InkWell
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
                if (firearm.nickname.isNotEmpty)
                  Text(
                    '"${firearm.nickname}"',
                    style: AppTextStyles.itemSubtitle,
                  ),
                CommonWidgets.buildStatusChip(firearm.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}