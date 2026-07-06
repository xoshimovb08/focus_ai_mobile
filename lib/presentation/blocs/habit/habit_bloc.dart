import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart'; // Hodisalar va holatlarni taqqoslashni optimallashtirish uchun
import 'package:uuid/uuid.dart';
import '../../../domain/entities/habit.dart';
import '../../../data/datasources/habit_local_datasource.dart';
import '../../../core/services/audio_haptic_service.dart';
import '../../../core/services/notification_service.dart';

// ==========================================
// --- HODISALAR (EVENTS) ---
// ==========================================
abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object?> get props => [];
}

class LoadHabitsEvent extends HabitEvent {}

class DeleteHabitEvent extends HabitEvent {
  final String id;

  const DeleteHabitEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CompleteWeeklyAgreementEvent extends HabitEvent {}

class AddHabitEvent extends HabitEvent {
  final String title;
  final int minutes;
  final String icon;
  final String? imagePath;

  const AddHabitEvent({
    required this.title,
    required this.minutes,
    required this.icon,
    this.imagePath,
  });

  @override
  List<Object?> get props => [title, minutes, icon, imagePath];
}

class EditHabitEvent extends HabitEvent {
  final String id;
  final String title;
  final int minutes;
  final String icon;
  final String? imagePath;

  const EditHabitEvent({
    required this.id,
    required this.title,
    required this.minutes,
    required this.icon,
    this.imagePath,
  });

  @override
  List<Object?> get props => [id, title, minutes, icon, imagePath];
}

class StartHabitEvent extends HabitEvent {
  final String id;
  const StartHabitEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class PauseHabitEvent extends HabitEvent {
  final String id;
  const PauseHabitEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class CompleteHabitEvent extends HabitEvent {
  final String id;
  const CompleteHabitEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ResetHabitEvent extends HabitEvent {
  final String id;
  const ResetHabitEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateTimerTickEvent extends HabitEvent {
  final int nowMs;
  const UpdateTimerTickEvent(this.nowMs);

  @override
  List<Object?> get props => [nowMs];
}

class DeviceOrientationChangedEvent extends HabitEvent {
  final bool isFaceDown;
  const DeviceOrientationChangedEvent(this.isFaceDown);

  @override
  List<Object?> get props => [isFaceDown];
}

class BuySafetyDayEvent extends HabitEvent {}

class StartWeeklyAgreementEvent extends HabitEvent {
  final int targetMinutes;
  const StartWeeklyAgreementEvent(this.targetMinutes);

  @override
  List<Object?> get props => [targetMinutes];
}

class GiveUpAgreementEvent extends HabitEvent {}

// ==========================================
// --- HOLATLAR (STATES) ---
// ==========================================
class HabitState extends Equatable {
  final List<Habit> habits;
  final int totalScore;
  final int currentStreak;
  final bool isFaceDown;
  final int lastTickMs;
  final int weeklyTargetMinutes;
  final int weeklyProgressMinutes;
  final bool isAgreementActive;
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

// ==========================================
// --- BLOC AMALIYOTI ---
// ==========================================
class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final HabitLocalDataSource dataSource;
  Timer? _tickerTimer;
  int _faceDownSecondsCounter = 0;

  String get _currentUid =>
      dataSource.prefs.getString('current_user_id') ?? 'guest';

  HabitBloc({required this.dataSource}) : super(const HabitState()) {
    on<LoadHabitsEvent>(_onLoadHabits);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<AddHabitEvent>(_onAddHabit);
    on<EditHabitEvent>(_onEditHabit);
    on<StartHabitEvent>(_onStartHabit);
    on<PauseHabitEvent>(_onPauseHabit);
    on<CompleteHabitEvent>(_onCompleteHabit);
    on<ResetHabitEvent>(_onResetHabit);
    on<UpdateTimerTickEvent>(_onUpdateTimerTick);
    on<DeviceOrientationChangedEvent>(_onDeviceOrientationChanged);
    on<BuySafetyDayEvent>(_onBuySafetyDay);
    on<StartWeeklyAgreementEvent>(_onStartWeeklyAgreement);
    on<GiveUpAgreementEvent>(_onGiveUpAgreement);

    _startInternalTicker();
  }

  void _startInternalTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isClosed) {
        add(UpdateTimerTickEvent(DateTime.now().millisecondsSinceEpoch));
      } else {
        timer
            .cancel(); // Blok yopilgan bo'lsa taymerni xotiradan butkul o'chirish
      }
    });
  }

