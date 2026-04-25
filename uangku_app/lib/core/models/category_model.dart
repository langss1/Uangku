import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final bool isIncome;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.isIncome,
  });
}
