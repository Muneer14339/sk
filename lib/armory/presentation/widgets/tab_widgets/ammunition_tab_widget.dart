import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_ammunition_form.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../common/empty_state_widget.dart';
import '../item_cards/ammunition_item_card.dart';

class AmmunitionTabWidget extends StatelessWidget {
  final String userId;

  const AmmunitionTabWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.ammunition,
      formTitle: 'Add Ammunition',
      formBadge: 'Level 1 UI',
      cardTitle: 'Ammunition',
      cardDescription: 'Catalog brands and track lots with chrono data for better analytics.',
      formBuilder: (userId) => AddAmmunitionForm(userId: userId),
      listBuilder: _buildAmmunitionList,
      getItemCount: (state) => state is ArmoryDataLoaded ? state.ammunition.length : 0,
      onAddPressed: (context) {
        final currentState = context.read<ArmoryBloc>().state;
        if (currentState is ArmoryDataLoaded && currentState.firearms.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a firearm first.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          context.read<ArmoryBloc>().add(
            ShowAddFormEvent(tabType: ArmoryTabType.ammunition),
          );
        }
      },
    );
  }

  Widget _buildAmmunitionList(ArmoryState state) {
    if (state is ArmoryLoading) {
      return CommonWidgets.buildLoading(message: 'Loading ammunition...');
    }

    if (state is ArmoryDataLoaded) {
      if (state.ammunition.isEmpty) {
        return const EmptyStateWidget(
          message: 'No ammunition lots yet.',
          icon: Icons.add_circle_outline,
        );
      }

      final cards = state.ammunition
          .map((ammo) => AmmunitionItemCard(ammunition: ammo, userId: userId))
          .toList();

      return ResponsiveGridWidget(children: cards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    return const EmptyStateWidget(
      message: 'No ammunition lots yet.',
      icon: Icons.add_circle_outline,
    );
  }
}