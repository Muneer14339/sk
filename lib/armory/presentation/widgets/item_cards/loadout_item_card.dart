// lib/armory/presentation/widgets/item_cards/loadout_item_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/armory_loadout.dart';
import '../../../domain/entities/armory_firearm.dart';
import '../../../domain/entities/armory_ammunition.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_state.dart';
import '../common/common_delete_dilogue.dart';
import '../common/common_item_card.dart';

class LoadoutItemCard extends StatefulWidget {
  final ArmoryLoadout loadout;
  final String userId;

  const LoadoutItemCard({super.key, required this.loadout, required this.userId});

  @override
  State<LoadoutItemCard> createState() => _LoadoutItemCardState();
}

class _LoadoutItemCardState extends State<LoadoutItemCard> {
  ArmoryFirearm? _firearm;
  ArmoryAmmunition? _ammunition;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArmoryBloc, ArmoryState>(
      builder: (context, state) {
        if (state is FirearmsLoaded && widget.loadout.firearmId != null) {
          _firearm = state.firearms.firstWhere(
                (f) => f.id == widget.loadout.firearmId,
            orElse: () => state.firearms.first,
          );
        }
        if (state is AmmunitionLoaded && widget.loadout.ammunitionId != null) {
          _ammunition = state.ammunition.firstWhere(
                (a) => a.id == widget.loadout.ammunitionId,
            orElse: () => state.ammunition.first,
          );
        }

        final dateStr = '${widget.loadout.dateAdded.day}/${widget.loadout.dateAdded.month}/${widget.loadout.dateAdded.year}';

        return CommonItemCard(
          item: widget.loadout,
          title: widget.loadout.name,
          details: [
            if (_firearm != null)
              CardDetailRow(
                icon: '🔫',
                text: '${_firearm!.make} ${_firearm!.model}',
              ),
            if (_ammunition != null)
              CardDetailRow(
                icon: '💣',
                text: '${_ammunition!.caliber} ${_ammunition!.bullet}',
                badge: '${_ammunition!.quantity} rds',
                date: dateStr,
              ),
          ],
          onDelete: () => CommonDialogs.showDeleteDialog(
            context: context,
            userId: widget.userId,
            armoryType: ArmoryTabType.loadouts,
            itemName: widget.loadout.name,
            item: widget.loadout,
          ),
        );
      },
    );
  }
}