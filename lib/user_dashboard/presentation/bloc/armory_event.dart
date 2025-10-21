// lib/user_dashboard/presentation/bloc/armory_event.dart
import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/entities/armory_loadout.dart';
import '../../domain/usecases/get_dropdown_options_usecase.dart';
import '../widgets/tab_widgets/armory_tab_view.dart';

abstract class ArmoryEvent extends Equatable {
  const ArmoryEvent();

  @override
  List<Object> get props => [];
}

// Load Events
class LoadFirearmsEvent extends ArmoryEvent {
  final String userId;
  const LoadFirearmsEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class LoadAmmunitionEvent extends ArmoryEvent {
  final String userId;
  const LoadAmmunitionEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class LoadGearEvent extends ArmoryEvent {
  final String userId;
  const LoadGearEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class LoadToolsEvent extends ArmoryEvent {
  final String userId;
  const LoadToolsEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class LoadLoadoutsEvent extends ArmoryEvent {
  final String userId;
  const LoadLoadoutsEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

// Add Events
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

// Dropdown Events
// lib/user_dashboard/presentation/bloc/armory_event.dart - Update LoadDropdownOptionsEvent

class LoadDropdownOptionsEvent extends ArmoryEvent {
  final DropdownType type;
  final String? filterValue;// Add this

  const LoadDropdownOptionsEvent({
    required this.type,
    this.filterValue,   // Add this
  });

  @override
  List<Object> get props => [
    type,
    filterValue ?? '',    // Add this
  ];
}

class LoadMaintenanceEvent extends ArmoryEvent {
  final String userId;
  const LoadMaintenanceEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}

class AddMaintenanceEvent extends ArmoryEvent {
  final String userId;
  final ArmoryMaintenance maintenance;
  const AddMaintenanceEvent({required this.userId, required this.maintenance});
  @override
  List<Object> get props => [userId, maintenance];
}



// Delete Events
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


class ShowAddFormEvent extends ArmoryEvent {
  final ArmoryTabType tabType;
  const ShowAddFormEvent({required this.tabType});
  @override
  List<Object> get props => [tabType];
}

class HideFormEvent extends ArmoryEvent {
  const HideFormEvent();
}