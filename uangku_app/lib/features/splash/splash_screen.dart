import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/features/auth/login_screen.dart';
import 'package:uangku_app/features/home/home_screen.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _continuousController;
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
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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
    return Scaffold(
      backgroundColor: Colors.white,
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
    );
  }
}
