import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../models/refuel_entry.dart';
import '../models/vehicle.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, 'fueltrack_pro.db');

    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        make TEXT,
        model TEXT,
        year INTEGER,
        fuel_type TEXT NOT NULL,
        license_plate TEXT,
        notes TEXT,
        photo_path TEXT,
        photo_crop_left REAL,
        photo_crop_top REAL,
        photo_crop_width REAL,
        photo_crop_height REAL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE refuel_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        refuel_date INTEGER NOT NULL,
        odometer REAL NOT NULL,
        quantity REAL NOT NULL,
        price_per_liter REAL,
        total_price REAL NOT NULL,
        fuel_type TEXT NOT NULL,
        station_name TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        currency_code TEXT NOT NULL DEFAULT 'USD',
        currency_symbol TEXT NOT NULL DEFAULT '\$',
        distance_unit TEXT NOT NULL DEFAULT 'km',
        fuel_unit TEXT NOT NULL DEFAULT 'liters',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        selected_vehicle_id INTEGER,
        updated_at INTEGER NOT NULL
      )
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('settings', {
      'id': 1,
      'currency_code': 'USD',
      'currency_symbol': r'$',
      'distance_unit': 'km',
      'fuel_unit': 'liters',
      'theme_mode': 'system',
      'onboarding_completed': 0,
      'selected_vehicle_id': null,
      'updated_at': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_path TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_left REAL');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_top REAL');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_width REAL');
      await db.execute(
        'ALTER TABLE vehicles ADD COLUMN photo_crop_height REAL',
      );
    }
  }

  Future<AppSettings> getSettings() async {
    final db = await database;
    final rows = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      final defaults = AppSettings.defaults();
      await saveSettings(defaults);
      return defaults;
    }
    return AppSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    await db.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'name ASC');
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getVehicle(int id) async {
    final db = await database;
    final rows = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Vehicle.fromMap(rows.first);
  }

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return db.insert('vehicles', vehicle.toMap());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> deleteVehicle(int id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RefuelEntry>> getRefuelEntries({int? vehicleId}) async {
    final db = await database;
    final rows = vehicleId != null
        ? await db.query(
            'refuel_entries',
            where: 'vehicle_id = ?',
            whereArgs: [vehicleId],
            orderBy: 'refuel_date DESC',
          )
        : await db.query('refuel_entries', orderBy: 'refuel_date DESC');
    return rows.map(RefuelEntry.fromMap).toList();
  }

  Future<RefuelEntry?> getRefuelEntry(int id) async {
    final db = await database;
    final rows = await db.query(
      'refuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return RefuelEntry.fromMap(rows.first);
  }

  Future<int> insertRefuelEntry(RefuelEntry entry) async {
    final db = await database;
    return db.insert('refuel_entries', entry.toMap());
  }

  Future<void> updateRefuelEntry(RefuelEntry entry) async {
    final db = await database;
    await db.update(
      'refuel_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteRefuelEntry(int id) async {
    final db = await database;
    await db.delete('refuel_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
