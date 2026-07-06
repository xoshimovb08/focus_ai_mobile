import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AudioHapticService {
  // Singleton Pattern - Yagona nusxa yaratish
  static final AudioHapticService _instance = AudioHapticService._internal();
  factory AudioHapticService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // 🎵 UI tinglashi (listen) uchun ValueNotifier qo'shildi
  final ValueNotifier<bool> isMusicPlayingNotifier = ValueNotifier<bool>(false);

  // ⚡ Eski o'zgaruvchini notifier qiymatiga bog'laymiz (Kodni buzmaslik uchun getter saqlab qolindi)
  bool get isPlaying => isMusicPlayingNotifier.value;

  // 📝 Standart (default) trek
  String _currentTrack = 'audio/amelie_reimagined.mp3';

  AudioHapticService._internal() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      // Player holati o'zgarganda notifier qiymatini yangilaymiz
      isMusicPlayingNotifier.value = state == PlayerState.playing;
    });
  }

  // Getters
  String get currentTrack => _currentTrack;

  // 📝 Fon musiqalari ro'yxati
  final List<String> focusMusicList = const [
    'audio/amelie_reimagined.mp3',
    'audio/balmorhea_remembrance.mp3',
    'audio/billie_eilish_hotline.m4a',
    'audio/dreamscape_nuages.mp3',
    'audio/feyza_van_gogh.m4a',
    'audio/golden_brown.m4a',
    'audio/hans_zimmer_interstellar.mp3',
    'audio/ludovico_einaudi_experience.mp3',
    'audio/max_richter_shutter_island.mp3',
    'audio/vangelis_la_petite.mp3',
  ];

  // --- 🔀 AUDIO (FON MUSIQASI) FUNKSIYALARI ---

  // Trekni o'zgartirish funksiyasi
  Future<void> changeTrack(String fullTrackPath) async {
    _currentTrack = fullTrackPath;

    if (isMusicPlayingNotifier.value) {
      await _audioPlayer.stop();
      isMusicPlayingNotifier.value = false; // Holatni zudlik bilan yangilash
    }
    // Yangi trekni avtomatik chalib ketish
    await playBackgroundMusic();
  }

  // Fon musiqasini chalish
  Future<void> playBackgroundMusic() async {
    if (isMusicPlayingNotifier.value) return;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.2); // Fon ovozi 20%
      await _audioPlayer.play(AssetSource(_currentTrack));
      isMusicPlayingNotifier.value = true;
    } catch (e) {
      debugPrint("Audio chalishda xatolik: $e");
    }
  }

  Future<void> pauseBackgroundMusic() async {
    await _audioPlayer.pause();
    // onPlayerStateChanged avtomatik ravishda notifier-ni false qiladi
  }

  Future<void> stopBackgroundMusic() async {
    await _audioPlayer.stop();
    isMusicPlayingNotifier.value = false;
  }

  // --- 📳 HAPTIC (VIBRATSIYA) FUNKSIYALARI ---

  static Future<void> triggerSuccessImpact() async {
    await HapticFeedback.vibrate();
  }

  static Future<void> triggerLightImpact() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> triggerFailureImpact() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
