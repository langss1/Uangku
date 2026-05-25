import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SecurityService {
  static bool _isRooted = false;
  static bool _isDeveloperMode = false;

  static bool get isRooted => _isRooted;
  static bool get isDeveloperMode => _isDeveloperMode;

  // Run security environment checks on app startup
  static Future<void> checkEnvironment() async {
    try {
      // Check for rooted (Android) or jailbroken (iOS) devices
      _isRooted = await FlutterJailbreakDetection.jailbroken;
      _isDeveloperMode = await FlutterJailbreakDetection.developerMode;

      if (_isRooted) {
        print("🚨 SECURITY AUDIT: Rooted or jailbroken environment detected! Extra runtime precautions recommended.");
      } else {
        print("🛡️ SECURITY AUDIT: OS Integrity verified successfully.");
      }

      if (_isDeveloperMode) {
        print("🛡️ SECURITY AUDIT: Developer options are enabled on the host device.");
      }
    } catch (e) {
      print("🛡️ SECURITY AUDIT: Error during runtime security checks: $e");
    }
  }
}
