import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/habit.dart';

class HabitLocalDataSource {
  final SharedPreferences prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  HabitLocalDataSource(this.prefs);

  String get _userId =>
      prefs.getString('current_user_id') ?? _auth.currentUser?.uid ?? 'guest';

  /// 🔄 Odatlar ro'yxatini Firestore bilan to'liq sinxron qilish
  Future<void> cacheHabits(List<Habit> habits) async {
    final String uid = _userId;

    // Agar foydalanuvchi tizimga kirmagan bo'lsa, Firestore so'rovini cheklaymiz
    if (uid == 'guest') return;

    try {
      // 1. Agar foydalanuvchi oxirgi odatini ham o'chirgan bo'lsa (ro'yxat bo'sh bo'lsa)
      if (habits.isEmpty) {
        final snapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('habits')
            .get();

        final deleteBatch = _firestore.batch();
        for (var doc in snapshot.docs) {
          deleteBatch.delete(doc.reference);
        }
        await deleteBatch.commit();
        return;
      }

      // 2. Mavjud odatlarni yozish yoki yangilash
      final batch = _firestore.batch();
      final List<String> currentHabitIds = [];

      for (var habit in habits) {
        currentHabitIds.add(habit.id);
        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('habits')
            .doc(habit.id);

        batch.set(docRef, habit.toJson(), SetOptions(merge: true));
      }
      await batch.commit();

      // 🔴 MUHIM FIX: `DeleteHabitEvent` ishlaganda Firestore'dan ham o'chib ketishi uchun
      // Mahalliy ro'yxatda bo'lmagan (o'chirilgan) odatlarni bulutdan ham o'chirib tashlaymiz
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      final cleanBatch = _firestore.batch();
      bool needDelete = false;

      for (var doc in snapshot.docs) {
        if (!currentHabitIds.contains(doc.id)) {
          cleanBatch.delete(doc.reference);
          needDelete = true;
        }
      }

      if (needDelete) {
        await cleanBatch.commit();
      }
    } catch (e) {
      debugPrint("Odatlarni Firestore-ga yozishda xatolik: $e");
      rethrow;
    }
  }

  /// 📥 Odatlarni yuklab olish
  Future<List<Habit>> getHabits() async {
    final String uid = _userId;
    if (uid == 'guest') return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      final List<Habit> parsedHabits = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();

        // 🛡️ Fayl tizimida rasm bor-yo'qligini tekshirish (Siz yozgan xavfsiz mantiq)
        if (data['imagePath'] != null &&
            !data['imagePath'].toString().startsWith('http') &&
            !data['imagePath'].toString().startsWith('assets/')) {
          final file = File(data['imagePath']);
          if (!await file.exists()) {
            data['imagePath'] = '';
          }
        }

        parsedHabits.add(Habit.fromJson(data));
      }

      return parsedHabits;
    } catch (e) {
      debugPrint("Odatlarni Firestore-dan o'qishda xatolik: $e");
      return [];
    }
  }

  /// 🏷️ Odat holatini (statusini) yangilash
  Future<void> updateHabitStatus(String habitId, HabitStatus newStatus) async {
    final String uid = _userId;
    if (uid == 'guest') return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(habitId);

    try {
      await docRef.update({
        'status': newStatus.name,
      });
    } catch (e) {
      debugPrint("Odat statusini yangilashda xatolik: $e");
      rethrow;
    }
  }
}
