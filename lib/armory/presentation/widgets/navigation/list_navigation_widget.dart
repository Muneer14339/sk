// ===== list_navigation_widget.dart =====
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';
import '../common/common_delete_dilogue.dart';
import '../tab_widgets/enhanced_armory_tab_view.dart';

class ListNavigationWidget extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final ArmoryState state;
  final Map<ArmoryTabType, int> counts;

  const ListNavigationWidget({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.state,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getTabItems();
    final orientation = MediaQuery.of(context).orientation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemHeight = (constraints.maxHeight - (items.length - 1) * 4) / items.length;
        final basePadding = itemHeight * 0.08;
        final iconSize = itemHeight * 0.35;
        final fontSize = itemHeight * 0.22;
        final countFontSize = itemHeight * 0.18;

        return Container(
          padding: EdgeInsets.all(basePadding),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final tabItem = entry.value;
              final isActive = selectedTabIndex >= 0 && selectedTabIndex == index;
              final isLast = index == items.length - 1;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                  child: _buildListItem(
                    context: context,
                    tabItem: tabItem,
                    isActive: isActive,
                    onTap: () => onTabChanged(index),
                    orientation: orientation,
                    itemHeight: itemHeight,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    countFontSize: countFontSize,
                    basePadding: basePadding,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required TabItemInfo tabItem,
    required bool isActive,
    required VoidCallback onTap,
    required Orientation orientation,
    required double itemHeight,
    required double iconSize,
    required double fontSize,
    required double countFontSize,
    required double basePadding,
  }) {
    final showIcons = orientation == Orientation.portrait;
    final itemPadding = basePadding * 1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ArmoryConstants.mediumDuration,
        padding: EdgeInsets.symmetric(
          horizontal: itemPadding,
          vertical: itemPadding * 0.6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary(context).withOpacity(0.1)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(basePadding),
          border: Border.all(
            color: isActive
                ? AppTheme.primary(context).withOpacity(0.3)
                : AppTheme.border(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (showIcons)
                    Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primary(context).withOpacity(0.1)
                            : AppTheme.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(basePadding * 0.75),
                      ),
                      padding: EdgeInsets.all(basePadding * 0.5),
                      child: Icon(
                        tabItem.icon,
                        size: iconSize,
                        color: isActive
                            ? AppTheme.primary(context)
                            : AppTheme.textPrimary(context),
                      ),
                    ),
                  if (showIcons) SizedBox(width: basePadding),
                  Expanded(
                    child: Text(
                      tabItem.title,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: isActive
                            ? AppTheme.primary(context)
                            : AppTheme.textPrimary(context),
                        fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tabItem.count > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary(context).withOpacity(0.1)
                          : AppTheme.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(basePadding * 1.25),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primary(context).withOpacity(0.3)
                            : AppTheme.border(context),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: basePadding * 0.75,
                      vertical: basePadding * 0.25,
                    ),
                    child: Text(
                      tabItem.count.toString(),
                      style: TextStyle(
                        fontSize: countFontSize,
                        color: isActive
                            ? AppTheme.primary(context)
                            : AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showIcons) SizedBox(width: basePadding * 0.5),
                if (showIcons)
                  Icon(
                    Icons.chevron_right,
                    size: iconSize * 0.85,
                    color: isActive
                        ? AppTheme.primary(context)
                        : AppTheme.textSecondary(context),
                  ),
              ],
            ),
          ],
        ),
      ),
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

// ===== grid_navigation_widget.dart =====

// ===== FORM WRAPPER PATTERN =====
