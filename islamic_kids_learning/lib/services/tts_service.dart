import 'package:flutter_tts/flutter_tts.dart';

// ============================================================
// خدمة النطق الصوتي
// تدعم اللغتين العربية والإنجليزية، وتُستخدم عند الضغط على
// أي حرف أو رقم لنطقه، وأيضاً لنطق الرسائل التشجيعية
// ============================================================
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  // تهيئة أولية لإعدادات النطق (السرعة، طبقة الصوت)
  static Future<void> _init() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.4); // بطيء قليلاً ليناسب الأطفال
    await _tts.setPitch(1.1); // نبرة أعلى قليلاً ودّية للأطفال
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  // نطق نص باللغة العربية
  static Future<void> speakArabic(String text) async {
    await _init();
    await _tts.setLanguage('ar-SA');
    await _tts.speak(text);
  }

  // نطق نص باللغة الإنجليزية
  static Future<void> speakEnglish(String text) async {
    await _init();
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  static Future<void> stop() async => _tts.stop();
}
