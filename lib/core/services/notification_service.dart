import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Klasdan obyekt olishni cheklash uchun xususiy konstruktor
  const NotificationService._();

  static final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  // Tasodifiy sonlar generatori (Xotirani tejash uchun yagona namuna)
  static final Random _random = Random();

  // 🔔 Foydalanuvchini odat qilishga chaqiruvchi do'stona tasodifiy matnlar
  static const List<String> _reminderMessages = [
    "Hey, bugun odatlaringni qilmaysanmi? Kutib qoldim-ku! 👀",
    "Do'stim, maqsadlar esdan chiqdimi? Dangasalikni yengamiz, qani ketdik! 💪",
    "Fokus vaqti bo'ldi! Telefonni chetga sur va maqsading sari bir qadam tashla! 🚀",
    "O'zingga bergan va'dang yodingdami? Focus AI seni kutmoqda! 🔥",
    "Muvaffaqiyat zinalari o'z-o'zidan qurilmaydi, bugungi vazifani ham bajarib qo'yamiz-a? 😉"
  ];

  // 🎉 Odat 100% bo'lib tugaganda chiqadigan quvonarli do'stona tabriklar
  static const List<String> _successMessages = [
    "Fokus taymeringiz 100% bo'ldi! G'alaba muborak! 🎉",
    "Daxshat! Bugun ajoyib natija ko'rsatdingiz. Marra bizniki! 🏆",
    "Yana bir to'lgan jarayon paneli! Siz endi kechagidanda kuchliroqsiz! 🌟",
    "Matonatingizga qoyil! Shunday davom eting, maqsad sari olg'a! 👑"
  ];

  // --- TASODIFIY MATN OLISH FUNKSIYALARI ---

  static String getRandomReminder() {
    return _reminderMessages[_random.nextInt(_reminderMessages.length)];
  }

  static String getRandomSuccess() {
    return _successMessages[_random.nextInt(_successMessages.length)];
  }

  // --- INIT (BILDIRISHNOMALARNI SOZLASH) ---

  static Future<void> init() async {
    // 🌍 Vaqt zonalarini ilova ishga tushganda sozlash
    tz.initializeTimeZones();
    // Mahalliy vaqt zonasini aniqlash (O'zbekiston vaqti uchun)
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    final fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) {},
    );

    // 🔔 ANDROID 13+ UCHUN BILDIRISHNOMA RUXSATINI SO'RASH
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  // --- SCHEDULE (ESLATMA REJALASHTIRISH) ---

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour, // 🕐 Soat (masalan: 18)
    required int minute, // 🕒 Daqiqa (masalan: 30)
    required int
        dayOfWeek, // 📅 Haftaning kuni (1 = Dushanba, ..., 7 = Yakshanba)
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
      'habit_scheduled_channel_id',
      'Rejalashtirilgan Odatlar',
      channelDescription: 'Belgilangan vaqtda keladigan eslatmalar',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      playSound: true,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const fln.NotificationDetails(
        android: androidPlatformChannelSpecifics,
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
