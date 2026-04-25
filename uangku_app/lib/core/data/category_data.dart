import 'package:flutter/material.dart';
import 'package:uangku_app/core/models/category_model.dart';

class CategoryData {
  static final CategoryData _instance = CategoryData._internal();

  factory CategoryData() {
    return _instance;
  }

  CategoryData._internal();

  final ValueNotifier<List<CategoryModel>> categoriesNotifier = ValueNotifier([
    // Expense
    CategoryModel(id: "exp_1", name: "Food & Drinks", icon: Icons.restaurant, color: const Color(0xFFFECACA), iconColor: const Color(0xFFDC2626), isIncome: false),
    CategoryModel(id: "exp_2", name: "Education", icon: Icons.school, color: const Color(0xFFBFDBFE), iconColor: const Color(0xFF2563EB), isIncome: false),
    CategoryModel(id: "exp_3", name: "Bills & Utilities", icon: Icons.receipt_long, color: const Color(0xFFE5E7EB), iconColor: const Color(0xFF4B5563), isIncome: false),
    CategoryModel(id: "exp_4", name: "Rent", icon: Icons.home, color: const Color(0xFFBBF7D0), iconColor: const Color(0xFF16A34A), isIncome: false),
    CategoryModel(id: "exp_5", name: "Health & Fitness", icon: Icons.medical_services, color: const Color(0xFFFBCFE8), iconColor: const Color(0xFFDB2777), isIncome: false),
    CategoryModel(id: "exp_6", name: "Transportation", icon: Icons.directions_car, color: const Color(0xFFFDE68A), iconColor: const Color(0xFFD97706), isIncome: false),
    CategoryModel(id: "exp_7", name: "Entertainment", icon: Icons.sports_esports, color: const Color(0xFFE9D5FF), iconColor: const Color(0xFF9333EA), isIncome: false),
    CategoryModel(id: "exp_8", name: "Home Maintenance", icon: Icons.cleaning_services, color: const Color(0xFFFEF08A), iconColor: const Color(0xFFCA8A04), isIncome: false),
    
    // Income
    CategoryModel(id: "inc_1", name: "Salary", icon: Icons.account_balance_wallet, color: const Color(0xFFD1FAE5), iconColor: const Color(0xFF059669), isIncome: true),
    CategoryModel(id: "inc_2", name: "Bonus", icon: Icons.card_giftcard, color: const Color(0xFFFEF08A), iconColor: const Color(0xFFCA8A04), isIncome: true),
    CategoryModel(id: "inc_3", name: "Investment", icon: Icons.trending_up, color: const Color(0xFFBAE6FD), iconColor: const Color(0xFF0284C7), isIncome: true),
    CategoryModel(id: "inc_4", name: "Other Income", icon: Icons.add_circle_outline, color: const Color(0xFFE2E8F0), iconColor: const Color(0xFF475569), isIncome: true),
  ]);

  void addCategory(CategoryModel category) {
    categoriesNotifier.value = [...categoriesNotifier.value, category];
  }
}
