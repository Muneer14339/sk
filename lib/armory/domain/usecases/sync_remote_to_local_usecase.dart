// lib/armory/domain/usecases/sync_remote_to_local_usecase.dart - NEW FILE
import 'package:dartz/dartz.dart';
import 'package:pa_sreens/core/error/failures.dart';
import 'package:pa_sreens/core/usecases/usecase.dart';
import '../../../core/utils/database_helper.dart';
import '../../../core/utils/logger.dart';

import '../../data/datasources/armory_local_dataresouces.dart';
import '../../data/datasources/armory_remote_datasource.dart';

class SyncRemoteToLocalUseCase implements UseCase<void, UserIdParams> {
  final ArmoryLocalDataSource localDataSource;
  final ArmoryRemoteDataSource remoteDataSource;
  final DatabaseHelper dbHelper;

  SyncRemoteToLocalUseCase({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.dbHelper,
  });

  // lib/armory/domain/usecases/sync_remote_to_local_usecase.dart - REPLACE entire call method
  @override
  Future<Either<Failure, void>> call(UserIdParams params) async {
    try {
      log.i('🔽 Starting download sync for user: ${params.userId}');

      // Get all remote data
      final remoteFirearms = await remoteDataSource.getFirearms(params.userId);
      final remoteFirearmIds = remoteFirearms.map((e) => e.id!).toSet();

      // Get local data
      final db = await dbHelper.database;
      final localFirearms = await db.query('firearms',
          where: 'userId = ?',
          whereArgs: [params.userId]
      );

      // Delete items that don't exist in remote (were deleted from Firebase)
      for (final local in localFirearms) {
        if (!remoteFirearmIds.contains(local['id'])) {
          await db.delete('firearms',
              where: 'id = ? AND userId = ?',
              whereArgs: [local['id'], params.userId]
          );
        }
      }

      // Add/update items from remote
      for (final firearm in remoteFirearms) {
        await localDataSource.addFirearm(params.userId, firearm);
        await localDataSource.markAsSynced('firearms', params.userId, firearm.id!);
      }
      log.i('✅ Synced ${remoteFirearms.length} firearms');

      // Repeat for ammunition
      final remoteAmmo = await remoteDataSource.getAmmunition(params.userId);
      final remoteAmmoIds = remoteAmmo.map((e) => e.id!).toSet();
      final localAmmo = await db.query('ammunition', where: 'userId = ?', whereArgs: [params.userId]);
      for (final local in localAmmo) {
        if (!remoteAmmoIds.contains(local['id'])) {
          await db.delete('ammunition', where: 'id = ? AND userId = ?', whereArgs: [local['id'], params.userId]);
        }
      }
      for (final ammo in remoteAmmo) {
        await localDataSource.addAmmunition(params.userId, ammo);
        await localDataSource.markAsSynced('ammunition', params.userId, ammo.id!);
      }
      log.i('✅ Synced ${remoteAmmo.length} ammunition');

      // Repeat for gear
      final remoteGear = await remoteDataSource.getGear(params.userId);
      final remoteGearIds = remoteGear.map((e) => e.id!).toSet();
      final localGear = await db.query('gear', where: 'userId = ?', whereArgs: [params.userId]);
      for (final local in localGear) {
        if (!remoteGearIds.contains(local['id'])) {
          await db.delete('gear', where: 'id = ? AND userId = ?', whereArgs: [local['id'], params.userId]);
        }
      }
      for (final gear in remoteGear) {
        await localDataSource.addGear(params.userId, gear);
        await localDataSource.markAsSynced('gear', params.userId, gear.id!);
      }
      log.i('✅ Synced ${remoteGear.length} gear');

      // Repeat for tools
      final remoteTools = await remoteDataSource.getTools(params.userId);
      final remoteToolIds = remoteTools.map((e) => e.id!).toSet();
      final localTools = await db.query('tools', where: 'userId = ?', whereArgs: [params.userId]);
      for (final local in localTools) {
        if (!remoteToolIds.contains(local['id'])) {
          await db.delete('tools', where: 'id = ? AND userId = ?', whereArgs: [local['id'], params.userId]);
        }
      }
      for (final tool in remoteTools) {
        await localDataSource.addTool(params.userId, tool);
        await localDataSource.markAsSynced('tools', params.userId, tool.id!);
      }
      log.i('✅ Synced ${remoteTools.length} tools');

      // Repeat for loadouts
      final remoteLoadouts = await remoteDataSource.getLoadouts(params.userId);
      final remoteLoadoutIds = remoteLoadouts.map((e) => e.id!).toSet();
      final localLoadouts = await db.query('loadouts', where: 'userId = ?', whereArgs: [params.userId]);
      for (final local in localLoadouts) {
        if (!remoteLoadoutIds.contains(local['id'])) {
          await db.delete('loadouts', where: 'id = ? AND userId = ?', whereArgs: [local['id'], params.userId]);
        }
      }
      for (final loadout in remoteLoadouts) {
        await localDataSource.addLoadout(params.userId, loadout);
        await localDataSource.markAsSynced('loadouts', params.userId, loadout.id!);
      }
      log.i('✅ Synced ${remoteLoadouts.length} loadouts');

      // Repeat for maintenance
      final remoteMaintenance = await remoteDataSource.getMaintenance(params.userId);
      final remoteMaintenanceIds = remoteMaintenance.map((e) => e.id!).toSet();
      final localMaintenance = await db.query('maintenance', where: 'userId = ?', whereArgs: [params.userId]);
      for (final local in localMaintenance) {
        if (!remoteMaintenanceIds.contains(local['id'])) {
          await db.delete('maintenance', where: 'id = ? AND userId = ?', whereArgs: [local['id'], params.userId]);
        }
      }
      for (final maintenance in remoteMaintenance) {
        await localDataSource.addMaintenance(params.userId, maintenance);
        await localDataSource.markAsSynced('maintenance', params.userId, maintenance.id!);
      }
      log.i('✅ Synced ${remoteMaintenance.length} maintenance');

      log.i('🎉 Download sync completed');
      return const Right(null);
    } catch (e) {
      log.e('❌ Download sync failed: $e');
      return Left(FileFailure('Download sync failed: $e'));
    }
  }
}