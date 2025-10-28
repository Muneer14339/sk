import 'package:flutter/material.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_firearm_form.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../common/empty_state_widget.dart';
import '../item_cards/firearm_item_card.dart';

class FirearmsTabWidget extends StatelessWidget {
  final String userId;

  const FirearmsTabWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.firearms,
      formTitle: 'Add Firearm',
      formBadge: 'Level 1 UI',
      cardTitle: 'Firearms',
      cardDescription: 'Track each gun as an asset or keep a simple quantity.',
      formBuilder: (userId) => AddFirearmForm(userId: userId),
      listBuilder: _buildFirearmsList,
      getItemCount: (state) => state is ArmoryDataLoaded ? state.firearms.length : 0,
    );
  }

  Widget _buildFirearmsList(ArmoryState state) {
    if (state is ArmoryLoading) {
      return CommonWidgets.buildLoading(message: 'Loading firearms...');
    }

    if (state is ArmoryDataLoaded) {
      if (state.firearms.isEmpty) {
        return const EmptyStateWidget(
          message: 'No firearms added yet.',
          icon: Icons.add_circle_outline,
        );
      }

      final cards = state.firearms
          .map((firearm) => FirearmItemCard(firearm: firearm, userId: userId))
          .toList();

      return ResponsiveGridWidget(children: cards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    return const EmptyStateWidget(
      message: 'No firearms added yet.',
      icon: Icons.add_circle_outline,
    );
  }
}