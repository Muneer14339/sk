import 'package:equatable/equatable.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/entities/armory_loadout.dart';
import '../widgets/common/common_delete_dilogue.dart';

abstract class ArmoryState extends Equatable {
  const ArmoryState();

  @override
  List<Object?> get props => [];
}

class ArmoryInitial extends ArmoryState {
  const ArmoryInitial();
}

class ArmoryLoading extends ArmoryState {
  const ArmoryLoading();
}

class ArmoryLoadingAction extends ArmoryState {
  const ArmoryLoadingAction();
}

class ArmoryDataLoaded extends ArmoryState {
  final List<ArmoryFirearm> firearms;
  final List<ArmoryAmmunition> ammunition;
  final List<ArmoryGear> gear;
  final List<ArmoryTool> tools;
  final List<ArmoryLoadout> loadouts;
  final List<ArmoryMaintenance> maintenance;

  const ArmoryDataLoaded({
    required this.firearms,
    required this.ammunition,
    required this.gear,
    required this.tools,
    required this.loadouts,
    required this.maintenance,
  });

  ArmoryDataLoaded copyWith({
    List<ArmoryFirearm>? firearms,
    List<ArmoryAmmunition>? ammunition,
    List<ArmoryGear>? gear,
    List<ArmoryTool>? tools,
    List<ArmoryLoadout>? loadouts,
    List<ArmoryMaintenance>? maintenance,
  }) {
    return ArmoryDataLoaded(
      firearms: firearms ?? this.firearms,
      ammunition: ammunition ?? this.ammunition,
      gear: gear ?? this.gear,
      tools: tools ?? this.tools,
      loadouts: loadouts ?? this.loadouts,
      maintenance: maintenance ?? this.maintenance,
    );
  }

  @override
  List<Object?> get props => [firearms, ammunition, gear, tools, loadouts, maintenance];
}

class ArmoryActionSuccess extends ArmoryState {
  final String message;
  const ArmoryActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ArmoryError extends ArmoryState {
  final String message;
  const ArmoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ShowingAddForm extends ArmoryState {
  final ArmoryTabType tabType;
  final List firearms;
  final List ammunition;
  final List gear;
  final List tools;
  final List loadouts;
  final List maintenance;

  const ShowingAddForm({
    required this.tabType,
    required this.firearms,
    required this.ammunition,
    required this.gear,
    required this.tools,
    required this.loadouts,
    required this.maintenance,
  });

  @override
  List<Object?> get props => [
    tabType,
    firearms,
    ammunition,
    gear,
    tools,
    loadouts,
    maintenance,
  ];
}
// lib/armory/presentation/bloc/armory_state.dart - ADD these states
class SyncInProgress extends ArmoryState {
  final String message;
  const SyncInProgress({required this.message});

  @override
  List<Object?> get props => [message];
}

class SyncCompleted extends ArmoryState {
  final String message;
  const SyncCompleted({required this.message});

  @override
  List<Object?> get props => [message];
}
