import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/habit/habit_bloc.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  final TextEditingController _targetController = TextEditingController();

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _showGiveUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Taslim bo'lasizmi? ❌",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Kelishuvdan voz kechsangiz, sizdan 15 jazo balli chegirib tashlanadi. Qaroringiz qat'iymi?",
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Yo'q, davom etaman",
                style: TextStyle(
                    color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              context.read<HabitBloc>().add(GiveUpAgreementEvent());
              Navigator.pop(dialogContext);
            },
            child: const Text("Ha, taslim bo'laman",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "Matonat Kelishuvi 🤝",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          final double progressPercentage = state.weeklyTargetMinutes > 0
              ? (state.weeklyProgressMinutes / state.weeklyTargetMinutes)
                  .clamp(0.0, 1.0)
              : 0.0;

          final bool isGoalAchieved =
              state.weeklyProgressMinutes >= state.weeklyTargetMinutes &&
                  state.weeklyTargetMinutes > 0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jami Ball Konteyneri (Gradient va Chiroyli Vizual)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars_rounded,
                              color: Colors.amber, size: 28),
                          SizedBox(width: 10),
                          Text("Jami to'plangan ball:",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Text(
                        "${state.totalScore}",
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!state.isAgreementActive) ...[
                  // KELISHUV YO'Q HOLAT (Yangi kelishuv tuzish)
                  const Text(
                    "Yangi Haftalik Kelishuv ⚔️",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
                    ),
                    child: Text(
                      "Kelishuv qoidasi:\nHaftalik fokuslanish maqsadini daqiqalarda belgilang. Agar hafta yakunida ushbu marraga to'liq erishsangiz, sizga +50 BONUS ball taqdim etiladi. Agarda maqsadga erisholmay muddatidan oldin taslim bo'lsangiz, intizom jazosi sifatida hisobingizdan -15 ball chegirib tashlanadi.",
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Haftalik maqsad (daqiqada)",
                      labelStyle: const TextStyle(color: Colors.cyanAccent),
                      prefixIcon: const Icon(Icons.timer_outlined,
                          color: Colors.cyanAccent),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Colors.cyanAccent, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shadowColor: Colors.cyanAccent.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        final int? mins = int.tryParse(_targetController.text);
                        if (mins != null && mins > 0) {
                          context
                              .read<HabitBloc>()
                              .add(StartWeeklyAgreementEvent(mins));
                          _targetController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              content: const Text(
                                  "Iltimos, noldan katta va to'g'ri daqiqa kiriting!",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Kelishuvni Imzolash 🤝",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ] else ...[
                  // KELISHUV FAOL HOLAT (Progress monitoring)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isGoalAchieved
                              ? Colors.greenAccent.withOpacity(0.05)
                              : Colors.cyanAccent.withOpacity(0.03),
                          blurRadius: 20,
                          spreadRadius: 1,
                        )
                      ],
                      border: Border.all(
                        color: isGoalAchieved
                            ? Colors.greenAccent.withOpacity(0.4)
                            : Colors.cyanAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isGoalAchieved
                                    ? Colors.greenAccent.withOpacity(0.1)
                                    : Colors.cyanAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isGoalAchieved
                                    ? "Bajarildi! 🎉"
                                    : "Holati: FAOL 🔥",
                                style: TextStyle(
                                    color: isGoalAchieved
                                        ? Colors.greenAccent
                                        : Colors.cyanAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            Text(
                              "${(progressPercentage * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                  color: isGoalAchieved
                                      ? Colors.greenAccent
                                      : Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.outlined_flag_rounded,
                                color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            Text("Maqsad: ${state.weeklyTargetMinutes} daqiqa",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                                "Bajarildi: ${state.weeklyProgressMinutes} daqiqa",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressPercentage,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                isGoalAchieved
                                    ? Colors.greenAccent
                                    : Colors.cyanAccent),
                          ),
                        ),
                        const SizedBox(height: 28),
                        isGoalAchieved
                            ? SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    foregroundColor: Colors.black,
                                    shadowColor:
                                        Colors.greenAccent.withOpacity(0.2),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    context
                                        .read<HabitBloc>()
                                        .add(CompleteWeeklyAgreementEvent());
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emoji_events_rounded,
                                          size: 22),
                                      SizedBox(width: 8),
                                      Text("Bonus +50 Ballni Olish 🏆",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _showGiveUpDialog(context),
                                  icon: const Icon(Icons.flag_rounded,
                                      color: Colors.redAccent, size: 20),
                                  label: const Text(
                                    "Taslim Bo'lish (-15 ball)",
                                    style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
