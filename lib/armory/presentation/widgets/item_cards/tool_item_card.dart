// lib/user_dashboard/presentation/widgets/tool_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_tool.dart';
import '../common/armory_constants.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/tappable_item_wrapper.dart';
import '../../bloc/armory_bloc.dart';

// ===== tool_item_card.dart =====
class ToolItemCard extends StatelessWidget {
  final ArmoryTool tool;
  final String userId;

  const ToolItemCard({super.key, required this.tool, required this.userId});

  @override
  Widget build(BuildContext context) {
    return TappableItemWrapper(
      item: tool,
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
                    tool.name,
                    style: AppTheme.titleMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                Text(
                  'Qty: ${tool.quantity}',
                  style: AppTheme.labelMedium(context),
                ),
                if (tool.category?.isNotEmpty == true)
                  Text(
                    'Category: ${tool.category}',
                    style: AppTheme.labelMedium(context),
                  ),
                CommonWidgets.buildStatusChip(context, tool.status),
                if (tool.notes?.isNotEmpty == true)
                  Flexible(
                    child: Text(
                      tool.notes!,
                      style: AppTheme.labelMedium(context),
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