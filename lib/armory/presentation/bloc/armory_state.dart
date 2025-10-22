// lib/user_dashboard/presentation/bloc/armory_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/entities/armory_loadout.dart';
import '../../domain/entities/dropdown_option.dart';
import '../widgets/common/common_delete_dilogue.dart';

abstract class ArmoryState extends Equatable {
  const ArmoryState();

  @override
  List<Object> get props => [];
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

// Success States
class FirearmsLoaded extends ArmoryState {
  final List<ArmoryFirearm> firearms;
  const FirearmsLoaded({required this.firearms});
  @override
  List<Object> get props => [firearms];
}

class AmmunitionLoaded extends ArmoryState {
  final List<ArmoryAmmunition> ammunition;
  const AmmunitionLoaded({required this.ammunition});
  @override
  List<Object> get props => [ammunition];
}

class GearLoaded extends ArmoryState {
  final List<ArmoryGear> gear;
  const GearLoaded({required this.gear});
  @override
  List<Object> get props => [gear];
}

class ToolsLoaded extends ArmoryState {
  final List<ArmoryTool> tools;
  const ToolsLoaded({required this.tools});
  @override
  List<Object> get props => [tools];
}

class LoadoutsLoaded extends ArmoryState {
  final List<ArmoryLoadout> loadouts;
  const LoadoutsLoaded({required this.loadouts});
  @override
  List<Object> get props => [loadouts];
}

class DropdownOptionsLoaded extends ArmoryState {
  final List<DropdownOption> options;
  const DropdownOptionsLoaded({required this.options});
  @override
  List<Object> get props => [options];
}

class ArmoryActionSuccess extends ArmoryState {
  final String message;
  const ArmoryActionSuccess({required this.message});
  @override
  List<Object> get props => [message];
}

class ArmoryError extends ArmoryState {
  final String message;
  const ArmoryError({required this.message});
  @override
  List<Object> get props => [message];
}

class MaintenanceLoaded extends ArmoryState {
  final List<ArmoryMaintenance> maintenance;
  const MaintenanceLoaded({required this.maintenance});
  @override
  List<Object> get props => [maintenance];
}


class ShowingAddForm extends ArmoryState {
  final ArmoryTabType tabType;
  const ShowingAddForm({required this.tabType});
  @override
  List<Object> get props => [tabType];
}