import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:focus_ai/core/constants/app_colors.dart';
import 'package:focus_ai/presentation/blocs/settings/settings_bloc.dart';
import '../../core/services/gemini_ai_service.dart';
import '../../core/services/audio_haptic_service.dart';
import '../utils/lang_extension.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // 📜 TO'G'RILANDI: Scroll boshqaruvchisi
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 🌐 TO'G'RILANDI: Birinchi kadr chizilgach, xavfsiz tarzda kutib olish xabarini qo'shamiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() {
    if (mounted && _messages.isEmpty) {
      setState(() {
        _messages.add({
          "role": "ai",
          "message": context.tr(
            "Salom! Men sizning shaxsiy AI murabbiyingizman. Bugun qaysi odatni shakllantiramiz yoki nimalarga fokuslanamiz?",
            "Hello! I am your personal AI coach. Which habit are we building or focusing on today?",
            "Привет! Я ваш личный ИИ-тренер. Какую привычку мы будем формировать или на чем сфокусируемся сегодня?",
          ),
        });
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // 🛠️ Xotirani tozalash
    super.dispose();
  }

  // 📜 Chatni avtomatik pastga tushirish funksiyasi
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    AudioHapticService.triggerLightImpact();

    setState(() {
      _messages.add({"role": "user", "message": text});
      _isLoading = true;
    });

    _scrollToBottom(); // Foydalanuvchi xabar yozganda pastga tushadi

    // AI dan javob olish
    final aiResponse = await GeminiAiService().getCoachResponse(text);

    if (!mounted) return;

    setState(() {
      _messages.add({"role": "ai", "message": aiResponse});
      _isLoading = false;
    });

    _scrollToBottom(); // AI javob berganda pastga tushadi
    AudioHapticService.triggerSuccessImpact();
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
        final Color textColor = isDark ? AppColors.textMain : Colors.black87;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: cardBackground,
            elevation: 0,
            title: Text(
              context.tr(
                  "AI Fokus Murabbiy", "AI Focus Coach", "ИИ Фокус Тренер"),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            iconTheme: IconThemeData(color: primaryColor),
          ),
          body: Column(
            children: [
              // Chat xabarlari ro'yxati
              Expanded(
                child: ListView.builder(
                  controller: _scrollController, // 📜 Controller bog'landi
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg["role"] == "user";

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser
                              ? primaryColor.withValues(alpha: 0.15)
                              : cardBackground,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                            bottomLeft: isUser
                                ? const Radius.circular(16)
                                : const Radius.circular(0),
                          ),
                          border: Border.all(
                            color: isUser
                                ? primaryColor
                                : (isDark ? Colors.white10 : Colors.black12),
                          ),
                        ),
                        child: Text(
                          msg["message"] ?? "",
                          style: TextStyle(
                            color: isUser && isDark ? primaryColor : textColor,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Yuklanish indikatori
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),

              // Xabar yozish paneli
              Container(
                padding: const EdgeInsets.all(12),
                color: cardBackground,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.background
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: context.tr("Murabbiydan so'rang...",
                                  "Ask the coach...", "Спросите тренера..."),
                              hintStyle:
                                  TextStyle(color: textColor.withOpacity(0.4)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: primaryColor,
                        radius: 22,
                        child: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.paperPlane,
                              color: Colors.black, size: 18),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
