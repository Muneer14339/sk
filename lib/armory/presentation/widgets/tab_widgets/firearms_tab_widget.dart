// lib/user_dashboard/presentation/widgets/tab_widgets/firearms_tab_widget.dart
import 'package:flutter/material.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_firearm_form.dart';
import 'enhanced_armory_tab_view.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../empty_state_widget.dart';
import '../firearm_item_card.dart';


class FirearmsTabWidget extends StatelessWidget {
  final String userId;

  FirearmsTabWidget({super.key, required this.userId});

  static List<Widget> lastFirearmCards = [];

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
      getItemCount: (state) =>
      state is FirearmsLoaded ? state.firearms.length : lastFirearmCards.length,
    );
  }

  Widget _buildFirearmsList(ArmoryState state) {
    if (state is ArmoryLoading) {
      // Loading dikhate hue bhi last data preserve karein
      return lastFirearmCards.isNotEmpty
          ? ResponsiveGridWidget(children: lastFirearmCards)
          : CommonWidgets.buildLoading(message: 'Loading firearms...');
    }

    if (state is FirearmsLoaded) {
      if (state.firearms.isEmpty) {
        lastFirearmCards = []; // clear cache jab actual empty aajaye
        return const EmptyStateWidget(
          message: 'No firearms added yet.',
          icon: Icons.add_circle_outline,
        );
      }

      lastFirearmCards = state.firearms
          .map((firearm) => FirearmItemCard(
        firearm: firearm,
        userId: userId,
      ))
          .toList();

      return ResponsiveGridWidget(children: lastFirearmCards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    // Agar koi aur state ho to last non-empty list preserve karein
    return lastFirearmCards.isNotEmpty
        ? ResponsiveGridWidget(children: lastFirearmCards)
        : const EmptyStateWidget(
      message: 'No firearms added yet.',
      icon: Icons.add_circle_outline,
    );
  }
}
