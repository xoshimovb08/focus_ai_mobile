import 'package:equatable/equatable.dart';
import '../../../domain/entities/habit.dart';

class HabitState extends Equatable {
  final List<Habit>
      habits; // 🚀 TO'G'RILANDI: dynamic o'rniga aniq Habit modeli qo'yildi
  final int totalScore;
  final int currentStreak;
  final bool isFaceDown;
  final int lastTickMs;
  final int weeklyTargetMinutes; // Kelishuv maqsadi (daqiqa)
  final int weeklyProgressMinutes; // Shu haftalik bajarilgan umumiy daqiqa
  final bool isAgreementActive; // Kelishuv faolmi?
  final String lastSuccessMessage;

  const HabitState({
    this.habits = const [],
    this.totalScore = 0,
    this.currentStreak = 0,
    this.isFaceDown = false,
    this.lastTickMs = 0,
    this.weeklyTargetMinutes = 0,
    this.weeklyProgressMinutes = 0,
    this.isAgreementActive = false,
    this.lastSuccessMessage = '',
  });

  HabitState copyWith({
    List<Habit>? habits,
    int? totalScore,
    int? currentStreak,
    bool? isFaceDown,
    int? lastTickMs,
    int? weeklyTargetMinutes,
    int? weeklyProgressMinutes,
    bool? isAgreementActive,
    String? lastSuccessMessage,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      totalScore: totalScore ?? this.totalScore,
      currentStreak: currentStreak ?? this.currentStreak,
      isFaceDown: isFaceDown ?? this.isFaceDown,
      lastTickMs: lastTickMs ?? this.lastTickMs,
      weeklyTargetMinutes: weeklyTargetMinutes ?? this.weeklyTargetMinutes,
      weeklyProgressMinutes:
          weeklyProgressMinutes ?? this.weeklyProgressMinutes,
      isAgreementActive: isAgreementActive ?? this.isAgreementActive,
      lastSuccessMessage: lastSuccessMessage ?? this.lastSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [
        habits,
        totalScore,
        currentStreak,
        isFaceDown,
        lastTickMs,
        weeklyTargetMinutes,
        weeklyProgressMinutes,
        isAgreementActive,
        lastSuccessMessage,
      ];
}
