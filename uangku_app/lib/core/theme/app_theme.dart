import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0056B3)),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
    );
  }
}
