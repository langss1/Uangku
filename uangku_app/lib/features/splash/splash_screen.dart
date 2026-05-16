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
            final floatY = math.sin(_floatingAnimation.value * math.pi * 2) * 15;
            final floatX = math.cos(_floatingAnimation.value * math.pi * 2) * 10;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Abstract Orbs Animation - Moved to Background Layer
                ...List.generate(6, (index) {
                  final random = math.Random(index + 100);
                  final speed = 0.3 + random.nextDouble() * 0.4;
                  final size = 60.0 + random.nextDouble() * 100;
                  
                  return AnimatedBuilder(
                    animation: _continuousController,
                    builder: (context, child) {
                      // Gerakan abstrak yang lebih luas di latar belakang
                      final angle = _continuousController.value * math.pi * 2 * speed;
                      final radiusX = MediaQuery.of(context).size.width * 0.4;
                      final radiusY = MediaQuery.of(context).size.height * 0.4;
                      
                      final x = math.cos(angle + index) * radiusX;
                      final y = math.sin(angle * 0.5 + index) * radiusY;
                      
                      return Positioned(
                        left: MediaQuery.of(context).size.width / 2 + x - (size / 2),
                        top: MediaQuery.of(context).size.height / 2 + y - (size / 2),
                        child: Transform.scale(
                          scale: _polarScaleAnimation.value,
                          child: Opacity(
                            opacity: 0.08,
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primaryBlue.withOpacity(0.5),
                                    AppColors.primaryBlue.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Background decorative circles (Polar Static)
                Positioned(
                  top: -100 + floatY,
                  right: -100 + floatX,
                  child: Transform.scale(
                    scale: _polarScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _polarRotateAnimation.value + (_floatingAnimation.value * 0.1),
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.12),
                              AppColors.primaryBlue.withOpacity(0.01),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80 - floatY,
                  left: -80 - floatX,
                  child: Transform.scale(
                    scale: _polarScaleAnimation.value,
                    child: Transform.rotate(
                      angle: -_polarRotateAnimation.value - (_floatingAnimation.value * 0.15),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.1),
                              AppColors.primaryBlue.withOpacity(0.01),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Logo and content (Now above the background animations)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/images/Logo SplashScreen.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            "Kelola Keuangan Jadi Lebih Mudah",
                            style: TextStyle(
                              color: AppColors.textDark.withOpacity(0.6),
                              fontSize: 15,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Version text at bottom
                Positioned(
                  bottom: 50,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
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
