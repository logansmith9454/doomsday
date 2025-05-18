import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('responses.db');
    print('Database initialized at: ${await getDatabasesPath()}/responses.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE responses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp TEXT NOT NULL,
      time_taken REAL NOT NULL,
      is_correct INTEGER NOT NULL
    )
    ''');
    print('Table responses created');
  }

  Future<void> insertResponse(Map<String, dynamic> response) async {
    final db = await database;
    await db.insert(
      'responses',
      response,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Inserted response: $response');
  }

  Future<List<Map<String, dynamic>>> getResponses() async {
    final db = await database;
    final responses = await db.query('responses', orderBy: 'timestamp DESC');
    print('Fetched ${responses.length} responses');
    return responses;
  }

  Future<int> getResponseCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM responses');
    final count = result.first['count'] as int;
    print('Response count: $count');
    return count;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    print('Database closed');
  }
}
