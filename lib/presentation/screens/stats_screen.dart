import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';
import 'package:focus_ai/presentation/utils/lang_extension.dart';

// ⚠️ DIQQAT: Agar loyihangizda widget_service.dart boshqa papkada bo'lsa,
// quyidagi import yo'lini o'zingizni papkaga moslab o'zgartiring (masalan: core/services/widget_service.dart)
import 'package:focus_ai/core/services/widget_service.dart';

import '../blocs/habit/habit_bloc.dart';
import 'contracts_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;

  // Akkaunt keshini boshqarish uchun lokal Map (Xatoliklarni chetlab o'tish uchun)
  static final Map<int, String> _localCalendarNotes = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<HabitBloc>().state;
      _scrollToCurrentDay(state.currentStreak);
      _checkAndShowTodayNote(state.currentStreak, _localCalendarNotes);
      WidgetService.updateWidgetData(days: state.currentStreak);
    });
  }

  void _scrollToCurrentDay(int day) {
    if (day > 3 && _scrollController.hasClients) {
      _scrollController.animateTo(
        (day - 2) * 130.0,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  void _checkAndShowTodayNote(int currentDay, Map<int, String> calendarNotes) {
    if (calendarNotes.containsKey(currentDay)) {
      final note = calendarNotes[currentDay];
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _openEnvelopeDialog(currentDay, note!);
        }
      });
    }
  }

  void _openEnvelopeDialog(int day, String note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "✉️ $day-kun Konverti ochildi!",
          style: const TextStyle(
              color: Colors.cyanAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(note,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Tushunarli",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  void _showCalendarDialog(int currentStreak, Map<int, String> calendarNotes) {
    int selectedDay = currentStreak + 1;
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Text("📅 ", style: TextStyle(fontSize: 24)),
              Expanded(
                child: Text(
                  context.tr(
                      "Konvert joylash", "Place Envelope", "Поставить конверт"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                    "Kelgusi kunlardan birini tanlang. U yerga konvert ikonasi joylashadi va unga yetib borgandagina ochiladi!",
                    "Choose an upcoming day. An envelope icon will be placed there and will only open when reached!",
                    "Выберите предстоящий день. Там появится иконка конверта, которая откроется только по достижении!"),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      context.tr(
                          "Qaysi kunga:", "For which day:", "На какой день:"),
                      style: const TextStyle(color: Colors.white)),
                  DropdownButton<int>(
                    dropdownColor: const Color(0xFF1E293B),
                    value: selectedDay,
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    items: List.generate(100, (index) => index + 1)
                        .where((day) => day > currentStreak)
                        .map((day) => DropdownMenuItem(
                            value: day, child: Text("$day-kun")))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedDay = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLength: 100,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: context.tr(
                      "Maktub matni (Motivatsiya)...",
                      "Letter text (Motivation)...",
                      "Текст письма (Мотивация)..."),
                  hintStyle:
                      const TextStyle(color: Colors.white30, fontSize: 13),
                  counterStyle: const TextStyle(color: Color(0x80FFFFFF)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr("Bekor qilish", "Cancel", "Отмена"),
                  style: const TextStyle(color: Color(0x80FFFFFF))),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  setState(() {
                    _localCalendarNotes[selectedDay] =
                        textController.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "$selectedDay-kun yoniga maxfiy konvert berkitildi! ✉️"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                context.tr("Saqlash", "Save", "Сохранить"),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SettingsBloc, bool>(
      (bloc) => bloc.state.themeMode == ThemeMode.dark,
    );

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: BlocBuilder<HabitBloc, dynamic>(
        builder: (context, state) {
          WidgetService.updateWidgetData(days: state.currentStreak);

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 110, bottom: 140),
                itemCount: 100,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isReached = day <= state.currentStreak;
                  final isCurrent = day == state.currentStreak;
                  final isChestDay = day % 7 == 0;
                  final hasEnvelope = _localCalendarNotes.containsKey(day);
                  double alignmentX = 0.5 * math.sin(index * 1.0);
                  double textOffsetX = alignmentX > 0 ? -70 : 70;

                  return SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (index < 99)
                          Positioned(
                            top: 60,
                            child: CustomPaint(
                              size: const Size(100, 80),
                              painter: PathPainter(
                                isReached: day < state.currentStreak,
                                nextAlignmentX:
                                    0.5 * math.sin((index + 1) * 1.0),
                                currentAlignmentX: alignmentX,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment(alignmentX, 0),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (hasEnvelope) {
                                    if (isCurrent) {
                                      _openEnvelopeDialog(
                                          day, _localCalendarNotes[day]!);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "🔒 Ushbu konvert yopiq! Faqat o'sha kunga yetib kelganda ochiladi."),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: _buildStep(day, isReached, isCurrent,
                                    Theme.of(context)),
                              ),
                              if (hasEnvelope)
                                Positioned(
                                  right: alignmentX > 0 ? 75 : null,
                                  left: alignmentX <= 0 ? 75 : null,
                                  child: const Text("✉️",
                                      style: TextStyle(fontSize: 28)),
                                ),
                              if (isReached)
                                Positioned(
                                  bottom: -22,
                                  left: textOffsetX > 0 ? textOffsetX : null,
                                  right: textOffsetX < 0 ? -textOffsetX : null,
                                  child: Text(
                                    "$day-kun",
                                    style: TextStyle(
                                      color: isCurrent
                                          ? const Color(0xFF00FFCC)
                                          : Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isChestDay)
                          Positioned(
                            right: alignmentX > 0 ? null : 40,
                            left: alignmentX > 0 ? 40 : null,
                            child: TreasureChestWidget(
                              isOpened: day <= state.currentStreak,
                              isWiggling: day == state.currentStreak ||
                                  (state.currentStreak + 1 == day),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 15,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _showCalendarDialog(
                          state.currentStreak, _localCalendarNotes),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text("📅", style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ContractsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFCC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFCC).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 24,
                          child: Text("🤝", style: TextStyle(fontSize: 32)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep(int day, bool isReached, bool isCurrent, ThemeData theme) {
    if (isCurrent) {
      return const BreathingCurrentStep();
    }
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isReached ? theme.primaryColor : Colors.grey.withOpacity(0.3),
        boxShadow: isReached
            ? [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Center(
        child: isReached
            ? const Icon(Icons.check, color: Colors.black, size: 30)
            : Text(
                "$day",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class BreathingCurrentStep extends StatefulWidget {
  const BreathingCurrentStep({super.key});

  @override
  State<BreathingCurrentStep> createState() => _BreathingCurrentStepState();
}

class _BreathingCurrentStepState extends State<BreathingCurrentStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 70.0, end: 82.0).animate(
        CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 90,
          height: 90,
          child: Center(
            child: Container(
              width: _glowAnimation.value,
              height: _glowAnimation.value,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [Color(0xFF00FFCC), Color(0xFF009988)]),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xAA00FFCC),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child:
                    Icon(Icons.directions_run, color: Colors.black, size: 35),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TreasureChestWidget extends StatefulWidget {
  final bool isOpened;
  final bool isWiggling;

  const TreasureChestWidget(
      {super.key, required this.isOpened, required this.isWiggling});

  @override
  State<TreasureChestWidget> createState() => _TreasureChestWidgetState();
}

class _TreasureChestWidgetState extends State<TreasureChestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.isWiggling && !widget.isOpened)
      _wiggleController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TreasureChestWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWiggling && !widget.isOpened) {
      _wiggleController.repeat(reverse: true);
    } else {
      _wiggleController.stop();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        double angle = widget.isOpened
            ? 0
            : (math.sin(_wiggleController.value * math.pi * 2) * 0.1);
        return Transform.rotate(
          angle: angle,
          child: Column(
            children: [
              Text(widget.isOpened ? "🔓" : "📦",
                  style: const TextStyle(fontSize: 50)),
              if (widget.isOpened)
                const Text(
                  "+50",
                  style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PathPainter extends CustomPainter {
  final bool isReached;
  final double currentAlignmentX;
  final double nextAlignmentX;

  PathPainter({
    required this.isReached,
    required this.currentAlignmentX,
    required this.nextAlignmentX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isReached
          ? const Color(0xFF00FFCC).withOpacity(0.6)
          : Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double startX = size.width / 2 + (currentAlignmentX * 150);
    double endX = size.width / 2 + (nextAlignmentX * 150);
    path.moveTo(startX, 10);
    path.quadraticBezierTo(
        (startX + endX) / 2, size.height / 2, endX, size.height + 30);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
