import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/features/auth/login_screen.dart';
import 'package:uangku_app/features/home/home_screen.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'package:uangku_app/core/services/biometric_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _continuousController;
  bool _showAuthRetryScreen = false;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _polarScaleAnimation;
  late Animation<double> _polarRotateAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _continuousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _polarScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _polarRotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _continuousController, curve: Curves.linear),
    );

    _animationController.forward();

    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    // Wait for 4 seconds in total as requested by the user
    await Future.delayed(const Duration(seconds: 4));
    
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedInPref = prefs.getBool('isLoggedIn') ?? false;

    bool isLoggedIn = false;
    if (isLoggedInPref) {
      try {
        final token = await SecureStorageHelper.getToken();
        final email = prefs.getString('user_email');
        if (token != null && token.isNotEmpty && email != null && email.isNotEmpty) {
          isLoggedIn = true;
        } else {
          debugPrint("⚠️ Secure session invalid or empty. Forcing clean logout...");
          await prefs.setBool('isLoggedIn', false);
          await prefs.remove('profile_image_path');
          await prefs.remove('user_name');
          await prefs.remove('user_email');
          await SecureStorageHelper.clearAll();
        }
      } catch (e) {
        debugPrint("⚠️ Secure storage failed on startup: $e. Forcing clean logout...");
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('profile_image_path');
        await prefs.remove('user_name');
        await prefs.remove('user_email');
        await SecureStorageHelper.clearAll();
      }
    }
    if (!context.mounted) return;

    if (isLoggedIn) {
      final isLockEnabled = await BiometricService.isAppLockEnabled();
      if (isLockEnabled) {
        final authenticated = await BiometricService.authenticate();
        if (authenticated) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          setState(() {
            _showAuthRetryScreen = true;
          });
        }
      } else {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const LoginScreen(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _continuousController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              AppColors.background.withOpacity(0.5),
              AppColors.background,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_animationController, _continuousController]),
          builder: (context, child) {
            if (_showAuthRetryScreen) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 72,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Uangku Terkunci",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "Silakan verifikasi sidik jari atau PIN Anda untuk masuk ke aplikasi.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final authenticated = await BiometricService.authenticate();
                        if (authenticated) {
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.fingerprint, color: Colors.white),
                      label: const Text(
                        "Verifikasi & Masuk",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              );
            }

            final floatY = math.sin(_floatingAnimation.value * math.pi * 2) * 12;
            final floatX = math.cos(_floatingAnimation.value * math.pi * 2) * 8;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Abstract Orbs Animation - Unified and simplified for modern minimalism
                ...List.generate(4, (index) {
                  final random = math.Random(index + 200);
                  final size = 80.0 + random.nextDouble() * 80;
                  
                  double leftOffset = 0;
                  double topOffset = 0;
                  if (index == 0) {
                    leftOffset = -30;
                    topOffset = 150;
                  } else if (index == 1) {
                    leftOffset = MediaQuery.of(context).size.width - 120;
                    topOffset = 250;
                  } else if (index == 2) {
                    leftOffset = 40;
                    topOffset = MediaQuery.of(context).size.height - 250;
                  } else {
                    leftOffset = MediaQuery.of(context).size.width - 150;
                    topOffset = MediaQuery.of(context).size.height - 180;
                  }

                  // Float opposite to foreground for subtle premium parallax
                  final orbFloatX = -floatX * (0.4 + index * 0.15);
                  final orbFloatY = -floatY * (0.4 + index * 0.15);

                  return Positioned(
                    left: leftOffset,
                    top: topOffset,
                    child: Transform.translate(
                      offset: Offset(orbFloatX, orbFloatY),
                      child: Transform.scale(
                        scale: _polarScaleAnimation.value,
                        child: Opacity(
                          opacity: 0.06,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primaryBlue.withOpacity(0.4),
                                  AppColors.primaryBlue.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Background decorative circles
                Positioned(
                  top: -100,
                  right: -100,
                  child: Transform.translate(
                    offset: Offset(-floatX * 0.6, -floatY * 0.6),
                    child: Transform.scale(
                      scale: _polarScaleAnimation.value,
                      child: Transform.rotate(
                        angle: _polarRotateAnimation.value + (_floatingAnimation.value * 0.05),
                        child: Container(
                          width: 350,
                          height: 350,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primaryBlue.withOpacity(0.10),
                                AppColors.primaryBlue.withOpacity(0.01),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Transform.translate(
                    offset: Offset(-floatX * 0.4, -floatY * 0.4),
                    child: Transform.scale(
                      scale: _polarScaleAnimation.value,
                      child: Transform.rotate(
                        angle: -_polarRotateAnimation.value - (_floatingAnimation.value * 0.08),
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primaryBlue.withOpacity(0.08),
                                AppColors.primaryBlue.withOpacity(0.01),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Logo and content (Now above the background animations)
                Transform.translate(
                  offset: Offset(floatX, floatY),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.12),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Image.asset(
                                'assets/images/Logo SplashScreen.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          "Uangku",
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          "Kelola Keuangan Jadi Lebih Mudah",
                          style: TextStyle(
                            color: AppColors.textDark.withOpacity(0.55),
                            fontSize: 15,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Version text at bottom
                Positioned(
                  bottom: 50,
                  child: Transform.translate(
                    offset: Offset(floatX * 0.5, floatY * 0.5),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "Version 1.0.0",
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    )
    );
  }
}
