import 'package:dartz/dartz.dart';
import 'package:pa_sreens/armory/data/datasources/armory_remote_datasource.dart';
import 'package:pa_sreens/armory/data/models/armory_ammunition_model.dart';
import 'package:pa_sreens/armory/data/models/armory_firearm_model.dart';
import 'package:pa_sreens/core/error/failures.dart';
import 'package:pa_sreens/core/usecases/usecase.dart';
import '../../../core/utils/logger.dart';


import '../../data/datasources/armory_local_dataresouces.dart';
import '../../data/datasources/armory_local_repository_impl.dart';

class InitialDataSyncUseCase implements UseCase<void, UserIdParams> {
  final ArmoryRemoteDataSource remoteDataSource;
  final ArmoryLocalDataSource localDataSource;

  InitialDataSyncUseCase({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // lib/armory/domain/usecases/initial_data_sync_usecase.dart - MODIFY
  @override
  Future<Either<Failure, void>> call(UserIdParams params) async {
    try {
      final isEmpty = await localDataSource.isDatabaseEmpty();

      if (isEmpty) {
        log.i('📥 Fetching system data...');
        final systemFirearmsData = await remoteDataSource.getFirearmsRawData();
        final systemFirearms = systemFirearmsData
            .map<ArmoryFirearmModel>((e) => ArmoryFirearmModel.fromMap(e, e['id']))
            .toList();
        await localDataSource.saveSystemFirearms(systemFirearms);
        log.i('✅ Saved ${systemFirearms.length} system firearms');

        final systemAmmoData = await remoteDataSource.getAmmunitionRawData();
        final systemAmmo = systemAmmoData
            .map<ArmoryAmmunitionModel>((e) => ArmoryAmmunitionModel.fromMap(e, e['id']))
            .toList();
        await localDataSource.saveSystemAmmunition(systemAmmo);
        log.i('✅ Saved ${systemAmmo.length} system ammunition');
      }

      final hasUserData = await localDataSource.hasUserData(params.userId);

      if (!hasUserData) {
        log.i('📥 Fetching user data for: ${params.userId}');

        final remoteFirearms = await remoteDataSource.getFirearms(params.userId);
        await localDataSource.saveUserFirearms(params.userId, remoteFirearms);
        for (final firearm in remoteFirearms) {
          await localDataSource.markAsSynced('firearms', params.userId, firearm.id!);
        }

        final remoteAmmunition = await remoteDataSource.getAmmunition(params.userId);
        await localDataSource.saveUserAmmunition(params.userId, remoteAmmunition);
        for (final ammo in remoteAmmunition) {
          await localDataSource.markAsSynced('ammunition', params.userId, ammo.id!);
        }

        final remoteGear = await remoteDataSource.getGear(params.userId);
        await localDataSource.saveUserGear(params.userId, remoteGear);
        for (final gear in remoteGear) {
          await localDataSource.markAsSynced('gear', params.userId, gear.id!);
        }

        final remoteTools = await remoteDataSource.getTools(params.userId);
        await localDataSource.saveUserTools(params.userId, remoteTools);
        for (final tool in remoteTools) {
          await localDataSource.markAsSynced('tools', params.userId, tool.id!);
        }

        final remoteLoadouts = await remoteDataSource.getLoadouts(params.userId);
        await localDataSource.saveUserLoadouts(params.userId, remoteLoadouts);
        for (final loadout in remoteLoadouts) {
          await localDataSource.markAsSynced('loadouts', params.userId, loadout.id!);
        }

        final remoteMaintenance = await remoteDataSource.getMaintenance(params.userId);
        await localDataSource.saveUserMaintenance(params.userId, remoteMaintenance);
        for (final maintenance in remoteMaintenance) {
          await localDataSource.markAsSynced('maintenance', params.userId, maintenance.id!);
        }

        log.i('✅ User data synced for: ${params.userId}');
      } else {
        log.i('ℹ️ User ${params.userId} already has local data');
      }

      log.i('🎉 Initial sync completed');
      return const Right(null);
    } catch (e, stackTrace) {
      log.e('❌ Failed to sync: $e\n$stackTrace');
      return Left(FileFailure('Failed to sync: $e'));
    }
  }
}