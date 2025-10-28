import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../bloc/armory_bloc.dart';
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
  final Map<String, bool> _expanded = {
    'firearms': false,
    'ammunition': false,
    'gear': false,
    'tools': false,
    'loadouts': false,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonWidgets.buildPageHeader(context: context, title: 'Inventory Report'),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Builder(
      builder: (context) {
        return Column(
          children: [
            _buildSection('firearms', 'Firearms'),
            _buildSection('ammunition', 'Ammunition'),
            _buildSection('gear', 'Gear'),
            _buildSection('tools', 'Tools'),
            _buildSection('loadouts', 'Loadouts'),
          ],
        );
      },
    );
  }

  Widget _buildSection(String key, String title) {
    return Builder(
      builder: (context) {
        return BlocBuilder<ArmoryBloc, ArmoryState>(
          builder: (context, state) {
            if (state is! ArmoryDataLoaded) {
              return const SizedBox();
            }

            final items = _getItems(state, key);
            final count = items.length;
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
                          Expanded(child: Text(title, style: AppTheme.titleLarge(context))),
                          const SizedBox(width: 12),
                          CommonWidgets.buildCountBadge(context, count, 'items'),
                          const SizedBox(width: 12),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary(context), size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: _buildGrid(context, items, key, state),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List _getItems(ArmoryDataLoaded state, String type) {
    switch (type) {
      case 'firearms':
        return state.firearms;
      case 'ammunition':
        return state.ammunition;
      case 'gear':
        return state.gear;
      case 'tools':
        return state.tools;
      case 'loadouts':
        return state.loadouts;
      default:
        return [];
    }
  }

  Widget _buildGrid(BuildContext context, List items, String type, ArmoryDataLoaded state) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No items', style: AppTheme.bodySmall(context)),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCard(item, type, state),
        );
      }).toList(),
    );
  }

  Widget _buildCard(dynamic item, String type, ArmoryDataLoaded state) {
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
        final loadout = item;
        final firearmsMap = {for (var f in state.firearms) if (f.id != null) f.id!: f};
        final ammunitionMap = {for (var a in state.ammunition) if (a.id != null) a.id!: a};
        final firearm = loadout.firearmId != null ? firearmsMap[loadout.firearmId] : null;
        final ammunition = loadout.ammunitionId != null ? ammunitionMap[loadout.ammunitionId] : null;
        return LoadoutItemCard(loadout: loadout, firearm: firearm, ammunition: ammunition, userId: widget.userId);
      default:
        return const SizedBox();
    }
  }
}

