import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class ToggleThemeEvent extends SettingsEvent {
  const ToggleThemeEvent();
}

class ChangeLanguageEvent extends SettingsEvent {
  final String langCode;

  const ChangeLanguageEvent(this.langCode);

  @override
  List<Object?> get props => [langCode];
}

// 📱 Asosiy ekran vidjetini yoqish/o'chirish eventi
class ToggleWidgetEvent extends SettingsEvent {
  final bool isEnabled;

  const ToggleWidgetEvent(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

// ⏳ Kunlik fokus limitini o'zgartirish eventi
class UpdateDailyGoalHoursEvent extends SettingsEvent {
  final double hours;

  const UpdateDailyGoalHoursEvent(this.hours);

  @override
  List<Object?> get props => [hours];
}

// 🤖 AI murabbiy ohangini o'zgartirish eventi
class UpdateCoachToneEvent extends SettingsEvent {
  final String tone;

  const UpdateCoachToneEvent(this.tone);

  @override
  List<Object?> get props => [tone];
}

// 🔊 Ovozli tavsiyalarni (TTS) yoqish/o'chirish eventi
class ToggleTtsEvent extends SettingsEvent {
  final bool isEnabled;

  const ToggleTtsEvent(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}
