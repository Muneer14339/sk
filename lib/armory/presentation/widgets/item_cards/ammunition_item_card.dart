// lib/armory/presentation/widgets/item_cards/ammunition_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class AmmunitionItemCard extends StatelessWidget {
  final ArmoryAmmunition ammunition;
  final String userId;

  const AmmunitionItemCard({super.key, required this.ammunition, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CommonItemCard(
      item: ammunition,
      title: '${ammunition.brand} ${ammunition.line ?? ''}',
      details: [
        CardDetailRow(
          icon: '🔫',
          text: ammunition.caliber,
          badge: '${ammunition.quantity} rds',
        ),
        CardDetailRow(
          icon: '💣',
          text: ammunition.bullet,
        ),
      ],
      onDelete: () => CommonDialogs.showDeleteDialog(
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.ammunition,
        itemName: '${ammunition.brand} ${ammunition.line ?? ''}',
        item: ammunition,
      ),
    );
  }
}