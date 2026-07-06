import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_ai/core/constants/app_colors.dart';
import 'package:focus_ai/presentation/screens/onboarding_screen.dart';
import 'package:focus_ai/presentation/screens/auth_screen.dart';
import 'package:focus_ai/presentation/screens/main_navigation_hub.dart';
import 'package:focus_ai/data/datasources/user_stats_datasource.dart';
import 'package:focus_ai/services/service_locator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scannerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    final stopwatch = Stopwatch()..start();

    // 🔌 Service Locator orqali markaziy ma'lumotlar manbasini olamiz
    final userStatsDataSource = sl<UserStatsDataSource>();
    final prefs = userStatsDataSource.sharedPreferences;

    // Tizimga birinchi marta kirish yoki akkaunt holatini tekshirish
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    // Yangi arxitekturaga mos ravishda joriy foydalanuvchi ID sini aniqlaymiz
    final String currentUid = prefs.getString('current_user_id') ?? 'guest';

    // Agar foydalanuvchi tizimga kirgan bo'lsa (guest emas va bo'sh bo'lmasa) yoki aniq Mehmon bo'lsa
    final bool hasActiveSession =
        currentUid != 'guest' && currentUid.isNotEmpty;
    final bool isGuestMode = prefs.getBool('is_guest') ?? false;

    stopwatch.stop();

    // Splash ekran animatsiyasi chiroyli ko'rinishi uchun minimal kechikish vaqti (2.5 soniya)
    final remainingTime = 2500 - stopwatch.elapsedMilliseconds;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }
    if (!mounted) return;

    Widget nextScreen;
    if (hasActiveSession || isGuestMode) {
      nextScreen = const MainNavigationHub();
    } else if (isFirstTime) {
      nextScreen = const OnboardingScreen();
    } else {
      nextScreen = const AuthScreen();
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 85,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        top: 65 + (_scanAnimation.value * 50),
                        child: Container(
                          width: 90,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary,
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'FOCUS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' AI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withOpacity(0.6),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: (0.4 + (_scanAnimation.value.abs() * 0.6))
                        .clamp(0.0, 1.0),
                    child: const Text(
                      'TIZIM KODLARI SKANERLANMOQDA...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
