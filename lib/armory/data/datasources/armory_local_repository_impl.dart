import 'dart:developer';

import 'package:pa_sreens/armory/data/models/armory_ammunition_model.dart';
import 'package:pa_sreens/armory/data/models/armory_firearm_model.dart';
import 'package:pa_sreens/armory/data/models/armory_gear_model.dart';
import 'package:pa_sreens/armory/data/models/armory_loadout_model.dart';
import 'package:pa_sreens/armory/data/models/armory_maintenance_model.dart';
import 'package:pa_sreens/armory/data/models/armory_tool_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/utils/database_helper.dart';
import 'armory_local_dataresouces.dart';

class ArmoryLocalDataSourceImpl implements ArmoryLocalDataSource {
  final DatabaseHelper dbHelper;

  ArmoryLocalDataSourceImpl({required DatabaseHelper dbHelper}) : this.dbHelper = dbHelper;

  Future<Database> get db async => await dbHelper.database;

  @override
  Future<List<ArmoryFirearmModel>> getFirearms(String userId) async {
    final db = await this.db;
    final maps = await db.query('firearms',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'deleted'],
        orderBy: 'lastModified DESC'  // ✅ ADD
    );
    return maps.map((map) => ArmoryFirearmModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryAmmunitionModel>> getAmmunition(String userId) async {
    final db = await this.db;
    final maps = await db.query('ammunition',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'deleted'],
        orderBy: 'lastModified DESC'  // ✅ ADD
    );
    return maps.map((map) => ArmoryAmmunitionModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryGearModel>> getGear(String userId) async {
    final db = await this.db;
    final maps = await db.query('gear',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'deleted'],
        orderBy: 'lastModified DESC'  // ✅ ADD
    );
    return maps.map((map) => ArmoryGearModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryToolModel>> getTools(String userId) async {
    final db = await this.db;
    final maps = await db.query('tools',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'deleted'],
        orderBy: 'lastModified DESC'  // ✅ ADD
    );
    return maps.map((map) => ArmoryToolModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryLoadoutModel>> getLoadouts(String userId) async {
    final db = await this.db;
    final maps = await db.query('loadouts',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'deleted'],
        orderBy: 'lastModified DESC'  // ✅ ADD
    );
    return maps.map((map) => ArmoryLoadoutModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryMaintenanceModel>> getMaintenance(String userId) async {
    final db = await this.db;
    final maps = await db.query('maintenance',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'deleted'],
        orderBy: 'lastModified DESC'  // ✅ ADD (or 'date DESC' for maintenance)
    );
    return maps.map((map) => ArmoryMaintenanceModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<void> addFirearm(String userId, ArmoryFirearmModel firearm) async {
    final db = await this.db;
    final map = firearm.toMap();
    map['userId'] = userId;
    map['id'] = firearm.id;
    map['syncStatus'] = 'pending';
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('firearms', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // lib/armory/data/datasources/armory_local_repository_impl.dart - MODIFY all update methods to include lastModified
  @override
  Future<void> updateFirearm(String userId, ArmoryFirearmModel firearm) async {
    final db = await this.db;
    final map = firearm.toMap();
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('firearms', map, where: 'id = ? AND userId = ?', whereArgs: [firearm.id, userId]);
  }

  @override
  Future<void> deleteFirearm(String userId, String firearmId) async {
    final db = await this.db;
    await db.update('firearms',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [firearmId, userId]
    );
  }

  // lib/armory/data/datasources/armory_local_repository_impl.dart - MODIFY addAmmunition
  @override
  Future<void> addAmmunition(String userId, ArmoryAmmunitionModel ammo) async {
    final db = await this.db;
    final map = ammo.toMap();
    map['userId'] = userId;
    map['id'] = ammo.id;
    map['syncStatus'] = 'pending';
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('ammunition', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

// MODIFY updateAmmunition
  @override
  Future<void> updateAmmunition(String userId, ArmoryAmmunitionModel ammo) async {
    final db = await this.db;
    final map = ammo.toMap();
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('ammunition', map, where: 'id = ? AND userId = ?', whereArgs: [ammo.id, userId]);
  }

  @override
  Future<void> deleteAmmunition(String userId, String ammoId) async {
    final db = await this.db;
    await db.update('ammunition',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [ammoId, userId]
    );
  }


  @override
  Future<void> addGear(String userId, ArmoryGearModel gear) async {
    final db = await this.db;
    final map = gear.toMap();
    map['userId'] = userId;
    map['id'] = gear.id;
    map['syncStatus'] = 'pending';
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('gear', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateGear(String userId, ArmoryGearModel gear) async {
    final db = await this.db;
    final map = gear.toMap();
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('gear', map, where: 'id = ? AND userId = ?', whereArgs: [gear.id, userId]);
  }

  @override
  Future<void> deleteGear(String userId, String gearId) async {
    final db = await this.db;
    await db.update('gear',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [gearId, userId]
    );
  }

  @override
  Future<void> addTool(String userId, ArmoryToolModel tool) async {
    final db = await this.db;
    final map = tool.toMap();
    map['userId'] = userId;
    map['id'] = tool.id;
    map['syncStatus'] = 'pending';
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('tools', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateTool(String userId, ArmoryToolModel tool) async {
    final db = await this.db;
    final map = tool.toMap();
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('tools', map, where: 'id = ? AND userId = ?', whereArgs: [tool.id, userId]);
  }

  @override
  Future<void> deleteTool(String userId, String toolId) async {
    final db = await this.db;
    await db.update('tools',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [toolId, userId]
    );
  }



  @override
  Future<void> addLoadout(String userId, ArmoryLoadoutModel loadout) async {
    final db = await this.db;
    final map = loadout.toMap();
    map['userId'] = userId;
    map['id'] = loadout.id;
    map['syncStatus'] = 'pending';
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('loadouts', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateLoadout(String userId, ArmoryLoadoutModel loadout) async {
    final db = await this.db;
    final map = loadout.toMap();
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.update('loadouts', map, where: 'id = ? AND userId = ?', whereArgs: [loadout.id, userId]);
  }
  @override
  Future<void> deleteLoadout(String userId, String loadoutId) async {
    final db = await this.db;
    await db.update('loadouts',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [loadoutId, userId]
    );
  }


  @override
  Future<void> addMaintenance(String userId, ArmoryMaintenanceModel maintenance) async {
    final db = await this.db;
    final map = maintenance.toMap();
    map['userId'] = userId;
    map['id'] = maintenance.id;
    map['syncStatus'] = 'pending';
    map['lastModified'] = DateTime.now().millisecondsSinceEpoch;
    await db.insert('maintenance', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteMaintenance(String userId, String maintenanceId) async {
    final db = await this.db;
    await db.update('maintenance',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [maintenanceId, userId]
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getFirearmsRawData() async {
    final db = await this.db;
    return await db.query('systemFirearms');
  }

  @override
  Future<List<Map<String, dynamic>>> getAmmunitionRawData() async {
    final db = await this.db;
    return await db.query('systemAmmunition');
  }

  @override
  Future<List<Map<String, dynamic>>> getUserFirearmsRawData(String userId) async {
    final db = await this.db;
    return await db.query('firearms', where: 'userId = ?', whereArgs: [userId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserAmmunitionRawData(String userId) async {
    final db = await this.db;
    return await db.query('ammunition', where: 'userId = ?', whereArgs: [userId]);
  }

  @override
  Future<void> saveSystemFirearms(List<ArmoryFirearmModel> firearms) async {
    final db = await this.db;
    final batch = db.batch();
    batch.delete('systemFirearms');
    for (final firearm in firearms) {
      final map = firearm.toMap();
      map['id'] = firearm.id;
      batch.insert('systemFirearms', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveSystemAmmunition(List<ArmoryAmmunitionModel> ammunition) async {
    final db = await this.db;
    final batch = db.batch();
    batch.delete('systemAmmunition');
    for (final ammo in ammunition) {
      final map = ammo.toMap();
      map['id'] = ammo.id;
      batch.insert('systemAmmunition', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveUserFirearms(String userId, List<ArmoryFirearmModel> firearms) async {
    final db = await this.db;
    final batch = db.batch();
    for (final firearm in firearms) {
      final map = firearm.toMap();
      map['userId'] = userId;
      map['id'] = firearm.id;
      batch.insert('firearms', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveUserAmmunition(String userId, List<ArmoryAmmunitionModel> ammunition) async {
    final db = await this.db;
    final batch = db.batch();
    for (final ammo in ammunition) {
      final map = ammo.toMap();
      map['userId'] = userId;
      map['id'] = ammo.id;
      batch.insert('ammunition', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveUserGear(String userId, List<ArmoryGearModel> gear) async {
    final db = await this.db;
    final batch = db.batch();
    for (final item in gear) {
      final map = item.toMap();
      map['userId'] = userId;
      map['id'] = item.id;
      batch.insert('gear', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveUserTools(String userId, List<ArmoryToolModel> tools) async {
    final db = await this.db;
    final batch = db.batch();
    for (final tool in tools) {
      final map = tool.toMap();
      map['userId'] = userId;
      map['id'] = tool.id;
      batch.insert('tools', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveUserLoadouts(String userId, List<ArmoryLoadoutModel> loadouts) async {
    final db = await this.db;
    final batch = db.batch();
    for (final loadout in loadouts) {
      final map = loadout.toMap();
      map['userId'] = userId;
      map['id'] = loadout.id;
      batch.insert('loadouts', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> saveUserMaintenance(String userId, List<ArmoryMaintenanceModel> maintenance) async {
    final db = await this.db;
    final batch = db.batch();
    for (final item in maintenance) {
      final map = item.toMap();
      map['userId'] = userId;
      map['id'] = item.id;
      batch.insert('maintenance', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<bool> hasUserData(String userId) async {
    try {
      final db = await this.db;

      // Single optimized query to check all tables at once
      final result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM firearms WHERE userId = ? AND syncStatus != ?) +
        (SELECT COUNT(*) FROM ammunition WHERE userId = ? AND syncStatus != ?) +
        (SELECT COUNT(*) FROM gear WHERE userId = ? AND syncStatus != ?) +
        (SELECT COUNT(*) FROM tools WHERE userId = ? AND syncStatus != ?) +
        (SELECT COUNT(*) FROM loadouts WHERE userId = ? AND syncStatus != ?) +
        (SELECT COUNT(*) FROM maintenance WHERE userId = ? AND syncStatus != ?)
        AS total_count
    ''', [
        userId, 'deleted',  // firearms
        userId, 'deleted',  // ammunition
        userId, 'deleted',  // gear
        userId, 'deleted',  // tools
        userId, 'deleted',  // loadouts
        userId, 'deleted',  // maintenance
      ]);

      final totalCount = Sqflite.firstIntValue(result) ?? 0;
      return totalCount > 0;
    } catch (e) {
      log('Error in hasUserData: $e');
      return false;
    }
  }


  @override
  Future<bool> isDatabaseEmpty() async {
    try {
      final db = await this.db;
      final systemCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM systemFirearms')
      ) ?? 0;
      return systemCount == 0;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<List<ArmoryFirearmModel>> getUnsyncedFirearms(String userId) async {
    final db = await this.db;
    final maps = await db.query('firearms',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'synced']
    );
    return maps.map((map) => ArmoryFirearmModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryAmmunitionModel>> getUnsyncedAmmunition(String userId) async {
    final db = await this.db;
    final maps = await db.query('ammunition',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'synced']
    );
    return maps.map((map) => ArmoryAmmunitionModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryGearModel>> getUnsyncedGear(String userId) async {
    final db = await this.db;
    final maps = await db.query('gear',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'synced']
    );
    return maps.map((map) => ArmoryGearModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryToolModel>> getUnsyncedTools(String userId) async {
    final db = await this.db;
    final maps = await db.query('tools',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'synced']
    );
    return maps.map((map) => ArmoryToolModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryLoadoutModel>> getUnsyncedLoadouts(String userId) async {
    final db = await this.db;
    final maps = await db.query('loadouts',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'synced']
    );
    return maps.map((map) => ArmoryLoadoutModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryMaintenanceModel>> getUnsyncedMaintenance(String userId) async {
    final db = await this.db;
    final maps = await db.query('maintenance',
        where: 'userId = ? AND syncStatus != ?',
        whereArgs: [userId, 'synced']
    );
    return maps.map((map) => ArmoryMaintenanceModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<void> markAsSynced(String table, String userId, String id) async {
    final db = await this.db;
    await db.update(table,
        {'syncStatus': 'synced', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId]
    );
  }

  @override
  Future<void> markAsUnsynced(String table, String userId, String id) async {
    final db = await this.db;
    await db.update(table,
        {'syncStatus': 'pending', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId]
    );
  }

  // lib/armory/data/datasources/armory_local_repository_impl.dart - ADD method to get deleted items
  Future<List<Map<String, dynamic>>> getDeletedItems(String userId, String table) async {
    final db = await this.db;
    return await db.query(table,
        where: 'userId = ? AND syncStatus = ?',
        whereArgs: [userId, 'deleted']
    );
  }

  // lib/armory/data/datasources/armory_local_repository_impl.dart - ADD at the end before closing brace
  // UPDATE getFirearmCountByCaliber
  @override
  Future<int> getFirearmCountByCaliber(String userId, String caliber) async {
    final db = await this.db;
    final result = await db.query('firearms',
      where: 'userId = ? AND syncStatus != ?',
      whereArgs: [userId, 'deleted'],
    );

    return result.where((firearmMap) {
      final caliberData = firearmMap['caliber']?.toString() ?? '';
      final calibers = caliberData.split(',').map((c) => c.trim().toLowerCase()).toList();
      return calibers.contains(caliber.toLowerCase());
    }).length;
  }

  @override
  Future<List<ArmoryAmmunitionModel>> getAmmunitionByCaliber(String userId, String caliber) async {
    final db = await this.db;
    final maps = await db.query(
      'ammunition',
      where: 'userId = ? AND caliber = ? AND syncStatus != ?',
      whereArgs: [userId, caliber, 'deleted'],
    );
    return maps.map((map) => ArmoryAmmunitionModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryLoadoutModel>> getLoadoutsByFirearmId(String userId, String firearmId) async {
    final db = await this.db;
    final maps = await db.query(
      'loadouts',
      where: 'userId = ? AND firearmId = ? AND syncStatus != ?',
      whereArgs: [userId, firearmId, 'deleted'],
    );
    return maps.map((map) => ArmoryLoadoutModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<List<ArmoryLoadoutModel>> getLoadoutsByAmmunitionId(String userId, String ammunitionId) async {
    final db = await this.db;
    final maps = await db.query(
      'loadouts',
      where: 'userId = ? AND ammunitionId = ? AND syncStatus != ?',
      whereArgs: [userId, ammunitionId, 'deleted'],
    );
    return maps.map((map) => ArmoryLoadoutModel.fromMap(map, map['id'] as String)).toList();
  }

  @override
  Future<void> batchDeleteLoadouts(String userId, List<String> loadoutIds) async {
    if (loadoutIds.isEmpty) return;
    final db = await this.db;
    final batch = db.batch();
    for (final id in loadoutIds) {
      batch.update(
        'loadouts',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> batchDeleteAmmunition(String userId, List<String> ammunitionIds) async {
    if (ammunitionIds.isEmpty) return;
    final db = await this.db;
    final batch = db.batch();
    for (final id in ammunitionIds) {
      batch.update(
        'ammunition',
        {'syncStatus': 'deleted', 'lastModified': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> clearAllData() async {
    final db = await this.db;
    final batch = db.batch();
    batch.delete('firearms');
    batch.delete('ammunition');
    batch.delete('gear');
    batch.delete('tools');
    batch.delete('loadouts');
    batch.delete('maintenance');
    batch.delete('systemFirearms');
    batch.delete('systemAmmunition');
    await batch.commit(noResult: true);
  }
}