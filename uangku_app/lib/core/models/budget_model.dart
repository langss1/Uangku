import 'package:flutter/material.dart';

class BudgetModel {
  final String id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'iconCodePoint': icon.codePoint,
      'bgColor': bgColor.value,
      'iconColor': iconColor.value,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      category: json['category'],
      amount: json['amount'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
      bgColor: Color(json['bgColor']),
      iconColor: Color(json['iconColor']),
    );
  }
}
