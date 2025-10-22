// lib/user_dashboard/presentation/widgets/tab_widgets/loadouts_tab_widget.dart
import 'package:flutter/material.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_loadout_form.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../empty_state_widget.dart';
import '../loadout_item_card.dart';
import 'enhanced_armory_tab_view.dart';

class LoadoutsTabWidget extends StatelessWidget {
  final String userId;

  LoadoutsTabWidget({super.key, required this.userId});

  List<Widget> _lastLoadoutCards = [];

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.loadouts,
      formTitle: 'Create Loadout',
      cardTitle: 'Loadouts',
      cardDescription: 'Create named bundles of your gear to speed up Training setup.',
      formBuilder: (userId) => AddLoadoutForm(userId: userId),
      listBuilder: _buildLoadoutsList,
      getItemCount: (state) =>
      state is LoadoutsLoaded ? state.loadouts.length : _lastLoadoutCards.length,
    );
  }

  Widget _buildLoadoutsList(ArmoryState state) {
    if (state is ArmoryLoading) {
      // Show cache while loading if available
      return _lastLoadoutCards.isNotEmpty
          ? ResponsiveGridWidget(children: _lastLoadoutCards)
          : CommonWidgets.buildLoading(message: 'Loading loadouts...');
    }

    if (state is LoadoutsLoaded) {
      if (state.loadouts.isEmpty) {
        _lastLoadoutCards = []; // clear cache if backend confirms empty
        return const EmptyStateWidget(
          message: 'No loadouts yet.',
          icon: Icons.add_circle_outline,
        );
      }

      _lastLoadoutCards = state.loadouts
          .map((loadout) => LoadoutItemCard(loadout: loadout, userId: userId))
          .toList();

      return ResponsiveGridWidget(children: _lastLoadoutCards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    // Fallback for unknown state: use cache if available
    return _lastLoadoutCards.isNotEmpty
        ? ResponsiveGridWidget(children: _lastLoadoutCards)
        : const EmptyStateWidget(
      message: 'No loadouts yet.',
      icon: Icons.add_circle_outline,
    );
  }
}
