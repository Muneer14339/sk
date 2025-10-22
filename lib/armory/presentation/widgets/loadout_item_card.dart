// lib/user_dashboard/presentation/widgets/loadout_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../domain/entities/armory_loadout.dart';
import 'common/armory_constants.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

// ===== loadout_item_card.dart =====
class LoadoutItemCard extends StatelessWidget {
  final ArmoryLoadout loadout;
  final String userId;

  const LoadoutItemCard({super.key, required this.loadout, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: loadout,
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
                    loadout.name,
                    style: AppTheme.titleMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    CommonDialogs.showDeleteDialog(
                      context: context,
                      userId: userId,
                      armoryType: ArmoryTabType.loadouts,
                      itemName: loadout.name,
                      item: loadout,
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
                if (loadout.firearmId != null)
                  _buildComponentChip(context, 'Firearm', Icons.gps_fixed),
                if (loadout.ammunitionId != null)
                  _buildComponentChip(context, 'Ammo', Icons.circle),
                if (loadout.gearIds.isNotEmpty)
                  _buildComponentChip(context, '${loadout.gearIds.length} Gear', Icons.build),
              ],
            ),
            if (loadout.notes?.isNotEmpty == true) ...[
              const SizedBox(height: ArmoryConstants.smallSpacing),
              Text(
                loadout.notes!,
                style: AppTheme.labelMedium(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComponentChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary(context).withOpacity(0.1),
        border: Border.all(color: AppTheme.primary(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.primary(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.labelMedium(context).copyWith(
              fontSize: 10,
              color: AppTheme.primary(context),
            ),
          ),
        ],
      ),
    );
  }
}