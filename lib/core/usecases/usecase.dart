import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../user_dashboard/domain/entities/armory_ammunition.dart';
import '../../user_dashboard/domain/entities/armory_firearm.dart';
import '../../user_dashboard/domain/entities/armory_gear.dart';
import '../../user_dashboard/domain/entities/armory_loadout.dart';
import '../../user_dashboard/domain/entities/armory_maintenance.dart';
import '../../user_dashboard/domain/entities/armory_tool.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
// Parameters
class UserIdParams {
  final String userId;
  UserIdParams({required this.userId});
}

class AddFirearmParams {
  final String userId;
  final ArmoryFirearm firearm;
  AddFirearmParams({required this.userId, required this.firearm});
}

class DeleteFirearmParams {
  final String userId;
  final ArmoryFirearm firearm;
  DeleteFirearmParams({required this.userId, required this.firearm});
}

class AddAmmunitionParams {
  final String userId;
  final ArmoryAmmunition ammunition;
  AddAmmunitionParams({required this.userId, required this.ammunition});
}

class DeleteAmmunitionParams {
  final String userId;
  final ArmoryAmmunition ammunition;
  DeleteAmmunitionParams({required this.userId, required this.ammunition});
}

class AddGearParams {
  final String userId;
  final ArmoryGear gear;
  AddGearParams({required this.userId, required this.gear});
}

class DeleteGearParams {
  final String userId;
  final ArmoryGear gear;
  DeleteGearParams({required this.userId, required this.gear});
}

class AddToolParams {
  final String userId;
  final ArmoryTool tool;
  AddToolParams({required this.userId, required this.tool});
}

class DeleteToolParams {
  final String userId;
  final ArmoryTool tool;
  DeleteToolParams({required this.userId, required this.tool});
}

class AddLoadoutParams {
  final String userId;
  final ArmoryLoadout loadout;
  AddLoadoutParams({required this.userId, required this.loadout});
}

class DeleteLoadoutParams {
  final String userId;
  final ArmoryLoadout loadout;
  DeleteLoadoutParams({required this.userId, required this.loadout});
}

class AddMaintenanceParams {
  final String userId;
  final ArmoryMaintenance maintenance;
  AddMaintenanceParams({required this.userId, required this.maintenance});
}

class DeleteMaintenanceParams {
  final String userId;
  final ArmoryMaintenance maintenance;
  DeleteMaintenanceParams({required this.userId, required this.maintenance});
}

class DropdownParams extends Equatable {
  final DropdownType type;
  final String? filterValue;
  final String? secondaryFilter;
  final String? tertiaryFilter;  // Add this
  final String? quaternaryFilter;  // Add this
  final String? quinaryFilter;  // Add this

  const DropdownParams({
    required this.type,
    this.filterValue,
    this.secondaryFilter,
    this.tertiaryFilter,    // Add this
    this.quaternaryFilter,  // Add this
    this.quinaryFilter,     // Add this
  });

  @override
  List<Object> get props => [
    type,
    filterValue ?? '',
    secondaryFilter ?? '',
    tertiaryFilter ?? '',     // Add this
    quaternaryFilter ?? '',   // Add this
    quinaryFilter ?? '',      // Add this
  ];
}

enum DropdownType {
  firearmBrands,
  firearmModels,
  firearmGenerations,
  firearmFiringMechanisms,
  firearmMakes,
  calibers,
  ammunitionBrands,
  ammunitionCaliber,
  bulletTypes  // Add this line
}