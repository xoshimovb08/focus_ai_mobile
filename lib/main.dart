import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BLocs va Ekranlar
import 'package:focus_ai/presentation/blocs/habit/habit_bloc.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_state.dart';
import 'package:focus_ai/presentation/pages/splash/splash_page.dart'; // SplashPage import qilindi

// Servislar va DI
import 'package:focus_ai/core/services/notification_service.dart';
import 'package:focus_ai/data/datasources/habit_local_datasource.dart';
import 'package:focus_ai/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  // 🔌 GetIt orqali barcha dependency'larni ro'yxatdan o'tkazamiz
  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HabitBloc>(
          // ⚡ OPTIMALLASHTIRISH: Konkret obyekt emas, sl() orqali Interfeys chaqirildi
          create: (context) => HabitBloc(
            dataSource: sl<HabitLocalDataSource>(),
          )..add(LoadHabitsEvent()),
        ),
        BlocProvider<SettingsBloc>(
          // SettingsBloc ham SharedPreferences'ni sl dan oladi
          create: (context) => SettingsBloc(sl<SharedPreferences>()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        // ⚡ UX unumdorlik: Faqat til yoki mavzu o'zgargandagina MaterialApp qayta chiziladi
        buildWhen: (previous, current) =>
            previous.locale != current.locale ||
            previous.themeMode != current.themeMode,
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Focus AI',
            debugShowCheckedModeBanner: false,
            locale: settingsState.locale,
            themeMode: settingsState.themeMode,

            // Light Theme sozlamalari
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              cardColor: Colors.white,
              primaryColor: const Color(0xFF00AA88),
              dialogBackgroundColor: Colors.white,
              textTheme: ThemeData.light().textTheme.copyWith(
                    bodyLarge: const TextStyle(color: Colors.black87),
                  ),
            ),

            // Dark Theme sozlamalari
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF09090E),
              cardColor: const Color(0xFF13131A),
              primaryColor: const Color(0xFF00FFCC),
              dialogBackgroundColor: const Color(0xFF1E293B),
              textTheme: ThemeData.dark().textTheme.copyWith(
                    bodyLarge: const TextStyle(color: Colors.white),
                  ),
            ),

            // Splash har doim birinchi ochiladi va barcha yo'naltirishlarni ichida hal qiladi
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
