import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;
  final bool isWidgetEnabled;
  final String coachTone;
  final double dailyFocusLimit;
  final bool isTtsEnabled;

  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.isWidgetEnabled,
    required this.coachTone,
    required this.dailyFocusLimit,
    required this.isTtsEnabled,
  });

  // 🔄 Faqat o'zgargan maydonni yangilab, qolganlarini saqlab qolish uchun
  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isWidgetEnabled,
    String? coachTone,
    double? dailyFocusLimit,
    bool? isTtsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isWidgetEnabled: isWidgetEnabled ?? this.isWidgetEnabled,
      coachTone: coachTone ?? this.coachTone,
      dailyFocusLimit: dailyFocusLimit ?? this.dailyFocusLimit,
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
    );
  }

  // 📊 BLoC ob'ektlarni xotirada oson solishtirishi uchun
  @override
  List<Object?> get props => [
        themeMode,
        locale,
        isWidgetEnabled,
        coachTone,
        dailyFocusLimit,
        isTtsEnabled,
      ];
}
