// lib/armory/domain/usecases/sync_local_to_remote_usecase.dart - NEW FILE
import 'package:dartz/dartz.dart';
import 'package:pa_sreens/core/error/failures.dart';
import 'package:pa_sreens/core/usecases/usecase.dart';
import '../../../core/utils/logger.dart';

import '../../data/datasources/armory_local_dataresouces.dart';
import '../../data/datasources/armory_local_repository_impl.dart';
import '../../data/datasources/armory_remote_datasource.dart';

class SyncLocalToRemoteUseCase implements UseCase<void, UserIdParams> {
  final ArmoryLocalDataSource localDataSource;
  final ArmoryRemoteDataSource remoteDataSource;

  SyncLocalToRemoteUseCase({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  // lib/armory/domain/usecases/sync_local_to_remote_usecase.dart - MODIFY to handle deletes
  // lib/armory/domain/usecases/sync_local_to_remote_usecase.dart - MODIFY delete handling
  @override
  Future<Either<Failure, void>> call(UserIdParams params) async {
    try {
      log.i('🔼 Starting upload sync for user: ${params.userId}');

      // Handle deletes first
      final deletedFirearms = await (localDataSource as ArmoryLocalDataSourceImpl).getDeletedItems(params.userId, 'firearms');
      for (final item in deletedFirearms) {
        try {
          await remoteDataSource.deleteFirearm(params.userId, item['id'] as String);
        } catch (e) {
          if (e.toString().contains('not-found')) {
            log.i('ℹ️ Firearm ${item['id']} not in Firebase, skipping delete');
          } else {
            rethrow;
          }
        }
        await (localDataSource as ArmoryLocalDataSourceImpl).db.then((db) =>
            db.delete('firearms', where: 'id = ? AND userId = ?', whereArgs: [item['id'], params.userId])
        );
      }
      log.i('🗑️ Deleted ${deletedFirearms.length} firearms');

      final deletedAmmo = await (localDataSource as ArmoryLocalDataSourceImpl).getDeletedItems(params.userId, 'ammunition');
      for (final item in deletedAmmo) {
        try {
          await remoteDataSource.deleteAmmunition(params.userId, item['id'] as String);
        } catch (e) {
          if (e.toString().contains('not-found')) {
            log.i('ℹ️ Ammunition ${item['id']} not in Firebase, skipping delete');
          } else {
            rethrow;
          }
        }
        await (localDataSource as ArmoryLocalDataSourceImpl).db.then((db) =>
            db.delete('ammunition', where: 'id = ? AND userId = ?', whereArgs: [item['id'], params.userId])
        );
      }
      log.i('🗑️ Deleted ${deletedAmmo.length} ammunition');

      final deletedGear = await (localDataSource as ArmoryLocalDataSourceImpl).getDeletedItems(params.userId, 'gear');
      for (final item in deletedGear) {
        try {
          await remoteDataSource.deleteGear(params.userId, item['id'] as String);
        } catch (e) {
          if (e.toString().contains('not-found')) {
            log.i('ℹ️ Gear ${item['id']} not in Firebase, skipping delete');
          } else {
            rethrow;
          }
        }
        await (localDataSource as ArmoryLocalDataSourceImpl).db.then((db) =>
            db.delete('gear', where: 'id = ? AND userId = ?', whereArgs: [item['id'], params.userId])
        );
      }
      log.i('🗑️ Deleted ${deletedGear.length} gear');

      final deletedTools = await (localDataSource as ArmoryLocalDataSourceImpl).getDeletedItems(params.userId, 'tools');
      for (final item in deletedTools) {
        try {
          await remoteDataSource.deleteTool(params.userId, item['id'] as String);
        } catch (e) {
          if (e.toString().contains('not-found')) {
            log.i('ℹ️ Tool ${item['id']} not in Firebase, skipping delete');
          } else {
            rethrow;
          }
        }
        await (localDataSource as ArmoryLocalDataSourceImpl).db.then((db) =>
            db.delete('tools', where: 'id = ? AND userId = ?', whereArgs: [item['id'], params.userId])
        );
      }
      log.i('🗑️ Deleted ${deletedTools.length} tools');

      final deletedLoadouts = await (localDataSource as ArmoryLocalDataSourceImpl).getDeletedItems(params.userId, 'loadouts');
      for (final item in deletedLoadouts) {
        try {
          await remoteDataSource.deleteLoadout(params.userId, item['id'] as String);
        } catch (e) {
          if (e.toString().contains('not-found')) {
            log.i('ℹ️ Loadout ${item['id']} not in Firebase, skipping delete');
          } else {
            rethrow;
          }
        }
        await (localDataSource as ArmoryLocalDataSourceImpl).db.then((db) =>
            db.delete('loadouts', where: 'id = ? AND userId = ?', whereArgs: [item['id'], params.userId])
        );
      }
      log.i('🗑️ Deleted ${deletedLoadouts.length} loadouts');

      final deletedMaintenance = await (localDataSource as ArmoryLocalDataSourceImpl).getDeletedItems(params.userId, 'maintenance');
      for (final item in deletedMaintenance) {
        try {
          await remoteDataSource.deleteMaintenance(params.userId, item['id'] as String);
        } catch (e) {
          if (e.toString().contains('not-found')) {
            log.i('ℹ️ Maintenance ${item['id']} not in Firebase, skipping delete');
          } else {
            rethrow;
          }
        }
        await (localDataSource as ArmoryLocalDataSourceImpl).db.then((db) =>
            db.delete('maintenance', where: 'id = ? AND userId = ?', whereArgs: [item['id'], params.userId])
        );
      }
      log.i('🗑️ Deleted ${deletedMaintenance.length} maintenance');

      // Upload new/modified items
      final unsyncedFirearms = await localDataSource.getUnsyncedFirearms(params.userId);
      for (final firearm in unsyncedFirearms) {
        await remoteDataSource.addFirearm(params.userId, firearm);
        await localDataSource.markAsSynced('firearms', params.userId, firearm.id!);
      }
      log.i('✅ Uploaded ${unsyncedFirearms.length} firearms');

      final unsyncedAmmo = await localDataSource.getUnsyncedAmmunition(params.userId);
      for (final ammo in unsyncedAmmo) {
        await remoteDataSource.addAmmunition(params.userId, ammo);
        await localDataSource.markAsSynced('ammunition', params.userId, ammo.id!);
      }
      log.i('✅ Uploaded ${unsyncedAmmo.length} ammunition');

      final unsyncedGear = await localDataSource.getUnsyncedGear(params.userId);
      for (final gear in unsyncedGear) {
        await remoteDataSource.addGear(params.userId, gear);
        await localDataSource.markAsSynced('gear', params.userId, gear.id!);
      }
      log.i('✅ Uploaded ${unsyncedGear.length} gear');

      final unsyncedTools = await localDataSource.getUnsyncedTools(params.userId);
      for (final tool in unsyncedTools) {
        await remoteDataSource.addTool(params.userId, tool);
        await localDataSource.markAsSynced('tools', params.userId, tool.id!);
      }
      log.i('✅ Uploaded ${unsyncedTools.length} tools');

      final unsyncedLoadouts = await localDataSource.getUnsyncedLoadouts(params.userId);
      for (final loadout in unsyncedLoadouts) {
        await remoteDataSource.addLoadout(params.userId, loadout);
        await localDataSource.markAsSynced('loadouts', params.userId, loadout.id!);
      }
      log.i('✅ Uploaded ${unsyncedLoadouts.length} loadouts');

      final unsyncedMaintenance = await localDataSource.getUnsyncedMaintenance(params.userId);
      for (final maintenance in unsyncedMaintenance) {
        await remoteDataSource.addMaintenance(params.userId, maintenance);
        await localDataSource.markAsSynced('maintenance', params.userId, maintenance.id!);
      }
      log.i('✅ Uploaded ${unsyncedMaintenance.length} maintenance');

      log.i('🎉 Upload sync completed');
      return const Right(null);
    } catch (e) {
      log.e('❌ Upload sync failed: $e');
      return Left(FileFailure('Upload sync failed: $e'));
    }
  }
}