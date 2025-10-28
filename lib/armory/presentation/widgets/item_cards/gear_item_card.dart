// lib/armory/presentation/widgets/item_cards/gear_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_gear.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class GearItemCard extends StatelessWidget {
  final ArmoryGear gear;
  final String userId;
  final bool showDelete;  // ADD

  const GearItemCard({super.key, required this.gear, required this.userId,this.showDelete = true,});

  @override
  Widget build(BuildContext context) {
    return CommonItemCard(
      item: gear,
      title: gear.model,
      showDelete: showDelete,  // ADD
      details: [
        CardDetailRow(
          icon: 'assets/icons/armory_icons/gear_category.png',
          text: gear.category,
          badge: 'Qty: ${gear.quantity}',
        ),
      ],
      onDelete: showDelete ? () => CommonDialogs.showDeleteDialog(  // ADD condition
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.gear,
        itemName: gear.model,
        item: gear,
      ) : null,
    );
  }
}