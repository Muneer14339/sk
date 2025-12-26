import 'package:dartz/dartz.dart';
import 'package:pa_sreens/armory/data/datasources/armory_remote_datasource.dart';
import 'package:pa_sreens/core/error/failures.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_loadout.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/entities/dropdown_option.dart';
import '../../domain/repositories/armory_repository.dart';
import '../../utils/caliber_calculator.dart';
import '../datasources/armory_local_dataresouces.dart';
import '../models/armory_ammunition_model.dart';
import '../models/armory_firearm_model.dart';
import '../models/armory_gear_model.dart';
import '../models/armory_loadout_model.dart';
import '../models/armory_maintenance_model.dart';
import '../models/armory_tool_model.dart';

class ArmoryRepositoryImpl implements ArmoryRepository {
  final ArmoryRemoteDataSource remoteDataSource;
  final ArmoryLocalDataSource localDataSource;
  final _uuid = const Uuid();

  ArmoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<ArmoryFirearm>>> getFirearms(String userId) async {
    try {
      final models = await localDataSource.getFirearms(userId);
      return Right(models.cast<ArmoryFirearm>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFirearm(String userId, ArmoryFirearm firearm) async {
    try {
      final model = _mapFirearmToModel(firearm);
      await localDataSource.addFirearm(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFirearm(String userId, ArmoryFirearm firearm) async {
    try {
      final model = firearm as ArmoryFirearmModel;
      await localDataSource.updateFirearm(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFirearm(String userId, String firearmId) async {
    try {
      await localDataSource.deleteFirearm(userId, firearmId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArmoryAmmunition>>> getAmmunition(String userId) async {
    try {
      final models = await localDataSource.getAmmunition(userId);
      return Right(models.cast<ArmoryAmmunition>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAmmunition(String userId, ArmoryAmmunition ammunition) async {
    try {
      final model = _mapAmmunitionToModel(ammunition);
      await localDataSource.addAmmunition(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAmmunition(String userId, ArmoryAmmunition ammunition) async {
    try {
      final model = ammunition as ArmoryAmmunitionModel;
      await localDataSource.updateAmmunition(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAmmunition(String userId, String ammunitionId) async {
    try {
      await localDataSource.deleteAmmunition(userId, ammunitionId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArmoryGear>>> getGear(String userId) async {
    try {
      final models = await localDataSource.getGear(userId);
      return Right(models.cast<ArmoryGear>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addGear(String userId, ArmoryGear gear) async {
    try {
      final model = _mapGearToModel(gear);
      await localDataSource.addGear(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGear(String userId, ArmoryGear gear) async {
    try {
      final model = gear as ArmoryGearModel;
      await localDataSource.updateGear(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGear(String userId, String gearId) async {
    try {
      await localDataSource.deleteGear(userId, gearId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArmoryTool>>> getTools(String userId) async {
    try {
      final models = await localDataSource.getTools(userId);
      return Right(models.cast<ArmoryTool>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addTool(String userId, ArmoryTool tool) async {
    try {
      final model = _mapToolToModel(tool);
      await localDataSource.addTool(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTool(String userId, ArmoryTool tool) async {
    try {
      final model = tool as ArmoryToolModel;
      await localDataSource.updateTool(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTool(String userId, String toolId) async {
    try {
      await localDataSource.deleteTool(userId, toolId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArmoryLoadout>>> getLoadouts(String userId) async {
    try {
      final models = await localDataSource.getLoadouts(userId);
      return Right(models.cast<ArmoryLoadout>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addLoadout(String userId, ArmoryLoadout loadout) async {
    try {
      final model = _mapLoadoutToModel(loadout);
      await localDataSource.addLoadout(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoadout(String userId, ArmoryLoadout loadout) async {
    try {
      final model = loadout as ArmoryLoadoutModel;
      await localDataSource.updateLoadout(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLoadout(String userId, String loadoutId) async {
    try {
      await localDataSource.deleteLoadout(userId, loadoutId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ArmoryMaintenance>>> getMaintenance(String userId) async {
    try {
      final models = await localDataSource.getMaintenance(userId);
      return Right(models.cast<ArmoryMaintenance>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addMaintenance(String userId, ArmoryMaintenance maintenance) async {
    try {
      final model = _mapMaintenanceToModel(maintenance);
      await localDataSource.addMaintenance(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMaintenance(String userId, String maintenanceId) async {
    try {
      await localDataSource.deleteMaintenance(userId, maintenanceId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getFirearmsRawData() async {
    try {
      final data = await localDataSource.getFirearmsRawData();
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAmmunitionRawData() async {
    try {
      final data = await localDataSource.getAmmunitionRawData();
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserFirearmsRawData(String userId) async {
    try {
      final data = await localDataSource.getUserFirearmsRawData(userId);
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserAmmunitionRawData(String userId) async {
    try {
      final data = await localDataSource.getUserAmmunitionRawData(userId);
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getFirearmBrands([String? type]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getFirearmModels([String? brand]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getFirearmGenerations([String? model]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getCalibers([String? generation]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getFirearmFiringMechanisms([String? caliber]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getFirearmMakes([String? firingMechanism]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getAmmoCalibers() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getAmmunitionBrands([String? caliber]) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<DropdownOption>>> getBulletTypes([String? brand]) async {
    return const Right([]);
  }

  // lib/armory/data/repositories/armory_repository_impl.dart - ADD implementations

  @override
  Future<Either<Failure, void>> batchDeleteLoadouts(String userId, List<String> loadoutIds) async {
    try {
      await localDataSource.batchDeleteLoadouts(userId, loadoutIds);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> batchDeleteAmmunition(String userId, List<String> ammunitionIds) async {
    try {
      await localDataSource.batchDeleteAmmunition(userId, ammunitionIds);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  String _generateId() => _uuid.v4();

  ArmoryFirearmModel _mapFirearmToModel(ArmoryFirearm firearm) {
    return ArmoryFirearmModel(
      id: firearm.id ?? _generateId() ,
      type: firearm.type,
      make: firearm.make,
      model: firearm.model,
      caliber: firearm.caliber,
      nickname: firearm.nickname,
      status: firearm.status,
      serial: firearm.serial,
      notes: firearm.notes,
      brand: firearm.brand,
      generation: firearm.generation,
      firingMechanism: firearm.firingMechanism,
      detailedType: firearm.detailedType,
      purpose: firearm.purpose,
      condition: firearm.condition,
      purchaseDate: firearm.purchaseDate,
      purchasePrice: firearm.purchasePrice,
      currentValue: firearm.currentValue,
      fflDealer: firearm.fflDealer,
      manufacturerPN: firearm.manufacturerPN,
      finish: firearm.finish,
      stockMaterial: firearm.stockMaterial,
      triggerType: firearm.triggerType,
      safetyType: firearm.safetyType,
      feedSystem: firearm.feedSystem,
      magazineCapacity: firearm.magazineCapacity,
      twistRate: firearm.twistRate,
      threadPattern: firearm.threadPattern,
      overallLength: firearm.overallLength,
      weight: firearm.weight,
      barrelLength: firearm.barrelLength,
      actionType: firearm.actionType,
      roundCount: firearm.roundCount,
      lastCleaned: firearm.lastCleaned,
      zeroDistance: firearm.zeroDistance,
      modifications: firearm.modifications,
      accessoriesIncluded: firearm.accessoriesIncluded,
      storageLocation: firearm.storageLocation,
      photos: firearm.photos,
      dateAdded: firearm.dateAdded,
    );
  }

  ArmoryAmmunitionModel _mapAmmunitionToModel(ArmoryAmmunition ammunition) {
    final diameter = ammunition.bulletDiameter ?? CaliberCalculator.calculateBulletDiameter(ammunition.caliber, ammunition.bulletDiameter);
    return ArmoryAmmunitionModel(
      id: ammunition.id ?? _generateId() ,
      brand: ammunition.brand,
      line: ammunition.line,
      caliber: ammunition.caliber,
      bullet: ammunition.bullet,
      quantity: ammunition.quantity,
      status: ammunition.status,
      lot: ammunition.lot,
      notes: ammunition.notes,
      primerType: ammunition.primerType,
      powderType: ammunition.powderType,
      powderWeight: ammunition.powderWeight,
      caseMaterial: ammunition.caseMaterial,
      caseCondition: ammunition.caseCondition,
      headstamp: ammunition.headstamp,
      ballisticCoefficient: ammunition.ballisticCoefficient,
      muzzleEnergy: ammunition.muzzleEnergy,
      velocity: ammunition.velocity,
      temperatureTested: ammunition.temperatureTested,
      standardDeviation: ammunition.standardDeviation,
      extremeSpread: ammunition.extremeSpread,
      groupSize: ammunition.groupSize,
      testDistance: ammunition.testDistance,
      testFirearm: ammunition.testFirearm,
      storageLocation: ammunition.storageLocation,
      purchaseDate: ammunition.purchaseDate,
      purchasePrice: ammunition.purchasePrice,
      costPerRound: ammunition.costPerRound,
      expirationDate: ammunition.expirationDate,
      performanceNotes: ammunition.performanceNotes,
      environmentalConditions: ammunition.environmentalConditions,
      isHandloaded: ammunition.isHandloaded,
      loadData: ammunition.loadData,
      bulletDiameter: diameter,
      dateAdded: ammunition.dateAdded,
    );
  }

  ArmoryGearModel _mapGearToModel(ArmoryGear gear) {
    return ArmoryGearModel(
      id: gear.id?? _generateId() ,
      category: gear.category,
      model: gear.model,
      serial: gear.serial,
      quantity: gear.quantity,
      notes: gear.notes,
      dateAdded: gear.dateAdded,
    );
  }

  ArmoryToolModel _mapToolToModel(ArmoryTool tool) {
    return ArmoryToolModel(
      id: tool.id ?? _generateId() ,
      name: tool.name,
      category: tool.category,
      quantity: tool.quantity,
      status: tool.status,
      notes: tool.notes,
      dateAdded: tool.dateAdded,
    );
  }

  ArmoryLoadoutModel _mapLoadoutToModel(ArmoryLoadout loadout) {
    return ArmoryLoadoutModel(
      id: loadout.id ?? _generateId(),
      name: loadout.name,
      firearmId: loadout.firearmId,
      ammunitionId: loadout.ammunitionId,
      gearIds: loadout.gearIds,
      toolIds: loadout.toolIds,
      maintenanceIds: loadout.maintenanceIds,
      notes: loadout.notes,
      dateAdded: loadout.dateAdded,
    );
  }

  ArmoryMaintenanceModel _mapMaintenanceToModel(ArmoryMaintenance maintenance) {
    return ArmoryMaintenanceModel(
      id: maintenance.id ?? _generateId(),
      assetType: maintenance.assetType,
      assetId: maintenance.assetId,
      maintenanceType: maintenance.maintenanceType,
      date: maintenance.date,
      roundsFired: maintenance.roundsFired,
      notes: maintenance.notes,
      dateAdded: maintenance.dateAdded,
    );
  }
}