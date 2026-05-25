import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/theme/app_theme.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/core/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:uangku_app/core/services/network_service.dart';
import 'package:uangku_app/core/services/security_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      
      // Jalankan logika sinkronisasi dan pengecekan notifikasi harian
      debugPrint("🔄 Background Task (Workmanager) Sedang Berjalan...");
      await TransactionData().syncUnsyncedTransactions();
      await NotificationService().triggerMorningReport();
    } catch (e) {
      debugPrint("Error di Background Task: $e");
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize Security and SSL Pinning HTTP Client
  await NetworkService.init();
  await SecurityService.checkEnvironment();
  
  // Inisialisasi WorkManager untuk berjalan meski aplikasi di-kill
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  
  // Daftarkan tugas periodik (Setiap 1 jam)
  Workmanager().registerPeriodicTask(
    "uangku_background_task",
    "background_sync_and_report",
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
  
  // Dengarkan perubahan koneksi internet di latar belakang (saat diminimize)
  Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    if (results.isNotEmpty && results.first != ConnectivityResult.none) {
      debugPrint("🟢 Internet Terhubung! Memulai Auto-Sync di latar...");
      TransactionData().syncUnsyncedTransactions();
    }
  });

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
          themeMode: prefs.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
