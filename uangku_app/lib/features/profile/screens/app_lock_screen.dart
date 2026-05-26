import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/features/profile/screens/pin_entry_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _PinLockService {
  static const String _keyPin = 'app_lock_pin_code';

  static Future<bool> hasPin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_keyPin);
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> savePin(String pin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, pin);
  }

  static Future<void> clearPin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPin);
  }

  static Future<bool> verifyPin(String enteredPin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_keyPin);
    return savedPin == enteredPin;
  }
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isPinLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool canCheck = false;
    bool biometricAvailable = false;
    List<BiometricType> biometrics = [];

    try {
      canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        biometrics = await _localAuth.getAvailableBiometrics();
        biometricAvailable = biometrics.isNotEmpty;
      }
    } on PlatformException {
      canCheck = false;
    }

    final hasPinCode = await _PinLockService.hasPin();

    if (mounted) {
      setState(() {
        _isPinLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
        // If has no PIN code but pref says true, sync it
        if (_isPinLockEnabled && !hasPinCode) {
          _isPinLockEnabled = false;
          prefs.setBool('app_lock_enabled', false);
        }
        
        // Force biometric off in UI and Prefs if PIN lock is disabled
        if (!_isPinLockEnabled) {
          _isBiometricEnabled = false;
          prefs.setBool('biometric_lock_enabled', false);
        } else {
          _isBiometricEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
        }
        
        _isBiometricAvailable = biometricAvailable;
        _availableBiometrics = biometrics;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePinLock(bool value, bool isIndo) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      // 1. Enabling lock: Open PIN entry screen in setup mode
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const PinEntryScreen(mode: PinEntryMode.setup),
        ),
      );

      if (result != null && result.length == 4) {
        await _PinLockService.savePin(result);
        await prefs.setBool('app_lock_enabled', true);
        setState(() {
          _isPinLockEnabled = true;
        });
        if (mounted) {
          CustomPopup.show(
            context,
            isIndo ? 'PIN pengunci berhasil diaktifkan!' : 'Lock PIN enabled successfully!',
            isSuccess: true,
          );
        }
      }
    } else {
      // 2. Disabling lock: Confirm with current PIN first
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const PinEntryScreen(mode: PinEntryMode.verifyToDisable),
        ),
      );

      if (result != null) {
        final isCorrect = await _PinLockService.verifyPin(result);
        if (isCorrect) {
          await _PinLockService.clearPin();
          await prefs.setBool('app_lock_enabled', false);
          await prefs.setBool('biometric_lock_enabled', false);
          setState(() {
            _isPinLockEnabled = false;
            _isBiometricEnabled = false;
          });
          if (mounted) {
            CustomPopup.show(
              context,
              isIndo ? 'Kunci aplikasi dinonaktifkan' : 'App lock disabled',
              isSuccess: true,
            );
          }
        } else {
          if (mounted) {
            CustomPopup.show(
              context,
              isIndo ? 'PIN salah, gagal menonaktifkan kunci' : 'Incorrect PIN, failed to disable lock',
              isSuccess: false,
            );
          }
        }
      }
    }
  }

  Future<void> _changePin(bool isIndo) async {
    // 1. Verify current PIN
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinEntryScreen(mode: PinEntryMode.verifyToChange),
      ),
    );

    if (result != null) {
      final isCorrect = await _PinLockService.verifyPin(result);
      if (isCorrect) {
        // 2. Enter new PIN
        if (!mounted) return;
        final newPin = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => const PinEntryScreen(mode: PinEntryMode.setup),
          ),
        );

        if (newPin != null && newPin.length == 4) {
          await _PinLockService.savePin(newPin);
          if (mounted) {
            CustomPopup.show(
              context,
              isIndo ? 'PIN berhasil diubah!' : 'PIN changed successfully!',
              isSuccess: true,
            );
          }
        }
      } else {
        if (mounted) {
          CustomPopup.show(
            context,
            isIndo ? 'PIN saat ini salah' : 'Current PIN is incorrect',
            isSuccess: false,
          );
        }
      }
    }
  }

  Future<void> _toggleBiometric(bool value, bool isIndo) async {
    if (!_isPinLockEnabled) {
      CustomPopup.show(
        context,
        isIndo ? 'Aktifkan PIN pengunci terlebih dahulu' : 'Enable security PIN lock first',
        isSuccess: false,
      );
      return;
    }

    if (value) {
      // Prompt biometric authentication to verify it works
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: isIndo
              ? 'Konfirmasi identitas Anda untuk mengaktifkan biometrik'
              : 'Confirm your identity to enable biometrics',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (authenticated) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_lock_enabled', true);
          setState(() {
            _isBiometricEnabled = true;
          });
          if (mounted) {
            CustomPopup.show(
              context,
              isIndo ? 'Autentikasi biometrik berhasil diaktifkan!' : 'Biometric lock enabled successfully!',
              isSuccess: true,
            );
          }
        }
      } on PlatformException catch (e) {
        if (mounted) {
          CustomPopup.show(
            context,
            isIndo ? 'Sensor biometrik tidak dapat diakses: ${e.message}' : 'Biometric sensor not accessible: ${e.message}',
            isSuccess: false,
          );
        }
      }
    } else {
      // Directly disable biometric
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_lock_enabled', false);
      setState(() {
        _isBiometricEnabled = false;
      });
      if (mounted) {
        CustomPopup.show(
          context,
          isIndo ? 'Autentikasi biometrik dinonaktifkan' : 'Biometric lock disabled',
          isSuccess: true,
        );
      }
    }
  }

  String _getBiometricTypeLabel(bool isIndo) {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return isIndo ? 'Wajah (Face ID)' : 'Face Recognition';
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return isIndo ? 'Sidik Jari' : 'Fingerprint';
    }
    return isIndo ? 'Biometrik Perangkat' : 'Device Biometric';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face_outlined;
    }
    return Icons.fingerprint_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isIndo =
        Provider.of<PreferencesProvider>(context).language.toLowerCase() == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isIndo ? 'Kunci Aplikasi' : 'App Lock',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIndo
                          ? 'Gunakan kunci PIN dan sensor biometrik perangkat Anda untuk mencegah akses fisik tidak sah ke data keuangan Anda.'
                          : 'Use a PIN lock and your device biometric sensor to prevent unauthorized physical access to your financial data.',
                      style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // Card 1: PIN Lock Switch Card
                    _buildSwitchCard(
                      title: isIndo ? 'Kunci PIN Keamanan' : 'PIN Security Lock',
                      subtitle: isIndo
                          ? 'Minta 4-digit PIN keamanan saat aplikasi dibuka.'
                          : 'Require a 4-digit security PIN when launching Uangku.',
                      icon: Icons.dialpad_rounded,
                      iconColor: AppColors.primaryBlue,
                      value: _isPinLockEnabled,
                      onChanged: (val) => _togglePinLock(val, isIndo),
                    ),

                    // Additional action button for changing PIN if lock is enabled
                    if (_isPinLockEnabled) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _changePin(isIndo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderColor, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue, size: 22),
                                  const SizedBox(width: 16),
                                  Text(
                                    isIndo ? 'Ubah PIN Keamanan' : 'Change Security PIN',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Card 2: Biometric Authentication Card
                    _buildSwitchCard(
                      title: _getBiometricTypeLabel(isIndo),
                      subtitle: _isBiometricAvailable
                          ? (isIndo
                              ? 'Gunakan sensor biometrik untuk mempercepat proses membuka kunci.'
                              : 'Use biometric sensor to unlock the app instantly.')
                          : (isIndo
                              ? 'Sensor biometrik tidak tersedia pada perangkat Anda.'
                              : 'Biometric sensor is not available on this device.'),
                      icon: _getBiometricIcon(),
                      iconColor: AppColors.primaryBlue, // ALWAYS PURE BLUE!
                      value: _isBiometricEnabled,
                      onChanged: _isBiometricAvailable && _isPinLockEnabled
                          ? (val) => _toggleBiometric(val, isIndo)
                          : null,
                      isEnabled: _isBiometricAvailable && _isPinLockEnabled,
                    ),

                    if (!_isBiometricAvailable) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isIndo
                                    ? 'Biometrik tidak terdeteksi. Silakan daftarkan sidik jari atau wajah terlebih dahulu di menu Pengaturan HP Anda.'
                                    : 'Biometrics not detected. Please enroll your fingerprint or face in your device Settings first.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled && onChanged != null
          ? () => onChanged(!value)
          : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? AppColors.primaryBlue : context.borderColor,
              width: 1.5,
            ),
          ),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryBlue,
              activeTrackColor: AppColors.primaryBlue.withOpacity(0.3),
            ),
          ],
        ),
      ),
    ),
  );
}
}
