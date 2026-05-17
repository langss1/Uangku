import 'package:flutter/material.dart';
import 'package:uangku_app/core/models/budget_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BudgetData {
  static final BudgetData _instance = BudgetData._internal();

  factory BudgetData() {
    return _instance;
  }

  BudgetData._internal();

  final ValueNotifier<List<BudgetModel>> budgetsNotifier = ValueNotifier([]);

  Future<String> _getStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'default';
    return 'local_budgets_$email';
  }

  Future<void> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    final String? budgetsJson = prefs.getString(key);
    
    if (budgetsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(budgetsJson);
        budgetsNotifier.value = decoded.map((json) => BudgetModel.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error decoding local budgets: $e');
        budgetsNotifier.value = [];
      }
    } else {
      budgetsNotifier.value = [];
    }
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    final String encoded = jsonEncode(budgetsNotifier.value.map((b) => b.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  void addBudget(BudgetModel budget) {
    budgetsNotifier.value = [budget, ...budgetsNotifier.value];
    _saveToLocal();
  }

  void removeBudget(String id) {
    budgetsNotifier.value = budgetsNotifier.value.where((b) => b.id != id).toList();
    _saveToLocal();
  }

  void updateBudget(BudgetModel updatedBudget) {
    budgetsNotifier.value = budgetsNotifier.value.map((b) {
      return b.id == updatedBudget.id ? updatedBudget : b;
    }).toList();
    _saveToLocal();
  }

  void clearMemory() {
    budgetsNotifier.value = [];
  }
}
