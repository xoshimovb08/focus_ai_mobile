import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// BLocs va Utils
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_event.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_state.dart';
import 'package:focus_ai/presentation/utils/lang_extension.dart';
import 'package:focus_ai/presentation/pages/splash/splash_page.dart';
import 'package:focus_ai/services/service_locator.dart';
import 'package:focus_ai/core/services/audio_haptic_service.dart';
import 'package:focus_ai/core/services/widget_service.dart';
import 'package:focus_ai/presentation/blocs/habit/habit_bloc.dart';
import 'package:focus_ai/data/datasources/user_stats_datasource.dart';
import 'package:focus_ai/presentation/screens/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SharedPreferences _prefs;
  late final UserStatsDataSource _userStatsDataSource;
  User? _currentUser;
  List<Map<String, String>> _savedAccounts = [];
  String _currentDeviceName = "Ushbu Qurilma";

  @override
  void initState() {
    super.initState();
    _userStatsDataSource = sl<UserStatsDataSource>();
    _prefs = _userStatsDataSource.sharedPreferences;
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadSavedAccounts();
    _getDeviceInfo();
  }

  /// Markaziy `UserStatsDataSource` arxitekturasiga muvofiq saqlangan hisoblarni yuklash
  Future<void> _loadSavedAccounts() async {
    if (_currentUser == null || _currentUser!.isAnonymous) {
      if (mounted) setState(() => _savedAccounts = []);
      return;
    }

    List<String> savedUids = _prefs.getStringList('saved_user_uids') ?? [];
    final String uid = _currentUser!.uid;

    if (!savedUids.contains(uid)) {
      savedUids.add(uid);
      await _prefs.setStringList('saved_user_uids', savedUids);
    }

    List<Map<String, String>> tempAccounts = [];
    for (String savedUid in savedUids) {
      String name = _prefs.getString('act_name_$savedUid') ?? 'Focus User';
      String email =
          _prefs.getString('act_email_$savedUid') ?? 'user@focusai.com';
      String photo = _prefs.getString('act_photo_$savedUid') ?? '';

      tempAccounts.add({
        'uid': savedUid,
        'name': name,
        'email': email,
        'photoUrl': photo,
      });
    }

    if (mounted) {
      setState(() {
        _savedAccounts = tempAccounts;
      });
    }
  }

  /// Qurilma nomini aniqlash funksiyasi
  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = "Smartfon";
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = "${androidInfo.manufacturer} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _currentDeviceName = deviceName);
    }
  }

  /// Akkauntni ro'yxatdan butunlay o'chirish (Kesh ma'lumotlarini buzmasdan tozalash)
  Future<void> _deleteAccount(String uid) async {
    AudioHapticService.triggerLightImpact();
    List<String> savedUids = _prefs.getStringList('saved_user_uids') ?? [];
    savedUids.remove(uid);
    await _prefs.setStringList('saved_user_uids', savedUids);

    await _prefs.remove('act_name_$uid');
    await _prefs.remove('act_email_$uid');
    await _prefs.remove('act_photo_$uid');

    // Agar o'chirilayotgan akkaunt hozirgi faol akkaunt bo'lsa, tizimdan to'liq chiqariladi
    final String currentUid = _prefs.getString('current_user_id') ?? 'guest';
    if (currentUid == uid || _currentUser?.uid == uid) {
      _logoutAndGoToSplash();
    } else {
      _loadSavedAccounts();
    }
  }

  /// Tizimdan chiqish va Splash ekranga yo'naltirish algoritmi (Haftalik kelishuvlarga zarar yetkazmaydi)
  Future<void> _logoutAndGoToSplash({bool isAddingAccount = false}) async {
    AudioHapticService.triggerLightImpact();
    AudioHapticService().stopBackgroundMusic();

    try {
      await WidgetService.clearWidgetOnLogout();
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}

    final String currentUserId = _prefs.getString('current_user_id') ?? 'guest';
    if (!isAddingAccount) {
      await _prefs.remove('USER_NAME_$currentUserId');
      await _prefs.remove('USER_AVATAR_PATH_$currentUserId');
      await _prefs.remove('current_user_id');
    }

    // Tizim holatlarini to'g'rilash
    await _prefs.setBool('is_first_time', false);
    await _prefs.setBool('is_logged_in', false);
    await _prefs.setBool('is_guest', false);

    if (!mounted) return;

    // 🔥 MANA SHU YERDA SHART QO'YAMIZ:
    if (isAddingAccount) {
      // Agar yangi akkaunt qo'shilayotgan bo'olsa, SplashPage'ga bormaymiz,
      // chunki u baribir adashib HomeScreen'ga otib yuboryapti. To'g'ri AuthPage'ga yo'naltiramiz.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) =>
                const AuthScreen()), // 👈 O'zingizning Login/Auth sahifangiz klassi nomini yozing (masalan AuthPage yoki LoginScreen)
        (route) => false,
      );
    } else {
      // Oddiy chiqish bo'lsa, har doimgidek SplashPage'ga boradi
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashPage()),
        (route) => false,
      );
    }
  }

  /// Akkauntlar boshqaruvi dialog oynasi
  void _openAccountsDialog() {
    AudioHapticService.triggerLightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color neonCyan = Color(0xFF00FFCC);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                dialogCtx.tr(
                    "Barcha Akkauntlar", "All Accounts", "Все Аккаунты"),
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_savedAccounts.isEmpty ||
                        _currentUser == null ||
                        _currentUser!.isAnonymous)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(dialogCtx.tr(
                            "Ulangan akkauntlar yo'q",
                            "No connected accounts",
                            "Нет подключенных аккаунтов")),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _savedAccounts.length,
                          itemBuilder: (context, index) {
                            final account = _savedAccounts[index];
                            final isCurrent =
                                account['uid'] == _currentUser?.uid;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: neonCyan,
                                child: Icon(Icons.person, color: Colors.black),
                              ),
                              title: Text(
                                account['name']!,
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal),
                              ),
                              subtitle: Text(account['email']!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await _deleteAccount(account['uid']!);
                                  setDialogState(() {
                                    _loadSavedAccounts();
                                  });
                                  if (account['uid'] == _currentUser?.uid) {
                                    Navigator.pop(dialogCtx);
                                  }
                                },
                              ),
                              onTap: () async {
                                if (!isCurrent) {
                                  Navigator.pop(dialogCtx);
                                  // Markaziy UID o'zgartiriladi va tizim SplashPage orqali qayta yuklanadi
                                  await _prefs.setString(
                                      'current_user_id', account['uid']!);
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SplashPage()),
                                    (route) => false,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.add_circle_outline, color: neonCyan),
                      title: Text(
                        dialogCtx.tr("Yangi akkaunt qo'shish",
                            "Add new account", "Добавить аккаунт"),
                        style: const TextStyle(
                            color: neonCyan, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(dialogCtx);
                        _logoutAndGoToSplash(isAddingAccount: true);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDevicesDialog() {
    AudioHapticService.triggerLightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.tr("Ulangan Qurilmalar", "Connected Devices",
                "Подключенные Устройства"),
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold),
          ),
          content: currentUser == null
              ? const Text("User not logged in")
              : SizedBox(
                  width: double.maxFinite,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .collection('devices')
                        .orderBy('lastActive', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final devices = snapshot.data!.docs;

                      if (devices.isEmpty) {
                        return Text(context.tr("Qurilmalar topilmadi",
                            "No devices found", "Устройства не найдены"));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device =
                              devices[index].data() as Map<String, dynamic>;
                          final String deviceName =
                              device['deviceName'] ?? 'Unknown';
                          final Timestamp? lastActiveTime =
                              device['lastActive'] as Timestamp?;

                          String timeStr = "";
                          if (lastActiveTime != null) {
                            final date = lastActiveTime.toDate();
                            timeStr =
                                "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                          }

                          // Agar joriy telefon bo'lsa Active deb chiqaramiz
                          final bool isThisDevice =
                              device['deviceName'] == _currentDeviceName;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                                Platform.isIOS
                                    ? Icons.phone_iphone
                                    : Icons.phone_android,
                                color: const Color(0xFF00FFCC)),
                            title: Text(
                              deviceName,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${context.tr("Oxirgi faollik:", "Last active:", "Последняя активность:")} $timeStr",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: isThisDevice
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                isThisDevice
                                    ? context.tr("Faol", "Active", "Активен")
                                    : context.tr(
                                        "Uzoqdagi", "Remote", "Удаленный"),
                                style: TextStyle(
                                    color: isThisDevice
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color neonCyan = Color(0xFF00FFCC);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          context.tr("Sozlamalar", "Settings", "Настройки"),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ========================================================
          // 🌐 GLOBAL TIZIM SOZLAMALARI
          // ========================================================
          Text(
            context.tr(
                "TIZIM SOZLAMALARI", "SYSTEM SETTINGS", "СИСТЕМНЫЕ НАСТРОЙКИ"),
            style: const TextStyle(
                color: neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),

          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.language,
                      color: neonCyan, size: 20),
                  title: Text(
                    context.tr("Ilova tili", "App Language", "Язык приложения"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: BlocSelector<SettingsBloc, SettingsState, String>(
                    selector: (state) => state.locale.languageCode,
                    builder: (context, langCode) {
                      return DropdownButton<String>(
                        value: langCode,
                        dropdownColor: theme.cardColor,
                        underline: const SizedBox(),
                        style: TextStyle(
                            color: isDark ? neonCyan : theme.primaryColor,
                            fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(
                              value: 'uz', child: Text("🇺🇿 O'zbek")),
                          DropdownMenuItem(
                              value: 'en', child: Text("🇺🇸 English")),
                          DropdownMenuItem(
                              value: 'ru', child: Text("🇷🇺 Русский")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            context
                                .read<SettingsBloc>()
                                .add(ChangeLanguageEvent(val));
                          }
                        },
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: FaIcon(
                    isDark
                        ? FontAwesomeIcons.solidMoon
                        : FontAwesomeIcons.solidSun,
                    color: neonCyan,
                    size: 20,
                  ),
                  title: Text(
                    context.tr("Tungi rejim", "Dark Mode", "Тёмный режим"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: Switch(
                    value: isDark,
                    activeColor: neonCyan,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleThemeEvent());
                    },
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                BlocSelector<SettingsBloc, SettingsState, bool>(
                  selector: (state) => state.isWidgetEnabled,
                  builder: (context, isWidgetEnabled) {
                    return ListTile(
                      leading: FaIcon(
                        FontAwesomeIcons.squarePlus,
                        color: isWidgetEnabled ? neonCyan : Colors.grey,
                        size: 20,
                      ),
                      title: Text(
                        context.tr("Asosiy ekran vidjeti", "Home Screen Widget",
                            "Виджет экрана"),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: isWidgetEnabled
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                      trailing: Switch(
                        value: isWidgetEnabled,
                        activeColor: neonCyan,
                        onChanged: (val) {
                          // 🛠️ BUG FIX: ToggleThemeEvent emas, to'g'ri ToggleWidgetEvent chaqirildi
                          context
                              .read<SettingsBloc>()
                              .add(ToggleWidgetEvent(val));
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // ========================================================
          // ⚡ AKKAUNT VA XAVFSIZLIK BO'LIMLARI
          // ========================================================
          Text(
            context.tr("XAVFSIZLIK VA HISOB", "SECURITY AND ACCOUNT",
                "БЕЗОПАСНОСТЬ И УЧЕТНАЯ ЗАПИСЬ"),
            style: const TextStyle(
                color: neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts, color: neonCyan),
                  title: Text(
                    context.tr("Akkauntlar", "Accounts", "Аккаунты"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                  onTap: _openAccountsDialog,
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  leading: const Icon(Icons.devices, color: neonCyan),
                  title: Text(
                    context.tr("Ulangan qurilmalar", "Connected devices",
                        "Подключенные устройства"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                  onTap: _openDevicesDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // ========================================================
          // 👤 PROFIL SOZLAMALARI
          // ========================================================
          Text(
            context.tr(
                "PROFIL SOZLAMALARI", "PROFILE SETTINGS", "НАСТРОЙКИ ПРОФИЛЯ"),
            style: const TextStyle(
                color: neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),

          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: BlocSelector<SettingsBloc, SettingsState, double>(
                selector: (state) => state.dailyFocusLimit,
                builder: (context, dailyFocusLimit) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${context.tr("Kunlik Fokus Limiti:", "Daily Focus Limit:", "Ежедневный лимит фокуса:")} ${dailyFocusLimit.toInt()} ${context.tr("soat", "hours", "ч.")}",
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      Slider(
                        value: dailyFocusLimit,
                        min: 1,
                        max: 8,
                        activeColor: neonCyan,
                        inactiveColor: isDark ? Colors.white10 : Colors.black12,
                        onChanged: (val) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateDailyGoalHoursEvent(val));
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 25),

          // ========================================================
          // 🤖 AI MURABBIY INTEGRATSIYASI
          // ========================================================
          Text(
            context.tr("AI MURABBIY INTEGRATSIYASI", "AI COACH INTEGRATION",
                "ИНТЕГРАЦИЯ AI НАСТАВНИКА"),
            style: const TextStyle(
                color: neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),

          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: BlocSelector<SettingsBloc, SettingsState, String>(
              selector: (state) => state.coachTone,
              builder: (context, coachTone) {
                return ListTile(
                  title: Text(
                    context.tr("Murabbiy Ohangi (Tone)", "Coach Tone",
                        "Тон Наставника"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: DropdownButton<String>(
                    value: coachTone,
                    dropdownColor: theme.cardColor,
                    style: const TextStyle(
                        color: neonCyan, fontWeight: FontWeight.bold),
                    underline: Container(),
                    items: [
                      DropdownMenuItem(
                          value: 'Do\'stona',
                          child: Text(context.tr(
                              "Do'stona", "Friendly", "Дружелюбный"))),
                      DropdownMenuItem(
                          value: 'Qat\'iy / Harbiy',
                          child:
                              Text(context.tr("Qat'iy", "Strict", "Строгий"))),
                      DropdownMenuItem(
                          value: 'Motivatsion',
                          child: Text(context.tr(
                              "Motivatsion", "Motivational", "Мотивационный"))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateCoachToneEvent(val));
                      }
                    },
                  ),
                );
              },
            ),
          ),

          Card(
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: BlocSelector<SettingsBloc, SettingsState, bool>(
              selector: (state) => state.isTtsEnabled,
              builder: (context, isTtsEnabled) {
                return SwitchListTile(
                  title: Text(
                    context.tr(
                        "Ovozli tavsiyalar (TTS)",
                        "Voice Recommendations (TTS)",
                        "Голосовые рекомендации (TTS)"),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  subtitle: Text(
                    context.tr(
                        "Gemini matnlarini ovozli o'qish",
                        "Read Gemini texts aloud",
                        "Озвучивание текстов Gemini"),
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontSize: 11),
                  ),
                  value: isTtsEnabled,
                  activeColor: neonCyan,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(ToggleTtsEvent(val));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
