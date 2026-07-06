import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class UserStatsDataSource {
  final SharedPreferences sharedPreferences;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Global sozlamalar (barcha akkauntlar uchun umumiy)
  static const String _themeKey = 'APP_THEME_MODE';
  static const String _langKey = 'APP_LANGUAGE';

  // Akkauntga tegishli bazaviy mahalliy kalitlar
  static const String _usernameBaseKey = 'USER_NAME';
  static const String _avatarBaseKey = 'USER_AVATAR_PATH';
  static const String _weeklyContractBaseKey = 'WEEKLY_CONTRACT_CHOICE';
  static const String _contractStartBaseKey = 'CONTRACT_START_TIMESTAMP';

  // 🔥 Streak, Score va Kalendar Konvertlari uchun bazaviy kalitlar
  static const String _streakBaseKey = 'CURRENT_STREAK_DAYS';
  static const String _lastOpenBaseKey = 'LAST_APP_OPEN_DATE';
  static const String _scoreBaseKey = 'TOTAL_SCORE_POINTS';
  static const String _calendarNotesBaseKey = 'CALENDAR_ENVELOPE_NOTES';

  // 🔐 Haqiqiy akkauntlar ro'yxati kaliti
  static const String _accountsListKey = 'saved_focus_ai_accounts';

  UserStatsDataSource(this.sharedPreferences);

  /// 🔐 Akkauntga xos unikal prefiks kalitini olish
  String _getPrefKey(String baseKey) {
    final currentUserId = sharedPreferences.getString('current_user_id');
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return '${baseKey}_$currentUserId';
    }
    // Agar Firebase foydalanuvchisi mavjud bo'lsa, o'shani ishlatamiz
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return '${baseKey}_${firebaseUser.uid}';
    }
    return '${baseKey}_guest';
  }

  // ==========================================
  // 👤 FOYDALANUVCHI AKKAUNT PROFILI METODLARI
  // ==========================================

  String getUsername() {
    return sharedPreferences.getString(_getPrefKey(_usernameBaseKey)) ?? '';
  }

  Future<void> saveUsername(String name) async {
    await sharedPreferences.setString(_getPrefKey(_usernameBaseKey), name);
    await syncUserDataToCloud();
  }

  String getAvatar() {
    return sharedPreferences.getString(_getPrefKey(_avatarBaseKey)) ?? '';
  }

  Future<void> saveAvatar(String path) async {
    await sharedPreferences.setString(_getPrefKey(_avatarBaseKey), path);
    await syncUserDataToCloud();
  }

  // ==========================================
  // 📦 KO'P AKKAUNTLAR BILAN ISHLASH METODLARI
  // ==========================================

  List<Map<String, String>> getSavedAccounts() {
    final String? accountsJson = sharedPreferences.getString(_accountsListKey);
    if (accountsJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      return decoded.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      debugPrint("Akkauntlarni o'qishda xato: $e");
      return [];
    }
  }

  Future<void> saveAccountToList({
    required String uid,
    required String name,
    required String email,
    required String photoUrl,
  }) async {
    List<Map<String, String>> accounts = getSavedAccounts();
    accounts.removeWhere((acc) => acc['uid'] == uid);
    accounts.add({
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    });
    await sharedPreferences.setString(_accountsListKey, jsonEncode(accounts));
  }

  Future<void> deleteAccountFromList(String uid) async {
    List<Map<String, String>> accounts = getSavedAccounts();
    accounts.removeWhere((acc) => acc['uid'] == uid);
    await sharedPreferences.setString(_accountsListKey, jsonEncode(accounts));

    // Ushbu akkauntning barcha lokal keshlarini tozalash
    await sharedPreferences.remove('${_usernameBaseKey}_$uid');
    await sharedPreferences.remove('${_avatarBaseKey}_$uid');
    await sharedPreferences.remove('${_weeklyContractBaseKey}_$uid');
    await sharedPreferences.remove('${_contractStartBaseKey}_$uid');
    await sharedPreferences.remove('${_streakBaseKey}_$uid');
    await sharedPreferences.remove('${_lastOpenBaseKey}_$uid');
    await sharedPreferences.remove('${_scoreBaseKey}_$uid');
    await sharedPreferences.remove('${_calendarNotesBaseKey}_$uid');
  }

  // ==========================================
  // 📊 BALLAR VA KUNLAR (STREAK & SCORE) METODLARI
  // ==========================================

  int getTotalScore() {
    return sharedPreferences.getInt(_getPrefKey(_scoreBaseKey)) ?? 0;
  }

  Future<void> saveTotalScore(int score) async {
    await sharedPreferences.setInt(_getPrefKey(_scoreBaseKey), score);
    await syncUserDataToCloud();
  }

  int getStreakDays() {
    return sharedPreferences.getInt(_getPrefKey(_streakBaseKey)) ?? 1;
  }

  /// 🔄 Har kuni ilovaga kirganda streak kunini yangilash mantiqi
  Future<int> updateStreakDays() async {
    final streakKey = _getPrefKey(_streakBaseKey);
    final lastOpenKey = _getPrefKey(_lastOpenBaseKey);

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    final lastOpenStr = sharedPreferences.getString(lastOpenKey);

    int currentStreak = sharedPreferences.getInt(streakKey) ?? 1;

    if (lastOpenStr == null) {
      currentStreak = 1;
    } else if (lastOpenStr != todayStr) {
      final lastOpenDate = DateTime.parse(lastOpenStr);
      final difference = today.difference(lastOpenDate).inDays;

      if (difference == 1) {
        currentStreak += 1;
      } else if (difference > 1) {
        currentStreak = 1; // Kun o'tkazib yuborilsa streak 1-kundan boshlanadi
      }
    }

    await sharedPreferences.setString(lastOpenKey, todayStr);
    await sharedPreferences.setInt(streakKey, currentStreak);

    // Bulutga aynan shu yangilangan ma'lumotlarni sinxronlash
    await syncUserDataToCloud();

    return currentStreak;
  }

  // ==========================================
  // ⚔️ HAFTALIK KELISHUV VA ZINALAR METODLARI
  // ==========================================

  String getWeeklyContract() {
    return sharedPreferences.getString(_getPrefKey(_weeklyContractBaseKey)) ??
        '';
  }

  Future<void> saveWeeklyContract(String contract) async {
    await sharedPreferences.setString(
        _getPrefKey(_weeklyContractBaseKey), contract);
    await sharedPreferences.setInt(
      _getPrefKey(_contractStartBaseKey),
      DateTime.now().millisecondsSinceEpoch,
    );
    await syncUserDataToCloud();
  }

  int getContractStartTimestamp() {
    return sharedPreferences.getInt(_getPrefKey(_contractStartBaseKey)) ?? 0;
  }

  // ==========================================
  // ✉️ KALENDAR KONVERT ESLATMALARI METODLARI
  // ==========================================

  Map<int, String> getCalendarNotes() {
    final String? notesJson =
        sharedPreferences.getString(_getPrefKey(_calendarNotesBaseKey));
    if (notesJson == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(notesJson);
      return decoded
          .map((key, value) => MapEntry(int.parse(key), value.toString()));
    } catch (e) {
      debugPrint("Konvertlarni o'qishda xato: $e");
      return {};
    }
  }

  Future<void> saveCalendarNote(int day, String note) async {
    final Map<int, String> currentNotes = getCalendarNotes();
    currentNotes[day] = note;

    final Map<String, String> stringMap =
        currentNotes.map((key, value) => MapEntry(key.toString(), value));
    await sharedPreferences.setString(
        _getPrefKey(_calendarNotesBaseKey), jsonEncode(stringMap));
    await syncUserDataToCloud();
  }

  // ==========================================
  // ☁️ BULUTGA PLANETAR SINXRONIZATSIYA (FIREBASE)
  // ==========================================

  /// 🚀 Ma'lumotlarni har bir hisob uchun Firebase Firestore'ga alohida joylash va saqlash
  Future<void> syncUserDataToCloud() async {
    final currentUserId = sharedPreferences.getString('current_user_id');
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      final String username = getUsername();
      final String avatarPath = getAvatar();
      final int streak = getStreakDays();
      final int score = getTotalScore();
      final String contract = getWeeklyContract();
      final int contractTime = getContractStartTimestamp();

      // Taqvim konvertlarini string ko'rinishida Firestore uchun tayyorlash
      final Map<String, String> stringNotes = getCalendarNotes()
          .map((key, value) => MapEntry(key.toString(), value));

      await _firestore.collection('users_stats').doc(currentUserId).set({
        'uid': currentUserId,
        'username': username,
        'avatarPath': avatarPath,
        'currentStreakDays': streak,
        'totalScorePoints': score,
        'weeklyContractChoice': contract,
        'contractStartTimestamp': contractTime,
        'calendarEnvelopeNotes': stringNotes,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
          "☁️ [Firebase Sync] Akkaunt ($currentUserId) ma'lumotlari bulutga muvaffaqiyatli saqlandi.");
    } catch (e) {
      debugPrint("❌ Bulutga sinxronizatsiya qilishda xatolik yuz berdi: $e");
    }
  }

  /// 📥 Bulutdan (Firebase) akkaunt ma'lumotlarini telefonga toza yuklab olish
  Future<void> fetchUserDataFromCloud() async {
    final currentUserId = sharedPreferences.getString('current_user_id');
    if (currentUserId == null || currentUserId.isEmpty) return;

    try {
      final doc =
          await _firestore.collection('users_stats').doc(currentUserId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (data['username'] != null) {
          await sharedPreferences.setString(
              _getPrefKey(_usernameBaseKey), data['username']);
        }
        if (data['avatarPath'] != null) {
          await sharedPreferences.setString(
              _getPrefKey(_avatarBaseKey), data['avatarPath']);
        }
        if (data['currentStreakDays'] != null) {
          await sharedPreferences.setInt(
              _getPrefKey(_streakBaseKey), data['currentStreakDays']);
        }
        if (data['totalScorePoints'] != null) {
          await sharedPreferences.setInt(
              _getPrefKey(_scoreBaseKey), data['totalScorePoints']);
        }
        if (data['weeklyContractChoice'] != null) {
          await sharedPreferences.setString(_getPrefKey(_weeklyContractBaseKey),
              data['weeklyContractChoice']);
        }
        if (data['contractStartTimestamp'] != null) {
          await sharedPreferences.setInt(_getPrefKey(_contractStartBaseKey),
              data['contractStartTimestamp']);
        }
        if (data['calendarEnvelopeNotes'] != null) {
          final Map<String, dynamic> notes =
              Map<String, dynamic>.from(data['calendarEnvelopeNotes']);
          await sharedPreferences.setString(
              _getPrefKey(_calendarNotesBaseKey), jsonEncode(notes));
        }

        debugPrint(
            "📥 [Firebase Fetch] Akkaunt ($currentUserId) ma'lumotlari bulutdan muvaffaqiyatli yuklandi.");
      }
    } catch (e) {
      debugPrint("❌ Bulutdan ma'lumot yuklashda xatolik: $e");
    }
  }

  // ==========================================
  // ⚙️ GLOBAL SOZLAMALAR (ILOVA TILI VA TEMASI)
  // ==========================================

  String getAppLanguage() {
    return sharedPreferences.getString(_langKey) ?? 'uz';
  }

  Future<void> saveAppLanguage(String langCode) async {
    await sharedPreferences.setString(_langKey, langCode);
  }

  String getThemeMode() {
    return sharedPreferences.getString(_themeKey) ?? 'system';
  }

  Future<void> saveThemeMode(String mode) async {
    await sharedPreferences.setString(_themeKey, mode);
  }
}
