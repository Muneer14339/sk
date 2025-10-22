import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_ammunition_form.dart';
import '../ammunition_item_card.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../empty_state_widget.dart';
import 'enhanced_armory_tab_view.dart';
import 'firearms_tab_widget.dart';

class AmmunitionTabWidget extends StatelessWidget {
  final String userId;

  AmmunitionTabWidget({super.key, required this.userId});

  List<Widget> _lastAmmoCards = [];

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.ammunition,
      formTitle: 'Add Ammunition',
      formBadge: 'Level 1 UI',
      cardTitle: 'Ammunition',
      cardDescription:
      'Catalog brands and track lots with chrono data for better analytics.',
      formBuilder: (userId) => AddAmmunitionForm(userId: userId),
      listBuilder: _buildAmmunitionList,
      getItemCount: (state) =>
      state is AmmunitionLoaded ? state.ammunition.length : _lastAmmoCards.length,
      onAddPressed: (context) {
        // Check if firearms exist using FirearmsTabWidget.lastFirearmCards
        if (FirearmsTabWidget.lastFirearmCards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a firearm first.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Otherwise show the form normally
          context.read<ArmoryBloc>().add(
            ShowAddFormEvent(tabType: ArmoryTabType.ammunition),
          );
        }
      },
    );
  }

  Widget _buildAmmunitionList(ArmoryState state) {
    if (state is ArmoryLoading) {
      // Loading dikhate waqt agar cache hai to woh show karein
      return _lastAmmoCards.isNotEmpty
          ? ResponsiveGridWidget(children: _lastAmmoCards)
          : CommonWidgets.buildLoading(message: 'Loading ammunition...');
    }

    if (state is AmmunitionLoaded) {
      if (state.ammunition.isEmpty) {
        _lastAmmoCards = []; // cache clear karein
        return const EmptyStateWidget(
          message: 'No ammunition lots yet.',
          icon: Icons.add_circle_outline,
        );
      }

      _lastAmmoCards = state.ammunition
          .map((ammo) =>
          AmmunitionItemCard(ammunition: ammo, userId: userId))
          .toList();

      return ResponsiveGridWidget(children: _lastAmmoCards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    // Unknown state: agar cache hai to woh show karein
    return _lastAmmoCards.isNotEmpty
        ? ResponsiveGridWidget(children: _lastAmmoCards)
        : const EmptyStateWidget(
      message: 'No ammunition lots yet.',
      icon: Icons.add_circle_outline,
    );
  }
}
