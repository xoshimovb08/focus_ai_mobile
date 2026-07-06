import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/settings/settings_bloc.dart';
import '../utils/lang_extension.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  String _getCurrentLangCode(SettingsState state, BuildContext context) {
    // SettingsState ichidan uning o'zgaruvchisi (masalan state.locale.languageCode) orqali olish tavsiya etiladi.
    // Agar u bo'lmasa, state obyektining xususiyatlarini tekshiramiz:
    final stateStr = state.toString().toLowerCase();

    if (stateStr.contains('uz') || stateStr.contains('uzbek')) {
      return 'uz';
    } else if (stateStr.contains('en') || stateStr.contains('english')) {
      return 'en';
    } else if (stateStr.contains('ru') || stateStr.contains('russian')) {
      return 'ru';
    }

    // Agar state ichidan topilmasa, context orqali olingan joriy lokalizatsiyani tekshiramiz
    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      if (localeCode == 'uz' || localeCode == 'en' || localeCode == 'ru') {
        return localeCode;
      }
    } catch (_) {}

    return 'uz'; // Standart til sifatida oʻzbek tilini belgilaymiz
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Til kodini aniqlash mantiqi yaxshilandi
        final currentLang = _getCurrentLangCode(settingsState, context);

        // 🌐 Lottie va matnlar integratsiyasi
        final List<Map<String, dynamic>> slides = [
          {
            'title': context.tr('Vaqtni Aniq Moʻljallang',
                'Target Your Goals Precisely', 'Цельтесь точно в цель'),
            'desc': context.tr(
                'Maqsadlaringiz sari harakatni yangi bosqichga olib chiqing! Biz sizga shunchaki vazifalar roʻyxatini bermaymiz, Focus AI sizning odatingizga ajratgan har bir qimmatli soniyangizni intellektual tarzda muhrlab boradi.',
                'Take the action towards your goals to the next level! We don\'t just give you a to-do list, Focus AI intellectually seals every precious second you dedicate to your habit.',
                'Поднимите движение к своим целям на новый уровень! Мы не просто даем вам список задач, Focus AI интеллектуально фиксирует каждую драгоценную секунду, которую вы посвящаете своей привычке.'),
            'lottieUrl': 'assets/animations/target.json',
            'gradient': [const Color(0xFF00F2FE), const Color(0xFF4FACFE)],
          },
          {
            'title': context.tr('Zinalar (Streaks)', 'Streaks Progression',
                'Лестница достижений'),
            'desc': context.tr(
                'Har kuni kirib odatlaringizni bajaring, zinalardan ko\'tariling! 5 kun kirmasangiz zinalaringiz nolga tushadi, ehtiyot bo\'ling!',
                'Log in every day, complete your habits, and climb the streaks! Be careful, if you don\'t visit for 5 days, your streaks reset to zero!',
                'Заходите каждый день, выполняйте привычки и поднимайтесь по лестнице! Будьте осторожны, если вы не зайдете 5 дней, ваш прогресс обнулится!'),
            'lottieUrl': 'assets/animations/zina.json',
            'gradient': [const Color(0xFFFF512F), const Color(0xDDDD2476)],
          },
          {
            'title': context.tr('Telefonni Yuztuban Yotqizing',
                'Place Phone Face Down', 'Положите телефон экраном вниз'),
            'desc': context.tr(
                'Sessiya davomida chuqur fokuslanish uchun telefoningizni teskari yuztuban qo\'ying va har yarim soat uchun qo\'shimcha 5 ball yuting!',
                'For deep focus during a session, place your phone face down and win an extra 5 points for every half hour!',
                'Для глубокого фокуса во время сессии положите телефон экраном вниз и получайте дополнительные 5 баллов за каждые полчаса!'),
            'lottieUrl': 'assets/animations/yuztuban.json',
            'gradient': [const Color(0xFFB5FFFC), const Color(0xFFFFDEE9)],
          },
          {
            'title': context.tr('Shaxsiy AI Murabbiy', 'Personal AI Coach',
                'Личный AI Наставник'),
            'desc': context.tr(
                'Siz shakllantirayotgan odatlar bo\'yicha Fokus AI Murabbiyi sizni tahlil qiladi, aqlli maslahatlar va doimiy motivatsiya beradi.',
                'Focus AI Coach analyzes your building habits, provides smart insights, and keeps you constantly motivated.',
                'AI Наставник анализирует ваши привычки, дает умные советы и поддерживает вашу мотивацию на высоком уровне.'),
            'lottieUrl': 'assets/animations/ai_murabiy.json',
            'gradient': [const Color(0xFF00FF87), const Color(0xFF60EFFF)],
          },
          {
            'title': context.tr(
                'Chuqur Analitika', 'Deep Analytics', 'Глубокая Аналитика'),
            'desc': context.tr(
                'Odatlaringiz va fokuslangan vaqtlaringiz jadvalini vizual tahlillar orqali kuzating. O\'z intizomingizni yangi bosqichga olib chiqing.',
                'Track your habits and focused hours with dynamic charts. Elevate your self-discipline to the next tier.',
                'Отслеживайте графики привычек и времени фокусировки. Поднимите свою самодисциплину на совершенно новый уровень.'),
            'lottieUrl': 'assets/animations/status.json',
            'gradient': [const Color(0xFFF355BE), const Color(0xFF5B06E3)],
          }
        ];

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.background : theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    context.read<SettingsBloc>().add(ToggleThemeEvent());
                  },
                ),
                const SizedBox(width: 4),
                DropdownButton<String>(
                  value: currentLang,
                  dropdownColor: isDark ? AppColors.cardBg : theme.cardColor,
                  icon: const Icon(Icons.language,
                      color: AppColors.primary, size: 20),
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMain
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'uz', child: Text(" UZ")),
                    DropdownMenuItem(value: 'en', child: Text(" EN")),
                    DropdownMenuItem(value: 'ru', child: Text(" RU")),
                  ],
                  onChanged: (String? newLang) {
                    if (newLang != null) {
                      context
                          .read<SettingsBloc>()
                          .add(ChangeLanguageEvent(newLang));
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _finishOnboarding,
                style:
                    TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                child: Text(
                  context.tr('O\'tkazib yuborish', 'Skip', 'Пропустить'),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemCount: slides.length,
                    itemBuilder: (context, idx) {
                      final slide = slides[idx];
                      final List<Color> textGradient = slide['gradient'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.35,
                              child: Lottie.asset(
                                slide['lottieUrl'],
                                fit: BoxFit.contain,
                                animate: _currentIndex == idx,
                              ),
                            ),
                            const SizedBox(height: 35),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: textGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                slide['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                .animate(key: ValueKey(idx))
                                .animate() // To'g'rilangan animatsiya zanjiri
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 18),
                            Text(
                              slide['desc'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.textMuted
                                    : theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.7),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 26 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: _currentIndex == index
                            ? LinearGradient(colors: slides[index]['gradient'])
                            : null,
                        color: _currentIndex == index
                            ? null
                            : (isDark
                                ? const Color(0xFF1E2235)
                                : theme.dividerColor.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (_currentIndex == slides.length - 1) {
                          _finishOnboarding();
                        } else {
                          _pageController.nextPage(
                              duration: 400.ms, curve: Curves.fastOutSlowIn);
                        }
                      },
                      child: Text(
                        _currentIndex == slides.length - 1
                            ? context.tr('Focus Ai GA KIRISH 🚀',
                                'ENTER Focus Ai 🚀', 'ВОЙТИ В Focus Ai 🚀')
                            : context.tr('KEYINGISI ➔', 'NEXT ➔', 'ДАЛЕЕ ➔'),
                        style: const TextStyle(
                          color: AppColors.background,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// RespondsToLocale tekshiruvi uchun extension
extension on SettingsState {
  bool get respondsToLocale {
    try {
      // Agar state obyektida locale yoki languageCode nomli property bo'lsa tekshiramiz
      return (this as dynamic).locale != null ||
          (this as dynamic).languageCode != null;
    } catch (_) {
      return false;
    }
  }
}
