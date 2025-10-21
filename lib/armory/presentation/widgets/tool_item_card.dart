// lib/user_dashboard/presentation/widgets/tool_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/armory_tool.dart';
import '../core/theme/user_app_theme.dart';
import 'common/common_delete_dilogue.dart';
import 'common/common_widgets.dart';
import 'common/tappable_item_wrapper.dart';
import '../bloc/armory_bloc.dart';

class ToolItemCard extends StatelessWidget {
  final ArmoryTool tool;
  final String userId;

  const ToolItemCard({super.key, required this.tool, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: tool,
      child: Container(
        margin: AppSizes.itemMargin,
        padding: AppSizes.itemPadding,
        decoration: AppDecorations.itemCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tool.name,
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
                      armoryType: ArmoryTabType.tools,
                      itemName: tool.name,
                      item: tool,
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
            Wrap(
              spacing: 10,
              runSpacing: AppSizes.smallSpacing,
              children: [
                Text(
                  'Qty: ${tool.quantity}',
                  style: AppTextStyles.itemSubtitle,
                ),
                if (tool.category?.isNotEmpty == true)
                  Text(
                    'Category: ${tool.category}',
                    style: AppTextStyles.itemSubtitle,
                  ),
                CommonWidgets.buildStatusChip(tool.status),
                if (tool.notes?.isNotEmpty == true)
                  Flexible(
                    child: Text(
                      tool.notes!,
                      style: AppTextStyles.itemSubtitle,
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