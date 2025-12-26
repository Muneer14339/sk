import 'package:flutter/material.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_loadout_form.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../common/empty_state_widget.dart';
import '../item_cards/loadout_item_card.dart';

class LoadoutsTabWidget extends StatelessWidget {
  final String userId;
  final VoidCallback? onNavigateToAddAmmo;

  const LoadoutsTabWidget({super.key, required this.userId,this.onNavigateToAddAmmo, });

  @override
  Widget build(BuildContext context) {
    return FormWrapperWidget(
      userId: userId,
      tabType: ArmoryTabType.loadouts,
      formTitle: 'Create Loadout',
      cardTitle: 'Loadouts',
      cardDescription: 'Create named bundles of your gear to speed up Training setup.',
      formBuilder: (userId) => AddLoadoutForm(userId: userId, onNavigateToAddAmmo: onNavigateToAddAmmo,),
      listBuilder: _buildLoadoutsList,
      getItemCount: (state) => state is ArmoryDataLoaded ? state.loadouts.length : 0,
    );
  }

  Widget _buildLoadoutsList(ArmoryState state) {
    if (state is ArmoryLoading) {
      return CommonWidgets.buildLoading(message: 'Loading loadouts...');
    }

    if (state is ArmoryDataLoaded) {
      if (state.loadouts.isEmpty) {
        return const EmptyStateWidget(
          message: 'No loadouts yet.',
          icon: Icons.add_circle_outline,
        );
      }

      final firearmsMap = <String, ArmoryFirearm>{
        for (var f in state.firearms) if (f.id != null) f.id!: f
      };
      final ammunitionMap = <String, ArmoryAmmunition>{
        for (var a in state.ammunition) if (a.id != null) a.id!: a
      };

      final cards = state.loadouts.map((loadout) {
        final firearm = loadout.firearmId != null ? firearmsMap[loadout.firearmId] : null;
        final ammunition = loadout.ammunitionId != null ? ammunitionMap[loadout.ammunitionId] : null;

        return LoadoutItemCard(
          loadout: loadout,
          firearm: firearm,
          ammunition: ammunition,
          userId: userId,
        );
      }).toList();

      return ResponsiveGridWidget(children: cards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    return const EmptyStateWidget(
      message: 'No loadouts yet.',
      icon: Icons.add_circle_outline,
    );
  }
}