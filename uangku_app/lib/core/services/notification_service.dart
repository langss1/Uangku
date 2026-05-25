import 'package:flutter/material.dart';
import 'package:uangku_app/core/database/database_helper.dart';
import 'package:uangku_app/core/models/notification_model.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/core/models/transaction_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(initializationSettings);

    // Request permissions for newer Android versions
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> _showSystemNotification(String title, String body) async {
    if (!_isInitialized) await init();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'uangku_channel',
      'Uangku Notifications',
      channelDescription: 'Main notifications for Uangku app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFF2962FF),
    );
    
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );
    
    try {
      await DatabaseHelper.instance.insertNotification(notification.toMap());
    } catch (e) {
      debugPrint('Error saving notification locally: $e');
    }
    
    // Also trigger system notification
    try {
      await _showSystemNotification(title, message);
    } catch (e) {
      debugPrint('Error showing system notification: $e');
    }
  }

  Future<void> triggerMorningReport() async {
    // Ambil email user aktif dari SecureStorage
    final userEmail = await SecureStorageHelper.getUserEmail() ?? '';
    if (userEmail.isEmpty) return; // Tidak ada user aktif, jangan kirim notif

    final prefs = await SharedPreferences.getInstance();
    // Key di-prefix dengan email agar tiap akun punya state sendiri
    final reportKey = 'last_morning_report_date_$userEmail';
    final String lastReportDate = prefs.getString(reportKey) ?? '';
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Only generate if it's past 6 AM and hasn't been generated today for THIS user
    if (DateTime.now().hour >= 6 && lastReportDate != todayDate) {
      final transactions = await DatabaseHelper.instance.getAllTransactions();
      
      // Calculate yesterday's expenses
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayString = DateFormat('yyyy-MM-dd').format(yesterday);
      
      double totalYesterdayExpense = 0;
      for (var t in transactions) {
        if (t['type'] == 'expense' && t['date'].startsWith(yesterdayString)) {
          totalYesterdayExpense += (t['amount'] as num).toDouble();
        }
      }

      final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      
      String message = "Selamat pagi! Kemarin Anda mengeluarkan ${format.format(totalYesterdayExpense)}.";
      if (totalYesterdayExpense > 0) {
        message += " Tetap pantau pengeluaran Anda agar sesuai budget ya! Semangat!";
      } else {
        message += " Wah hebat, kemarin tidak ada pengeluaran! Pertahankan!";
      }

      await createNotification(
        title: "Laporan Pagi ☀️",
        message: message,
        type: "report",
      );

      // Random feature discovery
      await createNotification(
        title: "Tahukah Kamu? 🤖",
        message: "Fitur AI Chatbot (Gemini) siap membantu menganalisis pola pengeluaranmu. Yuk cobain sekarang!",
        type: "info",
      );

      // Simpan dengan key yang sudah di-prefix email agar tidak bocor ke akun lain
      await prefs.setString(reportKey, todayDate);
    }
  }

  /// Hapus semua SharedPreferences yang terkait dengan notifikasi user tertentu.
  /// Dipanggil saat logout untuk mencegah data notifikasi bocor ke akun lain.
  Future<void> clearUserNotificationPrefs(String userEmail) async {
    if (userEmail.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_morning_report_date_$userEmail');
    // Hapus juga key lama (tanpa prefix) jika masih ada untuk backward compat
    await prefs.remove('last_morning_report_date');
  }

  Future<void> triggerTransactionAdded(String title, double amount) async {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    await createNotification(
      title: "Transaksi Baru Dicatat 📝",
      message: "Transaksi '$title' sebesar ${format.format(amount)} berhasil ditambahkan.",
      type: "success",
    );
  }

  Future<void> checkBudgetThreshold(TransactionModel newTx) async {
    if (newTx.isIncome) return;

    final budgets = BudgetData().budgetsNotifier.value;
    final categoryBudgets = budgets.where((b) => b.category == newTx.category).toList();
    if (categoryBudgets.isEmpty) return;

    final transactions = TransactionData().transactionsNotifier.value;

    for (var budget in categoryBudgets) {
      if (newTx.date.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
          newTx.date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
        
        double totalSpent = 0;
        for (var tx in transactions) {
          if (!tx.isIncome && tx.category == budget.category &&
              tx.date.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
              tx.date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
            totalSpent += tx.amount;
          }
        }

        double percentage = totalSpent / budget.amount;
        
        // Calculate previous spent (without the new transaction)
        double prevSpent = totalSpent - newTx.amount;
        double prevPercentage = prevSpent / budget.amount;

        // Only notify when crossing the 80% or 100% threshold to avoid spam
        if (percentage >= 0.8 && percentage < 1.0 && prevPercentage < 0.8) {
           await createNotification(
             title: "Peringatan Anggaran ⚠️",
             message: "Pengeluaran untuk ${budget.category} sudah mencapai ${(percentage * 100).toInt()}% dari anggaran!",
             type: "warning",
           );
        } else if (percentage >= 1.0 && prevPercentage < 1.0) {
           await createNotification(
             title: "Anggaran Terlampaui 🚨",
             message: "Pengeluaran ${budget.category} telah melewati batas anggaran Anda!",
             type: "danger",
           );
        }
      }
    }
  }
}
