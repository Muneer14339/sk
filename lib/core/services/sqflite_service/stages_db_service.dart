import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@injectable
class StagesDBService {
  static final StagesDBService instance = StagesDBService._internal();
  factory StagesDBService() => instance;
  // static Database? _database;

  StagesDBService._internal();

  Future<void> addAdditionalTables(Database db) async {
    await _createStagesTable(db);
    await _createDrillsTable(db);
    await _createSessionTable(db);
  }

  Future<void> _createStagesTable(Database db) async {
    await db.execute('''
    CREATE TABLE stages(
      userId TEXT PRIMARY KEY,   
      drill TEXT,
      mode TEXT,
      firearm TEXT,
      vanue TEXT,
      mount_location TEXT,
      dominant_hand TEXT,
      aim_sync TEXT,
      distance TEXT
    )
  ''');
  }

  Future<void> _createDrillsTable(Database db) async {
    await db.execute('''
    CREATE TABLE drills(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT,
      drill TEXT 
    )
  ''');
  }

  Future<void> _createSessionTable(Database db) async {
    await db.execute('''
    CREATE TABLE session(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session TEXT 
    )
  ''');
  }
}
