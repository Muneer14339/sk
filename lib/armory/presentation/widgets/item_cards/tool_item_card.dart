// lib/armory/presentation/widgets/item_cards/tool_item_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_tool.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class ToolItemCard extends StatelessWidget {
  final ArmoryTool tool;
  final String userId;

  const ToolItemCard({super.key, required this.tool, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CommonItemCard(
      item: tool,
      title: tool.name,
      details: [
        CardDetailRow(
          icon: '🔧',
          text: tool.category ?? '',
          badge: 'Qty: ${tool.quantity}',
        ),
      ],
      onDelete: () => CommonDialogs.showDeleteDialog(
        context: context,
        userId: userId,
        armoryType: ArmoryTabType.tools,
        itemName: tool.name,
        item: tool,
      ),
    );
  }
}