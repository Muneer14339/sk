// lib/user_dashboard/presentation/widgets/tab_widgets/tools_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/armory_maintenance.dart';
import '../../../domain/entities/armory_tool.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
import '../add_forms/add_maintenance_form.dart';
import '../add_forms/add_tool_form.dart';
import '../common/common_widgets.dart';
import '../common/inline_form_wrapper.dart';
import '../common/responsive_grid_widget.dart';
import '../empty_state_widget.dart';
import '../maintenance_item_card.dart';
import '../tool_item_card.dart';
import 'armory_tab_view.dart';

class ToolsTabWidget extends StatefulWidget {
  final String userId;

  const ToolsTabWidget({super.key, required this.userId});

  @override
  State<ToolsTabWidget> createState() => _ToolsTabWidgetState();
}

class _ToolsTabWidgetState extends State<ToolsTabWidget> {
  List<ArmoryTool> _tools = [];
  List<ArmoryMaintenance> _maintenance = [];

  // Cache lists
  List<ArmoryTool> _cachedTools = [];
  List<ArmoryMaintenance> _cachedMaintenance = [];

  bool _showingToolForm = false;
  bool _showingMaintenanceForm = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ArmoryBloc>().add(LoadMaintenanceEvent(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        // Update local data and cache
        if (state is ToolsLoaded) {
          setState(() {
            _tools = state.tools;
            if (_tools.isNotEmpty) _cachedTools = List.from(_tools);
          });
        } else if (state is MaintenanceLoaded) {
          setState(() {
            _maintenance = state.maintenance;
            if (_maintenance.isNotEmpty) {
              _cachedMaintenance = List.from(_maintenance);
            }
          });
        }

        // Handle form visibility
        else if (state is ShowingAddForm) {
          if (state.tabType == ArmoryTabType.tools) {
            setState(() {
              _showingToolForm = true;
              _showingMaintenanceForm = false;
            });
          } else if (state.tabType == ArmoryTabType.maintenence) {
            setState(() {
              _showingToolForm = false;
              _showingMaintenanceForm = true;
            });
          }
        }

        // Hide forms on success/cancel
        else if (state is ArmoryActionSuccess || state is ArmoryInitial) {
          setState(() {
            _showingToolForm = false;
            _showingMaintenanceForm = false;
          });

          if (state is ArmoryActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.successColor,
              ),
            );
          }
        }

        // Show errors
        else if (state is ArmoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        if (_showingToolForm) {
          return InlineFormWrapper(
            title: 'Add Tool',
            onCancel: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
            child: AddToolForm(userId: widget.userId),
          );
        }

        if (_showingMaintenanceForm) {
          return InlineFormWrapper(
            title: 'Log Maintenance',
            onCancel: () => context.read<ArmoryBloc>().add(const HideFormEvent()),
            child: AddMaintenanceForm(userId: widget.userId),
          );
        }

        return _buildCard(state);
      },
    );
  }

  Widget _buildCard(ArmoryState state) {
    return Container(
      margin: AppSizes.cardMargin,
      decoration: AppDecorations.mainCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: AppSizes.cardPadding,
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalItems = _tools.length + _maintenance.length;
    final cachedCount = _cachedTools.length + _cachedMaintenance.length;

    return Container(
      padding: AppSizes.cardPadding,
      decoration: AppDecorations.headerBorderDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Tools & Maintenance',
                        style: AppTextStyles.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((totalItems > 0 || cachedCount > 0)) ...[
                      const SizedBox(width: 8),
                      CommonWidgets.buildCountBadge(
                          totalItems > 0 ? totalItems : cachedCount, 'items'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cleaning kits, torque tools, chronographs — plus per-asset maintenance logs.',
                  style: AppTextStyles.cardDescription,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => context
                .read<ArmoryBloc>()
                .add(const ShowAddFormEvent(tabType: ArmoryTabType.tools)),
            icon: const Icon(Icons.add, size: AppSizes.smallIcon),
            label: const Text('Add'),
            style: AppButtonStyles.addButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ArmoryState state) {
    final tools = _tools.isNotEmpty ? _tools : _cachedTools;
    final maintenance = _maintenance.isNotEmpty ? _maintenance : _cachedMaintenance;

    if (state is ArmoryLoading && tools.isEmpty && maintenance.isEmpty) {
      return CommonWidgets.buildLoading(message: 'Loading tools & maintenance...');
    }

    if (tools.isEmpty && maintenance.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CommonWidgets.buildActionButton(
                  label: 'Log Maintenance',
                  onPressed: () => context
                      .read<ArmoryBloc>()
                      .add(const ShowAddFormEvent(tabType: ArmoryTabType.maintenence)),
                  icon: Icons.build_circle_outlined,
                ),
              ],
            ),
          ),
          const EmptyStateWidget(
            message: 'No tools or maintenance logs yet.',
            icon: Icons.add_circle_outline,
          ),
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
                label: 'Log Maintenance',
                onPressed: () => context
                    .read<ArmoryBloc>()
                    .add(const ShowAddFormEvent(tabType: ArmoryTabType.maintenence)),
                icon: Icons.build_circle_outlined,
              ),
            ],
          ),
        ),
        _buildToolsSection(tools),
        _buildMaintenanceSection(maintenance),
      ],
    );
  }

  Widget _buildToolsSection(List<ArmoryTool> tools) {
    final toolCards =
    tools.map((tool) => ToolItemCard(tool: tool, userId: widget.userId)).toList();

    return CommonWidgets.buildExpandableSection(
      title: 'Tools & Equipment',
      subtitle: 'cleaning kits, torque wrenches, chronographs',
      initiallyExpanded: tools.isNotEmpty,
      children: [ResponsiveGridWidget(children: toolCards)],
    );
  }

  Widget _buildMaintenanceSection(List<ArmoryMaintenance> maintenance) {
    final maintenanceCards = maintenance
        .map((m) => MaintenanceItemCard(maintenance: m, userId: widget.userId))
        .toList();

    return CommonWidgets.buildExpandableSection(
      title: 'Maintenance Logs',
      subtitle: 'cleaning, lubrication, repairs, inspections',
      initiallyExpanded: maintenance.isNotEmpty,
      children: [ResponsiveGridWidget(children: maintenanceCards)],
    );
  }
}
