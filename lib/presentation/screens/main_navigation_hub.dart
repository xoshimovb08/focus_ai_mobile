import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';
import 'package:focus_ai/presentation/pages/splash/splash_page.dart'; // SplashPage import qilindi

// Bloklar va Utils
import '../blocs/habit/habit_bloc.dart';
import '../utils/lang_extension.dart';
import '../../data/datasources/user_stats_datasource.dart';
import '../../services/service_locator.dart';

// Ekranlar
import 'auth_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'ai_coach_screen.dart';
import 'settings_screen.dart';
import 'add_habit_screen.dart';

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  Map<String, String>? _currentUser;
  List<Map<String, String>> _savedAccounts = [];
  late final UserStatsDataSource _userStatsDataSource;
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const AiCoachScreen(),
      const StatsScreen(),
      const ProfileScreen(),
    ];
    _prefs = sl<SharedPreferences>();
    _userStatsDataSource = UserStatsDataSource(_prefs);
    _loadCurrentAccount();
  }

  /// 🔄 Akkaunt ma'lumotlarini keshdan yuklash va sinxronlash
  Future<void> _loadCurrentAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. UserStatsDataSource orqali real saqlangan akkauntlar ro'yxatini yuklash
    _savedAccounts = _userStatsDataSource.getSavedAccounts();

    // 2. Agar ro'yxat bo'sh bo'lsa yoki Firebase'da yangi foydalanuvchi bo'lsa, birlamchi ro'yxat tuzamiz
    if (_savedAccounts.isEmpty && user != null) {
      final localName = _userStatsDataSource.getUsername();
      final localAvatar = _userStatsDataSource.getAvatar();

      await _userStatsDataSource.saveAccountToList(
        uid: user.uid,
        name: localName.isNotEmpty ? localName : (user.displayName ?? ''),
        email: user.email ?? '',
        photoUrl: localAvatar.isNotEmpty ? localAvatar : (user.photoURL ?? ''),
      );

      // Yangilangan ro'yxatni qayta o'qiymiz
      _savedAccounts = _userStatsDataSource.getSavedAccounts();
    }

    // 3. Aktiv (hozirgi foydalanuvchi) ID'sini xotiradan tekshiramiz
    final savedActiveUid = _prefs.getString('current_user_id');

    setState(() {
      if (_savedAccounts.isNotEmpty) {
        _currentUser = _savedAccounts.firstWhere(
          (acc) => acc['uid'] == savedActiveUid,
          orElse: () => _savedAccounts.first,
        );

        // Sinxronizatsiya: UserStatsDataSource ichidagi keshni ham joriy hisobga moslaymiz
        _userStatsDataSource.saveUsername(_currentUser!['name']!);
        _userStatsDataSource.saveAvatar(_currentUser!['photoUrl']!);
        _prefs.setString('current_user_id', _currentUser!['uid']!);
      }
    });
  }

  /// 🔄 Akkauntni login oynasiga chiqmasdan tezkor almashtirish funksiyasi
  Future<void> _switchAccount(Map<String, String> selectedAccount) async {
    setState(() {
      _currentUser = selectedAccount;
    });

    // 1. Yangi tanlangan hisob ma'lumotlarini telefonga xotirlaymiz
    await _userStatsDataSource.saveUsername(selectedAccount['name']!);
    await _userStatsDataSource.saveAvatar(selectedAccount['photoUrl']!);
    await _prefs.setString('current_user_id', selectedAccount['uid']!);

    // 2. Navigatsiyani yangilash va xabarnoma ko'rsatish
    if (!mounted) return;

    // settingsState xatoligini oldini olish uchun joriy state'ni o'qib olamiz
    final currentSettingsState = context.read<SettingsBloc>().state;
    context.read<SettingsBloc>().add(
          ChangeLanguageEvent(currentSettingsState.locale.languageCode),
        );

    // 🚀 Akkaunt almashganda Splash ekranni integratsiya qilish
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashPage()),
      (route) => false,
    );
  }

  /// ⚡ Tezkor almashtirish (Double Tap qilinganda)
  void _handleFastAccountSwitch() {
    if (_savedAccounts.length > 1 && _currentUser != null) {
      final alternativeAccount = _savedAccounts.firstWhere(
        (acc) => acc['uid'] != _currentUser!['uid'],
        orElse: () => _savedAccounts.first,
      );

      _switchAccount(alternativeAccount);
    }
  }

  /// 📱 Ikkala tugma uchun yagona universal Bottom Sheet oynasi
  void _showAccountSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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

                  // Saqlangan hamma akkauntlarni dinamik chiqarish
                  ..._savedAccounts.map((account) {
                    final isSelected = account['uid'] == _currentUser?['uid'];
                    final bool isNetworkImage =
                        account['photoUrl']!.startsWith('http');
                    final bool isLocalFile = !isNetworkImage &&
                        account['photoUrl']!.isNotEmpty &&
                        File(account['photoUrl']!).existsSync();

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[300],
                          backgroundImage: isNetworkImage
                              ? NetworkImage(account['photoUrl']!)
                              : (isLocalFile
                                  ? FileImage(File(account['photoUrl']!))
                                  : null) as ImageProvider?,
                          child: (account['photoUrl']!.isEmpty ||
                                  (!isNetworkImage && !isLocalFile))
                              ? Icon(Icons.person,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54)
                              : null,
                        ),
                        title: Text(
                          account['name']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          account['email']!,
                          style:
                              TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ❌ Akkaunt o'chirish tugmasi (Delete Icon)
                            if (!isSelected)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  await _userStatsDataSource
                                      .deleteAccountFromList(account['uid']!);
                                  // Asosiy va modal oynadagi listlarni real vaqtda yangilash
                                  _savedAccounts =
                                      _userStatsDataSource.getSavedAccounts();
                                  setModalState(() {});
                                  setState(() {});
                                },
                              ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: theme.primaryColor),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetCtx);
                          if (!isSelected) {
                            _switchAccount(account);
                          }
                        },
                      ),
                    );
                  }),

                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.add, color: theme.primaryColor),
                    ),
                    title: Text(
                      context.tr(
                          'Hisob qo\'shish', 'Add Account', 'Добавить аккаунт'),
                      style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold),
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
      },
    );
  }

  /// 🚪 Tizimdan chiqish va xavfsiz tozalash
  Future<void> _logoutAndGoToAuth({bool isAddingAccount = false}) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!isAddingAccount) {
      final currentUserId = _prefs.getString('current_user_id') ?? 'guest';
      await _prefs.remove('USER_NAME_$currentUserId');
      await _prefs.remove('USER_AVATAR_PATH_$currentUserId');
      await _prefs.remove('current_user_id');
      await _prefs.remove('saved_focus_ai_accounts');
    }

    await _prefs.setBool('is_logged_in', false);
    await _prefs.setBool('is_guest', false);

    if (!mounted) return;
    context.read<HabitBloc>().add(LoadHabitsEvent());

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: theme.primaryColor),
            const SizedBox(width: 10),
            Text(
              context.tr(
                  'Yo\'riqnoma & Info', 'Guide & Info', 'Инструкция & Инфо'),
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Zinalar va ball tizimi
              _buildInfoSection(
                context,
                context.tr(
                    "🔥 Zinalar nima va ball qanday to'planadi?",
                    "🔥 What are levels and how to score?",
                    "🔥 Что такое уровни и как набирать очки?"),
                context.tr(
                  "Har gal belgilangan odat taymerini muvaffaqiyatli yakunlaganingizda sizga ball yoziladi va olovli kunlik zanjiringiz (Streak) ortadi.",
                  "Every time you successfully complete a habit timer, you score points and your streak increases.",
                  "Каждый раз, когда вы успешно завершаете таймер привычки, вы получаете очки, а ваш стрик увеличивается.",
                ),
              ),
              const SizedBox(height: 12),

              // 2. AI Murabbiy
              _buildInfoSection(
                context,
                context.tr(
                    "🤖 AI Murabbiy bilan qanday gaplashaman?",
                    "🤖 How to talk to AI Coach?",
                    "🤖 Как общаться с AI Тренером?"),
                context.tr(
                  "Pastki navigatsiya panelidan 'AI Murabbiy' bo'limiga o'ting. U yerda sun'iy intellekt sizga kunlik rejalar tuzishda va motivatsiyani ushlab turishda yordam beradi.",
                  "Go to 'AI Coach' from the bottom navigation. AI will help you stay motivated and build your daily routine.",
                  "Перейдите в раздел 'AI Тренер' на нижней панели. ИИ поможет вам с планами и поддержит мотивацию.",
                ),
              ),
              const SizedBox(height: 12),

              // 3. Yangi odat yaratish
              _buildInfoSection(
                context,
                context.tr(
                    "➕ Yangi odat qanday yaratiladi?",
                    "➕ How to create a new habit?",
                    "➕ Как создать новую привычку?"),
                context.tr(
                  "Bosh ekrandagi 'Yangi Odat Qo'shish' tugmasini bosing, unga mos belgi (icon), rang va maqsad qilingan umumiy soatni belgilab saqlang.",
                  "Tap 'Add Habit' button on the dashboard, choose an icon, color, set target hours and save it.",
                  "Нажмите 'Добавить привычку' на главном экране, выберите иконку, цвет, задайте целевые часы и сохраните.",
                ),
              ),
              const SizedBox(height: 12),

              // 4. Profil va Sozlamalar menyusi (Siz so'ragan qism)
              _buildInfoSection(
                context,
                context.tr(
                    "👤 Profil va Sozlamalarda nimalar bor?",
                    "👤 What is inside Profile and Settings?",
                    "👤 Что находится в Профиле и Настройках?"),
                context.tr(
                  "Profil rasmingizni bossangiz, shaxsiy ma'lumotlaringiz ochiladi. U yerda ilova tilini o'zgartirishingiz, yorug'/to'q (Light/Dark) rejimlarni yoqishingiz yoki hisobingizdan chiqishingiz (Logout) mumkin.",
                  "Tapping your profile reveals personal settings. You can switch languages, toggle Light/Dark themes, or safely Log Out from your account.",
                  "Нажатие на профиль открывает личные настройки. Вы можете изменить язык, переключить светлую/темную тему или выйти из аккаунта.",
                ),
              ),
              const SizedBox(height: 12),

              // 5. Maxfiy kalendar konvertlari (Kreativ funksiya)
              _buildInfoSection(
                context,
                context.tr(
                    "✉️ Kalendardagi konvertlar nima?",
                    "✉️ What are the envelopes in the calendar?",
                    "✉️ Что за конверты в календаре?"),
                context.tr(
                  "Bu — kelajakdagi o'zingizga motivatsiya! Kalendardan o'zingiz yetib bormagan kunni tanlab, maxfiy xat berkitib qo'yasiz. Unga faqat o'sha kunlik marraga (Streak) yetib kelgandagina ruxsat ochiladi.",
                  "It's a motivation for your future self! Pick an upcoming day on the calendar, leave a secret note, and it will unlock only when you reach that day's streak.",
                  "Это мотивация для будущего себя! Выберите предстоящий день в календаре, оставьте секретное письмо, и оно откроется только тогда, когда вы дойдете до этого дня.",
                ),
              ),
              const SizedBox(height: 12),

              // 6. Shartnomalar (Contracts Screen)
              _buildInfoSection(
                context,
                context.tr(
                    "🤝 Odat shartnomasi (Contracts) nima?",
                    "🤝 What is a Habit Contract?",
                    "🤝 Что такое контракт привычки?"),
                context.tr(
                  "Bu o'z-o'zingiz bilan tuzadigan jiddiy va'da! Biror odatni tashlamaslikka qasam ichasiz. Agar va'dangizni buzib, taymerni bajarmasangiz, tizim buni qayd etadi. Bu mas'uliyatni oshirish uchun eng zo'r yechim.",
                  "It's a serious promise to yourself! You commit to not giving up on a habit. If you break the promise and skip the timer, the app tracks it. Great for self-discipline.",
                  "Это серьезное обещание самому себе! Вы обязуетесь не бросать привычку. Если вы нарушите обещание и пропустите таймер, приложение это зафиксирует.",
                ),
              ),
              const SizedBox(height: 12),

              // 7. Telefonsiz vaqt rejimi (Yuztuban / Flip mode)
              _buildInfoSection(
                context,
                context.tr(
                    "📱 Yuztuban (Flip) rejimi qanday ishlaydi?",
                    "📱 How does Flip-to-Focus mode work?",
                    "📱 Как работает режим переворота телефона?"),
                context.tr(
                  "Fokus taymerini yoqing va telefoningizni ekrani bilan pastga qaratib (yuztuban) stolga qo'ying. Akselerometr buni aniqlaydi va sizga telefondan chalg'imaganingiz uchun qo'shimcha bonus ballar taqdim etadi!",
                  "Start the focus timer and place your phone screen-down on the table. The accelerometer detects it and grants you extra bonus points for staying away from your phone!",
                  "Запустите таймер фокуса и положите телефон экраном вниз на стол. Акселерометр обнаружит это и начислит бонусные очки за то, что вы не отвлекались!",
                ),
              ),
              const SizedBox(height: 12),

              // 8. Audio fon va Haptic (Yumshoq musiqa)
              _buildInfoSection(
                context,
                context.tr(
                    "🎵 Fokus uchun fon musiqalarini qanday yoqaman?",
                    "🎵 How do I turn on background music for focus?",
                    "🎵 Как включить фоновую музыку для фокуса?"),
                context.tr(
                  "Taymer ishlayotgan vaqtda ekrandagi musiqa belgisini bosing. U yerda diqqatni jamlashga yordam beradigan yumshoq  ohanglarinio  yoqishingiz mumkin. Shuningdek, sessiya boshlanganda va tugaganda yengil tebranish (vibratsiya) his qilasiz.",
                  "Tap the music icon on the screen while the timer is running. There you can turn on soft lo-fi tunes or rain sounds to help you focus. You will also feel a gentle vibration when the session starts and ends.",
                  "Нажмите на иконку музыки на экране во время работы таймера. Там вы можете включить мягкие lo-fi мелодии или звуки дождя, которые помогут вам сосредоточиться. Вы также почувствуете легкую вибрацию в начале и конце сессии.",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              context.tr('Tushunarli', 'Got it', 'Понятно'),
              style: TextStyle(
                  color: theme.primaryColor, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final userPhotoUrl = _userStatsDataSource.getAvatar();
        final bool isNetworkImage = userPhotoUrl.startsWith('http');
        final bool isLocalFile = !isNetworkImage &&
            userPhotoUrl.isNotEmpty &&
            File(userPhotoUrl).existsSync();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor ??
                (isDark ? const Color.fromARGB(255, 28, 28, 39) : Colors.white),
            elevation: 0,
            iconTheme: IconThemeData(color: theme.primaryColor),
            title: GestureDetector(
              onTap: () => _showAccountSwitcher(context),
              child: const Text(
                'Focus AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: BlocBuilder<HabitBloc, HabitState>(
                  buildWhen: (previous, current) =>
                      previous.currentStreak != current.currentStreak ||
                      previous.totalScore != current.totalScore,
                  builder: (context, habitState) {
                    return Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.fire,
                            color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${habitState.currentStreak}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 14),
                        FaIcon(FontAwesomeIcons.award,
                            color: theme.primaryColor, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${habitState.totalScore}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: theme.cardColor),
                    child: Center(
                      child: Text(
                        context.tr(
                            'Focus AI Menyu', 'Focus AI Menu', 'Focus AI Меню'),
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.help_outline, color: theme.primaryColor),
                    title: Text(context.tr('Ilovadan foydalanish (Info)',
                        'How to use (Info)', 'Инструкция (Инфо)')),
                    onTap: () {
                      Navigator.pop(context);
                      _showInfoDialog(context);
                    },
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.add_box_outlined, color: theme.primaryColor),
                    title: Text(context.tr('Yangi Odat Qo\'shish',
                        'Add New Habit', 'Добавить привычку')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddHabitScreen()));
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings_outlined,
                        color: theme.primaryColor),
                    title:
                        Text(context.tr('Sozlamalar', 'Settings', 'Настройки')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()));
                    },
                  ),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(context.tr('Chiqish', 'Log Out', 'Выйти'),
                        style: const TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      _logoutAndGoToAuth();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.cardColor,
            selectedItemColor: theme.primaryColor,
            unselectedItemColor:
                isDark ? const Color(0xFF8F8F9E) : Colors.black38,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.check_circle_outline),
                label: context.tr('Odatlar', 'Habits', 'Привычки'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.psychology),
                label: context.tr('AI Murabbiy', 'AI Coach', 'AI Тренер'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.local_fire_department),
                label: context.tr('Zina', 'Stats', 'Статистика'),
              ),
              BottomNavigationBarItem(
                icon: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _currentIndex = 3);
                  },
                  onDoubleTap: _handleFastAccountSwitch,
                  onLongPress: () => _showAccountSwitcher(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentIndex == 3
                            ? theme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.transparent,
                      backgroundImage: isNetworkImage
                          ? NetworkImage(userPhotoUrl)
                          : (isLocalFile ? FileImage(File(userPhotoUrl)) : null)
                              as ImageProvider?,
                      child: (userPhotoUrl.isEmpty ||
                              (!isNetworkImage && !isLocalFile))
                          ? Icon(Icons.person,
                              size: 14, color: theme.primaryColor)
                          : null,
                    ),
                  ),
                ),
                label: context.tr('Profil', 'Profile', 'Профиль'),
              ),
            ],
          ),
        );
      },
    );
  }
}
