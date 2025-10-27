// lib/armory/presentation/widgets/item_cards/maintenance_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class MaintenanceItemCard extends StatelessWidget {
  final ArmoryMaintenance maintenance;
  final String userId;

  const MaintenanceItemCard({super.key, required this.maintenance, required this.userId});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${maintenance.date.day}/${maintenance.date.month}/${maintenance.date.year}';

    return CommonItemCard(
      item: maintenance,
      title: maintenance.maintenanceType,
      details: [
        CardDetailRow(
          icon: 'assets/icons/armory_icons/maintenence_asset_type.png',
          text: maintenance.assetType,
          date: dateStr,
        ),
        if (maintenance.roundsFired != null && maintenance.roundsFired! > 0)
          CardDetailRow(
            icon: 'assets/icons/armory_icons/ammo.png',
            text: 'Rounds: ${maintenance.roundsFired}',
          ),
      ],
      onDelete: () => CommonDialogs.showDeleteDialog(
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.maintenence,
        itemName: maintenance.maintenanceType,
        item: maintenance,
      ),
    );
  }
}