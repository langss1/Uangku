import 'package:flutter/material.dart';

/// Utility untuk membuat ukuran yang responsive di semua ukuran layar HP.
/// Base reference screen: 390 × 844 (medium — antara S25 FE & A21s)
class Responsive {
  static const double _baseWidth = 390.0;
  static const double _baseHeight = 844.0;

  /// Lebar layar
  static double w(BuildContext context) => MediaQuery.of(context).size.width;

  /// Tinggi layar
  static double h(BuildContext context) => MediaQuery.of(context).size.height;

  /// Scale berdasarkan LEBAR layar (untuk padding, radius, icon size, widget width)
  /// [size] adalah ukuran di reference screen (390px wide)
  static double r(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / _baseWidth);
  }

  /// Scale berdasarkan TINGGI layar (untuk vertical padding)
  static double rv(BuildContext context, double size) {
    final screenHeight = MediaQuery.of(context).size.height;
    return size * (screenHeight / _baseHeight);
  }

  /// Font size yang responsive — lebih konservatif agar tidak terlalu besar/kecil
  static double sp(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Clamp: min 0.8x, max 1.15x dari base
    final scale = (screenWidth / _baseWidth).clamp(0.80, 1.15);
    return size * scale;
  }

  /// Apakah layar ini tergolong kecil? (lebar < 360px)
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  /// Apakah layar ini tergolong besar? (lebar > 400px)
  static bool isLarge(BuildContext context) =>
      MediaQuery.of(context).size.width > 400;
}
