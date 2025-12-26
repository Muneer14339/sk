import 'package:flutter/material.dart';
import '../../../domain/entities/armory_gear.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_gear_form.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../common/empty_state_widget.dart';
import '../item_cards/gear_item_card.dart';

class GearTabWidget extends StatelessWidget {
  final String userId;

  const GearTabWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.gear,
      formTitle: 'Add Gear',
      cardTitle: 'Gear',
      cardDescription: 'Optics, supports, sensors, attachments, and more — organized as collapsible sections.',
      formBuilder: (userId) => AddGearForm(userId: userId),
      listBuilder: _buildGearAccordion,
      getItemCount: (state) => state is ArmoryDataLoaded ? state.gear.length : 0,
    );
  }

  Widget _buildGearAccordion(ArmoryState state) {
    if (state is ArmoryLoading) {
      return CommonWidgets.buildLoading(message: 'Loading gear...');
    }

    if (state is ArmoryDataLoaded) {
      final gearByCategory = <String, List<ArmoryGear>>{};
      for (final gear in state.gear) {
        final category = gear.category.toLowerCase();
        gearByCategory[category] = (gearByCategory[category] ?? [])..add(gear);
      }

      if (gearByCategory.isEmpty) {
        return const EmptyStateWidget(
          message: 'No gear items yet.',
          icon: Icons.add_circle_outline,
        );
      }

      return Column(
        children: [
          _buildGearSection('optics', 'Optics & Sights', 'scopes, RDS, irons', gearByCategory['optics'] ?? []),
          _buildGearSection('supports', 'Supports', 'bipods, tripods, rests', gearByCategory['supports'] ?? []),
          _buildGearSection('attachments', 'Attachments', 'suppressors, brakes, lights', gearByCategory['attachments'] ?? []),
          _buildGearSection('sensors', 'Sensors & Electronics', 'ShotPulse, RifleAxis, PulseSkadi', gearByCategory['sensors'] ?? []),
          _buildGearSection('misc', 'Misc. Gear', 'slings, cases, ear/eye pro', gearByCategory['misc'] ?? []),
        ],
      );
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    return const EmptyStateWidget(
      message: 'No gear items yet.',
      icon: Icons.add_circle_outline,
    );
  }

  Widget _buildGearSection(String categoryKey, String title, String subtitle, List<ArmoryGear> items) {
    final gearCards = items.map((gear) => GearItemCard(gear: gear, userId: userId)).toList();

    return Builder(
      builder: (context) => CommonWidgets.buildExpandableSection(
        context: context,
        title: title,
        subtitle: subtitle,
        count: items.length, // ✅ ADD
        children: [ResponsiveGridWidget(children: gearCards)],
      ),
    );
  }
}