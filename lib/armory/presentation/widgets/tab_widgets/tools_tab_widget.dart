import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../../../domain/entities/armory_tool.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_maintenance_form.dart';
import '../add_forms/add_tool_form.dart';
import '../common/armory_constants.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/inline_form_wrapper.dart';
import '../common/responsive_grid_widget.dart';
import '../common/empty_state_widget.dart';
import '../item_cards/maintenance_item_card.dart';
import '../item_cards/tool_item_card.dart';

class ToolsTabWidget extends StatelessWidget {
  final String userId;

  const ToolsTabWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArmoryBloc, ArmoryState>(
      builder: (context, state) {
        if (state is ShowingAddForm) {
          if (state.tabType == ArmoryTabType.tools) {
            return InlineFormWrapper(
              title: 'Add Tool',
              onCancel: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
              child: AddToolForm(userId: userId),
            );
          } else if (state.tabType == ArmoryTabType.maintenence) {
            return InlineFormWrapper(
              title: 'Log Maintenance',
              onCancel: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
              child: AddMaintenanceForm(userId: userId),
            );
          }
        }

        return _buildCard(context, state);
      },
    );
  }

  Widget _buildCard(BuildContext context, ArmoryState state) {
    return Container(
      margin: ArmoryConstants.cardMargin,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(ArmoryConstants.cardBorderRadius),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          Padding(
            padding: ArmoryConstants.cardPadding,
            child: _buildContent(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ArmoryState state) {
    final totalItems = state is ArmoryDataLoaded ? (state.tools.length + state.maintenance.length) : 0;

    return Container(
      padding: ArmoryConstants.cardPadding,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('Tools & Maintenance', style: AppTheme.titleLarge(context), overflow: TextOverflow.ellipsis),
                    ),
                    if (totalItems > 0) ...[
                      const SizedBox(width: 8),
                      CommonWidgets.buildCountBadge(context, totalItems, 'items'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('Cleaning kits, torque tools, chronographs — plus per-asset maintenance logs.', style: AppTheme.labelMedium(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context.read<ArmoryBloc>().add(const ShowAddFormEvent(tabType: ArmoryTabType.tools)),
            icon: const Icon(Icons.add, size: ArmoryConstants.smallIcon),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ArmoryState state) {
    if (state is ArmoryLoading) {
      return CommonWidgets.buildLoading(message: 'Loading tools & maintenance...');
    }

    if (state is ArmoryDataLoaded) {
      if (state.tools.isEmpty && state.maintenance.isEmpty) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CommonWidgets.buildActionButton(
                    context: context,
                    label: 'Log Maintenance',
                    onPressed: () => context.read<ArmoryBloc>().add(const ShowAddFormEvent(tabType: ArmoryTabType.maintenence)),
                    icon: Icons.build_circle_outlined,
                  ),
                ],
              ),
            ),
            const EmptyStateWidget(message: 'No tools or maintenance logs yet.', icon: Icons.add_circle_outline),
          ],
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CommonWidgets.buildActionButton(
                  context: context,
                  label: 'Log Maintenance',
                  onPressed: () => context.read<ArmoryBloc>().add(const ShowAddFormEvent(tabType: ArmoryTabType.maintenence)),
                  icon: Icons.build_circle_outlined,
                ),
              ],
            ),
          ),
          _buildToolsSection(context, state.tools),
          _buildMaintenanceSection(context, state.maintenance),
        ],
      );
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    return const EmptyStateWidget(message: 'No tools or maintenance logs yet.', icon: Icons.add_circle_outline);
  }

  Widget _buildToolsSection(BuildContext context, List<ArmoryTool> tools) {
    final toolCards = tools.map((tool) => ToolItemCard(tool: tool, userId: userId)).toList();

    return CommonWidgets.buildExpandableSection(
      context: context,
      title: 'Tools & Equipment',
      subtitle: 'cleaning kits, torque wrenches, chronographs',
      initiallyExpanded: tools.isNotEmpty,
      children: [ResponsiveGridWidget(children: toolCards)],
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, List<ArmoryMaintenance> maintenance) {
    final maintenanceCards = maintenance.map((m) => MaintenanceItemCard(maintenance: m, userId: userId)).toList();

    return CommonWidgets.buildExpandableSection(
      context: context,
      title: 'Maintenance Logs',
      subtitle: 'cleaning, lubrication, repairs, inspections',
      initiallyExpanded: maintenance.isNotEmpty,
      children: [ResponsiveGridWidget(children: maintenanceCards)],
    );
  }
}