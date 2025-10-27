// lib/armory/presentation/widgets/tab_widgets/report_tab_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../../domain/entities/armory_tool.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../common/common_widgets.dart';
import '../item_cards/firearm_item_card.dart';
import '../item_cards/ammunition_item_card.dart';
import '../item_cards/gear_item_card.dart';
import '../item_cards/tool_item_card.dart';
import '../item_cards/loadout_item_card.dart';

class ReportTabWidget extends StatefulWidget {
  final String userId;

  const ReportTabWidget({super.key, required this.userId});

  @override
  State<ReportTabWidget> createState() => _ReportTabWidgetState();
}

class _ReportTabWidgetState extends State<ReportTabWidget> {
  List<ArmoryFirearm> _firearms = [];
  List<ArmoryAmmunition> _ammunition = [];
  List<ArmoryGear> _gear = [];
  List<ArmoryTool> _tools = [];
  List<ArmoryLoadout> _loadouts = [];

  final Map<String, bool> _expanded = {
    'firearms': false,
    'ammunition': false,
    'gear': false,
    'tools': false,
    'loadouts': false,
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    final bloc = context.read<ArmoryBloc>();
    bloc.add(LoadFirearmsEvent(userId: widget.userId));
    bloc.add(LoadAmmunitionEvent(userId: widget.userId));
    bloc.add(LoadGearEvent(userId: widget.userId));
    bloc.add(LoadToolsEvent(userId: widget.userId));
    bloc.add(LoadLoadoutsEvent(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is FirearmsLoaded) setState(() => _firearms = state.firearms);
        if (state is AmmunitionLoaded) setState(() => _ammunition = state.ammunition);
        if (state is GearLoaded) setState(() => _gear = state.gear);
        if (state is ToolsLoaded) setState(() => _tools = state.tools);
        if (state is LoadoutsLoaded) setState(() => _loadouts = state.loadouts);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonWidgets.buildPageHeader(
              context: context,
              title: 'Inventory Report',
            ),
            _buildSection('firearms', 'Firearms', _firearms.length, _firearms),
            _buildSection('ammunition', 'Ammunition', _ammunition.length, _ammunition),
            _buildSection('gear', 'Gear', _gear.length, _gear),
            _buildSection('tools', 'Tools', _tools.length, _tools),
            _buildSection('loadouts', 'Loadouts', _loadouts.length, _loadouts),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String key, String title, int count, List items) {
    final isExpanded = _expanded[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded[key] = !isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTheme.titleLarge(context)),
                  ),
                  const SizedBox(width: 12),
                  CommonWidgets.buildCountBadge(context, count, 'items'),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary(context),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              child: _buildGrid(items, key),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(List items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No items',
            style: AppTheme.bodySmall(context),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildCard(item, type),
      )).toList(),
    );
  }

  Widget _buildCard(dynamic item, String type) {
    switch (type) {
      case 'firearms':
        return FirearmItemCard(firearm: item, userId: widget.userId);
      case 'ammunition':
        return AmmunitionItemCard(ammunition: item, userId: widget.userId);
      case 'gear':
        return GearItemCard(gear: item, userId: widget.userId);
      case 'tools':
        return ToolItemCard(tool: item, userId: widget.userId);
      case 'loadouts':
        return LoadoutItemCard(loadout: item, userId: widget.userId);
      default:
        return const SizedBox();
    }
  }
}