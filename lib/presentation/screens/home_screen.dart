import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:focus_ai/presentation/screens/add_habit_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../blocs/habit/habit_bloc.dart';
import '../../domain/entities/habit.dart';
import 'habit_history_screen.dart';
import 'package:focus_ai/presentation/utils/lang_extension.dart';
import 'package:focus_ai/core/services/widget_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Fayl tepasiga qo'shing
import 'package:device_info_plus/device_info_plus.dart'; // Fayl tepasiga qo'shing
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static FaIconData getIconData(String iconName) {
    switch (iconName) {
      case 'bookOpen':
        return FontAwesomeIcons.bookOpen;
      case 'code':
        return FontAwesomeIcons.code;
      case 'personRunning':
        return FontAwesomeIcons.personRunning;
      case 'brain':
        return FontAwesomeIcons.brain;
      default:
        return FontAwesomeIcons.star;
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastEventTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    saveCurrentDevice();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WidgetService.requestToPinWidgetIfNeeded();
    });

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      final now = DateTime.now();
      if (now.difference(_lastEventTime).inMilliseconds < 300) return;
      _lastEventTime = now;

      final bool isDown =
          event.z < -8.5 && event.x.abs() < 2 && event.y.abs() < 2;
      if (mounted) {
        context.read<HabitBloc>().add(DeviceOrientationChangedEvent(isDown));
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr("Mening Odatlarim", "My Habits", "Мои Привычки"),
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FFCC),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHabitScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          if (state.habits.isEmpty) {
            return Center(
                child: Text(
                    context.tr("Hali odat qo'shilmagan.",
                        "No habits added yet.", "Привычки еще не добавлены."),
                    style: const TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.habits.length,
            itemBuilder: (context, index) {
              return HabitCardTile(
                  habit: state.habits[index], isDark: isDark, theme: theme);
            },
          );
        },
      ),
    );
  }
}

Future<void> saveCurrentDevice() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final deviceInfo = DeviceInfoPlugin();
  String deviceName = "Unknown Device";
  String deviceId = "unknown_id";

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = "${androidInfo.brand} ${androidInfo.model}";
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      deviceId = iosInfo.identifierForVendor ?? "ios_id";
    }

    // Foydalanuvchining Firestore hujjati ostiga qurilmani saqlaymiz
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(deviceId)
        .set({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'lastActive': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  } catch (e) {
    debugPrint("Qurilmani bazaga yozishda xatolik: $e");
  }
}

class HabitCardTile extends StatefulWidget {
  final Habit habit;
  final bool isDark;
  final ThemeData theme;

  const HabitCardTile(
      {super.key,
      required this.habit,
      required this.isDark,
      required this.theme});

  @override
  State<HabitCardTile> createState() => _HabitCardTileState();
}

class _HabitCardTileState extends State<HabitCardTile> {
  Timer? _ticker;
  bool _isAlreadyTriggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit.isRunning) _startTicker();
  }

  @override
  void didUpdateWidget(covariant HabitCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habit.isRunning && _ticker == null) {
      _startTicker();
    } else if (!widget.habit.isRunning && _ticker != null) {
      _stopTicker();
    }
    if (!widget.habit.isCompleted) {
      _isAlreadyTriggered = false;
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final int remainingSecs =
          (((widget.habit.goalDurationMs - widget.habit.getElapsedTime()) /
                  1000))
              .ceil();

      if (remainingSecs <= 0 &&
          !_isAlreadyTriggered &&
          !widget.habit.isCompleted) {
        _isAlreadyTriggered = true;
        _stopTicker();
        context.read<HabitBloc>().add(CompleteHabitEvent(widget.habit.id));
      }

      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.habit.getProgress();
    final int remainingSecs =
        (((widget.habit.goalDurationMs - widget.habit.getElapsedTime()) / 1000))
            .ceil();
    final bool isFinished = remainingSecs <= 0 || widget.habit.isCompleted;

    String durationText = isFinished
        ? context.tr("Tugadi! 🎉", "Finished! 🎉", "Завершено! 🎉")
        : "${(remainingSecs / 60).floor()}:${(remainingSecs % 60).toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.habit.isRunning
                ? const Color(0xFF00FFCC).withOpacity(0.3)
                : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.habit.isRunning
                    ? const Color(0xFF00FFCC).withOpacity(0.2)
                    : Colors.white10,
                child: widget.habit.imagePath != null &&
                        widget.habit.imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(widget.habit.imagePath!),
                            width: 40, height: 40, fit: BoxFit.cover),
                      )
                    : FaIcon(HomeScreen.getIconData(widget.habit.iconName),
                        color: widget.habit.isRunning
                            ? const Color(0xFF00FFCC)
                            : Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.habit.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        "${context.tr("Qolgan vaqt", "Remaining time", "Оставшееся время")}: $durationText",
                        style: TextStyle(
                            color:
                                isFinished ? Colors.greenAccent : Colors.grey)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note,
                        color: Colors.white60, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddHabitScreen(habit: widget.habit),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: FaIcon(
                      widget.habit.isRunning
                          ? FontAwesomeIcons.circlePause
                          : FontAwesomeIcons.circlePlay,
                      color: widget.habit.isRunning
                          ? Colors.amberAccent
                          : const Color(0xFF00FFCC),
                      size: 28,
                    ),
                    onPressed: () {
                      if (widget.habit.isRunning) {
                        context
                            .read<HabitBloc>()
                            .add(PauseHabitEvent(widget.habit.id));
                      } else {
                        context
                            .read<HabitBloc>()
                            .add(StartHabitEvent(widget.habit.id));
                      }
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isFinished ? 1.0 : progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isFinished ? Colors.greenAccent : const Color(0xFF00FFCC)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                icon:
                    const Icon(Icons.refresh, color: Colors.white38, size: 16),
                label: Text(context.tr("Qayta boshlash", "Reset", "Сбросить"),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),
                onPressed: () => context
                    .read<HabitBloc>()
                    .add(ResetHabitEvent(widget.habit.id)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon:
                    const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                onPressed: () => context
                    .read<HabitBloc>()
                    .add(DeleteHabitEvent(widget.habit.id)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                icon: const Icon(Icons.history,
                    color: Color(0xFF00FFCC), size: 16),
                label: Text(
                    context.tr("Tarixni ko'rish", "View History", "История"),
                    style: const TextStyle(
                        color: Color(0xFF00FFCC),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            HabitHistoryScreen(habit: widget.habit)),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
