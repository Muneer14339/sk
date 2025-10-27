import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../add_forms/add_loadout_form.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_widgets.dart';
import '../common/form_wrapper_widget.dart';
import '../common/responsive_grid_widget.dart';
import '../common/empty_state_widget.dart';
import '../item_cards/loadout_item_card.dart';

class LoadoutsTabWidget extends StatefulWidget {
  final String userId;

  const LoadoutsTabWidget({super.key, required this.userId});

  @override
  State<LoadoutsTabWidget> createState() => _LoadoutsTabWidgetState();
}

class _LoadoutsTabWidgetState extends State<LoadoutsTabWidget> {
  Map<String, ArmoryFirearm> _firearmsMap = {};
  Map<String, ArmoryAmmunition> _ammunitionMap = {};
  List<ArmoryLoadout> _pendingLoadouts = []; // 🔹 store loadouts temporarily
  List<Widget> _lastLoadoutCards = [];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ArmoryBloc>();
    bloc.add(LoadFirearmsEvent(userId: widget.userId));
    bloc.add(LoadAmmunitionEvent(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArmoryBloc, ArmoryState>(
      listener: (context, state) {
        if (state is FirearmsLoaded) {
          _firearmsMap = {
            for (var f in state.firearms)
              if (f.id != null) f.id!: f
          };
        }

        if (state is AmmunitionLoaded) {
          _ammunitionMap = {
            for (var a in state.ammunition)
              if (a.id != null) a.id!: a
          };
        }

        // 🔹 if both are loaded and we already have loadouts waiting, rebuild cards
        if (_pendingLoadouts.isNotEmpty &&
            _firearmsMap.isNotEmpty &&
            _ammunitionMap.isNotEmpty) {
          _lastLoadoutCards = _pendingLoadouts.map((loadout) {
            final firearm = loadout.firearmId != null
                ? _firearmsMap[loadout.firearmId]
                : null;
            final ammunition = loadout.ammunitionId != null
                ? _ammunitionMap[loadout.ammunitionId]
                : null;

            return LoadoutItemCard(
              loadout: loadout,
              firearm: firearm,
              ammunition: ammunition,
              userId: widget.userId,
            );
          }).toList();
          _pendingLoadouts.clear(); // ✅ prevent double rebuild
        }
      },
      builder: (context, state) {
        return FormWrapperWidget(
          userId: widget.userId,
          tabType: ArmoryTabType.loadouts,
          formTitle: 'Create Loadout',
          cardTitle: 'Loadouts',
          cardDescription:
          'Create named bundles of your gear to speed up Training setup.',
          formBuilder: (userId) => AddLoadoutForm(userId: userId),
          listBuilder: _buildLoadoutsList,
          getItemCount: (state) =>
          state is LoadoutsLoaded ? state.loadouts.length : _lastLoadoutCards.length,
        );
      },
    );
  }

  Widget _buildLoadoutsList(ArmoryState state) {
    if (state is ArmoryLoading) {
      return _lastLoadoutCards.isNotEmpty
          ? ResponsiveGridWidget(children: _lastLoadoutCards)
          : CommonWidgets.buildLoading(message: 'Loading loadouts...');
    }

    if (state is LoadoutsLoaded) {
      // 🔹 save loadouts immediately
      _pendingLoadouts = state.loadouts;

      if (state.loadouts.isEmpty) {
        _lastLoadoutCards = [];
        return const EmptyStateWidget(
          message: 'No loadouts yet.',
          icon: Icons.add_circle_outline,
        );
      }

      // 🔹 only show when both maps are ready
      if (_firearmsMap.isEmpty || _ammunitionMap.isEmpty) {
        return CommonWidgets.buildLoading(
            message: 'Loading firearms and ammunition...');
      }

      // 🔹 normal rendering
      _lastLoadoutCards = state.loadouts.map((loadout) {
        final firearm = loadout.firearmId != null
            ? _firearmsMap[loadout.firearmId]
            : null;
        final ammunition = loadout.ammunitionId != null
            ? _ammunitionMap[loadout.ammunitionId]
            : null;

        return LoadoutItemCard(
          loadout: loadout,
          firearm: firearm,
          ammunition: ammunition,
          userId: widget.userId,
        );
      }).toList();

      return ResponsiveGridWidget(children: _lastLoadoutCards);
    }

    if (state is ArmoryError) {
      return CommonWidgets.buildError(state.message);
    }

    return _lastLoadoutCards.isNotEmpty
        ? ResponsiveGridWidget(children: _lastLoadoutCards)
        : const EmptyStateWidget(
      message: 'No loadouts yet.',
      icon: Icons.add_circle_outline,
    );
  }
}