  Future<void> _onDeleteHabit(
      DeleteHabitEvent event, Emitter<HabitState> emit) async {
    try {
      AudioHapticService.triggerLightImpact();

      final updated =
          state.habits.where((habit) => habit.id != event.id).toList();

      emit(state.copyWith(habits: updated));
      await dataSource.cacheHabits(updated);
    } catch (e) {
      print("O'chirishda xatolik yuz berdi: $e");
    }
  }

  Future<void> _onLoadHabits(
      LoadHabitsEvent event, Emitter<HabitState> emit) async {
    try {
      final cached = await dataSource.getHabits();
      final prefs = dataSource.prefs;
      final String uid = _currentUid;

      final score = prefs.getInt('${uid}_total_score') ?? 0;
      int streak = prefs.getInt('${uid}_current_streak') ?? 0;
      final int targetMins = prefs.getInt('${uid}_weekly_target_minutes') ?? 0;
      final int progressMins =
          prefs.getInt('${uid}_weekly_progress_minutes') ?? 0;
      final bool isAgreementActive =
          prefs.getBool('${uid}_is_agreement_active') ?? false;

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastLogin = prefs.getString('${uid}_last_login');

      if (lastLogin != null && lastLogin != todayStr) {
        try {
          final lastDate = DateTime.parse(lastLogin);
          final difference = DateTime.now().difference(lastDate).inDays;

          if (difference > 5) {
            streak = 0;
            prefs.setInt('${uid}_current_streak', 0);
          } else if (difference == 1) {
            streak += 1;
            prefs.setInt('${uid}_current_streak', streak);
          }
        } catch (_) {
          streak = 1;
          prefs.setInt('${uid}_current_streak', 1);
        }
      } else if (lastLogin == null) {
        streak = 1;
        prefs.setInt('${uid}_current_streak', 1);
      }

      prefs.setString('${uid}_last_login', todayStr);

      emit(state.copyWith(
        habits: cached,
        totalScore: score,
        currentStreak: streak,
        weeklyTargetMinutes: targetMins,
        weeklyProgressMinutes: progressMins,
        isAgreementActive: isAgreementActive,
      ));
    } catch (e) {
      emit(state.copyWith(habits: const [], totalScore: 0, currentStreak: 1));
    }
  }

  Future<void> _onAddHabit(
      AddHabitEvent event, Emitter<HabitState> emit) async {
    final newHabit = Habit(
      id: const Uuid().v4(),
      title: event.title,
      goalMinutes: event.minutes,
      iconName: event.icon,
      imagePath: event.imagePath,
      accumulatedMs: 0,
      isCompleted: false,
      status: HabitStatus.active,
    );

    final updated = List<Habit>.from(state.habits)..add(newHabit);
    emit(state.copyWith(habits: updated));
    await dataSource.cacheHabits(updated);
  }

  Future<void> _onEditHabit(
      EditHabitEvent event, Emitter<HabitState> emit) async {
    AudioHapticService.triggerLightImpact();

    final updated = state.habits.map((habit) {
      if (habit.id == event.id) {
        return habit.copyWith(
          title: event.title,
          goalMinutes: event.minutes,
          iconName: event.icon,
          imagePath: () => event.imagePath,
        );
      }
      return habit;
    }).toList();

    emit(state.copyWith(habits: updated));
    await dataSource.cacheHabits(updated);
  }

