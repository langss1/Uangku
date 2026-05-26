import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyAppLock = 'is_app_lock_enabled';

  // Check if biometric hardware exists and is configured on the device
  static Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Trigger Biometric (Fingerprint/FaceID) or Device PIN/Pattern/Password fallback
  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Silakan verifikasi sidik jari atau PIN Anda untuk masuk ke Uangku.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // fallback to PIN/Pattern/Password if biometrics fail
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Check if optional app lock is enabled by the user in SharedPreferences
  static Future<bool> isAppLockEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('app_lock_enabled') ?? prefs.getBool(_keyAppLock) ?? false;
  }

  // Save the user's preference for app lock in SharedPreferences
  static Future<void> setAppLockEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);
    await prefs.setBool(_keyAppLock, value);
  }
}
