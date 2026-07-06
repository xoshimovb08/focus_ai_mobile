import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // 📂 Doimiy papka bilan ishlash uchun
import 'package:path/path.dart' as path; // 📝 Fayl nomini ajratish uchun
import '../../domain/entities/habit.dart';
import '../blocs/habit/habit_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import 'package:focus_ai/presentation/utils/lang_extension.dart';
import 'package:focus_ai/core/constants/app_colors.dart';
import 'package:focus_ai/core/services/notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // 📍 Tahrirlash uchun ixtiyoriy habit obyekti

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  String? _selectedImagePath;
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();

  final int _selectedMinutes = 30;
  final String _selectedIcon = 'star';
  bool _isAiLoading = false; // 🤖 AI yuklanish holati uchun

  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<Map<String, dynamic>> _weekDays = [
    {"uz": "Du", "en": "Mo", "ru": "Пн", "isSelected": false, "value": 1},
    {"uz": "Se", "en": "Tu", "ru": "Вт", "isSelected": false, "value": 2},
    {"uz": "Cho", "en": "We", "ru": "Ср", "isSelected": false, "value": 3},
    {"uz": "Pa", "en": "Th", "ru": "Чт", "isSelected": false, "value": 4},
    {"uz": "Ju", "en": "Fr", "ru": "Пт", "isSelected": false, "value": 5},
    {"uz": "Sha", "en": "Sa", "ru": "Сб", "isSelected": false, "value": 6},
    {"uz": "Yak", "en": "Su", "ru": "Вс", "isSelected": false, "value": 7},
  ];

  // 📍 Tahrirlash rejimi ekanligini aniqlash bayrog'i
  bool get _isEditMode => widget.habit != null;

  @override
  void initState() {
    super.initState();
    // 📍 Agar tahrirlash rejimi bo'lsa, ma'lumotlarni maydonlarga yuklaymiz
    if (_isEditMode) {
      final h = widget.habit!;
      _titleController.text = h.title;
      _durationController.text = h.goalMinutes.toString();
      _selectedImagePath = h.imagePath;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickHabitImage() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        // 💾 Rasmni vaqtinchalik keshdan doimiy (Application Documents) papkaga ko'chiramiz
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(pickedFile.path);
        final File localImage =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          _selectedImagePath =
              localImage.path; // Endi xavfsiz doimiy manzil saqlanadi
        });
      }
    } catch (e) {
      debugPrint("Rasm tanlash yoki nusxalashda xatolik: $e");
    }
  }

  // 🤖 Gemini AI simulyatsiyasi
  void _suggestOptimalTime() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              "Avval odat nomini kiriting!",
              "Enter habit title first!",
              "Сначала введите название привычки!",
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isAiLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _selectedTime = const TimeOfDay(hour: 7, minute: 0);
      _isAiLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            context.tr(
              "Gemini AI: Ushbu odat uchun tonggi soat 07:00 eng optimal vaqt deb topildi! ⚡",
              "Gemini AI: 07:00 AM is found to be optimal for this habit! ⚡",
              "Gemini AI: 07:00 утра — оптимальное время для этой привычки! ⚡",
            ),
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final Color primaryColor = AppColors.primary;
        final Color cardBackground =
            isDark ? AppColors.cardBg : theme.cardColor;
        final Color backgroundColor =
            isDark ? AppColors.background : theme.scaffoldBackgroundColor;
        final Color textColor = isDark
            ? AppColors.textMain
            : (theme.textTheme.bodyLarge?.color ?? Colors.black);

        return BlocListener<HabitBloc, HabitState>(
          listener: (context, state) {},
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                _isEditMode
                    ? context.tr("Odatni Tahrirlash", "Edit Habit",
                        "Редактировать привычку")
                    : context.tr("Yangi Odat Qo'shish", "Add New Habit",
                        "Добавить новую привычку"),
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              iconTheme: IconThemeData(color: textColor),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepHeader(
                    stepNumber: "1",
                    title: context.tr("Odat sarlavhasi va turi",
                        "Habit title and type", "Название и тип привычки"),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: context.tr("Odat nomini kiriting",
                          "Enter habit title", "Введите название привычки"),
                      hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                      filled: true,
                      fillColor: cardBackground,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr(
                        "Odat davomiyligi (daqiqa)",
                        "Habit duration (minutes)",
                        "Продолжительность (минуты)"),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _durationController,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: context.tr("Vaqtni kiriting (daqiqa)",
                          "Enter duration (minutes)", "Введите время (минуты)"),
                      hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
                      filled: true,
                      fillColor: cardBackground,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _StepHeader(
                    stepNumber: "2",
                    title: context.tr(
                        "Odat uchun vizual rasm (Ixtiyoriy)",
                        "Visual image for habit (Optional)",
                        "Визуальное фото (Опционально)"),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickHabitImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImagePath != null &&
                                  _selectedImagePath!.isNotEmpty
                              ? primaryColor
                              : (isDark ? Colors.white10 : Colors.black12),
                          width: 1,
                        ),
                      ),
                      child: _selectedImagePath != null &&
                              _selectedImagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: _selectedImagePath!.startsWith('http') ||
                                      !_selectedImagePath!.contains('/')
                                  ? const Icon(Icons.broken_image, size: 40)
                                  : Image.file(
                                      File(_selectedImagePath!),
                                      fit: BoxFit.cover,
                                      // 🛡️ Agar fayl tizimda topilmasa, qizil xoch o'rniga xatolikni ushlab qolib, chiroyli ikonka qaytaramiz
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: cardBackground,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image_not_supported,
                                                  color: primaryColor,
                                                  size: 36),
                                              const SizedBox(height: 4),
                                              Text(
                                                context.tr(
                                                    "Rasm topilmadi",
                                                    "Image not found",
                                                    "Фото не найдено"),
                                                style: TextStyle(
                                                    color: textColor
                                                        .withOpacity(0.5),
                                                    fontSize: 12),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    color: primaryColor, size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(
                                      "Galereyadan maxsus rasm biriktirish",
                                      "Attach custom image from gallery",
                                      "Прикрепить фото из галереи"),
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.5),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _StepHeader(
                    stepNumber: "3",
                    title: context.tr(
                        "Haftalik davriylik grafigi va Vaqt",
                        "Weekly frequency and Time",
                        "Еженедельный график и Время"),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekDays.map((day) {
                      final bool isSelected = day["isSelected"];
                      final String dayLabel =
                          context.tr(day["uz"], day["en"], day["ru"]);

                      return GestureDetector(
                        onTap: () =>
                            setState(() => day["isSelected"] = !isSelected),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              isSelected ? primaryColor : cardBackground,
                          child: Text(
                            dayLabel,
                            style: TextStyle(
                              color: isSelected ? Colors.black : primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() => _selectedTime = pickedTime);
                      }
                    },
                    tileColor: cardBackground,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(Icons.access_time, color: primaryColor),
                    title: Text(
                      "${context.tr('Eslatma vaqti', 'Reminder time', 'Время напоминания')}: ${_selectedTime.format(context)}",
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: textColor),
                  ),
                  const SizedBox(height: 30),
                  _StepHeader(
                    stepNumber: "4",
                    title: context.tr(
                        "Gemini AI aqlli vaqt tavsiyasi",
                        "Gemini AI smart time recommendation",
                        "Умная рекомендация времени Gemini AI"),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.blue.shade50,
                      foregroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(color: primaryColor.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isAiLoading ? null : _suggestOptimalTime,
                    icon: _isAiLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isAiLoading
                          ? context.tr("AI tahlil qilmoqda...",
                              "AI analyzing...", "ИИ анализирует...")
                          : context.tr(
                              "AI orqali optimal vaqtni aniqlash",
                              "Determine optimal time via AI",
                              "Определить оптимальное время через ИИ"),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🎯 Odatni Saqlash / Yangilash Tugmasi
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 56),
                      shadowColor: primaryColor.withOpacity(0.3),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final title = _titleController.text.trim();
                      final minutes =
                          int.tryParse(_durationController.text.trim()) ??
                              _selectedMinutes;

                      if (title.isNotEmpty) {
                        if (_isEditMode) {
                          context.read<HabitBloc>().add(
                                EditHabitEvent(
                                  id: widget.habit!.id,
                                  title: title,
                                  minutes: minutes,
                                  icon: _selectedIcon,
                                  imagePath: _selectedImagePath,
                                ),
                              );
                        } else {
                          context.read<HabitBloc>().add(
                                AddHabitEvent(
                                  title: title,
                                  minutes: minutes,
                                  icon: _selectedIcon,
                                  imagePath: _selectedImagePath,
                                ),
                              );
                        }

                        // 🔄 Ekrandan chiqishdan oldin ro'yxatni majburiy yangilatish
                        context.read<HabitBloc>().add(LoadHabitsEvent());

                        // Bildirishnomalarni rejalashtirish
                        try {
                          for (var day in _weekDays) {
                            if (day["isSelected"] == true) {
                              int dayValue =
                                  int.tryParse(day["value"].toString()) ?? 0;
                              int notificationId =
                                  (DateTime.now().millisecondsSinceEpoch %
                                          100000) +
                                      dayValue;

                              await NotificationService.scheduleNotification(
                                id: notificationId,
                                title: context.tr(
                                    "Odat vaqti bo'ldi! 🎯",
                                    "Time for your habit! 🎯",
                                    "Время привычки! 🎯"),
                                body:
                                    "$title ${context.tr('odatizni bajarish vaqti keldi!', 'habit time has arrived!', 'пора выполнять привычку!')}",
                                hour: _selectedTime.hour,
                                minute: _selectedTime.minute,
                                dayOfWeek: dayValue,
                              );
                            }
                          }
                        } catch (e) {
                          debugPrint("Notification Error: $e");
                        }

                        if (context.mounted) Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                  "Iltimos, odat sarlavhasini kiriting!",
                                  "Please enter a habit title!",
                                  "Пожалуйста, введите название привычки!"),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      _isEditMode
                          ? context.tr("Odatni Yangilash", "Update Habit",
                              "Обновить привычку")
                          : context.tr("Odatni Saqlash", "Save Habit",
                              "Сохранить привычку"),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🧱 _StepHeader widgeti dizayn va matn ranglari to'g'ri ishlashi uchun moslashtirildi
class _StepHeader extends StatelessWidget {
  final String stepNumber;
  final String title;
  final Color textColor;

  const _StepHeader({
    required this.stepNumber,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text(
            stepNumber,
            style: const TextStyle(
                color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
