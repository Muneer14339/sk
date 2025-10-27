import 'package:flutter/material.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class LoadoutItemCard extends StatelessWidget {
  final ArmoryLoadout loadout;
  final ArmoryFirearm? firearm;
  final ArmoryAmmunition? ammunition;
  final String userId;

  const LoadoutItemCard({
    super.key,
    required this.loadout,
    this.firearm,
    this.ammunition,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${loadout.dateAdded.day}/${loadout.dateAdded.month}/${loadout.dateAdded.year}';

    return CommonItemCard(
      item: loadout,
      title: loadout.name,
      firearm: firearm,
      ammunition: ammunition,
      details: [
        if (firearm != null)
          CardDetailRow(
            icon: 'assets/icons/armory_icons/firearm.png',
            text: '${firearm!.make} ${firearm!.model}',
          ),
        if (ammunition != null)
          CardDetailRow(
            icon: 'assets/icons/armory_icons/ammo.png',
            text: '${ammunition!.caliber} ${ammunition!.bullet}',
            badge: '${ammunition!.quantity} rds',
            date: dateStr,
          ),
      ],
      onDelete: () => CommonDialogs.showDeleteDialog(
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.loadouts,
        itemName: loadout.name,
        item: loadout,
      ),
    );
  }
}