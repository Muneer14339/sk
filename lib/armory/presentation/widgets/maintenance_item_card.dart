// lib/user_dashboard/presentation/widgets/maintenance_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../domain/entities/armory_maintenance.dart';
import 'common/armory_constants.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

// ===== maintenance_item_card.dart =====
class MaintenanceItemCard extends StatelessWidget {
  final ArmoryMaintenance maintenance;
  final String userId;

  const MaintenanceItemCard({super.key, required this.maintenance, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: maintenance,
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
                    maintenance.maintenanceType,
                    style: AppTheme.titleMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CommonWidgets.buildTag(context, maintenance.assetType),
                GestureDetector(
                  onTap: () {
                    CommonDialogs.showDeleteDialog(
                      context: context,
                      userId: userId,
                      armoryType: ArmoryTabType.maintenence,
                      itemName: maintenance.maintenanceType,
                      item: maintenance,
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
                Text(
                  '${maintenance.date.day}/${maintenance.date.month}/${maintenance.date.year}',
                  style: AppTheme.labelMedium(context),
                ),
                if (maintenance.roundsFired != null && maintenance.roundsFired! > 0)
                  Text(
                    'Rounds: ${maintenance.roundsFired}',
                    style: AppTheme.labelMedium(context),
                  ),
                if (maintenance.notes?.isNotEmpty == true)
                  Flexible(
                    child: Text(
                      maintenance.notes!,
                      style: AppTheme.labelMedium(context),
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