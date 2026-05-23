import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/auth/login_screen.dart';
import 'package:uangku_app/features/home/home_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  bool _isLoading = false;
  int _passwordStrength = 0; // 0: None, 1: Weak, 2: Fair, 3: Strong

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;

    if (password.isNotEmpty) {
      if (password.length >= 8) strength++;
      if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) strength++;
      if (password.contains(RegExp(r'[0-9]')) || password.contains(RegExp(r'[!@#\$&*~]'))) strength++;
    }

    if (strength != _passwordStrength) {
      setState(() {
        _passwordStrength = strength;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _animController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPassController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      CustomPopup.show(context, 'Please fill all fields', isSuccess: false);
      return;
    }

    if (_passwordStrength < 3) {
      CustomPopup.show(context, 'Please use a stronger password (min. 8 chars, letters, & numbers)', isSuccess: false);
      return;
    }

    if (password != confirmPassword) {
      CustomPopup.show(context, 'Passwords do not match', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        // API Url targeting the VPS
        Uri.parse('http://145.79.10.157:8000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Registration success, navigate to Login
        CustomPopup.show(context, 'Registration successful! Please login.', isSuccess: true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Registration failed';
        CustomPopup.show(context, errorMsg, isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(context, 'Error connecting to server: $e', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const LoginScreen(),
                ),
              ),
            );
          },
        ),
        title: const Text(
          'Register Uangku',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8EFFF), // Slightly blue
              Color(0xFFF5F8FF),
              Colors.white,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false, // Let the bottom sheet go all the way down
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.08, // Dynamic big top margin to push it down like Login
                        bottom: 36, // Increased spacing before the white form container
                        left: 24, 
                        right: 24
                      ),
                      child: Column(
                        children: [

                          // Header Illustration with premium shadow
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066CC).withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/regis.png',
                                width: double.infinity,
                                fit: BoxFit.contain, // Changed from cover to contain/fitWidth to prevent cropping
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Spacing before subtitle
                          const Text(
                            'Join the future of wealth management.\nStart your smart financial journey with us today.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14, // Compact font
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Form Container (Spans full width)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), // Tighter padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32), // Match login 32
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 20), // Tighter spacing
                          
                          _buildInputLabel('FULL NAME'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _fullNameController,
                            hintText: 'John Doe',
                          ),
                          const SizedBox(height: 16), // Tighter spacing
                          
                          _buildInputLabel('EMAIL ADDRESS'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'john@example.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16), // Tighter spacing
                          
                          _buildInputLabel('PASSWORD'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: '••••••••',
                            isPassword: true,
                          ),
                          
                          // Password strength indicator
                          const SizedBox(height: 10),
                          _buildPasswordStrength(),
                          
                          const SizedBox(height: 16), // Tighter spacing
                          
                          _buildInputLabel('CONFIRM PASSWORD'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _confirmPassController,
                            hintText: '••••••••',
                            isPassword: true,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16), // Softer button
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading 
                                ? const SizedBox(
                                    width: 22, 
                                    height: 22, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          
                          const Spacer(),
                          const SizedBox(height: 32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 600),
                                      pageBuilder: (_, animation, __) => FadeTransition(
                                        opacity: animation,
                                        child: const LoginScreen(),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Color(0xFF0066CC),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    Color color1 = const Color(0xFFE2E8F0);
    Color color2 = const Color(0xFFE2E8F0);
    Color color3 = const Color(0xFFE2E8F0);
    String label = 'Strength: Weak';
    Color labelColor = const Color(0xFF94A3B8);

    if (_passwordStrength >= 1) {
      color1 = const Color(0xFFEF4444); // Red
      label = 'Strength: Weak';
      labelColor = color1;
    }
    if (_passwordStrength >= 2) {
      color1 = const Color(0xFFEAB308); // Yellow
      color2 = color1;
      label = 'Strength: Fair';
      labelColor = color1;
    }
    if (_passwordStrength >= 3) {
      color1 = const Color(0xFF22C55E); // Green
      color2 = color1;
      color3 = color1;
      label = 'Strength: Strong';
      labelColor = color1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: color1,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: color2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: color3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _passwordController.text.isEmpty ? 'Strength: None' : label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _passwordController.text.isEmpty ? const Color(0xFF94A3B8) : labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Soft gray/blue Fill per design
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
