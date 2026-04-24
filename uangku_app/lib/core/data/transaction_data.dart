import 'package:flutter/material.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class TransactionData {
  static final TransactionData _instance = TransactionData._internal();

  factory TransactionData() {
    return _instance;
  }

  TransactionData._internal();

  final ValueNotifier<List<TransactionModel>> transactionsNotifier = ValueNotifier([]);

  Future<void> fetchFromBackend() async {
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

        transactionsNotifier.value = loaded;
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  void addTransaction(TransactionModel transaction) async {
    // Optimistic UI update
    transactionsNotifier.value = [transaction, ...transactionsNotifier.value];
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      await http.post(
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
    } catch (e) {
      debugPrint('Error saving transaction: $e');
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
}
