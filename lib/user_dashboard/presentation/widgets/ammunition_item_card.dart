// lib/user_dashboard/presentation/widgets/ammunition_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../core/theme/user_app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

class AmmunitionItemCard extends StatelessWidget {
  final ArmoryAmmunition ammunition;
  final String userId;

  const AmmunitionItemCard({super.key, required this.ammunition, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: ammunition,
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
                    '${ammunition.brand} ${ammunition.line ?? ''}',
                    style: AppTextStyles.itemTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CommonWidgets.buildTag(ammunition.caliber),
                // Delete icon - prevent event propagation
                GestureDetector(
                  onTap: () {
                    CommonDialogs.showDeleteDialog(
                      context: context,
                      userId: userId,
                      armoryType: ArmoryTabType.ammunition,
                      itemName: '${ammunition.brand} ${ammunition.line ?? ''}',
                      item: ammunition,
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
                if (ammunition.lot?.isNotEmpty == true)
                  Text(
                    'Lot: ${ammunition.lot}',
                    style: AppTextStyles.itemSubtitle,
                  ),
                Text(
                  'Qty: ${ammunition.quantity} rds',
                  style: AppTextStyles.itemSubtitle,
                ),
                CommonWidgets.buildStatusChip(ammunition.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}