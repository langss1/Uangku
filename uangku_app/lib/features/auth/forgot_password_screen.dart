import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/auth/otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendRecoveryLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Simulate sending email
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    // Navigate to OTP Screen
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const OtpScreen(),
        ),
      ),
    );
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // extremely light blue
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_reset_outlined,
                    size: 40,
                    color: Color(0xFF0066CC),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Forgot your password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                "Enter your registered email address\nand we'll send you a link to reset\nyour password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Form Email
              const Text(
                'EMAIL ADDRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF94A3B8), size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    errorText: _errorMessage,
                  ),
                  onChanged: (val) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Send Button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendRecoveryLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 22, 
                        height: 22, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Send Recovery Link',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_outlined, size: 20),
                        ],
                      ),
              ),
              
              const SizedBox(height: 48),
              
              // Back to Login
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.chevron_left, color: Color(0xFF0066CC), size: 20),
                      Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color(0xFF0066CC),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Footer Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Need help?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.5,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(text: 'If you no longer have access to this email, please contact our '),
                          TextSpan(
                            text: 'Security Support',
                            style: TextStyle(
                              color: Color(0xFF0066CC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' team for identity verification.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
