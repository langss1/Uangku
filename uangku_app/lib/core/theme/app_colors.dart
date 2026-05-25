import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF4F7FB);
  static const Color primaryBlue = Color(0xFF0056B3);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color inputBackground = Color(0xFFF7F9FC);
  static const Color inputBorder = Color(0xFFE2E8F0);
}

extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get surfaceColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get scaffoldBackgroundColor => isDarkMode ? const Color(0xFF181A1E) : AppColors.background;
  Color get textPrimary => isDarkMode ? const Color(0xFFE2E8F0) : AppColors.textDark;
  Color get textSecondary => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get borderColor => isDarkMode ? Colors.grey[800]! : const Color(0xFFF1F5F9);
  Color get cardColor => isDarkMode ? const Color(0xFF22252A) : Colors.white;
  Color get cardColor70 => isDarkMode ? const Color(0xFF22252A).withOpacity(0.7) : Colors.white70;
  Color get cardColor24 => isDarkMode ? const Color(0xFF22252A).withOpacity(0.24) : Colors.white24;
}
