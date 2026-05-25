import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/services/network_service.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'dart:convert';
import 'package:uangku_app/features/home/home_screen.dart';
import 'package:uangku_app/features/auth/force_reset_password_screen.dart';

class VerifyLogin2FAScreen extends StatefulWidget {
  final String tempToken;
  final String twoFactorType;

  const VerifyLogin2FAScreen({Key? key, required this.tempToken, required this.twoFactorType}) : super(key: key);

  @override
  State<VerifyLogin2FAScreen> createState() => _VerifyLogin2FAScreenState();
}

class _VerifyLogin2FAScreenState extends State<VerifyLogin2FAScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify2FA() async {
    final token = _tokenController.text.trim();
    if (token.length != 6) {
      CustomPopup.show(context, 'Please enter a valid 6-digit code', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await NetworkService.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/login-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tempToken': widget.tempToken,
          'token': token,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await SecureStorageHelper.saveToken(data['token']);
        if (data['user'] != null) {
          await SecureStorageHelper.saveUserData(
            name: data['user']['full_name'] ?? '',
            email: data['user']['email'] ?? '',
          );
        }

        if (data['requiresPasswordChange'] == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ForceResetPasswordScreen(token: data['token']),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Verification failed';
        CustomPopup.show(context, errorMsg, isSuccess: false);
      }
    } catch (e) {
      CustomPopup.show(context, 'Error connecting to server: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String message = 'Enter the 6-digit code from your Authenticator app';
    if (widget.twoFactorType == 'EMAIL') {
      message = 'Enter the 6-digit OTP sent to your email';
    } else if (widget.twoFactorType == 'BOTH') {
      message = 'Enter the 6-digit code from your Authenticator app or Email OTP';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    widget.twoFactorType == 'EMAIL' ? Icons.mail_lock : Icons.security, 
                    size: 40, color: const Color(0xFF0066CC)
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Two-Factor Authentication',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _tokenController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 32, letterSpacing: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2)),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify2FA,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Verify & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
