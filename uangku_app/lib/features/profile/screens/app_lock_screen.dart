import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isAppLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _canCheckBiometrics = false;
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

    if (mounted) {
      setState(() {
        _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
        _isBiometricEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
        _canCheckBiometrics = canCheck;
        _isBiometricAvailable = biometricAvailable;
        _availableBiometrics = biometrics;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAppLock(bool value, bool isIndo) async {
    if (value) {
      final authenticated = await _authenticate(isIndo);
      if (!authenticated) return;
    } else {
      final confirm = await _showConfirmDialog(isIndo);
      if (!confirm) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_lock_enabled', false);
      if (mounted) setState(() => _isBiometricEnabled = false);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_lock_enabled', value);
    if (mounted) {
      setState(() => _isAppLockEnabled = value);
      _showSnackBar(
        isIndo
            ? (value ? 'Kunci aplikasi diaktifkan' : 'Kunci aplikasi dinonaktifkan')
            : (value ? 'App lock enabled' : 'App lock disabled'),
        value ? Colors.green : Colors.orange,
      );
    }
  }

  Future<void> _toggleBiometric(bool value, bool isIndo) async {
    if (!_isAppLockEnabled) {
      _showSnackBar(
        isIndo ? 'Aktifkan kunci aplikasi terlebih dahulu' : 'Enable app lock first',
        Colors.orange,
      );
      return;
    }

    if (value && !_isBiometricAvailable) {
      _showSnackBar(
        isIndo
            ? 'Perangkat tidak mendukung biometrik atau belum diatur'
            : 'Device does not support biometrics or not enrolled',
        Colors.red,
      );
      return;
    }

    if (value) {
      final authenticated = await _authenticate(isIndo);
      if (!authenticated) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock_enabled', value);
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
      _showSnackBar(
        isIndo
            ? (value ? 'Sidik jari/wajah diaktifkan' : 'Sidik jari/wajah dinonaktifkan')
            : (value ? 'Biometric enabled' : 'Biometric disabled'),
        value ? Colors.green : Colors.orange,
      );
    }
  }

  Future<bool> _authenticate(bool isIndo) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: isIndo
            ? 'Konfirmasi identitas Anda untuk mengubah pengaturan keamanan'
            : 'Confirm your identity to change security settings',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Auth error: $e');
      if (mounted) {
        _showSnackBar(
          isIndo
              ? 'Autentikasi gagal: ${e.message}'
              : 'Authentication failed: ${e.message}',
          Colors.red,
        );
      }
      return false;
    }
  }

  Future<bool> _showConfirmDialog(bool isIndo) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              isIndo ? 'Nonaktifkan Kunci?' : 'Disable Lock?',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            content: Text(
              isIndo
                  ? 'Menonaktifkan kunci akan membuat aplikasi dapat dibuka tanpa verifikasi. Yakin?'
                  : 'Disabling app lock will allow the app to open without verification. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(isIndo ? 'Batal' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isIndo ? 'Nonaktifkan' : 'Disable'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getBiometricTypeLabel(bool isIndo) {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return isIndo ? 'Wajah (Face ID)' : 'Face Recognition';
    }
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return isIndo ? 'Sidik Jari' : 'Fingerprint';
    }
    if (_availableBiometrics.contains(BiometricType.iris)) {
      return isIndo ? 'Iris Mata' : 'Iris';
    }
    return isIndo ? 'Biometrik' : 'Biometric';
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: isDark ? Colors.white : Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isIndo ? 'Kunci Aplikasi' : 'App Lock',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(isIndo),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                        isIndo ? 'KUNCI APLIKASI' : 'APP LOCK', isDark),
                    const SizedBox(height: 12),
                    _buildGroupCard(isDark, [
                      _buildSwitchTile(
                        icon: Icons.lock_outlined,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo
                            ? 'Aktifkan Kunci Aplikasi'
                            : 'Enable App Lock',
                        subtitle: isIndo
                            ? 'Aplikasi memerlukan verifikasi saat dibuka'
                            : 'App requires verification when opened',
                        value: _isAppLockEnabled,
                        onChanged: (val) => _toggleAppLock(val, isIndo),
                        isDark: isDark,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                        isIndo ? 'BIOMETRIK' : 'BIOMETRICS', isDark),
                    const SizedBox(height: 12),
                    _buildGroupCard(isDark, [
                      _buildSwitchTile(
                        icon: _getBiometricIcon(),
                        iconColor: _isBiometricAvailable
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                        title: _getBiometricTypeLabel(isIndo),
                        subtitle: _isBiometricAvailable
                            ? (isIndo
                                ? 'Gunakan ${_getBiometricTypeLabel(isIndo).toLowerCase()} untuk membuka aplikasi'
                                : 'Use ${_getBiometricTypeLabel(isIndo)} to unlock the app')
                            : (isIndo
                                ? 'Tidak tersedia di perangkat ini'
                                : 'Not available on this device'),
                        value: _isBiometricEnabled,
                        onChanged: _isBiometricAvailable
                            ? (val) => _toggleBiometric(val, isIndo)
                            : null,
                        isDark: isDark,
                        enabled: _isBiometricAvailable && _isAppLockEnabled,
                      ),
                    ]),
                    if (_canCheckBiometrics && _isBiometricAvailable) ...[
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        isIndo
                            ? 'Jika sidik jari/wajah gagal, PIN perangkat akan digunakan sebagai cadangan.'
                            : 'If biometric fails, device PIN will be used as fallback.',
                        Icons.info_outline_rounded,
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                    ],
                    if (!_isBiometricAvailable) ...[
                      const SizedBox(height: 12),
                      _buildNoteCard(
                        isIndo
                            ? 'Biometrik tidak tersedia. Pastikan sidik jari/wajah sudah didaftarkan di Pengaturan perangkat.'
                            : 'Biometrics not available. Make sure fingerprint/face is enrolled in device Settings.',
                        Icons.warning_amber_rounded,
                        Colors.orange,
                        isDark,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildHowItWorksCard(isIndo, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard(bool isIndo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIndo ? 'Keamanan Ekstra' : 'Extra Security',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isIndo
                      ? 'Lindungi data keuangan kamu dari akses tidak sah'
                      : 'Protect your financial data from unauthorized access',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildGroupCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required bool isDark,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
            height: 1.4,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.primaryBlue,
          activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildNoteCard(String text, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(bool isIndo, bool isDark) {
    final steps = isIndo
        ? [
            'Kunci aplikasi akan aktif setelah aplikasi ditutup atau layar terkunci.',
            'Buka aplikasi → Verifikasi identitas Anda dengan sidik jari, wajah, atau PIN perangkat.',
            'Pilihan ini bersifat opsional dan dapat diubah kapan saja.',
          ]
        : [
            'App lock activates after the app is closed or the screen is locked.',
            'Open app → Verify your identity with fingerprint, face, or device PIN.',
            'This option is optional and can be changed at any time.',
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppColors.primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isIndo ? 'Cara Kerja' : 'How It Works',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
