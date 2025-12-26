import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pa_sreens/armory/data/datasources/armory_local_dataresouces.dart';
import 'package:pa_sreens/armory/data/datasources/armory_remote_datasource.dart';
import 'package:pa_sreens/armory/data/models/armory_firearm_model.dart';
import '../../../core/utils/database_helper.dart';
import '../../../core/utils/logger.dart';


class ArmorySyncService {
  final ArmoryLocalDataSource local;
  final ArmoryRemoteDataSource remote;
  final DatabaseHelper dbHelper = DatabaseHelper();

  ArmorySyncService(this.local, this.remote);

  /// ✅ Checks for internet connectivity
  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.mobile ||
           result == ConnectivityResult.wifi;
  }

  /// ✅ Main sync function (call on app start or when connectivity restored)
  Future<void> syncAllPendingData(String userId) async {
    if (!await _isOnline) {
      log.w('⚠️ No internet connection — skipping sync');
      return;
    }

    log.i('🔄 Starting data sync for user: $userId');
    final db = await dbHelper.database;

    // ========== FIREARMS ==========
    final pendingFirearms = await db.query(
      'firearms',
      where: "syncStatus != 'synced'",
    );

    for (final record in pendingFirearms) {
      try {
        final firearm = ArmoryFirearmModel.fromMap(record, userId);
        final status = record['syncStatus'];

        if (status == 'pending') {
          await remote.addFirearm(userId, firearm);
          await db.update(
            'firearms',
            {'syncStatus': 'synced'},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          log.i('✅ Synced firearm ${record['id']}');
        } else if (status == 'deleted') {
          await remote.deleteFirearm(userId,record['id'].toString());
          await db.delete('firearms', where: 'id = ?', whereArgs: [record['id']]);
          log.i('🗑️ Deleted firearm ${record['id']} from remote and local');
        }
      } catch (e) {
        log.e('❌ Firearm sync failed: $e');
      }
    }

  //   // ========== AMMUNITION ==========
  //   final pendingAmmo = await db.query(
  //     'ammunition',
  //     where: "syncStatus != 'synced'",
  //   );

  //   for (final record in pendingAmmo) {
  //     try {
  //       final ammo = ArmoryAmmunitionModel.fromMap(record, userId);
  //       final status = record['syncStatus'];

  //       if (status == 'pending') {
  //         await remote.uploadAmmunition(ammo);
  //         await db.update('ammunition', {'syncStatus': 'synced'},
  //             where: 'id = ?', whereArgs: [record['id']]);
  //         log.i('✅ Synced ammunition ${record['id']}');
  //       } else if (status == 'deleted') {
  //         await remote.deleteAmmunition(record['id']);
  //         await db.delete('ammunition', where: 'id = ?', whereArgs: [record['id']]);
  //         log.i('🗑️ Deleted ammunition ${record['id']}');
  //       }
  //     } catch (e) {
  //       log.e('❌ Ammunition sync failed: $e');
  //     }
  //   }

  //   // ========== GEAR ==========
  //   final pendingGear = await db.query('gear', where: "syncStatus != 'synced'");
  //   for (final record in pendingGear) {
  //     try {
  //       final gear = ArmoryGearModel.fromMap(record, userId);
  //       final status = record['syncStatus'];

  //       if (status == 'pending') {
  //         await remote.uploadGear(gear);
  //         await db.update('gear', {'syncStatus': 'synced'},
  //             where: 'id = ?', whereArgs: [record['id']]);
  //         log.i('✅ Synced gear ${record['id']}');
  //       } else if (status == 'deleted') {
  //         await remote.deleteGear(record['id']);
  //         await db.delete('gear', where: 'id = ?', whereArgs: [record['id']]);
  //       }
  //     } catch (e) {
  //       log.e('❌ Gear sync failed: $e');
  //     }
  //   }

  //   // ========== TOOLS ==========
  //   final pendingTools = await db.query('tools', where: "syncStatus != 'synced'");
  //   for (final record in pendingTools) {
  //     try {
  //       final tool = ArmoryToolModel.fromMap(record, userId);
  //       final status = record['syncStatus'];

  //       if (status == 'pending') {
  //         await remote.uploadTool(tool);
  //         await db.update('tools', {'syncStatus': 'synced'},
  //             where: 'id = ?', whereArgs: [record['id']]);
  //         log.i('✅ Synced tool ${record['id']}');
  //       } else if (status == 'deleted') {
  //         await remote.deleteTool(record['id']);
  //         await db.delete('tools', where: 'id = ?', whereArgs: [record['id']]);
  //       }
  //     } catch (e) {
  //       log.e('❌ Tool sync failed: $e');
  //     }
  //   }

  //   // ========== LOADOUTS ==========
  //   final pendingLoadouts =
  //       await db.query('loadouts', where: "syncStatus != 'synced'");
  //   for (final record in pendingLoadouts) {
  //     try {
  //       final loadout = ArmoryLoadoutModel.fromMap(record, userId);
  //       final status = record['syncStatus'];

  //       if (status == 'pending') {
  //         await remote.uploadLoadout(loadout);
  //         await db.update('loadouts', {'syncStatus': 'synced'},
  //             where: 'id = ?', whereArgs: [record['id']]);
  //         log.i('✅ Synced loadout ${record['id']}');
  //       } else if (status == 'deleted') {
  //         await remote.deleteLoadout(record['id']);
  //         await db.delete('loadouts', where: 'id = ?', whereArgs: [record['id']]);
  //       }
  //     } catch (e) {
  //       log.e('❌ Loadout sync failed: $e');
  //     }
  //   }

  //   // ========== MAINTENANCE ==========
  //   final pendingMaint = await db.query(
  //     'maintenance',
  //     where: "syncStatus != 'synced'",
  //   );
  //   for (final record in pendingMaint) {
  //     try {
  //       final maintenance = ArmoryMaintenanceModel.fromMap(record, userId);
  //       final status = record['syncStatus'];

  //       if (status == 'pending') {
  //         await remote.uploadMaintenance(maintenance);
  //         await db.update('maintenance', {'syncStatus': 'synced'},
  //             where: 'id = ?', whereArgs: [record['id']]);
  //         log.i('✅ Synced maintenance ${record['id']}');
  //       } else if (status == 'deleted') {
  //         await remote.deleteMaintenance(record['id']);
  //         await db.delete('maintenance', where: 'id = ?', whereArgs: [record['id']]);
  //       }
  //     } catch (e) {
  //       log.e('❌ Maintenance sync failed: $e');
  //     }
  //   }

  //   log.i('🎉 All pending data synced successfully for user: $userId');
   }
}
