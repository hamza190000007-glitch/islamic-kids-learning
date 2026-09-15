import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const burgundy = Color(0xFF6B1F2A);
const cream = Color(0xFFFFF8F5);
const gold = Color(0xFFF2B84B);

const aiEndpoint = String.fromEnvironment('AI_ENDPOINT', defaultValue: '');
const aiApiKey = String.fromEnvironment('AI_API_KEY', defaultValue: '');
const aiModel = String.fromEnvironment('AI_MODEL', defaultValue: 'gpt-4o-mini');

void main() => runApp(const KindergartenApp());

class Child {
  Child({required this.id, required this.name, this.points = 0});
  final String id;
  String name;
  int points;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'points': points};
  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: json['name']?.toString() ?? 'طفلي',
        points: (json['points'] as num?)?.toInt() ?? 0,
      );
}

class AppStore {
  static const childrenKey = 'children_v5';
  static const rewardKey = 'reward_value_v4';
  static const aiEndpointKey = 'ai_endpoint_v1';

  static Future<List<Child>> loadChildren() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(childrenKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Child.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChildren(List<Child> children) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(childrenKey, jsonEncode(children.map((e) => e.toJson()).toList()));
  }

  static Future<double> loadPointValue() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(rewardKey) ?? 0;
  }

  static Future<void> savePointValue(double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(rewardKey, value);
  }

  static Future<void> addPoints(Child child, int amount) async {
    child.points += amount;
    final all = await loadChildren();
    final i = all.indexWhere((x) => x.id == child.id);
    if (i >= 0) {
      all[i] = child;
      await saveChildren(all);
    }
  }

  static Future<String> loadAiEndpoint() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(aiEndpointKey) ?? '';
  }

  static Future<void> saveAiEndpoint(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(aiEndpointKey, value.trim());
  }
}

class Voice {
  static final FlutterTts tts = FlutterTts();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await tts.awaitSpeakCompletion(true);
    await tts.setVolume(1.0);
    await tts.setSpeechRate(0.38);
    await tts.setPitch(1.02);
    _ready = true;
  }

  static Future<void> speak(String text, {bool english = false}) async {
    await init();
    if (english) {
      await tts.setLanguage('en-US');
    } else {
      // Syrian Arabic when the device provides it; otherwise use the clearest
      // Arabic voice supplied by the Android text-to-speech engine.
      final langs = (await tts.getLanguages()).map((e) => e.toString().toLowerCase()).toList();
      String lang = 'ar-SY';
      if (!langs.any((x) => x == 'ar-sy' || x.contains('ar-sy'))) {
        if (langs.any((x) => x.contains('ar-lb'))) {
          lang = 'ar-LB';
        } else if (langs.any((x) => x.contains('ar-jo'))) {
          lang = 'ar-JO';
        } else {
          lang = 'ar-SA';
        }
      }
      await tts.setLanguage(lang);
    }
    await tts.stop();
    await tts.speak(text);
  }
}

class AiFriendService {
  static Future<String> ask(String question, {String endpoint = ''}) async {
    final url = endpoint.trim().isNotEmpty ? endpoint.trim() : aiEndpoint;
    if (url.isEmpty || aiApiKey.isEmpty) return _localAnswer(question);
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $aiApiKey'},
            body: jsonEncode({
              'model': aiModel,
              'messages': [
                {
                  'role': 'system',
                  'content': 'أنت صديق تعليمي للأطفال في روضة إسلامية. اسمك نور. أجب بالعربية السورية البسيطة، بجمل قصيرة ودافئة ومناسبة لعمر 4-8 سنوات. لا تطلب الاسم الكامل أو العنوان أو الهاتف أو الصور أو أي معلومات شخصية. لا تقدم محتوى مخيفاً أو غير مناسب. في الأسئلة الدينية قدّم أدباً إسلامياً عاماً بلطف، وإذا كان السؤال يحتاج فتوى فقل للطفل أن يسأل والديه. شجع الطفل على التعلم والصدق والصلاة وبر الوالدين.',
                },
                {'role': 'user', 'content': question}
              ],
              'temperature': 0.5,
              'max_tokens': 120,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content']?.toString();
        if (content != null && content.trim().isNotEmpty) return content.trim();
      }
    } catch (_) {}
    return _localAnswer(question);
  }

  static String _localAnswer(String q) {
    final x = q.toLowerCase();
    if (x.contains('صلاة') || x.contains('الصلاة')) return 'الصلاة جميلة يا بطل، ونحاول نحافظ على أوقاتها ونصلي بهدوء وأدب.';
    if (x.contains('وضوء') || x.contains('وضو')) return 'بالوضوء ننظف أنفسنا ونستعد للصلاة، ومن الجميل ألا نسرف بالماء.';
    if (x.contains('حيوان') || x.contains('قطة') || x.contains('كلب')) return 'الحيوانات مخلوقات جميلة، ونحسن إليها ولا نؤذيها.';
    if (x.contains('الله')) return 'الله يحب الخير والصدق والرحمة، وما أجمل أن نفعل الخير كل يوم.';
    if (x.contains('أبي') || x.contains('أمي') || x.contains('والدين')) return 'نحترم أهلنا ونساعدهم ونقول لهم كلاماً طيباً.';
    return 'سؤال حلو يا صديقي! حاول تتعلم وتجرّب، وإذا أردت جواباً دقيقاً اسأل ماما أو بابا معي.';
  }
}

class KindergartenApp extends StatelessWidget {
  const KindergartenApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
