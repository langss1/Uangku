import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/auth/reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool _isLoading = false;
  final int _otpLength = 4;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _otpLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    
    // Auto verify if all filled
    bool allFilled = _controllers.every((c) => c.text.isNotEmpty);
    if (allFilled && index == _otpLength - 1) {
      FocusScope.of(context).unfocus();
      _verifyOTP();
    }
  }

  void _verifyOTP() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const ResetPasswordScreen(),
        ),
      ),
    );
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
          'Email Verification',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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
                    color: const Color(0xFFEFF6FF), // extremely light blue
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: Color(0xFF0066CC),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter Recovery Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: "We've sent a 4-digit code to your email.\nPlease check your inbox."),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _otpLength,
                  (index) => SizedBox(
                    width: 60,
                    height: 65,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
                        ),
                      ),
                      onChanged: (val) => _onOtpChanged(val, index),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the email? ", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  GestureDetector(
                    onTap: () {}, // Resend logic
                    child: const Text("Click to resend", style: TextStyle(color: Color(0xFF0066CC), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
