import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/theme/app_theme.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
      ],
      child: const UangkuApp(),
    ),
  );
}

class UangkuApp extends StatelessWidget {
  const UangkuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, prefs, child) {
        return MaterialApp(
          title: 'UANGKU',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: prefs.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
