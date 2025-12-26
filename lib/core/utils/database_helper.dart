import 'dart:developer';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'armory_database3.db';
  static const int _databaseVersion = 4; // 🔼 Incremented

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    log('[DB] Initializing database at path: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // -----------------------------
  // 📦 TABLE CREATION
  // -----------------------------
  // MODIFY _onCreate to include lastModified
  Future<void> _onCreate(Database db, int version) async {
    log('[DB] Creating tables (v$version)...');

    // ---------------- FIREARMS ----------------
    await db.execute('''
    CREATE TABLE firearms (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      type TEXT,
      make TEXT,
      model TEXT,
      caliber TEXT,
      nickname TEXT,
      status TEXT,
      serial TEXT,
      notes TEXT,
      brand TEXT,
      generation TEXT,
      firingMechanism TEXT,
      detailedType TEXT,
      purpose TEXT,
      condition TEXT,
      purchaseDate INTEGER,
      purchasePrice REAL,
      currentValue REAL,
      fflDealer TEXT,
      manufacturerPN TEXT,
      finish TEXT,
      stockMaterial TEXT,
      triggerType TEXT,
      safetyType TEXT,
      feedSystem TEXT,
      magazineCapacity INTEGER,
      twistRate TEXT,
      threadPattern TEXT,
      overallLength REAL,
      weight REAL,
      barrelLength REAL,
      actionType TEXT,
      roundCount INTEGER,
      lastCleaned INTEGER,
      zeroDistance INTEGER,
      modifications TEXT,
      accessoriesIncluded TEXT,
      storageLocation TEXT,
      photos TEXT,
      dateAdded INTEGER,
      syncStatus TEXT DEFAULT 'synced',
      lastModified INTEGER DEFAULT 0,
      UNIQUE(id, userId)
    )
  ''');
    log('[DB] Created firearms table ✅');

    // ---------------- SYSTEM FIREARMS ----------------
    await db.execute('''
    CREATE TABLE systemFirearms (
      id TEXT PRIMARY KEY,
      type TEXT,
      make TEXT,
      model TEXT,
      caliber TEXT,
      nickname TEXT,
      status TEXT,
      serial TEXT,
      notes TEXT,
      brand TEXT,
      generation TEXT,
      firingMechanism TEXT,
      detailedType TEXT,
      purpose TEXT,
      condition TEXT,
      purchaseDate INTEGER,
      purchasePrice REAL,
      currentValue REAL,
      fflDealer TEXT,
      manufacturerPN TEXT,
      finish TEXT,
      stockMaterial TEXT,
      triggerType TEXT,
      safetyType TEXT,
      feedSystem TEXT,
      magazineCapacity INTEGER,
      twistRate TEXT,
      threadPattern TEXT,
      overallLength REAL,
      weight REAL,
      barrelLength REAL,
      actionType TEXT,
      roundCount INTEGER,
      lastCleaned INTEGER,
      zeroDistance INTEGER,
      modifications TEXT,
      accessoriesIncluded TEXT,
      storageLocation TEXT,
      photos TEXT,
      dateAdded INTEGER,
      UNIQUE(id)
    )
  ''');
    log('[DB] Created systemFirearms table ✅');

    // ---------------- AMMUNITION ----------------
    await db.execute('''
    CREATE TABLE ammunition (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      brand TEXT,
      line TEXT,
      caliber TEXT,
      bullet TEXT,
      quantity INTEGER,
      status TEXT,
      lot TEXT,
      notes TEXT,
      primerType TEXT,
      powderType TEXT,
      powderWeight REAL,
      caseMaterial TEXT,
      caseCondition TEXT,
      headstamp TEXT,
      ballisticCoefficient REAL,
      muzzleEnergy REAL,
      velocity REAL,
      temperatureTested REAL,
      standardDeviation REAL,
      extremeSpread REAL,
      groupSize REAL,
      testDistance INTEGER,
      testFirearm TEXT,
      storageLocation TEXT,
      purchaseDate INTEGER,
      purchasePrice REAL,
      costPerRound REAL,
      expirationDate INTEGER,
      performanceNotes TEXT,
      environmentalConditions TEXT,
      isHandloaded INTEGER DEFAULT 0,
      loadData TEXT,
      bulletDiameter REAL,
      dateAdded INTEGER,
      syncStatus TEXT DEFAULT 'synced',
      lastModified INTEGER DEFAULT 0,
      UNIQUE(id, userId)
    )
  ''');
    log('[DB] Created ammunition table ✅');

    // ---------------- SYSTEM AMMUNITION ----------------
    await db.execute('''
    CREATE TABLE systemAmmunition (
      id TEXT PRIMARY KEY,
      brand TEXT,
      line TEXT,
      caliber TEXT,
      bullet TEXT,
      quantity INTEGER,
      status TEXT,
      lot TEXT,
      notes TEXT,
      primerType TEXT,
      powderType TEXT,
      powderWeight REAL,
      caseMaterial TEXT,
      caseCondition TEXT,
      headstamp TEXT,
      ballisticCoefficient REAL,
      muzzleEnergy REAL,
      velocity REAL,
      temperatureTested REAL,
      standardDeviation REAL,
      extremeSpread REAL,
      groupSize REAL,
      testDistance INTEGER,
      testFirearm TEXT,
      storageLocation TEXT,
      purchaseDate INTEGER,
      purchasePrice REAL,
      costPerRound REAL,
      expirationDate INTEGER,
      performanceNotes TEXT,
      environmentalConditions TEXT,
      isHandloaded INTEGER DEFAULT 0,
      loadData TEXT,
      bulletDiameter REAL,
      dateAdded INTEGER,
      UNIQUE(id)
    )
  ''');
    log('[DB] Created systemAmmunition table ✅');

    // ---------------- GEAR ----------------
    await db.execute('''
    CREATE TABLE gear (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      category TEXT,
      model TEXT,
      serial TEXT,
      quantity INTEGER,
      notes TEXT,
      dateAdded INTEGER DEFAULT (strftime('%s','now')),
      syncStatus TEXT DEFAULT 'synced',
      lastModified INTEGER DEFAULT 0,
      UNIQUE(id, userId)
    )
  ''');
    log('[DB] Created gear table ✅');

    // ---------------- TOOLS ----------------
    await db.execute('''
    CREATE TABLE tools (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      name TEXT,
      category TEXT,
      quantity INTEGER,
      status TEXT,
      notes TEXT,
      dateAdded INTEGER,
      syncStatus TEXT DEFAULT 'synced',
      lastModified INTEGER DEFAULT 0,
      UNIQUE(id, userId)
    )
  ''');
    log('[DB] Created tools table ✅');

    // ---------------- LOADOUTS ----------------
    await db.execute('''
    CREATE TABLE loadouts (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      name TEXT,
      firearmId TEXT,
      ammunitionId TEXT,
      gearIds TEXT,
      toolIds TEXT,
      maintenanceIds TEXT,
      notes TEXT,
      dateAdded INTEGER,
      syncStatus TEXT DEFAULT 'synced',
      lastModified INTEGER DEFAULT 0,
      UNIQUE(id, userId)
    )
  ''');
    log('[DB] Created loadouts table ✅');

    // ---------------- MAINTENANCE ----------------
    await db.execute('''
    CREATE TABLE maintenance (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      assetType TEXT,
      assetId TEXT,
      maintenanceType TEXT,
      date INTEGER,
      roundsFired INTEGER,
      notes TEXT,
      dateAdded INTEGER,
      syncStatus TEXT DEFAULT 'synced',
      lastModified INTEGER DEFAULT 0,
      UNIQUE(id, userId)
    )
  ''');
    log('[DB] Created maintenance table ✅');

    // ---------------- SYNC METADATA ----------------
    await db.execute('''
    CREATE TABLE sync_metadata (
      key TEXT PRIMARY KEY,
      value TEXT,
      timestamp INTEGER
    )
  ''');
    log('[DB] Created sync_metadata table ✅');

    log('[DB] ✅ All tables created successfully');
  }

  // -----------------------------
  // ⚙️ UPGRADE HANDLER
  // -----------------------------
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    log('[DB] Upgrading from v$oldVersion → v$newVersion');

    if (oldVersion < 3) {
      final tables = ['firearms', 'ammunition', 'gear', 'tools', 'loadouts', 'maintenance'];
      for (final table in tables) {
        try {
          await db.execute("ALTER TABLE $table ADD COLUMN syncStatus TEXT DEFAULT 'synced'");
        } catch (e) {
          log('[DB] Column syncStatus might already exist in $table');
        }
      }
      log('[DB] Added syncStatus column ✅');
    }

    if (oldVersion < 4) {
      final tables = ['firearms', 'ammunition', 'gear', 'tools', 'loadouts', 'maintenance'];
      for (final table in tables) {
        try {
          await db.execute("ALTER TABLE $table ADD COLUMN lastModified INTEGER DEFAULT 0");
        } catch (e) {
          log('[DB] Column lastModified might already exist in $table');
        }
      }

      try {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT,
          timestamp INTEGER
        )
      ''');
      } catch (e) {
        log('[DB] Table sync_metadata might already exist');
      }

      log('[DB] Added lastModified column and sync_metadata table ✅');
    }
  }


  // -----------------------------
  // 🧰 UTILITY HELPERS
  // -----------------------------
  Future<void> clearAllTables() async {
    final db = await database;
    final tables = [
      'firearms',
      'systemFirearms',
      'ammunition',
      'systemAmmunition',
      'gear',
      'tools',
      'loadouts',
      'maintenance',
    ];
    for (final table in tables) {
      await db.delete(table);
    }
    log('[DB] ✅ Cleared all Armory data');
  }

  Future<void> markAsSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'syncStatus': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsPending(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'syncStatus': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // lib/core/utills/database_helper.dart - ADD this method

  Future<void> setLastSyncTime(String userId, int timestamp) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {'key': 'last_sync_$userId', 'value': timestamp.toString(), 'timestamp': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getLastSyncTime(String userId) async {
    final db = await database;
    final result = await db.query('sync_metadata', where: 'key = ?', whereArgs: ['last_sync_$userId']);
    if (result.isEmpty) return null;
    return int.tryParse(result.first['value'] as String);
  }

  Future<bool> hasSystemData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM systemFirearms')) ?? 0;
    return count > 0;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      log('[DB] 🔒 Database closed');
    }
  }
}
