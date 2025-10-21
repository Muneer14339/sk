// lib/user_dashboard/presentation/widgets/navigation/list_navigation_widget.dart
import 'package:flutter/material.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
import '../tab_widgets/enhanced_armory_tab_view.dart';

class ListNavigationWidget extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final ArmoryState state;
  final Map<ArmoryTabType, int> counts; // 👈 new field

  const ListNavigationWidget({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.state,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    // Limit navigation to 15-20% of screen height
    final maxHeight = orientation == Orientation.portrait
        ? screenHeight * 0.25  // 20% for portrait
        : screenHeight * 0.30; // 30% for landscape

    return Container(
      //height: maxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          children: _getTabItems().asMap().entries.map((entry) {
            final index = entry.key;
            final tabItem = entry.value;
            // For list navigation mode, no item should be active (-1 means no selection)
            final isActive = selectedTabIndex >= 0 && selectedTabIndex == index;

            return _buildListItem(
              tabItem: tabItem,
              isActive: isActive,
              onTap: () => onTabChanged(index),
              isLast: index == _getTabItems().length - 1,
              isCompact: true,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required TabItemInfo tabItem,
    required bool isActive,
    required VoidCallback onTap,
    required bool isLast,
    required bool isCompact,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppAnimations.mediumDuration,
            margin: EdgeInsets.only(bottom: isLast ? 0 : (isCompact ? 4 : 8)),
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accentBackgroundWithOpacity.withOpacity(0.2)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AppColors.accentText.withOpacity(0.3)
                    : AppColors.primaryBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Left side: Icon + Label
                Expanded(
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: isCompact ? 28 : 32,
                        height: isCompact ? 28 : 32,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accentText.withOpacity(0.1)
                              : AppColors.sectionBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          tabItem.icon,
                          size: isCompact ? 14 : 16,
                          color: isActive
                              ? AppColors.accentText
                              : AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Label
                      Expanded(
                        child: Text(
                          tabItem.title,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.accentText
                                : AppColors.primaryText,
                            fontSize: isCompact ? 12 : 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side: Count + Arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Count Badge
                    if (tabItem.count > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accentText.withOpacity(0.1)
                              : AppColors.sectionBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? AppColors.accentText.withOpacity(0.3)
                                : AppColors.primaryBorder,
                          ),
                        ),
                        child: Text(
                          tabItem.count.toString(),
                          style: TextStyle(
                            color: isActive
                                ? AppColors.accentText
                                : AppColors.secondaryText,
                            fontSize: isCompact ? 10 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    // Arrow - Always pointing right for navigation indication
                    Icon(
                      Icons.chevron_right,
                      size: isCompact ? 16 : 18,
                      color: isActive
                          ? AppColors.accentText
                          : AppColors.secondaryText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TabItemInfo> _getTabItems() {
    return [
      TabItemInfo(title: 'Firearms', icon: Icons.radio_button_unchecked, count: counts[ArmoryTabType.firearms] ?? 0),
      TabItemInfo(title: 'Ammunition', icon: Icons.inventory_2_outlined, count: counts[ArmoryTabType.ammunition] ?? 0),
      TabItemInfo(title: 'Gear & Equipment', icon: Icons.backpack_outlined, count: counts[ArmoryTabType.gear] ?? 0),
      TabItemInfo(title: 'Tools', icon: Icons.build_outlined, count: counts[ArmoryTabType.tools] ?? 0),
      TabItemInfo(title: 'Loadouts', icon: Icons.construction_outlined, count: counts[ArmoryTabType.loadouts] ?? 0),
      TabItemInfo(title: 'Report', icon: Icons.flash_on_outlined, count: counts[ArmoryTabType.report] ?? 0),
    ];
  }

  int _getFirearmsCount() {
    if (state is FirearmsLoaded) {
      return (state as FirearmsLoaded).firearms.length;
    }
    return 0;
  }

  int _getAmmunitionCount() {
    if (state is AmmunitionLoaded) {
      return (state as AmmunitionLoaded).ammunition.length;
    }
    return 0;
  }

  int _getGearCount() {
    if (state is GearLoaded) {
      return (state as GearLoaded).gear.length;
    }
    return 0;
  }

  int _getToolsCount() {
    if (state is ToolsLoaded) {
      return (state as ToolsLoaded).tools.length;
    }
    return 0;
  }

  int _getAllItemsCount() {
    return _getFirearmsCount() +
        _getAmmunitionCount() +
        _getGearCount() +
        _getToolsCount() +
        _getLoadoutsCount();
  }
  int _getLoadoutsCount() {
    if (state is LoadoutsLoaded) {
      return (state as LoadoutsLoaded).loadouts.length;
    }
    return 0;
  }
}

class TabItemInfo {
  final String title;
  final IconData icon;
  final int count;

  const TabItemInfo({
    required this.title,
    required this.icon,
    required this.count,
  });
}