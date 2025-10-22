// ===== COMPLETE IMPLEMENTATION GUIDE =====
// All files use AppTheme from core/theme/app_theme.dart
// Import pattern: import '../../../../core/theme/app_theme.dart';
// Import pattern: import 'common/armory_constants.dart';

// ===== ammunition_item_card.dart =====
import 'package:flutter/material.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../../core/theme/app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/item_details_dialog.dart';
import 'common/tappable_item_wrapper.dart';
import 'common/armory_constants.dart';

class AmmunitionItemCard extends StatelessWidget {
  final ArmoryAmmunition ammunition;
  final String userId;

  const AmmunitionItemCard({super.key, required this.ammunition, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: ammunition,
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
                    '${ammunition.brand} ${ammunition.line ?? ''}',
                    style: AppTheme.titleMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CommonWidgets.buildTag(context, ammunition.caliber),
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
                if (ammunition.lot?.isNotEmpty == true)
                  Text(
                    'Lot: ${ammunition.lot}',
                    style: AppTheme.labelMedium(context),
                  ),
                Text(
                  'Qty: ${ammunition.quantity} rds',
                  style: AppTheme.labelMedium(context),
                ),
                CommonWidgets.buildStatusChip(context, ammunition.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

















// ===== PATTERN FOR FORMS =====
// All forms use DialogWidgets methods
// Example: DialogWidgets.buildTextField(), DialogWidgets.buildDropdownField()
// All use AppTheme.method(context) for styling
// All use ArmoryConstants for sizes/spacing

// ===== NOTES =====
// 1. Replace all AppColors with AppTheme.method(context)
// 2. Replace all AppTextStyles with AppTheme.method(context)
// 3. Replace all AppSizes/AppBreakpoints with ArmoryConstants
// 4. Replace all AppDecorations with BoxDecoration using AppTheme
// 5. Merge dialog_widgets.dart, enhanced_dialog_widgets.dart, common_dialog_widgets.dart into single dialog_widgets.dart
// 6. All functionality remains 100% same