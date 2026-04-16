import 'package:flutter/material.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class TransactionData {
  static final TransactionData _instance = TransactionData._internal();

  factory TransactionData() {
    return _instance;
  }

  TransactionData._internal();

  final ValueNotifier<List<TransactionModel>> transactionsNotifier = ValueNotifier([
    TransactionModel(
      id: "1",
      title: "Netflix",
      category: "Entertainment",
      amount: 54000,
      date: DateTime.now(),
      icon: Icons.play_arrow,
      bgColor: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFDC2626),
      isIncome: false,
    ),
    TransactionModel(
      id: "2",
      title: "Starbucks",
      category: "Food & Drink",
      amount: 45000,
      date: DateTime.now(),
      icon: Icons.local_cafe,
      bgColor: const Color(0xFFD1FAE5),
      iconColor: const Color(0xFF059669),
      isIncome: false,
    ),
    TransactionModel(
      id: "3",
      title: "Indomaret",
      category: "Groceries",
      amount: 75000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.shopping_cart,
      bgColor: const Color(0xFFDBEAFE),
      iconColor: const Color(0xFF2563EB),
      isIncome: false,
    ),
    TransactionModel(
      id: "4",
      title: "PT. Tech Company",
      category: "Salary",
      amount: 5000000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.business,
      bgColor: const Color(0xFFD1FAE5),
      iconColor: const Color(0xFF059669),
      isIncome: true,
    ),
    TransactionModel(
      id: "5",
      title: "Monthly Rent",
      category: "Housing",
      amount: 1500000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.home,
      bgColor: const Color(0xFFFFEDD5),
      iconColor: const Color(0xFFD97706),
      isIncome: false,
    ),
  ]);

  void addTransaction(TransactionModel transaction) {
    transactionsNotifier.value = [transaction, ...transactionsNotifier.value];
  }

  void removeTransaction(String id) {
    transactionsNotifier.value = transactionsNotifier.value.where((tx) => tx.id != id).toList();
  }

  void updateTransaction(TransactionModel updatedTransaction) {
    transactionsNotifier.value = transactionsNotifier.value.map((tx) {
      return tx.id == updatedTransaction.id ? updatedTransaction : tx;
    }).toList();
  }
}
