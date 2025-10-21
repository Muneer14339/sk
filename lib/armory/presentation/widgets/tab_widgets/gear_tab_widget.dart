// lib/user_dashboard/presentation/widgets/tab_widgets/gear_tab_widget.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_gear_form.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../empty_state_widget.dart';
import '../gear_item_card.dart';
import 'armory_tab_view.dart';

class GearTabWidget extends StatelessWidget {
  final String userId;

  GearTabWidget({super.key, required this.userId});

  // Cache for previously loaded gear categories
  Map<String, List<ArmoryGear>> _lastGearByCategory = {};

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.gear,
      formTitle: 'Add Gear',
      cardTitle: 'Gear',
      cardDescription:
      'Optics, supports, sensors, attachments, and more — organized as collapsible sections.',
      formBuilder: (userId) => AddGearForm(userId: userId),
      listBuilder: _buildGearAccordion,
      getItemCount: (state) =>
      state is GearLoaded ? state.gear.length : _countCachedItems(),
    );
  }

  /// Build accordion sections based on current state or cache
  Widget _buildGearAccordion(ArmoryState state) {
    if (state is ArmoryLoading) {
      // Show cached accordion if available while loading
      return _lastGearByCategory.isNotEmpty
          ? _buildAccordionFromCache()
          : CommonWidgets.buildLoading(message: 'Loading gear...');
    }

    if (state is GearLoaded) {
      final gearByCategory = <String, List<ArmoryGear>>{};
      for (final gear in state.gear) {
        final category = gear.category.toLowerCase();
        gearByCategory[category] = (gearByCategory[category] ?? [])..add(gear);
      }

      if (gearByCategory.isEmpty) {
        _lastGearByCategory = {}; // Clear cache when actual data empty
        return const EmptyStateWidget(
          message: 'No gear items yet.',
          icon: Icons.add_circle_outline,
        );
      }

      // Update cache and build sections
      _lastGearByCategory = gearByCategory;
      return _buildAccordionFromMap(gearByCategory);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    // Unknown state: use cache if available
    return _lastGearByCategory.isNotEmpty
        ? _buildAccordionFromCache()
        : const EmptyStateWidget(
      message: 'No gear items yet.',
      icon: Icons.add_circle_outline,
    );
  }

  /// Build accordion from cached data
  Widget _buildAccordionFromCache() => _buildAccordionFromMap(_lastGearByCategory);

  /// Build accordion sections from a given category map
  Widget _buildAccordionFromMap(Map<String, List<ArmoryGear>> gearByCategory) {
    return Column(
      children: [
        _buildGearSection(
            'optics', 'Optics & Sights', 'scopes, RDS, irons', gearByCategory['optics'] ?? []),
        _buildGearSection(
            'supports', 'Supports', 'bipods, tripods, rests', gearByCategory['supports'] ?? []),
        _buildGearSection('attachments', 'Attachments', 'suppressors, brakes, lights',
            gearByCategory['attachments'] ?? []),
        _buildGearSection('sensors', 'Sensors & Electronics',
            'ShotPulse, RifleAxis, PulseSkadi', gearByCategory['sensors'] ?? []),
        _buildGearSection('misc', 'Misc. Gear', 'slings, cases, ear/eye pro',
            gearByCategory['misc'] ?? []),
      ],
    );
  }

  /// Count cached items for getItemCount fallback
  int _countCachedItems() =>
      _lastGearByCategory.values.fold(0, (sum, list) => sum + list.length);

  /// Build a single gear section with expandable UI
  Widget _buildGearSection(
      String categoryKey, String title, String subtitle, List<ArmoryGear> items) {
    final gearCards =
    items.map((gear) => GearItemCard(gear: gear, userId: userId)).toList();

    return CommonWidgets.buildExpandableSection(
      title: title,
      subtitle: subtitle,
      children: [
        ResponsiveGridWidget(children: gearCards),
      ],
    );
  }
}
