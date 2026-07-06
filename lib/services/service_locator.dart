import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data Sources (To'g'ri package importlari bilan)
import 'package:focus_ai/data/datasources/habit_local_datasource.dart';
import 'package:focus_ai/data/datasources/user_stats_datasource.dart';

// Servislar
import 'package:focus_ai/core/services/audio_haptic_service.dart';
import 'package:focus_ai/core/services/gemini_ai_service.dart';

// BloC'lar
import 'package:focus_ai/presentation/blocs/habit/habit_bloc.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ========================================================
  // 🔌 TIZIMLI DRAYVERLAR (External Dependencies)
  // ========================================================
  final sharedPreferences = await SharedPreferences.getInstance();

  // ⚡ OPTIMALLASHTIRISH: SharedPreferences instansi ilova ishga tushganda unikal bo'ladi
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerSingleton<SharedPreferences>(sharedPreferences);
  }

  // ========================================================
  // 📦 DATA SOURCES (Multi-Account & Kesh boshqaruvi)
  // ========================================================
  // UserStatsDataSource birinchi ro'yxatdan o'tishi kerak
  if (!sl.isRegistered<UserStatsDataSource>()) {
    sl.registerLazySingleton<UserStatsDataSource>(
      () => UserStatsDataSource(sl<SharedPreferences>()),
    );
  }

  if (!sl.isRegistered<HabitLocalDataSource>()) {
    sl.registerLazySingleton<HabitLocalDataSource>(
      () => HabitLocalDataSource(sl<SharedPreferences>()),
    );
  }

  // ========================================================
  // ⚙️ SERVISLAR (Global Services)
  // ========================================================
  if (!sl.isRegistered<AudioHapticService>()) {
    sl.registerLazySingleton(() => AudioHapticService());
  }

  if (!sl.isRegistered<GeminiAiService>()) {
    sl.registerLazySingleton(() => GeminiAiService());
  }

  // ========================================================
  // 🧠 BLOC'LAR INTEGRATSIYASI (State Management Injection)
  // ========================================================
  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory(() => SettingsBloc(sl<SharedPreferences>()));
  }

  if (!sl.isRegistered<HabitBloc>()) {
    sl.registerFactory(() => HabitBloc(
          dataSource: sl<HabitLocalDataSource>(),
        ));
  }
}
