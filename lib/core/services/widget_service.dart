import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  // Klasdan obyekt olishni cheklash uchun xususiy konstruktor
  const WidgetService._();

  // Guruh ID yangi paket nomiga moslashtirildi
  static const String groupId = 'group.com.example.focus_ai';
  static const String androidProvider = 'HomeWidgetProvider';
  static const String _prefKey = 'is_widget_prompted';
  static const String _installedKey = 'is_widget_installed';

  // Guruh sozlamalarini faollashtirish (iOS va ba'zi Android tizimlar uchun zarur)
  static void _initGroupId() {
    HomeWidget.setAppGroupId(groupId);
  }

  // 🔍 Ekrandan vidjet bor-yo'gligini SharedPreferences orqali xavfsiz tekshirish
  static Future<bool> isWidgetInstalled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_installedKey) ?? false;
    } catch (e) {
      debugPrint("Vidjet holatini tekshirishda xatolik: $e");
      return false;
    }
  }

  // ⚡ Faqat birinchi marta o'rnatilganda so'rash
  static Future<void> requestToPinWidgetIfNeeded() async {
    _initGroupId();
    final prefs = await SharedPreferences.getInstance();
    final bool isPrompted = prefs.getBool(_prefKey) ?? false;

    if (!isPrompted) {
      try {
        bool? isRequestPinnedSupported =
            await HomeWidget.isRequestPinWidgetSupported();
        if (isRequestPinnedSupported == true) {
          await HomeWidget.requestPinWidget(name: androidProvider);
          await prefs.setBool(_prefKey, true);
          await prefs.setBool(
              _installedKey, true); // O'rnatildi deb belgilaymiz
        }
      } catch (e) {
        debugPrint("Vidjet qo'shish so'rovida xatolik: $e");
      }
    }
  }

  // ⚙️ Sozlamalardan turib qo'shish yoki o'chirish (Switch uchun)
  static Future<bool> toggleWidget(bool enable) async {
    _initGroupId();
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      try {
        bool? isSupported = await HomeWidget.isRequestPinWidgetSupported();
        if (isSupported == true) {
          await HomeWidget.requestPinWidget(name: androidProvider);
          await prefs.setBool(_installedKey, true);
          return true;
        }
      } catch (e) {
        debugPrint("Vidjetni yoqishda xatolik: $e");
      }
      return false;
    } else {
      try {
        // Ma'lumotni tozalaymiz va o'chdi deb belgilaymiz
        await HomeWidget.saveWidgetData<String>('days_count', 'O\'chiq');
        await HomeWidget.updateWidget(name: androidProvider);
        await prefs.setBool(_installedKey, false);
      } catch (e) {
        debugPrint("Vidjetni o'chirishda xatolik: $e");
      }
      return false;
    }
  }

  // 🔄 Ma'lumotni yangilash (Zinalar bo'limidan kelgan kunni ekrandagi vidjetga chiqaradi)
  static Future<void> updateWidgetData({required dynamic days}) async {
    _initGroupId();
    try {
      final String resultText = days is int ? '$days-kun' : days.toString();

      await HomeWidget.saveWidgetData<String>('days_count', resultText);
      await HomeWidget.updateWidget(name: androidProvider);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_installedKey, true);
    } catch (e) {
      debugPrint("Vidjetni yangilashda xatolik: $e");
    }
  }

  // 🚪 Akkaunt almashganda yoki tizimdan chiqqanda vidjetni tozalash funksiyasi
  static Future<void> clearWidgetOnLogout() async {
    _initGroupId();
    try {
      await HomeWidget.saveWidgetData<String>('days_count', '0-kun');
      await HomeWidget.updateWidget(name: androidProvider);
    } catch (e) {
      debugPrint("Vidjetni tozalashda xatolik: $e");
    }
  }
}
