import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_ai/core/services/widget_service.dart'; // WidgetService import qilindi

import 'settings_event.dart';
import 'settings_state.dart';

export 'settings_event.dart';
export 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPreferences prefs;

  // Kesh kalitlari (SharedPreferences keys)
  static const String _themeKey = 'APP_THEME_MODE';
  static const String _langKey = 'APP_LANGUAGE';
  static const String _widgetKey = 'APP_WIDGET_ENABLED';
  static const String _toneKey = 'APP_COACH_TONE';
  static const String _focusLimitKey = 'APP_DAILY_FOCUS_LIMIT';
  static const String _ttsKey = 'APP_TTS_ENABLED';

  SettingsBloc(this.prefs)
      : super(
          SettingsState(
            themeMode: (prefs.getString(_themeKey) ?? 'dark') == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: Locale(prefs.getString(_langKey) ?? 'uz'),
            isWidgetEnabled: prefs.getBool(_widgetKey) ?? false,
            coachTone: prefs.getString(_toneKey) ?? 'Do\'stona',
            dailyFocusLimit: prefs.getDouble(_focusLimitKey) ?? 2.0,
            isTtsEnabled: prefs.getBool(_ttsKey) ?? true,
          ),
        ) {
    // 1. Mavzuni o'zgartirish oqimi
    on<ToggleThemeEvent>((event, emit) async {
      final isDark = state.themeMode == ThemeMode.dark;
      final nextTheme = isDark ? ThemeMode.light : ThemeMode.dark;

      await prefs.setString(_themeKey, isDark ? 'light' : 'dark');
      emit(state.copyWith(themeMode: nextTheme));
    });

    // 2. Tilni o'zgartirish oqimi
    on<ChangeLanguageEvent>((event, emit) async {
      await prefs.setString(_langKey, event.langCode);
      emit(state.copyWith(locale: Locale(event.langCode)));
    });

    // 3. Asosiy ekran vidjetini boshqarish oqimi
    on<ToggleWidgetEvent>((event, emit) async {
      // Tashqi xizmatni chaqiramiz va undan qaytgan haqiqiy holatni olamiz
      bool result = await WidgetService.toggleWidget(event.isEnabled);

      await prefs.setBool(_widgetKey, result);
      emit(state.copyWith(isWidgetEnabled: result));
    });

    // 4. Kunlik fokus limitini o'zgartirish oqimi
    on<UpdateDailyGoalHoursEvent>((event, emit) async {
      await prefs.setDouble(_focusLimitKey, event.hours);
      emit(state.copyWith(dailyFocusLimit: event.hours));
    });

    // 5. AI murabbiy ohangini o'zgartirish oqimi
    on<UpdateCoachToneEvent>((event, emit) async {
      await prefs.setString(_toneKey, event.tone);
      emit(state.copyWith(coachTone: event.tone));
    });

    // 6. Ovozli tavsiyalar (TTS) oqimi
    on<ToggleTtsEvent>((event, emit) async {
      await prefs.setBool(_ttsKey, event.isEnabled);
      emit(state.copyWith(isTtsEnabled: event.isEnabled));
    });
  }
}
