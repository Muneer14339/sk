// lib/user_dashboard/presentation/widgets/loadout_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/armory_loadout.dart';
import '../core/theme/user_app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

class LoadoutItemCard extends StatelessWidget {
  final ArmoryLoadout loadout;
  final String userId;

  const LoadoutItemCard({super.key, required this.loadout, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: loadout,
      child: Container(
        margin: AppSizes.itemMargin,
        padding: AppSizes.itemPadding,
        decoration: AppDecorations.itemCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loadout Name with Delete icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    loadout.name,
                    style: AppTextStyles.itemTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Delete icon - prevent event propagation
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

            // Components summary
            Wrap(
              spacing: 10,
              runSpacing: AppSizes.smallSpacing,
              children: [
                if (loadout.firearmId != null)
                  _buildComponentChip('Firearm', Icons.gps_fixed),
                if (loadout.ammunitionId != null)
                  _buildComponentChip('Ammo', Icons.circle),
                if (loadout.gearIds.isNotEmpty)
                  _buildComponentChip('${loadout.gearIds.length} Gear', Icons.build),
              ],
            ),

            // Notes
            if (loadout.notes?.isNotEmpty == true) ...[
              const SizedBox(height: AppSizes.smallSpacing),
              Text(
                loadout.notes!,
                style: AppTextStyles.itemSubtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComponentChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentBackgroundWithOpacity,
        border: Border.all(color: AppColors.accentBorderWithOpacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.accentText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.badgeText.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}