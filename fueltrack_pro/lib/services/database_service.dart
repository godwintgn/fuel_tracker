import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../models/fuel_card.dart';
import '../models/refuel_entry.dart';
import '../models/service_record.dart';
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
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicles (
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
      CREATE TABLE IF NOT EXISTS refuel_entries (
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
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        currency_code TEXT NOT NULL DEFAULT 'OMR',
        currency_symbol TEXT NOT NULL DEFAULT 'OMR',
        country_code TEXT NOT NULL DEFAULT 'OM',
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
      'currency_code': 'OMR',
      'currency_symbol': 'OMR',
      'country_code': 'OM',
      'distance_unit': 'km',
      'fuel_unit': 'liters',
      'theme_mode': 'system',
      'onboarding_completed': 0,
      'selected_vehicle_id': null,
      'updated_at': now,
    });

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fuel_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        provider TEXT NOT NULL,
        company_name TEXT,
        card_number TEXT,
        scope TEXT NOT NULL DEFAULT 'fleet',
        vehicle_id INTEGER,
        limit_type TEXT NOT NULL DEFAULT 'none',
        limit_value REAL,
        reset_period TEXT NOT NULL DEFAULT 'none',
        reset_day INTEGER,
        expiry_date INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        notes TEXT,
        trigger_type TEXT NOT NULL DEFAULT 'date',
        due_date INTEGER,
        due_odometer REAL,
        notify_before_days INTEGER NOT NULL DEFAULT 7,
        notify_before_km REAL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_date INTEGER,
        next_due_date INTEGER,
        next_due_odometer REAL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_path TEXT');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_left REAL');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_top REAL');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_width REAL');
      await db.execute('ALTER TABLE vehicles ADD COLUMN photo_crop_height REAL');
    }
    if (oldVersion < 3) {
      // Add country_code to settings
      try {
        await db.execute("ALTER TABLE settings ADD COLUMN country_code TEXT NOT NULL DEFAULT 'OM'");
      } catch (_) {}
      // Create new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fuel_cards (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          provider TEXT NOT NULL,
          company_name TEXT,
          card_number TEXT,
          scope TEXT NOT NULL DEFAULT 'fleet',
          vehicle_id INTEGER,
          limit_type TEXT NOT NULL DEFAULT 'none',
          limit_value REAL,
          reset_period TEXT NOT NULL DEFAULT 'none',
          reset_day INTEGER,
          expiry_date INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE SET NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS service_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicle_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          notes TEXT,
          trigger_type TEXT NOT NULL DEFAULT 'date',
          due_date INTEGER,
          due_odometer REAL,
          notify_before_days INTEGER NOT NULL DEFAULT 7,
          notify_before_km REAL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_date INTEGER,
          next_due_date INTEGER,
          next_due_odometer REAL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
        )
      ''');
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

  // ── Fuel cards ─────────────────────────────────────────────────────────────

  Future<List<FuelCard>> getFuelCards({int? vehicleId}) async {
    final db = await database;
    final rows = vehicleId != null
        ? await db.query(
            'fuel_cards',
            where: 'scope = ? OR vehicle_id = ?',
            whereArgs: ['fleet', vehicleId],
            orderBy: 'name ASC',
          )
        : await db.query('fuel_cards', orderBy: 'name ASC');
    return rows.map(FuelCard.fromMap).toList();
  }

  Future<int> insertFuelCard(FuelCard card) async {
    final db = await database;
    return db.insert('fuel_cards', card.toMap());
  }

  Future<void> updateFuelCard(FuelCard card) async {
    final db = await database;
    await db.update('fuel_cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  }

  Future<void> deleteFuelCard(int id) async {
    final db = await database;
    await db.delete('fuel_cards', where: 'id = ?', whereArgs: [id]);
  }

  // ── Service records ─────────────────────────────────────────────────────────

  Future<List<ServiceRecord>> getServiceRecords({int? vehicleId, bool activeOnly = false}) async {
    final db = await database;
    String? where;
    List<Object?> whereArgs = [];
    if (vehicleId != null && activeOnly) {
      where = 'vehicle_id = ? AND is_completed = 0';
      whereArgs = [vehicleId];
    } else if (vehicleId != null) {
      where = 'vehicle_id = ?';
      whereArgs = [vehicleId];
    } else if (activeOnly) {
      where = 'is_completed = 0';
    }
    final rows = await db.query(
      'service_records',
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'due_date ASC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<int> insertServiceRecord(ServiceRecord record) async {
    final db = await database;
    return db.insert('service_records', record.toMap());
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.update('service_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deleteServiceRecord(int id) async {
    final db = await database;
    await db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
