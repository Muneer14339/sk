// lib/armory/presentation/widgets/item_cards/firearm_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class FirearmItemCard extends StatelessWidget {
  final ArmoryFirearm firearm;
  final String userId;

  const FirearmItemCard({super.key, required this.firearm, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CommonItemCard(
      item: firearm,
      title: '${firearm.make} ${firearm.model}',
      details: [
        CardDetailRow(
          icon: 'assets/icons/armory_icons/firearm.png',
          text: firearm.caliber,
        ),
        if (firearm.nickname.isNotEmpty)
          CardDetailRow(
            icon: 'assets/icons/armory_icons/nickName.png',
            text: firearm.nickname,
          ),
      ],
      onDelete: () => CommonDialogs.showDeleteDialog(
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.firearms,
        itemName: '${firearm.make} ${firearm.model}',
        item: firearm,
      ),
    );
  }
}