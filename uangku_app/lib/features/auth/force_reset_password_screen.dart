import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/services/network_service.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'dart:convert';

class ForceResetPasswordScreen extends StatefulWidget {
  final String token;
  const ForceResetPasswordScreen({super.key, required this.token});

  @override
  State<ForceResetPasswordScreen> createState() => _ForceResetPasswordScreenState();
}

class _ForceResetPasswordScreenState extends State<ForceResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      CustomPopup.show(context, 'Password harus minimal 6 karakter', isSuccess: false);
      return;
    }
    if (password != confirm) {
      CustomPopup.show(context, 'Konfirmasi password tidak cocok', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await NetworkService.put(
        Uri.parse('http://145.79.10.157:8000/api/auth/security'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Fetch user data directly from profile
        final userResponse = await NetworkService.get(
          Uri.parse('http://145.79.10.157:8000/api/auth/profile'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await SecureStorageHelper.saveToken(widget.token);

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body)['user'];
          final userEmail = userData['email'] ?? '';
          await SecureStorageHelper.saveUserData(
            name: userData['full_name'] ?? '',
            email: userEmail,
          );
          await prefs.setString('user_email', userEmail);
        }

        CustomPopup.show(context, 'Password berhasil diperbarui!', isSuccess: true);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final data = jsonDecode(response.body);
        CustomPopup.show(context, data['error'] ?? 'Gagal update password', isSuccess: false);
      }
    } catch (e) {
      CustomPopup.show(context, 'Koneksi bermasalah', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.password, size: 40, color: Color(0xFFF97316)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Perbarui Password Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              const Text(
                'Demi keamanan, Anda wajib mengganti password pemulihan dengan password baru yang lebih aman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan & Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
