// lib/user_dashboard/data/repositories/armory_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/entities/armory_loadout.dart';
import '../../domain/entities/dropdown_option.dart';
import '../../domain/repositories/armory_repository.dart';
import '../../utils/caliber_calculator.dart';
import '../datasources/armory_remote_datasource.dart';
import '../models/armory_firearm_model.dart';
import '../models/armory_ammunition_model.dart';
import '../models/armory_gear_model.dart';
import '../models/armory_maintenance_model.dart';
import '../models/armory_tool_model.dart';
import '../models/armory_loadout_model.dart';

class ArmoryRepositoryImpl implements ArmoryRepository {
  final ArmoryRemoteDataSource remoteDataSource;

  ArmoryRepositoryImpl({
    required this.remoteDataSource,
  });

  // =============== Pure CRUD Operations ===============
  @override
  Future<Either<Failure, List<ArmoryFirearm>>> getFirearms(String userId) async {
    try {
      final models = await remoteDataSource.getFirearms(userId);
      return Right(models.cast<ArmoryFirearm>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFirearm(String userId, ArmoryFirearm firearm) async {
    try {
      final model = _mapFirearmToModel(firearm);
      await remoteDataSource.addFirearm(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFirearm(String userId, ArmoryFirearm firearm) async {
    try {
      final model = firearm as ArmoryFirearmModel;
      await remoteDataSource.updateFirearm(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFirearm(String userId, String firearmId) async {
    try {
      await remoteDataSource.deleteFirearm(userId, firearmId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Ammunition CRUD ===============
  @override
  Future<Either<Failure, List<ArmoryAmmunition>>> getAmmunition(String userId) async {
    try {
      final models = await remoteDataSource.getAmmunition(userId);
      return Right(models.cast<ArmoryAmmunition>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAmmunition(String userId, ArmoryAmmunition ammunition) async {
    try {
      final model = _mapAmmunitionToModel(ammunition);
      await remoteDataSource.addAmmunition(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAmmunition(String userId, ArmoryAmmunition ammunition) async {
    try {
      final model = ammunition as ArmoryAmmunitionModel;
      await remoteDataSource.updateAmmunition(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAmmunition(String userId, String ammunitionId) async {
    try {
      await remoteDataSource.deleteAmmunition(userId, ammunitionId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Gear CRUD ===============
  @override
  Future<Either<Failure, List<ArmoryGear>>> getGear(String userId) async {
    try {
      final models = await remoteDataSource.getGear(userId);
      return Right(models.cast<ArmoryGear>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addGear(String userId, ArmoryGear gear) async {
    try {
      final model = _mapGearToModel(gear);
      await remoteDataSource.addGear(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGear(String userId, ArmoryGear gear) async {
    try {
      final model = gear as ArmoryGearModel;
      await remoteDataSource.updateGear(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGear(String userId, String gearId) async {
    try {
      await remoteDataSource.deleteGear(userId, gearId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Tools CRUD ===============
  @override
  Future<Either<Failure, List<ArmoryTool>>> getTools(String userId) async {
    try {
      final models = await remoteDataSource.getTools(userId);
      return Right(models.cast<ArmoryTool>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addTool(String userId, ArmoryTool tool) async {
    try {
      final model = _mapToolToModel(tool);
      await remoteDataSource.addTool(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTool(String userId, ArmoryTool tool) async {
    try {
      final model = tool as ArmoryToolModel;
      await remoteDataSource.updateTool(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTool(String userId, String toolId) async {
    try {
      await remoteDataSource.deleteTool(userId, toolId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Loadouts CRUD ===============
  @override
  Future<Either<Failure, List<ArmoryLoadout>>> getLoadouts(String userId) async {
    try {
      final models = await remoteDataSource.getLoadouts(userId);
      return Right(models.cast<ArmoryLoadout>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addLoadout(String userId, ArmoryLoadout loadout) async {
    try {
      final model = _mapLoadoutToModel(loadout);
      await remoteDataSource.addLoadout(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoadout(String userId, ArmoryLoadout loadout) async {
    try {
      final model = loadout as ArmoryLoadoutModel;
      await remoteDataSource.updateLoadout(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLoadout(String userId, String loadoutId) async {
    try {
      await remoteDataSource.deleteLoadout(userId, loadoutId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Maintenance CRUD ===============
  @override
  Future<Either<Failure, List<ArmoryMaintenance>>> getMaintenance(String userId) async {
    try {
      final models = await remoteDataSource.getMaintenance(userId);
      return Right(models.cast<ArmoryMaintenance>());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addMaintenance(String userId, ArmoryMaintenance maintenance) async {
    try {
      final model = _mapMaintenanceToModel(maintenance);
      await remoteDataSource.addMaintenance(userId, model);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMaintenance(String userId, String maintenanceId) async {
    try {
      await remoteDataSource.deleteMaintenance(userId, maintenanceId);
      return const Right(null);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Raw Data Access (For Use Cases) ===============
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getFirearmsRawData() async {
    try {
      final data = await remoteDataSource.getFirearmsRawData();
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAmmunitionRawData() async {
    try {
      final data = await remoteDataSource.getAmmunitionRawData();
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserFirearmsRawData(String userId) async {
    try {
      final data = await remoteDataSource.getUserFirearmsRawData(userId);
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserAmmunitionRawData(String userId) async {
    try {
      final data = await remoteDataSource.getUserAmmunitionRawData(userId);
      return Right(data);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  // =============== Simple Dropdown Methods (For backward compatibility) ===============
  @override
  Future<Either<Failure, List<DropdownOption>>> getFirearmBrands([String? type]) async {
    // This will be handled by Use Cases now, but keeping for interface compatibility
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

  // =============== Entity to Model Mapping ===============
  ArmoryFirearmModel _mapFirearmToModel(ArmoryFirearm firearm) {
    return ArmoryFirearmModel(
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
    // Auto-calculate diameter agar nahi hai
    final diameter = ammunition.bulletDiameter ??
        CaliberCalculator.calculateBulletDiameter(
            ammunition.caliber,
            ammunition.bulletDiameter
        );
    return ArmoryAmmunitionModel(
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
      bulletDiameter: diameter,  // ADD THIS with calculated value
      dateAdded: ammunition.dateAdded,
    );
  }

  ArmoryGearModel _mapGearToModel(ArmoryGear gear) {
    return ArmoryGearModel(
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
      name: loadout.name,
      firearmId: loadout.firearmId,
      ammunitionId: loadout.ammunitionId,
      gearIds: loadout.gearIds,
      notes: loadout.notes,
      dateAdded: loadout.dateAdded,
    );
  }

  ArmoryMaintenanceModel _mapMaintenanceToModel(ArmoryMaintenance maintenance) {
    return ArmoryMaintenanceModel(
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