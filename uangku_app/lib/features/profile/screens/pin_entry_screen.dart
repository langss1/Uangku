import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'package:uangku_app/core/services/biometric_service.dart';

enum PinEntryMode {
  setup,
  confirm,
  verifyToDisable,
  verifyToChange,
  unlock,
}

class PinEntryScreen extends StatefulWidget {
  final PinEntryMode mode;
  final String? pinToConfirm;

  const PinEntryScreen({
    super.key,
    required this.mode,
    this.pinToConfirm,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _firstPin;
  late PinEntryMode _currentMode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isError = false;

  // Biometrics properties in unlock mode
  bool _showBiometricButton = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _firstPin = widget.pinToConfirm;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    if (_currentMode == PinEntryMode.unlock) {
      _checkBiometricAvailability();
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final isBiometricEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
    final isBiometricAvailable = await BiometricService.isBiometricsAvailable();

    if (mounted) {
      setState(() {
        _showBiometricButton = isBiometricEnabled && isBiometricAvailable;
      });

      // Auto-trigger biometric on unlock load
      if (_showBiometricButton) {
        _triggerBiometricAuth();
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final isIndo =
        Provider.of<PreferencesProvider>(context, listen: false).language == 'id';
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: isIndo
            ? 'Pindai sidik jari atau wajah Anda untuk masuk'
            : 'Scan your fingerprint or face to unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        Navigator.pop(context, 'BIOMETRIC_SUCCESS');
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric unlock failed: $e');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(int number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _isError = false;
        _enteredPin += number.toString();
      });

      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _processPin();
        });
      }
    }
  }

  void _onBackPressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _processPin() async {
    final isIndo =
        Provider.of<PreferencesProvider>(context, listen: false).language == 'id';

    if (_currentMode == PinEntryMode.setup) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _currentMode = PinEntryMode.confirm;
      });
    } else if (_currentMode == PinEntryMode.confirm) {
      if (_enteredPin == _firstPin) {
        Navigator.pop(context, _enteredPin);
      } else {
        _triggerErrorEffect();
        setState(() {
          _enteredPin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo ? 'PIN tidak cocok, silakan ulangi' : 'PINs do not match, please retry',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (_currentMode == PinEntryMode.unlock) {
      final isCorrect = await _verifyPin(_enteredPin);
      if (isCorrect) {
        if (mounted) Navigator.pop(context, 'PIN_SUCCESS');
      } else {
        _triggerErrorEffect();
        setState(() {
          _enteredPin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo ? 'PIN yang Anda masukkan salah' : 'The PIN you entered is incorrect',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      Navigator.pop(context, _enteredPin);
    }
  }

  Future<bool> _verifyPin(String enteredPin) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('app_lock_pin_code');
    return savedPin == enteredPin;
  }

  void _triggerErrorEffect() {
    setState(() {
      _isError = true;
    });
    _shakeController.forward(from: 0.0);
  }

  String _getInstructionText(bool isIndo) {
    switch (_currentMode) {
      case PinEntryMode.setup:
        return isIndo ? 'Atur 4-Digit PIN Keamanan' : 'Set 4-Digit Security PIN';
      case PinEntryMode.confirm:
        return isIndo ? 'Konfirmasi PIN Anda' : 'Confirm Your PIN';
      case PinEntryMode.verifyToDisable:
      case PinEntryMode.verifyToChange:
        return isIndo ? 'Masukkan PIN Saat Ini' : 'Enter Current PIN';
      case PinEntryMode.unlock:
        return isIndo ? 'Masukkan PIN Uangku' : 'Enter Uangku PIN';
    }
  }

  String _getSubtitleText(bool isIndo) {
    switch (_currentMode) {
      case PinEntryMode.setup:
        return isIndo
            ? 'Buat PIN numerik untuk mengamankan data Anda'
            : 'Create a numeric PIN to secure your data';
      case PinEntryMode.confirm:
        return isIndo
            ? 'Masukkan kembali PIN yang baru Anda buat'
            : 'Re-enter the PIN you just created';
      case PinEntryMode.verifyToDisable:
        return isIndo
            ? 'Konfirmasi PIN Anda untuk menonaktifkan kunci'
            : 'Confirm your PIN to disable app lock';
      case PinEntryMode.verifyToChange:
        return isIndo
            ? 'Konfirmasi PIN lama Anda sebelum membuat PIN baru'
            : 'Confirm your old PIN before creating a new one';
      case PinEntryMode.unlock:
        return isIndo
            ? 'Masukkan PIN keamanan untuk melanjutkan'
            : 'Enter security PIN to continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentMode != PinEntryMode.unlock
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _currentMode == PinEntryMode.unlock
                    ? Icons.lock_outline_rounded
                    : Icons.dialpad_rounded,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getInstructionText(isIndo),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _getSubtitleText(isIndo),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // PIN Indicator Dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value * (1 - 2 * (_shakeController.value * 5 % 2).floor()), 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? Colors.red
                          : (isFilled
                              ? AppColors.primaryBlue
                              : (isDark ? Colors.white10 : Colors.black12)),
                      border: Border.all(
                        color: _isError
                            ? Colors.red
                            : (isFilled
                                ? AppColors.primaryBlue
                                : (isDark ? Colors.white24 : Colors.black26)),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 2),

            // Numeric Keyboard Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Column(
                children: [
                  _buildKeyboardRow([1, 2, 3]),
                  const SizedBox(height: 16),
                  _buildKeyboardRow([4, 5, 6]),
                  const SizedBox(height: 16),
                  _buildKeyboardRow([7, 8, 9]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Biometric button if enabled and in unlock mode
                      _showBiometricButton
                          ? _buildBiometricButton()
                          : const SizedBox(width: 70, height: 70),
                      _buildKeyboardButton(0),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: numbers.map((n) => _buildKeyboardButton(n)).toList(),
    );
  }

  Widget _buildKeyboardButton(int number) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              width: 1,
            ),
          ),
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _triggerBiometricAuth,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withOpacity(0.08),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            size: 32,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackPressed,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
          ),
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
