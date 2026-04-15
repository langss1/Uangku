import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/auth/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // Once successful, navigate directly back to Login Screen
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const LoginScreen(),
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        automaticallyImplyLeading: false, // Don't want them to go back from here easily
        title: const Text(
          'Create New Password',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  child: const Icon(Icons.shield_outlined, size: 40, color: Color(0xFF0066CC)),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Set New Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your new password must be different\nfrom previous used passwords.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.5),
              ),
              const SizedBox(height: 40),
              
              _buildInputLabel('NEW PASSWORD'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••',
                isPassword: true,
              ),
              const SizedBox(height: 12),
              _buildPasswordStrength(),
              
              const SizedBox(height: 24),
              _buildInputLabel('CONFIRM NEW PASSWORD'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPassController,
                hintText: '••••••••',
                isPassword: true,
              ),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF0066CC), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF78B5F6), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Strength: Better than average',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0066CC)),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.2));
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
