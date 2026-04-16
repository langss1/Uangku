import 'package:flutter/material.dart';

class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isIncome;
  final String note;

  TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.isIncome,
    this.note = '',
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    IconData? icon,
    Color? bgColor,
    Color? iconColor,
    bool? isIncome,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      bgColor: bgColor ?? this.bgColor,
      iconColor: iconColor ?? this.iconColor,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
    );
  }
}