  Future<void> _onStartHabit(
      StartHabitEvent event, Emitter<HabitState> emit) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    AudioHapticService.triggerLightImpact();

    final updated = state.habits.map((habit) {
      if (habit.id == event.id && !habit.isCompleted) {
        return habit.copyWith(
          runningSince: () => now,
          status: HabitStatus.active,
        );
      }
      return habit;
    }).toList();

    emit(state.copyWith(habits: updated));
    await dataSource.cacheHabits(updated);
  }

  Future<void> _onPauseHabit(
      PauseHabitEvent event, Emitter<HabitState> emit) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    AudioHapticService.triggerLightImpact();

    final updated = state.habits.map((habit) {
      if (habit.id == event.id && habit.runningSince != null) {
        int elapsed = habit.accumulatedMs + (now - habit.runningSince!);
        return habit.copyWith(
          accumulatedMs: elapsed,
          runningSince: () => null,
          status: HabitStatus.paused,
        );
      }
      return habit;
    }).toList();

    emit(state.copyWith(habits: updated));
    await dataSource.cacheHabits(updated);
  }

  Future<void> _onCompleteHabit(
      CompleteHabitEvent event, Emitter<HabitState> emit) async {
    final prefs = dataSource.prefs;
    final String uid = _currentUid;
    int earnedScore = 0;
    int addedMinutes = 0;

    AudioHapticService.triggerSuccessImpact();

    final updated = state.habits.map((habit) {
      if (habit.id == event.id) {
        if (!habit.isCompleted) {
          earnedScore += 10;
          addedMinutes = habit.goalMinutes;
        }

        final String nowStr = DateTime.now().toString().substring(0, 16);
        final updatedHistory = List<String>.from(habit.completionHistory)
          ..add(nowStr);

        return habit.copyWith(
          isCompleted: true,
          runningSince: () => null,
          status: HabitStatus.paused,
          completionHistory: updatedHistory,
        );
      }
      return habit;
    }).toList();

    int newScore = state.totalScore + earnedScore;
    prefs.setInt('${uid}_total_score', newScore);

    int newProgress = state.weeklyProgressMinutes;
    int target = state.weeklyTargetMinutes;
    bool active = state.isAgreementActive;

    if (active && addedMinutes > 0) {
      newProgress += addedMinutes;
      prefs.setInt('${uid}_weekly_progress_minutes', newProgress);

      if (newProgress >= target && target > 0) {
        newScore += 50;
        prefs.setInt('${uid}_total_score', newScore);
        active = false;
        prefs.setBool('${uid}_is_agreement_active', false);
      }
    }

    emit(state.copyWith(
      habits: updated,
      totalScore: newScore,
      weeklyProgressMinutes: newProgress,
      isAgreementActive: active,
      lastSuccessMessage: NotificationService.getRandomSuccess(),
    ));

    await dataSource.cacheHabits(updated);
  }

  Future<void> _onResetHabit(
      ResetHabitEvent event, Emitter<HabitState> emit) async {
    AudioHapticService.triggerLightImpact();

    final updated = state.habits.map((habit) {
      if (habit.id == event.id) {
        return habit.copyWith(
          accumulatedMs: 0,
          runningSince: () => null,
          isCompleted: false,
          status: HabitStatus.restarted,
        );
      }
      return habit;
    }).toList();

    emit(state.copyWith(habits: updated));
    await dataSource.cacheHabits(updated);
  }

  Future<void> _onUpdateTimerTick(
      UpdateTimerTickEvent event, Emitter<HabitState> emit) async {
    final prefs = dataSource.prefs;
    final String uid = _currentUid;

    bool anyRunning = state.habits.any((h) => h.isRunning);
    if (anyRunning && state.isFaceDown) {
      _faceDownSecondsCounter++;
      if (_faceDownSecondsCounter >= 1800) {
        _faceDownSecondsCounter = 0;
        int updatedScore = state.totalScore + 5;
        prefs.setInt('${uid}_total_score', updatedScore);
        emit(state.copyWith(totalScore: updatedScore));
      }
    } else {
      _faceDownSecondsCounter = 0;
    }

    bool stateChanged = false;
    int addedMinutes = 0;

    final updated = state.habits.map((habit) {
      if (habit.isRunning && habit.getElapsedTime() >= habit.goalDurationMs) {
        stateChanged = true;
        addedMinutes += habit.goalMinutes;
        return habit.copyWith(
          accumulatedMs: habit.goalDurationMs,
          runningSince: () => null,
          isCompleted: true,
          status: HabitStatus.paused,
        );
      }
      return habit;
    }).toList();

    if (stateChanged) {
      AudioHapticService.triggerSuccessImpact();

      int bonus = 10;
      int newScore = state.totalScore + bonus;
      prefs.setInt('${uid}_total_score', newScore);

      int newProgress = state.weeklyProgressMinutes;
      int target = state.weeklyTargetMinutes;
      bool active = state.isAgreementActive;

      if (active && addedMinutes > 0) {
        newProgress += addedMinutes;
        prefs.setInt('${uid}_weekly_progress_minutes', newProgress);

        if (newProgress >= target && target > 0) {
          newScore += 50;
          prefs.setInt('${uid}_total_score', newScore);
          active = false;
          prefs.setBool('${uid}_is_agreement_active', false);
        }
      }

      emit(state.copyWith(
        habits: updated,
        totalScore: newScore,
        lastTickMs: event.nowMs,
        weeklyProgressMinutes: newProgress,
        isAgreementActive: active,
        lastSuccessMessage: NotificationService.getRandomSuccess(),
      ));

      await dataSource.cacheHabits(updated);
    } else {
      emit(state.copyWith(lastTickMs: event.nowMs));
    }
  }

  void _onDeviceOrientationChanged(
      DeviceOrientationChangedEvent event, Emitter<HabitState> emit) {
    emit(state.copyWith(isFaceDown: event.isFaceDown));
  }

  void _onBuySafetyDay(BuySafetyDayEvent event, Emitter<HabitState> emit) {
    if (state.totalScore >= 30) {
      final prefs = dataSource.prefs;
      final String uid = _currentUid;
      int newScore = state.totalScore - 30;
      prefs.setInt('${uid}_total_score', newScore);
      emit(state.copyWith(totalScore: newScore));
    }
  }

  void _onStartWeeklyAgreement(
      StartWeeklyAgreementEvent event, Emitter<HabitState> emit) {
    final prefs = dataSource.prefs;
    final String uid = _currentUid;

    prefs.setInt('${uid}_weekly_target_minutes', event.targetMinutes);
    prefs.setInt('${uid}_weekly_progress_minutes', 0);
    prefs.setBool('${uid}_is_agreement_active', true);

    emit(state.copyWith(
      weeklyTargetMinutes: event.targetMinutes,
      weeklyProgressMinutes: 0,
      isAgreementActive: true,
    ));
  }

  void _onGiveUpAgreement(
      GiveUpAgreementEvent event, Emitter<HabitState> emit) {
    final prefs = dataSource.prefs;
    final String uid = _currentUid;

    AudioHapticService.triggerFailureImpact();

    int penaltyScore = state.totalScore - 15;
    if (penaltyScore < 0) penaltyScore = 0;

    prefs.setInt('${uid}_total_score', penaltyScore);
    prefs.setInt('${uid}_weekly_target_minutes', 0);
    prefs.setInt('${uid}_weekly_progress_minutes', 0);
    prefs.setBool('${uid}_is_agreement_active', false);

    emit(state.copyWith(
      totalScore: penaltyScore,
      weeklyTargetMinutes: 0,
      weeklyProgressMinutes: 0,
      isAgreementActive: false,
    ));
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }
}
