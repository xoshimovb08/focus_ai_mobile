# 🚀 Focus AI — Geymifikatsiyalangan Fokus va Odatlar Tracker

**Focus AI** — bu "Konkurs TZ" talablari asosida maxsus ishlab chiqilgan, ilg'or algoritmlar, sun'iy intellekt murabbiysi hamda geymifikatsiya (o'yinlashtirilgan intizom) tizimiga ega mobil ilova. Ilova Clean Architecture (Toza arxitektura) tamoyillari va real-time sensor integratsiyalari asosida yozilgan.

---

## 🛠️ Ishlatilgan Texnologiyalar va Kutubxonalar

Loyihaning barqarorligi, tezkorligi va kengayuvchanligini ta'minlash uchun sanoat standartidagi eng ishonchli texnologik stek tanlangan:

- **Asosiy Karkas:** [Flutter SDK](https://flutter.dev) (Dart tili, Null-safety to'liq ta'minlangan).
- **Holat Boshqaruvi (State Management):** `flutter_bloc` (v9.1+) & `equatable` — ilova holatlarini (State) reaktiv, xavfsiz va xotirani tejaydigan ko'rinishda boshqarish uchun.
- **Sun'iy Intellekt (AI Coach):** Hugging Face API (`Qwen/Qwen2.5-7B-Instruct` modeli) — o'zbek tilida mukammal va grammatik to'g'ri so'zlashuvchi motivatsion shaxsiy murabbiy. O'zbekcha harflar buzilmasligi uchun `utf8.decode` filtrlari qo'llangan.
- **Ma'lumotlar Bazasi va Bulut (Backend):**
  - `firebase_core`, `firebase_auth`, `cloud_firestore` — real-time ma'lumotlar sinxronizatsiyasi va multi-account tizimi uchun.
  - `shared_preferences` — offlayn kesh, foydalanuvchi sozlamalari va lokal statlarni saqlash uchun.
- **Datchiklar va Sensorlar:** `sensors_plus` — foydalanuvchi odat taymerini yoqib, telefonini yuztuban (ekrani pastga qaratib) qo'yganini akselerometr yordamida aniqlash mantiqi (`isFaceDown`).
- **UI/UX va Grafika:** `flutter_animate`, `font_awesome_flutter`, `lottie`, `fl_chart` — interaktiv chiziqli grafiklar va silliq neon UI elementlari uchun.
- **Tizimli Xizmatlar:**
  - `audioplayers` (v6.8+) — fokus paytida fonda chalinuvchi musiqalar menejeri.
  - `flutter_local_notifications` & `timezone` — haftalik va kunlik rejalashtirilgan aqlli eslatmalar.
  - `home_widget` — Android ishchi stoliga (Home Screen) streak kunlarini chiqaruvchi vidjet xizmati.
  - `get_it` — Dependency Injection (Servislarni bog'lash) uchun.

---

## 🏗️ Arxitektura va Kod Strukturasi (Clean Architecture)

Loyiha qat'iy ravishda **Clean Architecture** hamda **SOLID** tamoyillariga asoslangan bo'lib, kodlar 3 ta asosiy qatlamga ajratilgan:

1.  **Core / Servislar:** Global konstantalar (`AppColors`), umumiy servislar (`AudioHapticService`, `NotificationService`, `WidgetService`).
2.  **Data Layer (Ma'lumotlar qatlami):** API va ma'lumotlar manbalari (`HabitLocalDataSource`, `UserStatsDataSource`). Mahalliy ma'lumotlar keshlanganda har bir foydalanuvchi uchun alohida prefiks (`${currentUserId}_...`) ishlatilgan, bu esa multi-account tizimida ma'lumotlar aralashib ketmasligini ta'minlaydi.
3.  **Domain Layer (Biznes mantiq):** Ilovaning asosiy qoidalari va modellari (`Habit` entity va `HabitStatus` enumlari).
4.  **Presentation Layer (UI va BLoC):** Foydalanuvchi ko'radigan ekranlar va ularning holatini boshqaruvchi BLoC komponentlari (`HabitBloc`, `SettingsBloc`).

---

## 📌 Asosiy Imkoniyatlar va Biznes Qoidalari

- **Aniq Timestamp Taymer Algoritmi:** Vaqt hisoblagichi oddiy periodik taymer emas, balki xavfsiz formula asosida ishlaydi:  
   $$\text{O'tgan vaqt} = \text{accumulatedMs} + (\text{Hozirgi vaqt} - \text{runningSince})$$  
   Bu algoritm tufayli ilova fonda o'chirib tashlansa yoki telefon o'chib yonsa ham fokus vaqti yo'qolmaydi va aniq hisoblanishda davom etadi.
- **Zinalar va Streak Qoidasi (Geymifikatsiya):** Foydalanuvchi ilovadan foydalangan sari muvaffaqiyat zinalari ochilib boradi va har bir kunga motivatsion konvert qaydlari yoziladi. Agar foydalanuvchi ketma-ket **5 kundan ko'p** ilovaga kirmasa, uning barcha zinalari va streak kunlari avtomatik ravishda `0` ga tushadi.
- **Hftalik Smart Kelishuvlar (Smart Contracts):** Foydalanuvchi o'z ballarini garovga tikib haftalik fokus rejasini tuzadi. Agar u maqsadga erisha olmay taslim bo'lsa (`GiveUp`), tizim undan shafqatsizlarcha **15 jazo balli** chegirib tashlaydi.
- **Ko'p Akkauntli Tizim (Multi-Account & Fast Switch):** Profil bo'limida foydalanuvchilar o'zlarining boshqa akkauntlariga profillar ustiga ikki marta bosish (`onDoubleTap`) orqali parolsiz va tezkor o'ta oladilar.
- **Mehmon Rejimi (Guest Mode):** Ro'yxatdan o'tishni xohlamagan foydalanuvchilar uchun Firebase talab qilmasdan, barcha funksiyalarni lokal xotirada to'liq ishlatish imkoniyati mavjud.

---

## 🛠️ Loyihani Ishga Tushirish Qadamlari

Ilovani o'z kompyuteringizda xatoliksiz va muammosiz ishga tushirish uchun quyidagi ko'rsatmalarga amal qiling:

### 1. Loyihani yuklab oling va papkaga kiring

Terminal orqali loyiha joylashgan katalogga o'ting:

```bash
cd E:\FlutterProjects\focus_ai
```
"# focus_ai_mobile" 
