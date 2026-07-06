import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';

class HabitHistoryScreen extends StatelessWidget {
  final Habit habit;

  const HabitHistoryScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("${habit.title} - Tarixi",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: habit.completionHistory.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off,
                        color: Colors.white24, size: 64),
                    SizedBox(height: 16),
                    Text(
                      "Bu odat hali biror marta yakunlanmagan.\nVaqtni to'ldirib g'alabaga erishing!",
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habit.completionHistory.length,
              itemBuilder: (context, index) {
                final reversedIndex =
                    habit.completionHistory.length - 1 - index;
                final dateTimeStr = habit.completionHistory[reversedIndex];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF00FFCC).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFCC).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.done_all,
                            color: Color(0xFF00FFCC), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${reversedIndex + 1}-marta bajarildi",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Sana: $dateTimeStr",
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
