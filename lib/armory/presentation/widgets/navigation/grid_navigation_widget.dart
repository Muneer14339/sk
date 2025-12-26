// lib/user_dashboard/presentation/widgets/navigation/grid_navigation_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';
import '../common/common_delete_dilogue.dart';

class GridNavigationWidget extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final ArmoryState state;
  final Map<ArmoryTabType, int> counts; // ADD THIS

  const GridNavigationWidget({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.state,
    required this.counts, // ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;

          if (orientation == Orientation.landscape) {
            crossAxisCount = constraints.maxWidth > 800 ? 6 : 3;
          } else {
            crossAxisCount = constraints.maxWidth > 400 ? 3 : 3;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
              childAspectRatio: orientation == Orientation.landscape ? 5 : 2,
            ),
            itemCount: _getTabItems().length,
            itemBuilder: (context, index) {
              final tabItem = _getTabItems()[index];
              final isActive = selectedTabIndex == index;

              return _buildGridItem(
                context: context,
                tabItem: tabItem,
                isActive: isActive,
                onTap: () => onTabChanged(index),
                isCompact: true,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGridItem({
    required BuildContext context,
    required TabItemInfo tabItem,
    required bool isActive,
    required VoidCallback onTap,
    required bool isCompact,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ArmoryConstants.mediumDuration,
        padding: EdgeInsets.all(isCompact ? 8 : 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary(context) : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.primary(context)
                : AppTheme.border(context),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    tabItem.icon,
                    size: isCompact ? 16 : 20,
                    color: isActive ? Colors.black : AppTheme.textPrimary(context),
                  ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.error(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          tabItem.count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                tabItem.title,
                style: TextStyle(
                  color: isActive ? Colors.black : AppTheme.textPrimary(context),
                  fontSize: isCompact ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Replace _getTabItems with:
  List<TabItemInfo> _getTabItems() {
    return [
      TabItemInfo(title: 'Firearms', icon: Icons.radio_button_unchecked, count: counts[ArmoryTabType.firearms] ?? 0),
      TabItemInfo(title: 'Ammo', icon: Icons.inventory_2_outlined, count: counts[ArmoryTabType.ammunition] ?? 0),
      TabItemInfo(title: 'Gear', icon: Icons.backpack_outlined, count: counts[ArmoryTabType.gear] ?? 0),
      TabItemInfo(title: 'Tools', icon: Icons.build_outlined, count: ((counts[ArmoryTabType.tools]?? 0) + (counts[ArmoryTabType.maintenence]?? 0))),
      TabItemInfo(title: 'Loadouts', icon: Icons.flash_on_outlined, count: counts[ArmoryTabType.loadouts] ?? 0),
      TabItemInfo(title: 'Report', icon: Icons.analytics_outlined, count: counts[ArmoryTabType.report] ?? 0),
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