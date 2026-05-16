import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN user_email TEXT DEFAULT ""');
      } catch (e) {
        // Ignore if exists
      }
      try {
        await db.execute('ALTER TABLE notifications ADD COLUMN user_email TEXT DEFAULT ""');
      } catch (e) {
        // Ignore if exists
      }
    }
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
        is_synced INTEGER DEFAULT 0,
        user_email TEXT DEFAULT ""
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        user_email TEXT DEFAULT ""
      )
    ''');
  }

  Future<String> _getCurrentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }

  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    final data = Map<String, dynamic>.from(transaction);
    data['user_email'] = email;
    await db.insert('transactions', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    return await db.query('transactions', where: 'is_synced = ? AND user_email = ?', whereArgs: [0, email]);
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
    final email = await _getCurrentEmail();
    return await db.query('transactions', where: 'user_email = ?', whereArgs: [email], orderBy: 'date DESC');
  }

  // --- Notifications ---
  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    final data = Map<String, dynamic>.from(notification);
    data['user_email'] = email;
    await db.insert('notifications', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    return await db.query('notifications', where: 'user_email = ?', whereArgs: [email], orderBy: 'created_at DESC');
  }

  Future<void> markNotificationAsRead(String id) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notifications WHERE is_read = 0 AND user_email = ?', [email]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAllNotifications() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    await db.delete('notifications', where: 'user_email = ?', whereArgs: [email]);
  }

  Future<void> deleteNotification(String id) async {
    final db = await instance.database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }
}
