// lib/user_dashboard/presentation/widgets/navigation/grid_navigation_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../bloc/armory_state.dart';
import '../common/armory_constants.dart';

class GridNavigationWidget extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final ArmoryState state;

  const GridNavigationWidget({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.state,
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
                  if (tabItem.count > 0)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
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

  List<TabItemInfo> _getTabItems() {
    return [
      TabItemInfo(
        title: 'Firearms',
        icon: Icons.radio_button_unchecked,
        count: _getFirearmsCount(),
      ),
      TabItemInfo(
        title: 'Ammo',
        icon: Icons.inventory_2_outlined,
        count: _getAmmunitionCount(),
      ),
      TabItemInfo(
        title: 'Gear',
        icon: Icons.backpack_outlined,
        count: _getGearCount(),
      ),
      TabItemInfo(
        title: 'Tools',
        icon: Icons.build_outlined,
        count: _getToolsCount(),
      ),
      TabItemInfo(
        title: 'Loadouts',
        icon: Icons.flash_on_outlined,
        count: _getLoadoutsCount(),
      ),
      TabItemInfo(
        title: 'Report',
        icon: Icons.analytics_outlined,
        count: _getAllItemsCount(),
      ),
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

  int _getLoadoutsCount() {
    if (state is LoadoutsLoaded) {
      return (state as LoadoutsLoaded).loadouts.length;
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