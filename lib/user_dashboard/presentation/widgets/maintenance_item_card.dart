// lib/user_dashboard/presentation/widgets/maintenance_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../core/theme/user_app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

class MaintenanceItemCard extends StatelessWidget {
  final ArmoryMaintenance maintenance;
  final String userId;

  const MaintenanceItemCard({super.key, required this.maintenance, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: maintenance,
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
                    maintenance.maintenanceType,
                    style: AppTextStyles.itemTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CommonWidgets.buildTag(maintenance.assetType),
                // Delete icon - prevent event propagation
                GestureDetector(
                  onTap: () {
                    CommonDialogs.showDeleteDialog(
                      context: context,
                      userId: userId,
                      armoryType: ArmoryTabType.maintenance,
                      itemName: maintenance.maintenanceType,
                      item: maintenance,
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
                Text(
                  '${maintenance.date.day}/${maintenance.date.month}/${maintenance.date.year}',
                  style: AppTextStyles.itemSubtitle,
                ),
                if (maintenance.roundsFired != null && maintenance.roundsFired! > 0)
                  Text(
                    'Rounds: ${maintenance.roundsFired}',
                    style: AppTextStyles.itemSubtitle,
                  ),
                if (maintenance.notes?.isNotEmpty == true)
                  Flexible(
                    child: Text(
                      maintenance.notes!,
                      style: AppTextStyles.itemSubtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}