import 'package:flutter/material.dart';
import 'package:uangku_app/core/models/budget_model.dart';
import 'package:uangku_app/core/database/database_helper.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'package:uangku_app/core/services/network_service.dart';
import 'dart:convert';

class BudgetData {
  static final BudgetData _instance = BudgetData._internal();

  factory BudgetData() {
    return _instance;
  }

  BudgetData._internal();

  final ValueNotifier<List<BudgetModel>> budgetsNotifier = ValueNotifier([]);

  Future<void> loadBudgets() async {
    try {
      final localData = await DatabaseHelper.instance.getAllBudgets();
      budgetsNotifier.value = localData.map((item) {
        return BudgetModel(
          id: item['id'],
          category: item['category'],
          amount: double.parse(item['amount'].toString()),
          startDate: DateTime.parse(item['start_date']),
          endDate: DateTime.parse(item['end_date']),
          iconCodePoint: item['icon_code_point'] as int,
          bgColor: Color(item['bg_color'] as int),
          iconColor: Color(item['icon_color'] as int),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading budgets from SQLite: $e');
    }

    // Sync unsynced budgets to server
    syncUnsyncedBudgets();

    // Fetch latest budgets from server
    fetchFromBackend();
  }

  Future<void> fetchFromBackend() async {
    final token = await SecureStorageHelper.getToken();
    if (token == null) return;

    try {
      final response = await NetworkService.get(
        Uri.parse('http://145.79.10.157:8000/api/data/budgets'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<BudgetModel> loaded = data.map((item) {
          int bgVal = const Color(0xFFD1FAE5).value; // default
          int iconVal = const Color(0xFF059669).value; // default
          if (item['bg_color'] != null) {
            bgVal = item['bg_color'] is int 
                ? item['bg_color'] 
                : int.tryParse(item['bg_color'].toString()) ?? bgVal;
          }
          if (item['icon_color'] != null) {
            iconVal = item['icon_color'] is int 
                ? item['icon_color'] 
                : int.tryParse(item['icon_color'].toString()) ?? iconVal;
          }

          return BudgetModel(
            id: item['id'].toString(),
            category: item['category'],
            amount: double.parse(item['amount'].toString()),
            startDate: DateTime.parse(item['start_date']),
            endDate: DateTime.parse(item['end_date']),
            iconCodePoint: item['icon_code_point'] as int,
            bgColor: Color(bgVal),
            iconColor: Color(iconVal),
          );
        }).toList();

        // Persist to local SQLite
        for (var b in loaded) {
          await DatabaseHelper.instance.insertBudget({
            'id': b.id,
            'category': b.category,
            'amount': b.amount,
            'start_date': b.startDate.toIso8601String(),
            'end_date': b.endDate.toIso8601String(),
            'icon_code_point': b.iconCodePoint,
            'bg_color': b.bgColor.value,
            'icon_color': b.iconColor.value,
            'is_synced': 1,
          });
        }

        // Reload combined SQLite data to prevent offline budgets from disappearing
        final localData = await DatabaseHelper.instance.getAllBudgets();
        budgetsNotifier.value = localData.map((item) {
          return BudgetModel(
            id: item['id'],
            category: item['category'],
            amount: double.parse(item['amount'].toString()),
            startDate: DateTime.parse(item['start_date']),
            endDate: DateTime.parse(item['end_date']),
            iconCodePoint: item['icon_code_point'] as int,
            bgColor: Color(item['bg_color'] as int),
            iconColor: Color(item['icon_color'] as int),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching budgets from backend: $e');
    }
  }

  Future<void> syncUnsyncedBudgets() async {
    final unsynced = await DatabaseHelper.instance.getUnsyncedBudgets();
    if (unsynced.isEmpty) return;

    final token = await SecureStorageHelper.getToken();
    if (token == null) return;

    debugPrint('🔄 Syncing ${unsynced.length} unsynced budgets...');

    for (var item in unsynced) {
      try {
        final response = await NetworkService.post(
          Uri.parse('http://145.79.10.157:8000/api/data/budgets'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({
            'id': item['id'],
            'category': item['category'],
            'amount': item['amount'],
            'startDate': item['start_date'],
            'endDate': item['end_date'],
            'iconCodePoint': item['icon_code_point'],
            'bgColor': item['bg_color'],
            'iconColor': item['icon_color'],
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await DatabaseHelper.instance.markBudgetsAsSynced([item['id'].toString()]);
        }
      } catch (e) {
        debugPrint('Sync failed for budget item ${item['id']}: $e');
      }
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    // Save to SQLite locally first (is_synced = 0)
    try {
      await DatabaseHelper.instance.insertBudget({
        'id': budget.id,
        'category': budget.category,
        'amount': budget.amount,
        'start_date': budget.startDate.toIso8601String(),
        'end_date': budget.endDate.toIso8601String(),
        'icon_code_point': budget.iconCodePoint,
        'bg_color': budget.bgColor.value,
        'icon_color': budget.iconColor.value,
        'is_synced': 0,
      });
    } catch (e) {
      debugPrint('Error saving budget to SQLite: $e');
    }

    // Optimistic UI update
    budgetsNotifier.value = [budget, ...budgetsNotifier.value];

    // Try posting to backend (fire and forget)
    _postBudgetToBackend(budget);
  }

  void _postBudgetToBackend(BudgetModel budget) async {
    final token = await SecureStorageHelper.getToken();
    if (token == null) return;

    try {
      final response = await NetworkService.post(
        Uri.parse('http://145.79.10.157:8000/api/data/budgets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'id': budget.id,
          'category': budget.category,
          'amount': budget.amount,
          'startDate': budget.startDate.toIso8601String(),
          'endDate': budget.endDate.toIso8601String(),
          'iconCodePoint': budget.iconCodePoint,
          'bgColor': budget.bgColor.value,
          'iconColor': budget.iconColor.value,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await DatabaseHelper.instance.markBudgetsAsSynced([budget.id]);
      }
    } catch (e) {
      debugPrint('Error saving budget to backend (will sync later): $e');
    }
  }

  Future<void> removeBudget(String id) async {
    // Delete locally from SQLite
    try {
      await DatabaseHelper.instance.deleteBudget(id);
    } catch (e) {
      debugPrint('Error deleting budget from SQLite: $e');
    }

    // Update memory
    budgetsNotifier.value = budgetsNotifier.value.where((b) => b.id != id).toList();

    // Call backend API for deletion (fire and forget)
    _deleteBudgetFromBackend(id);
  }

  void _deleteBudgetFromBackend(String id) async {
    final token = await SecureStorageHelper.getToken();
    if (token == null) return;

    try {
      await NetworkService.delete(
        Uri.parse('http://145.79.10.157:8000/api/data/budgets/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Error deleting budget from backend: $e');
    }
  }

  Future<void> updateBudget(BudgetModel updatedBudget) async {
    try {
      await DatabaseHelper.instance.insertBudget({
        'id': updatedBudget.id,
        'category': updatedBudget.category,
        'amount': updatedBudget.amount,
        'start_date': updatedBudget.startDate.toIso8601String(),
        'end_date': updatedBudget.endDate.toIso8601String(),
        'icon_code_point': updatedBudget.iconCodePoint,
        'bg_color': updatedBudget.bgColor.value,
        'icon_color': updatedBudget.iconColor.value,
        'is_synced': 0,
      });
    } catch (e) {
      debugPrint('Error updating budget in SQLite: $e');
    }

    // Update memory immediately
    budgetsNotifier.value = budgetsNotifier.value.map((b) {
      return b.id == updatedBudget.id ? updatedBudget : b;
    }).toList();

    // Update on backend (fire and forget)
    _updateBudgetOnBackend(updatedBudget);
  }

  void _updateBudgetOnBackend(BudgetModel updatedBudget) async {
    final token = await SecureStorageHelper.getToken();
    if (token == null) return;

    try {
      final response = await NetworkService.put(
        Uri.parse('http://145.79.10.157:8000/api/data/budgets/${updatedBudget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'category': updatedBudget.category,
          'amount': updatedBudget.amount,
          'startDate': updatedBudget.startDate.toIso8601String(),
          'endDate': updatedBudget.endDate.toIso8601String(),
          'iconCodePoint': updatedBudget.iconCodePoint,
          'bgColor': updatedBudget.bgColor.value,
          'iconColor': updatedBudget.iconColor.value,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await DatabaseHelper.instance.markBudgetsAsSynced([updatedBudget.id]);
      }
    } catch (e) {
      debugPrint('Error updating budget on backend: $e');
    }
  }

  void clearMemory() {
    budgetsNotifier.value = [];
  }
}
