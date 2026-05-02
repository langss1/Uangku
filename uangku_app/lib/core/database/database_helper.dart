import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('uangku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    await db.insert('transactions', transaction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  // Example to get all transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }
}
