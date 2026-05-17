import 'package:flutter/material.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uangku_app/core/services/notification_service.dart';
import 'package:uangku_app/core/database/database_helper.dart';

class TransactionData {
  static final TransactionData _instance = TransactionData._internal();

  factory TransactionData() {
    return _instance;
  }

  TransactionData._internal();

  final ValueNotifier<List<TransactionModel>> transactionsNotifier = ValueNotifier([]);

  Future<void> fetchFromBackend() async {
    // 1. Load dari SQLite dulu untuk tampilan cepat & offline support
    try {
      final localData = await DatabaseHelper.instance.getAllTransactions();
      if (localData.isNotEmpty) {
        transactionsNotifier.value = localData.map((item) {
          final isIncome = item['type'] == 'income';
          return TransactionModel(
            id: item['id'].toString(),
            title: item['title'],
            category: item['category'] ?? 'Other',
            amount: double.parse(item['amount'].toString()),
            date: DateTime.parse(item['date']),
            icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            bgColor: isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
            iconColor: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
            isIncome: isIncome,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading from SQLite: $e');
    }

    // 2. Jalankan sinkronisasi data yang belum ter-upload (offline sync)
    syncUnsyncedTransactions();

    // 3. Fetch data terbaru dari backend
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://145.79.10.157:8000/api/data/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<TransactionModel> loaded = data.map((item) {
          final isIncome = item['type'] == 'income';
          return TransactionModel(
             id: item['id'].toString(),
             title: item['title'],
             category: item['category'] ?? 'Other',
             amount: double.parse(item['amount'].toString()),
             date: DateTime.parse(item['date']),
             icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
             bgColor: isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
             iconColor: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
             isIncome: isIncome,
          );
        }).toList();

        // Update memory & SQLite agar sinkron
        transactionsNotifier.value = loaded;
        for (var tx in loaded) {
          await DatabaseHelper.instance.insertTransaction({
            'id': tx.id,
            'title': tx.title,
            'amount': tx.amount,
            'date': tx.date.toIso8601String(),
            'type': tx.isIncome ? 'income' : 'expense',
            'category': tx.category,
            'is_synced': 1,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  Future<void> syncUnsyncedTransactions() async {
    final unsynced = await DatabaseHelper.instance.getUnsyncedTransactions();
    if (unsynced.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    debugPrint('🔄 Syncing ${unsynced.length} unsynced transactions...');

    for (var item in unsynced) {
      try {
        final response = await http.post(
          Uri.parse('http://145.79.10.157:8000/api/data/transactions'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'title': item['title'],
            'amount': item['amount'],
            'date': item['date'],
            'type': item['type'],
            'category': item['category'],
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await DatabaseHelper.instance.markAsSynced([item['id'].toString()]);
        }
      } catch (e) {
        debugPrint('Sync failed for item ${item['id']}: $e');
      }
    }
  }

  void addTransaction(TransactionModel transaction) async {
    // 1. Simpan ke SQLite dulu (is_synced = 0)
    try {
      await DatabaseHelper.instance.insertTransaction({
        'id': transaction.id,
        'title': transaction.title,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'type': transaction.isIncome ? 'income' : 'expense',
        'category': transaction.category,
        'is_synced': 0,
      });
    } catch (e) {
      debugPrint('Error saving to SQLite: $e');
    }

    // 2. Update Optimistic UI (Memory)
    transactionsNotifier.value = [transaction, ...transactionsNotifier.value];
    
    // 3. Coba kirim ke Backend
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://145.79.10.157:8000/api/data/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'title': transaction.title,
          'amount': transaction.amount,
          'date': transaction.date.toIso8601String(),
          'type': transaction.isIncome ? 'income' : 'expense',
          'category': transaction.category,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Jika berhasil, update status di SQLite
        await DatabaseHelper.instance.markAsSynced([transaction.id]);
      }

      // Trigger notification
      await NotificationService().triggerTransactionAdded(transaction.title, transaction.amount);

      // Check budget threshold
      await NotificationService().checkBudgetThreshold(transaction);
    } catch (e) {
      debugPrint('Error saving transaction to backend (will sync later): $e');
    }
  }

  void removeTransaction(String id) {
    transactionsNotifier.value = transactionsNotifier.value.where((tx) => tx.id != id).toList();
    // (Optional: add api call for deletion here)
  }

  void updateTransaction(TransactionModel updatedTransaction) {
    transactionsNotifier.value = transactionsNotifier.value.map((tx) {
      return tx.id == updatedTransaction.id ? updatedTransaction : tx;
    }).toList();
  }

  void clearMemory() {
    transactionsNotifier.value = [];
  }
}
