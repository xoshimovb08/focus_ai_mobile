import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:focus_ai/services/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Bloklar va Utils
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';
import 'package:focus_ai/presentation/utils/lang_extension.dart';
import 'package:focus_ai/presentation/screens/auth_screen.dart';
import 'package:focus_ai/presentation/pages/splash/splash_page.dart'; // Splash qo'shildi
import '../../presentation/blocs/habit/habit_bloc.dart';
import 'package:focus_ai/presentation/screens/auth_screen.dart';
// Servislar va DI
import '../../core/services/audio_haptic_service.dart';
import '../../core/services/widget_service.dart';
import '../../data/datasources/user_stats_datasource.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String? _imagePath;

  late final UserStatsDataSource _userStatsDataSource;
  late final SharedPreferences _prefs;
  User? _currentUser;
  List<Map<String, String>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _prefs = sl<SharedPreferences>();
    _userStatsDataSource = UserStatsDataSource(_prefs);

    _loadProfileData();
    _syncWithFirebaseAndLoadAccounts();

    _nameFocusNode.addListener(_onNameFocusChange);
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus && mounted) {
      _saveData('user_name', _nameController.text.trim());
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChange);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// Profil ma'lumotlarini yuklash va Streak/Zinalarni bulutga sinxronizatsiya qilish
  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _nameController.text = _userStatsDataSource.getUsername();
      _imagePath = _userStatsDataSource.getAvatar();
    });

    // ⚡ TALAB: Zinalar va streak kunini bulutga yozish mantiqi
    await _userStatsDataSource.updateStreakDays();
    _uploadStatsToCloud();
  }

  /// Zinalar va statistikani Firestore bulutiga joylash
  Future<void> _uploadStatsToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous)
      return; // Mehmon bo'lsa bulutga saqlamaydi

    try {
      // Bu yerda local xotiradagi streak va zinalar olinib Firestore'ga yoziladi
      final int steps = _prefs.getInt('total_steps_or_stairs') ?? 0;
      final int streak = _prefs.getInt('streak_days') ?? 0;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'stairs_count': steps,
        'streak_days': streak,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Statistikani bulutga yuklashda xatolik: $e");
    }
  }

  /// ☁️ Bulutli Sinxronizatsiya va Akkauntlar ro'yxatini parallel yuklash (SOXTA AKKAUNTSIZ)
  Future<void> _syncWithFirebaseAndLoadAccounts() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    // ⚡ TALAB: Agar mehmon (Guest) bo'lsa yoki akkaunt bo'lmasa, ro'yxat butkul bo'sh bo'ladi
    if (_currentUser == null || _currentUser!.isAnonymous) {
      if (mounted) {
        setState(() {
          _savedAccounts = [];
        });
      }
      return;
    }

    final String uid = _currentUser!.uid;
    final String currentName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (_currentUser!.displayName ?? 'Focus User');
    final String currentEmail = _currentUser!.email ?? 'user@focusai.com';
    final String currentPhoto = _imagePath ?? _currentUser!.photoURL ?? '';

    try {
      // 1. Firestore'ga asosiy profilni sinxronlash
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': currentName,
        'email': currentEmail,
        'photoUrl': currentPhoto,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Real Local kesh ro'yxatini shakllantirish
      List<String> savedUids = _prefs.getStringList('saved_user_uids') ?? [];
      if (!savedUids.contains(uid)) {
        savedUids.add(uid);
        await _prefs.setStringList('saved_user_uids', savedUids);
      }

      await _prefs.setString('act_name_$uid', currentName);
      await _prefs.setString('act_email_$uid', currentEmail);
      await _prefs.setString('act_photo_$uid', currentPhoto);

      // 3. Faqat real qo'shilgan akkauntlarni yuklash (Hech qanday soxtalik yo'q)
      final List<Future<Map<String, String>?>> futures =
          savedUids.map((savedUid) async {
        try {
          String name = _prefs.getString('act_name_$savedUid') ?? 'Focus User';
          String email =
              _prefs.getString('act_email_$savedUid') ?? 'user@focusai.com';
          String photo = _prefs.getString('act_photo_$savedUid') ?? '';

          if (name == 'Focus User' && savedUid != uid) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(savedUid)
                .get();
            if (doc.exists) {
              name = doc.data()?['name'] ?? name;
              email = doc.data()?['email'] ?? email;
              photo = doc.data()?['photoUrl'] ?? photo;

              await _prefs.setString('act_name_$savedUid', name);
              await _prefs.setString('act_email_$savedUid', email);
              await _prefs.setString('act_photo_$savedUid', photo);
            }
          }

          return {
            'uid': savedUid,
            'name': name,
            'email': email,
            'photoUrl': photo,
          };
        } catch (_) {
          return null;
        }
      }).toList();

      final List<Map<String, String>?> rawAccounts = await Future.wait(futures);
      final List<Map<String, String>> tempAccounts =
          rawAccounts.whereType<Map<String, String>>().toList();

      if (mounted) {
        setState(() {
          _savedAccounts = tempAccounts;
        });
      }
    } catch (e) {
      debugPrint("Sinxronizatsiya xatosi: $e");
    }
  }

  /// ⚡ Akkauntni hamma joydan (kesh, Firestore va Firebase Auth) o'chirish funksiyasi
  Future<void> _deleteAccountFromList(String uid) async {
    AudioHapticService.triggerLightImpact();

    // 1. Local keshdan o'chirish
    List<String> savedUids = _prefs.getStringList('saved_user_uids') ?? [];
    savedUids.remove(uid);
    await _prefs.setStringList('saved_user_uids', savedUids);

    await _prefs.remove('act_name_$uid');
    await _prefs.remove('act_email_$uid');
    await _prefs.remove('act_photo_$uid');

    // 2. Agar o'chirilayotgan akkaunt hozirgi faol akkaunt bo'lsa
    if (_currentUser?.uid == uid) {
      try {
        // Firestore'dan foydalanuvchi hujjatini o'chirish
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // Firebase Auth'dan butkul o'chirib yuborish
        await _currentUser?.delete();
      } catch (e) {
        debugPrint(
            "Firebase'dan akkauntni o'chirishda xatolik (qayta avtorizatsiya talab qilinishi mumkin): $e");
        // Agarda foydalanuvchi tizimga kirganiga ko'p vaqt bo'lgan bo'lsa, delete() xato beradi.
        // Shuning uchun xatolik bo'lsa ham tizimdan chiqarib yuborish xavfsizroq.
      }

      _logoutAndGoToAuth();
    } else {
      // Agar boshqa akkaunt o'chirilayotgan bo'lsa, Firestore'dan ham o'chirish (ixtiyoriy)
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (_) {}

      _syncWithFirebaseAndLoadAccounts();
    }
  }

  ImageProvider? _getAvatarImageProvider(String? path) {
    if (path == null || path.isEmpty || path.startsWith('audio/')) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  /// Tezkor almashinuv oynasi (Quick Account Switcher)
  void _showAccountSwitcher(BuildContext context) {
    AudioHapticService.triggerLightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color neonCyan = Color(0xFF00FFCC);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              if (_savedAccounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(context.tr("Akkauntlar mavjud emas",
                      "No accounts available", "Нет доступных аккаунтов")),
                ),
              ..._savedAccounts.map((account) {
                final isSelected = account['uid'] == _currentUser?.uid;
                final avatar = _getAvatarImageProvider(account['photoUrl']);
                final targetUid = account['uid']!;

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? neonCyan.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[300],
                      backgroundImage: avatar,
                      child: avatar == null
                          ? Icon(Icons.person,
                              color: isDark ? Colors.white70 : Colors.black54)
                          : null,
                    ),
                    title: Text(
                      account['name']!,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      account['email']!,
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                    ),
                    // ⚡ TALAB: Tezkori oynada ham o'ng tomonda o'chirish (Delete) iconi bo'lishi
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: neonCyan, size: 20),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteAccountFromList(targetUid),
                        ),
                      ],
                    ),
                    onTap: () async {
                      Navigator.pop(bottomSheetCtx);
                      if (!isSelected) {
                        AudioHapticService.triggerLightImpact();

                        await _userStatsDataSource
                            .saveUsername(account['name']!);
                        await _userStatsDataSource
                            .saveAvatar(account['photoUrl']!);
                        await _prefs.setString('current_user_id', targetUid);

                        if (!mounted) return;

                        // ⚡ TALAB: Har safar akkaunt almashganda Splash_page'ga yo'naltirish
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const SplashPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                );
              }),
              const Divider(color: Colors.white10),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: neonCyan.withOpacity(0.1),
                  child: const Icon(Icons.add, color: neonCyan),
                ),
                title: Text(
                  context.tr(
                      'Hisob qo\'shish', 'Add Account', 'Добавить аккаунт'),
                  style: const TextStyle(
                      color: neonCyan, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _logoutAndGoToAuth(isAddingAccount: true);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logoutAndGoToAuth({bool isAddingAccount = false}) async {
    AudioHapticService.triggerLightImpact();
    AudioHapticService().stopBackgroundMusic();

    final habitBloc = context.read<HabitBloc>();
    await WidgetService.clearWidgetOnLogout();

    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}

    final currentUserId = _prefs.getString('current_user_id') ?? 'guest';
    if (!isAddingAccount) {
      await _prefs.remove('USER_NAME_$currentUserId');
      await _prefs.remove('USER_AVATAR_PATH_$currentUserId');
      await _prefs.remove('current_user_id');
    }

    // Yangi akkaunt qo'shish oson bo'lishi uchun birinchi marta kirgandek Auth oynasini ochamiz
    await _prefs.setBool('is_first_time', true);
    await _prefs.setBool('is_logged_in', false);
    await _prefs.setBool('is_guest', false);

    if (!mounted) return;

    habitBloc.add(LoadHabitsEvent());

    // 🔥 BU YERDA HAM TO'G'RIDAN-TO'G'RI AUTH SAHIFASIGA YO'NALTIRAMIZ:
    if (isAddingAccount) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) =>
                const AuthScreen()), // 👈 Bu yerga ham Login/Auth sahifangiz nomini yozing
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashPage()),
        (route) => false,
      );
    }
  }

  Future<void> _saveData(String key, String value) async {
    if (key == 'user_name') {
      await _userStatsDataSource.saveUsername(value);
    } else if (key == 'user_image') {
      await _userStatsDataSource.saveAvatar(value);
    }

    await _syncWithFirebaseAndLoadAccounts();

    if (!mounted) return;
    context.read<SettingsBloc>().add(
          ChangeLanguageEvent(
              context.read<SettingsBloc>().state.locale.languageCode),
        );
  }

  Future<void> _pickImage() async {
    AudioHapticService.triggerLightImpact();
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(pickedFile.path);
        final File savedImage =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');

        await _saveData('user_image', savedImage.path);

        if (mounted) {
          setState(() {
            _imagePath = savedImage.path;
          });
        }
        AudioHapticService.triggerLightImpact();
      } catch (e) {
        debugPrint("Rasmni saqlashda xatolik: $e");
      }
    }
  }

  String _getCleanTrackName(String path) {
    return path
        .replaceAll('audio/', '')
        .replaceAll('.mp3', '')
        .replaceAll('.m4a', '')
        .replaceAll('.flac', '')
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color neonCyan = Color(0xFF00FFCC);
    final currentAvatar = _getAvatarImageProvider(_imagePath);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () => _showAccountSwitcher(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.cardColor,
                  backgroundImage: currentAvatar,
                  child: currentAvatar == null
                      ? const Icon(Icons.person, size: 14, color: neonCyan)
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : 'Focus User',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: 16, color: isDark ? Colors.white54 : Colors.black54),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: theme.cardColor,
                      backgroundImage: currentAvatar,
                      child: currentAvatar == null
                          ? const FaIcon(FontAwesomeIcons.userAstronaut,
                              size: 44, color: neonCyan)
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: neonCyan),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: context.tr('Ismingizni tahrirlang', 'Edit your name',
                    'Редактировать имя'),
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
              textInputAction: TextInputAction.done,
              onTapOutside: (_) => _nameFocusNode.unfocus(),
            ),
            const Divider(color: Colors.white10, height: 24),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.language,
                        color: neonCyan, size: 20),
                    title: Text(
                      context.tr(
                          'Ilova tili', 'App Language', 'Язык приложения'),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500),
                    ),
                    trailing: BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        return DropdownButton<String>(
                          value: state.locale.languageCode,
                          dropdownColor: theme.cardColor,
                          underline: const SizedBox(),
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
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
                              AudioHapticService.triggerLightImpact();
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
                      context.tr('Tungi rejim', 'Dark Mode', 'Тёмный режим'),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500),
                    ),
                    trailing: Switch(
                      value: isDark,
                      activeColor: neonCyan,
                      onChanged: (val) {
                        AudioHapticService.triggerLightImpact();
                        context.read<SettingsBloc>().add(ToggleThemeEvent());
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        AudioHapticService().isMusicPlayingNotifier,
                    builder: (context, isMusicOn, child) {
                      return Column(
                        children: [
                          ListTile(
                            leading: FaIcon(
                              isMusicOn
                                  ? FontAwesomeIcons.music
                                  : FontAwesomeIcons.volumeXmark,
                              color: neonCyan,
                              size: 20,
                            ),
                            title: Text(
                              context.tr(
                                  'Fokus Fon Musiqasi',
                                  'Focus Background Music',
                                  'Фоновая музыка фокуса'),
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500),
                            ),
                            trailing: Switch(
                              value: isMusicOn,
                              activeColor: neonCyan,
                              onChanged: (val) {
                                AudioHapticService.triggerLightImpact();
                                if (val) {
                                  AudioHapticService().playBackgroundMusic();
                                } else {
                                  AudioHapticService().pauseBackgroundMusic();
                                }
                              },
                            ),
                          ),
                          if (isMusicOn) ...[
                            const Divider(color: Colors.white10, height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                children: AudioHapticService()
                                    .focusMusicList
                                    .map((String fullTrackPath) {
                                  return RadioListTile<String>(
                                    title: Text(
                                      _getCleanTrackName(fullTrackPath),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: fullTrackPath,
                                    groupValue:
                                        AudioHapticService().currentTrack,
                                    activeColor: neonCyan,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    onChanged: (value) {
                                      if (value != null) {
                                        AudioHapticService.triggerLightImpact();
                                        setState(() {
                                          AudioHapticService()
                                              .changeTrack(value);
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.redAccent.withOpacity(0.02),
                ),
                icon: const FaIcon(FontAwesomeIcons.rightFromBracket,
                    color: Colors.redAccent, size: 18),
                label: Text(
                  context.tr('Tizimdan Chiqish', 'Logout', 'Выйти из системы'),
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                onPressed: () => _logoutAndGoToAuth(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
