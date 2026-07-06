enum HabitStatus { active, paused, restarted }

class Habit {
  final String id;
  final String title;
  final int goalMinutes;
  final int accumulatedMs;
  final int? runningSince;
  final String iconName;
  final String? imagePath;
  final bool isCompleted;
  final HabitStatus status;
  final List<String>
      completionHistory; // 📅 Tugatilgan sana va vaqtlar ro'yxati

  const Habit({
    required this.id,
    required this.title,
    required this.goalMinutes,
    this.accumulatedMs = 0,
    this.runningSince,
    this.iconName = 'star',
    this.imagePath,
    this.isCompleted = false,
    this.status = HabitStatus.active,
    this.completionHistory = const [],
  });

  bool get isRunning => runningSince != null;

  int get goalDurationMs => goalMinutes * 60 * 1000;

  int getElapsedTime([int? mockNow]) {
    final currentMs = mockNow ?? DateTime.now().millisecondsSinceEpoch;
    if (runningSince == null) {
      return accumulatedMs;
    }
    return accumulatedMs + (currentMs - runningSince!);
  }

  double getProgress() {
    if (goalDurationMs == 0) return 0.0;
    final progress = getElapsedTime() / goalDurationMs;
    return progress > 1.0 ? 1.0 : progress;
  }

  Habit copyWith({
    String? id,
    String? title,
    int? goalMinutes,
    int? accumulatedMs,
    int? Function()? runningSince,
    String? iconName,
    String? Function()? imagePath,
    bool? isCompleted,
    HabitStatus? status,
    List<String>? completionHistory,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      goalMinutes: goalMinutes ?? this.goalMinutes,
      accumulatedMs: accumulatedMs ?? this.accumulatedMs,
      runningSince: runningSince != null ? runningSince() : this.runningSince,
      iconName: iconName ?? this.iconName,
      imagePath: imagePath != null ? imagePath() : this.imagePath,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'goalMinutes': goalMinutes,
      'accumulatedMs': accumulatedMs,
      'runningSince': runningSince,
      'iconName': iconName,
      'imagePath': imagePath,
      'isCompleted': isCompleted,
      'status': status.name,
      'completionHistory': completionHistory,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? '';
    final cleanStatus =
        rawStatus.contains('.') ? rawStatus.split('.').last : rawStatus;

    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      goalMinutes: json['goalMinutes'] as int,
      accumulatedMs: json['accumulatedMs'] as int? ?? 0,
      runningSince: json['runningSince'] as int?,
      iconName: json['iconName'] as String? ?? 'star',
      imagePath: json['imagePath'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      status: HabitStatus.values.firstWhere(
        (e) => e.name == cleanStatus,
        orElse: () => HabitStatus.active,
      ),
      completionHistory: List<String>.from(json['completionHistory'] ?? []),
    );
  }
}
