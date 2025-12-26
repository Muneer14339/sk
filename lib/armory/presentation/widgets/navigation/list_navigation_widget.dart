
import 'package:flutter/material.dart';


import '../../../../core/theme/app_theme.dart';
import '../../bloc/armory_state.dart';
import '../common/common_delete_dilogue.dart';



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

    return Container(
 
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final tabItem = items[index];
          final isActive = selectedTabIndex >= 0 && selectedTabIndex == index;

          return SizedBox(
            height: 60, // ✅ Fixed tab height
            child: _buildListItem(
              context: context,
              tabItem: tabItem,
              isActive: isActive,
              onTap: () => onTabChanged(index),
              orientation: orientation,
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required TabItemInfo tabItem,
    required bool isActive,
    required VoidCallback onTap,
    required Orientation orientation,
  }) {
    const double iconSize = 28;
    const double fontSize = 16;
    const double countFontSize = 14;
    const double borderRadius = 10;
    const double horizontalPadding = 16;

    final showIcons = orientation == Orientation.portrait;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary(context).withOpacity(0.2)
              : AppTheme.background(context),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isActive
                ? AppTheme.primary(context).withOpacity(0.2)
              : AppTheme.background(context),
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
                            ? AppTheme.primary(context).withOpacity(0.2)
              : AppTheme.background(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        tabItem.icon,
                        size: iconSize,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  if (showIcons) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tabItem.title,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                           
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
                      color: AppTheme.primary(context).withOpacity(0.2),
                    shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary(context).withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      tabItem.count.toString(),
                      style: TextStyle(
                        fontSize: countFontSize,
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (showIcons) const SizedBox(width: 8),
                if (showIcons)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
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
