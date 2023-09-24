import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'location_model.dart';
import 'package:path_provider/path_provider.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'location_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE locations(id INTEGER PRIMARY KEY, latitude REAL, longitude REAL, distance REAL)',
        );
      },
    );
  }

  Future<void> insertLocation(LocationModel location) async {
    Database db = await database;
    await db.insert(
      'locations',
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LocationModel>> getLocations() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('locations');
    return List.generate(maps.length, (i) {
      return LocationModel.fromMap(maps[i]);
    });
  }

  Future<List<LocationModel>> getDistances() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM locations WHERE distance > 0');
    return List.generate(maps.length, (i) {
      return LocationModel.fromMap(maps[i]);
    });
  }

  Future<void> saveDistances(List<Location> locations) async {
    Database db = await database;
    Batch batch = db.batch();
    locations.forEach((location) {
      batch.update(
        'locations',
        {'distance': location.distance},
        where: 'id = ?',
        whereArgs: [location.id],
      );
    });
    await batch.commit();
  }
}
