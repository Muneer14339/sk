import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/entities/armory_loadout.dart';
import '../../domain/usecases/get_dropdown_options_usecase.dart';
import '../widgets/common/common_delete_dilogue.dart';

abstract class ArmoryEvent extends Equatable {
  const ArmoryEvent();

  @override
  List<Object> get props => [];
}

class LoadAllDataEvent extends ArmoryEvent {
  final String userId;
  const LoadAllDataEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class AddFirearmEvent extends ArmoryEvent {
  final String userId;
  final ArmoryFirearm firearm;
  const AddFirearmEvent({required this.userId, required this.firearm});
  @override
  List<Object> get props => [userId, firearm];
}

class AddAmmunitionEvent extends ArmoryEvent {
  final String userId;
  final ArmoryAmmunition ammunition;
  const AddAmmunitionEvent({required this.userId, required this.ammunition});
  @override
  List<Object> get props => [userId, ammunition];
}

class AddGearEvent extends ArmoryEvent {
  final String userId;
  final ArmoryGear gear;
  const AddGearEvent({required this.userId, required this.gear});
  @override
  List<Object> get props => [userId, gear];
}

class AddToolEvent extends ArmoryEvent {
  final String userId;
  final ArmoryTool tool;
  const AddToolEvent({required this.userId, required this.tool});
  @override
  List<Object> get props => [userId, tool];
}

class AddLoadoutEvent extends ArmoryEvent {
  final String userId;
  final ArmoryLoadout loadout;
  const AddLoadoutEvent({required this.userId, required this.loadout});
  @override
  List<Object> get props => [userId, loadout];
}

class AddMaintenanceEvent extends ArmoryEvent {
  final String userId;
  final ArmoryMaintenance maintenance;
  const AddMaintenanceEvent({required this.userId, required this.maintenance});
  @override
  List<Object> get props => [userId, maintenance];
}

class DeleteFirearmEvent extends ArmoryEvent {
  final String userId;
  final ArmoryFirearm firearm;
  const DeleteFirearmEvent({required this.userId, required this.firearm});
  @override
  List<Object> get props => [userId, firearm];
}

class DeleteAmmunitionEvent extends ArmoryEvent {
  final String userId;
  final ArmoryAmmunition ammunition;
  const DeleteAmmunitionEvent({required this.userId, required this.ammunition});
  @override
  List<Object> get props => [userId, ammunition];
}

class DeleteGearEvent extends ArmoryEvent {
  final String userId;
  final ArmoryGear gear;
  const DeleteGearEvent({required this.userId, required this.gear});
  @override
  List<Object> get props => [userId, gear];
}

class DeleteToolEvent extends ArmoryEvent {
  final String userId;
  final ArmoryTool tool;
  const DeleteToolEvent({required this.userId, required this.tool});
  @override
  List<Object> get props => [userId, tool];
}

class DeleteMaintenanceEvent extends ArmoryEvent {
  final String userId;
  final ArmoryMaintenance maintenance;
  const DeleteMaintenanceEvent({required this.userId, required this.maintenance});
  @override
  List<Object> get props => [userId, maintenance];
}

class DeleteLoadoutEvent extends ArmoryEvent {
  final String userId;
  final ArmoryLoadout loadout;
  const DeleteLoadoutEvent({required this.userId, required this.loadout});
  @override
  List<Object> get props => [userId, loadout];
}

class LoadDropdownOptionsEvent extends ArmoryEvent {
  final DropdownType type;
  final String? filterValue;

  const LoadDropdownOptionsEvent({
    required this.type,
    this.filterValue,
  });

  @override
  List<Object> get props => [
    type,
    filterValue ?? '',
  ];
}

class ShowAddFormEvent extends ArmoryEvent {
  final ArmoryTabType tabType;
  const ShowAddFormEvent({required this.tabType});
  @override
  List<Object> get props => [tabType];
}

class HideFormEvent extends ArmoryEvent {
  const HideFormEvent();
}