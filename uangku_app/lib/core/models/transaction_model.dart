import 'package:flutter/material.dart';

class TransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount; // Amount in base currency (IDR)
  final double originalAmount; // Amount in original currency
  final String currencyCode; // e.g., 'IDR', 'USD'
  final double exchangeRate; // Rate used for conversion
  final DateTime date;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isIncome;
  final String note;
  final String? imagePath;

  TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.originalAmount = 0,
    this.currencyCode = 'IDR',
    this.exchangeRate = 1.0,
    required this.date,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.isIncome,
    this.note = '',
    this.imagePath,
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    double? originalAmount,
    String? currencyCode,
    double? exchangeRate,
    DateTime? date,
    IconData? icon,
    Color? bgColor,
    Color? iconColor,
    bool? isIncome,
    String? note,
    String? imagePath,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      originalAmount: originalAmount ?? this.originalAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      bgColor: bgColor ?? this.bgColor,
      iconColor: iconColor ?? this.iconColor,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
