import 'dart:convert';
import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:pulse_skadi/features/firearm/data/model/firearm_entity.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../../../../../core/services/sqflite_service/db_file_loading_service.dart';

@injectable
class FirearmDbHelper {
  //--------------------------- Adding Firearm

  Future<FirearmEntity?> addNewFirearm(
      String userId, FirearmEntity firearm) async {
    FirearmEntity firearmEntity = FirearmEntity();
    try {
      final db = await DbFileLoadingService().getLocalDatabase();
      await _addColumnIfNotExists(db);
      int? newFireArmId = await db.insert('firearm', {
        'userId': userId,
        'type': firearm.type,
        'brand': firearm.brand,
        'model': firearm.model,
        'generation': firearm.generation,
        'caliber': firearm.caliber,
        'firing_machanism': firearm.firingMachanism,
        'ammo_type': firearm.ammoType,
        'added_by_user': 1
      });
      firearmEntity =
          firearm.copyWith(id: newFireArmId.toString(), addedByUser: 1);
      List<Map<String, dynamic>> result = await db.query(
        'stages',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        await db.update(
          'stages',
          {'firearm': jsonEncode(firearmEntity.toJson())},
          where: 'userId = ?',
          whereArgs: [userId],
        );
      } else {
        await db.insert('stages', {
          'userId': userId,
          'firearm': jsonEncode(firearmEntity.toJson()),
        });
      }
      return firearmEntity;
    } catch (e) {
      log('message catch $e');
      return firearmEntity;
    }
  }

  //--------------------------- Updating Firearm

  Future<void> updateFirearmInStage(
      String userId, FirearmEntity firearm) async {
    final db = await DbFileLoadingService().getLocalDatabase();
    await _addColumnIfNotExists(db);
    List<Map<String, dynamic>> result = await db.query(
      'stages',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      await db.update(
        'stages',
        {'firearm': jsonEncode(firearm.toJson())},
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } else {
      await db.insert('stages', {
        'userId': userId,
        'firearm': jsonEncode(firearm.toJson()),
      });
    }
  }

  //-------------------------------------- Getting Firearm

  Future<List<FirearmEntity>> getFirearms(String userId) async {
    final db = await DbFileLoadingService().getLocalDatabase();
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('Tables in DB: ${tables.map((t) => t['name']).toList()}');

    try {
      List<Map<String, dynamic>> result = await db.query('the_firearms');
      return result.map((firearm) {
        return FirearmEntity.fromJson(firearm);
      }).toList();
    } catch (e) {
      print('message catch getFirearms e');
      return [];
    }
  }

  //-------------------------------------- Deleting Firearm

  Future<void> removeFirearm(int drillId, String userId) async {
    try {
      final db = await DbFileLoadingService().getLocalDatabase();
      await db.delete(
        'the_firearms',
        where: 'id = ? AND userId = ?',
        whereArgs: [drillId, userId],
      );
      List<Map<String, dynamic>> result = await db.query(
        'stages',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        await db.update(
          'stages',
          {'firearm': '{}'},
          where: 'userId = ?',
          whereArgs: [userId],
        );
      }
    } catch (e) {
      log('removeDrill :: $e');
    }
  }

  Future<void> _addColumnIfNotExists(
    Database db,
  ) async {
    List<Map<String, dynamic>> result =
        await db.rawQuery("PRAGMA table_info(the_firearms)");

    bool columnExists = result.any((column) => column['name'] == 'userId');

    if (!columnExists) {
      await db.execute('ALTER TABLE the_firearms ADD COLUMN userId TEXT');
    }

    bool addedByUserExists =
        result.any((column) => column['name'] == 'added_by_user');

    if (!addedByUserExists) {
      await db
          .execute('ALTER TABLE the_firearms ADD COLUMN added_by_user INTEGER');
    }
  }
}
