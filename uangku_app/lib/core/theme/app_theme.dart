import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0056B3),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0056B3),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
