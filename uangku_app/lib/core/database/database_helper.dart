import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'dart:convert';
import 'dart:math';

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

    // Fetch or generate cryptographically secure AES-256 database password key
    String? password = await SecureStorageHelper.getDbPassword();
    if (password == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      password = base64Url.encode(values);
      await SecureStorageHelper.saveDbPassword(password);
    }

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id TEXT PRIMARY KEY,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            icon_code_point INTEGER NOT NULL DEFAULT 0,
            bg_color INTEGER DEFAULT 0,
            icon_color INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            user_email TEXT NOT NULL DEFAULT ""
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_email)',
        );
      },
      password: password,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
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
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE notifications ADD COLUMN user_email TEXT DEFAULT ""');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      // Add indexes for performance + per-user isolation
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tx_user ON transactions(user_email, date DESC)',
        );
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_email, created_at DESC)',
        );
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_notif_unread ON notifications(user_email, is_read)',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL DEFAULT 0,
          bg_color INTEGER DEFAULT 0,
          icon_color INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0,
          user_email TEXT NOT NULL DEFAULT ""
        )
      ''');
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_email)',
        );
      } catch (_) {}
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
        category TEXT DEFAULT "Other",
        is_synced INTEGER DEFAULT 0,
        user_email TEXT NOT NULL DEFAULT ""
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
        user_email TEXT NOT NULL DEFAULT ""
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL DEFAULT 0,
        bg_color INTEGER DEFAULT 0,
        icon_color INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        user_email TEXT NOT NULL DEFAULT ""
      )
    ''');

    // Indexes for fast user-scoped queries
    await db.execute(
      'CREATE INDEX idx_tx_user ON transactions(user_email, date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_user ON notifications(user_email, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_notif_unread ON notifications(user_email, is_read)',
    );
    await db.execute(
      'CREATE INDEX idx_budgets_user ON budgets(user_email)',
    );
  }

  /// Ambil email dari SecureStorage (BUKAN SharedPreferences) untuk keamanan.
  /// Tidak bisa di-tamper oleh user karena tersimpan encrypted.
  Future<String> _getCurrentEmail() async {
    final email = await SecureStorageHelper.getUserEmail();
    return email ?? '';
  }

  // ─── TRANSACTIONS ────────────────────────────────────────────────────────────

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
    if (email.isEmpty) return [];
    return await db.query(
      'transactions',
      where: 'is_synced = ? AND user_email = ?',
      whereArgs: [0, email],
    );
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final email = await _getCurrentEmail();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'transactions',
      {'is_synced': 1},
      // Tambah user_email filter agar tidak bisa mark-synced milik user lain
      where: 'id IN ($placeholders) AND user_email = ?',
      whereArgs: [...ids, email],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return [];
    return await db.query(
      'transactions',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'date DESC',
    );
  }

  Future<int> getUserTransactionCount() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE user_email = ?',
      [email],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return; // Jangan simpan jika tidak ada user aktif
    final data = Map<String, dynamic>.from(notification);
    data['user_email'] = email;
    await db.insert('notifications', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return [];
    return await db.query(
      'notifications',
      where: 'user_email = ?',
      whereArgs: [email],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> markNotificationAsRead(String id) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    // Tambah user_email filter untuk keamanan — tidak bisa mark-read milik user lain
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, email],
    );
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return 0;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE is_read = 0 AND user_email = ?',
      [email],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAllNotifications() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return;
    await db.delete('notifications', where: 'user_email = ?', whereArgs: [email]);
  }

  Future<void> deleteNotification(String id) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    // Tambah user_email filter — tidak bisa hapus notif milik user lain
    await db.delete(
      'notifications',
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, email],
    );
  }

  // ─── BUDGETS ─────────────────────────────────────────────────────────────────

  Future<void> insertBudget(Map<String, dynamic> budget) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    final data = Map<String, dynamic>.from(budget);
    data['user_email'] = email;
    await db.insert('budgets', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return [];
    return await db.query(
      'budgets',
      where: 'user_email = ?',
      whereArgs: [email],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedBudgets() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return [];
    return await db.query(
      'budgets',
      where: 'is_synced = ? AND user_email = ?',
      whereArgs: [0, email],
    );
  }

  Future<void> markBudgetsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final email = await _getCurrentEmail();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'budgets',
      {'is_synced': 1},
      where: 'id IN ($placeholders) AND user_email = ?',
      whereArgs: [...ids, email],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    await db.delete(
      'budgets',
      where: 'id = ? AND user_email = ?',
      whereArgs: [id, email],
    );
  }

  Future<void> deleteAllBudgets() async {
    final db = await instance.database;
    final email = await _getCurrentEmail();
    if (email.isEmpty) return;
    await db.delete('budgets', where: 'user_email = ?', whereArgs: [email]);
  }

  /// Tutup dan reset instance database.
  /// Dipanggil saat logout untuk memastikan database di-reinitialize
  /// dengan user context yang baru saat login berikutnya.
  Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
