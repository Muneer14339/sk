// lib/armory/presentation/widgets/item_cards/ammunition_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class AmmunitionItemCard extends StatelessWidget {
  final ArmoryAmmunition ammunition;
  final String userId;
  final bool showDelete;  // ADD

  const AmmunitionItemCard({super.key, required this.ammunition, required this.userId,this.showDelete = true,});

  @override
  Widget build(BuildContext context) {
    return CommonItemCard(
      item: ammunition,
      title: '${ammunition.brand} ${ammunition.line ?? ''}',
      showDelete: showDelete,  // ADD
      details: [
        CardDetailRow(
          icon: 'assets/icons/armory_icons/caliber.png',
          text: ammunition.caliber,
          badge: '${ammunition.quantity} rds',
        ),
        CardDetailRow(
          icon: 'assets/icons/armory_icons/ammo.png',
          text: ammunition.bullet,
        ),
      ],
      onDelete: showDelete ? () => CommonDialogs.showDeleteDialog(  // ADD condition
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.ammunition,
        itemName: ammunition.brand,
        item: ammunition,
      ) : null,
    );
  }
}