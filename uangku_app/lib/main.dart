import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_theme.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';

void main() {
  runApp(const UangkuApp());
}

class UangkuApp extends StatelessWidget {
  const UangkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UANGKU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
