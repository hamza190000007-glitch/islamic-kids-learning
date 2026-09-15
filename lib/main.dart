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
      try {
        await tts.setLanguage('ar-SY');
      } catch (_) {
        try {
          await tts.setLanguage('ar-SA');
        } catch (_) {}
      }
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
        title: 'طفلي المسلم',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: burgundy, scaffoldBackgroundColor: cream),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
        home: const StartPage(),
      );
}

class Mosque extends StatelessWidget {
  const Mosque({super.key, this.size = 160});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * .72, child: CustomPaint(painter: MosquePainter()));
}

class MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = burgundy;
    final yellow = Paint()..color = gold;
    canvas.drawRect(Rect.fromLTWH(s.width * .18, s.height * .48, s.width * .64, s.height * .42), white);
    canvas.drawArc(Rect.fromLTWH(s.width * .28, s.height * .12, s.width * .44, s.height * .68), pi, pi, true, red);
    canvas.drawRect(Rect.fromLTWH(s.width * .04, s.height * .25, s.width * .12, s.height * .65), white);
    canvas.drawRect(Rect.fromLTWH(s.width * .84, s.height * .25, s.width * .12, s.height * .65), white);
    canvas.drawCircle(Offset(s.width * .10, s.height * .23), s.width * .055, red);
    canvas.drawCircle(Offset(s.width * .90, s.height * .23), s.width * .055, red);
    canvas.drawRect(Rect.fromLTWH(s.width * .49, s.height * .02, s.width * .02, s.height * .17), red);
    canvas.drawCircle(Offset(s.width * .50, s.height * .02), s.width * .035, yellow);
    canvas.drawArc(Rect.fromLTWH(s.width * .42, s.height * .54, s.width * .16, s.height * .36), pi, pi, true, red);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FriendAvatar extends StatelessWidget {
  const FriendAvatar({super.key, this.size = 150, this.girl = true});
  final double size;
  final bool girl;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: FriendPainter(girl: girl));
}

class FriendPainter extends CustomPainter {
  FriendPainter({required this.girl});
  final bool girl;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..style = PaintingStyle.fill;
    final center = Offset(s.width / 2, s.height / 2);
    p.color = const Color(0xFFFFD9BD);
    c.drawCircle(Offset(center.dx, s.height * .39), s.width * .22, p);
    if (girl) {
      p.color = burgundy;
      c.drawArc(Rect.fromCircle(center: Offset(center.dx, s.height * .38), radius: s.width * .28), pi, pi, true, p);
      c.drawPath(Path()
        ..moveTo(s.width * .22, s.height * .36)
        ..quadraticBezierTo(s.width * .50, s.height * .08, s.width * .78, s.height * .36)
        ..lineTo(s.width * .78, s.height * .72)
        ..lineTo(s.width * .22, s.height * .72)
        ..close(), p);
    } else {
      p.color = const Color(0xFF4B5D73);
      c.drawCircle(Offset(center.dx, s.height * .27), s.width * .24, p);
    }
    p.color = const Color(0xFFFFE6D6);
    c.drawCircle(Offset(s.width * .42, s.height * .38), s.width * .025, p);
    c.drawCircle(Offset(s.width * .58, s.height * .38), s.width * .025, p);
    p.color = burgundy;
    c.drawArc(Rect.fromLTWH(s.width * .42, s.height * .39, s.width * .16, s.height * .10), 0, pi, false, p..style = PaintingStyle.stroke..strokeWidth = 3);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFBBD7F2);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .20, s.height * .65, s.width * .60, s.height * .35), Radius.circular(s.width * .12)), p);
    p.color = gold;
    c.drawCircle(Offset(s.width * .80, s.height * .16), s.width * .07, p);
  }
  @override
  bool shouldRepaint(covariant FriendPainter oldDelegate) => oldDelegate.girl != girl;
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Child>>(
        future: AppStore.loadChildren(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (snapshot.data!.isEmpty) return const SetupPage();
          return ChildChooser(children: snapshot.data!);
        },
      );
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final controller = TextEditingController();
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  Future<void> enter() async {
    final child = Child(id: DateTime.now().microsecondsSinceEpoch.toString(), name: controller.text.trim().isEmpty ? 'طفلي' : controller.text.trim());
    await AppStore.saveChildren([child]);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(child: child)));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.asset('assets/images/children_logo.png', width: 210, height: 210, fit: BoxFit.cover)),
                const SizedBox(height: 10),
                const Text('طفلي المسلم', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: burgundy)),
                const SizedBox(height: 6),
                const Text('نور صديقك يساعدك في التعلم واللعب في طفلي المسلم 🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 22),
                TextField(controller: controller, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'اكتب اسم الطفل', prefixIcon: Icon(Icons.child_care), border: OutlineInputBorder())),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: enter, icon: const Icon(Icons.rocket_launch), label: const Padding(padding: EdgeInsets.all(10), child: Text('دخول إلى طفلي المسلم', style: TextStyle(fontSize: 19)))),
                const SizedBox(height: 24),
                const Text('© جميع الحقوق محفوظة — حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      );
}

class ChildChooser extends StatelessWidget {
  const ChildChooser({super.key, required this.children});
  final List<Child> children;
  Future<void> addChild(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
          title: const Text('إضافة طفل جديد'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'اسم الطفل')),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            final all = [...children, Child(id: DateTime.now().microsecondsSinceEpoch.toString(), name: controller.text.trim())];
            await AppStore.saveChildren(all);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }, child: const Text('إضافة'))],
        ));
    controller.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('من سيبدأ اليوم؟'), backgroundColor: burgundy, foregroundColor: Colors.white),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.asset('assets/images/children_logo.png', width: 180, height: 180, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          ...children.map((child) => Card(child: ListTile(
                leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/children_logo.png', width: 52, height: 52, fit: BoxFit.cover)),
                title: Text(child.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Text('${child.points} نقطة'),
                trailing: const Icon(Icons.play_circle_fill, color: burgundy, size: 34),
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(child: child))),
              ))),
          OutlinedButton.icon(onPressed: () => addChild(context), icon: const Icon(Icons.person_add), label: const Text('إضافة طفل جديد')),
        ]),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.child});
  final Child child;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _welcome()); }
  Future<void> _welcome() async {
    await Voice.speak('أهلاً يا ${widget.child.name}! أنا نور، صديقك في تطبيق طفلي المسلم.');
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (d) => AlertDialog(
          title: const Text('🌟 أهلاً بك يا بطل!', textAlign: TextAlign.center, style: TextStyle(color: burgundy)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.asset('assets/images/children_logo.png', width: 150, height: 150, fit: BoxFit.cover)), Text('أنا نور! إذا احتجت مساعدة اسألني 🤍', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))]),
          actions: [Center(child: FilledButton(onPressed: () => Navigator.pop(d), child: const Text('هيا نبدأ!')))],
        ));
  }
  void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) { if (mounted) setState(() {}); });
  Widget tile(String icon, String title, Color color, Widget page) => Card(color: color, clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => open(page), child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 38)), const SizedBox(height: 6), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))]))));
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: burgundy, foregroundColor: Colors.white, title: Text('أهلاً ${widget.child.name} في طفلي المسلم 🌟'), actions: [IconButton(onPressed: () => open(ParentSettings()), icon: const Icon(Icons.family_restroom))]),
        body: Column(children: [
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset('assets/images/children_logo.png', width: 82, height: 82, fit: BoxFit.cover)), const SizedBox(width: 10), Column(children: [const Text('طفلي المسلم', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: burgundy)), Text('${widget.child.points} نقطة مكافأة')])]),
          Expanded(child: GridView.count(padding: const EdgeInsets.all(14), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
            tile('أب', 'الحروف العربية', Colors.teal, LettersPage(child: widget.child)),
            tile('ABC', 'English Letters', Colors.blue, EnglishLettersPage()),
            tile('١٢٣', 'الأرقام العربية', Colors.indigo, NumbersPage(english: false)),
            tile('123', 'English Numbers', Colors.deepOrange, NumbersPage(english: true)),
            tile('🎮', 'الألعاب التعليمية', Colors.orange, const GameHub()),
            tile('🕌', 'التعلم الإسلامي', burgundy, IslamicHub(child: widget.child)),
            tile('🤍', 'صديقي نور', const Color(0xFF5078A0), AiFriendPage(child: widget.child)),
            tile('🎁', 'مكافآتي', Colors.pink, RewardsPage(child: widget.child)),
          ])),
          const Padding(padding: EdgeInsets.only(bottom: 7), child: Text('© حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold))),
        ]),
      );
}

class LettersPage extends StatelessWidget {
  const LettersPage({super.key, required this.child});
  final Child child;
  static const letters = ['أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي'];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الحروف العربية'), backgroundColor: burgundy, foregroundColor: Colors.white),
        body: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: letters.length, itemBuilder: (context, i) => InkWell(onTap: () => Voice.speak(letters[i]), child: Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(letters[i], style: const TextStyle(fontSize: 36, color: burgundy, fontWeight: FontWeight.bold)))))));
}

class EnglishLettersPage extends StatelessWidget {
  EnglishLettersPage({super.key});
  final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('English Letters'), backgroundColor: burgundy, foregroundColor: Colors.white), body: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: letters.length, itemBuilder: (context, i) => InkWell(onTap: () => Voice.speak(letters[i], english: true), child: Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(letters[i], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue)))))));
}

class NumbersPage extends StatelessWidget {
  const NumbersPage({super.key, required this.english});
  final bool english;
  @override
  Widget build(BuildContext context) {
    final values = List.generate(20, (i) => i + 1);
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return Scaffold(appBar: AppBar(title: Text(english ? 'English Numbers' : 'الأرقام العربية'), backgroundColor: burgundy, foregroundColor: Colors.white), body: GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: values.length, itemBuilder: (context, i) {
      final n = values[i];
      final text = english ? '$n' : n.toString().split('').map((c) => arabic[int.parse(c)]).join();
      return InkWell(onTap: () => Voice.speak(n.toString(), english: english), child: Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(text, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: burgundy)))));
    }));
  }
}

class GameHub extends StatelessWidget {
  const GameHub({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('الألعاب التعليمية'), backgroundColor: burgundy, foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(18), children: [
        gameCard(context, '🎨', 'التلوين بالقلم', const ColoringGame()),
        gameCard(context, '✏️', 'الرسم الحر', const DrawingGame()),
        gameCard(context, '🐾', 'أصوات الحيوانات', const AnimalGame()),
        gameCard(context, '🧩', 'لعبة المطابقة', const MatchingGame()),
      ]));
  Widget gameCard(BuildContext context, String icon, String title, Widget page) => Card(child: ListTile(leading: Text(icon, style: const TextStyle(fontSize: 36)), title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page))));
}

class ColoringGame extends StatefulWidget {
  const ColoringGame({super.key});
  @override
  State<ColoringGame> createState() => _ColoringGameState();
}

class _ColoringGameState extends State<ColoringGame> {
  final strokes = <ColorStroke>[];
  Color color = Colors.red;
  double width = 12;
  int page = 0;
  final pages = const ['قطة', 'فراشة', 'شجرة', 'بيت'];
  void clear() => setState(strokes.clear);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('التلوين بالقلم'), backgroundColor: burgundy, foregroundColor: Colors.white, actions: [IconButton(onPressed: clear, icon: const Icon(Icons.delete_outline))]),
        body: Column(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: burgundy, width: 2)), child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: ColoringOutlinePainter(page))),
            Positioned.fill(child: GestureDetector(onPanStart: (d) => setState(() => strokes.add(ColorStroke([d.localPosition], color, width))), onPanUpdate: (d) => setState(() => strokes.last.points.add(d.localPosition)), onPanEnd: (_) => setState(() {}), child: CustomPaint(painter: ColoringStrokePainter(strokes)))),
          ])))),
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
            for (final c in [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.brown, Colors.black]) Padding(padding: const EdgeInsets.all(5), child: GestureDetector(onTap: () => setState(() => color = c), child: CircleAvatar(radius: 20, backgroundColor: c, child: color == c ? const Icon(Icons.check, color: Colors.white) : null))),
          ])),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('حجم القلم'), Slider(value: width, min: 4, max: 30, onChanged: (v) => setState(() => width = v), activeColor: burgundy)]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton(onPressed: () { if (strokes.isNotEmpty) setState(() => strokes.removeLast()); }, icon: const Icon(Icons.undo)), OutlinedButton.icon(onPressed: clear, icon: const Icon(Icons.cleaning_services), label: const Text('مسح')), FilledButton.icon(onPressed: () => setState(() { page = (page + 1) % pages.length; strokes.clear(); }), icon: const Icon(Icons.arrow_back), label: Text(pages[(page + 1) % pages.length]))]),
          const SizedBox(height: 10),
        ]),
      );
}

class ColorStroke {
  ColorStroke(this.points, this.color, this.width);
  final List<Offset> points;
  final Color color;
  final double width;
}

class ColoringStrokePainter extends CustomPainter {
  ColoringStrokePainter(this.strokes);
  final List<ColorStroke> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final p = Paint()..color = s.color..strokeWidth = s.width..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      for (int i = 1; i < s.points.length; i++) canvas.drawLine(s.points[i - 1], s.points[i], p);
    }
  }
  @override
  bool shouldRepaint(covariant ColoringStrokePainter oldDelegate) => true;
}

class ColoringOutlinePainter extends CustomPainter {
  ColoringOutlinePainter(this.page);
  final int page;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    final fill = Paint()..color = Colors.white;
    final cx = s.width / 2;
    if (page == 0) {
      c.drawOval(Rect.fromCenter(center: Offset(cx, s.height * .50), width: s.width * .55, height: s.height * .42), fill);
      c.drawOval(Rect.fromCenter(center: Offset(cx, s.height * .50), width: s.width * .55, height: s.height * .42), p);
      c.drawCircle(Offset(cx, s.height * .27), s.width * .13, fill); c.drawCircle(Offset(cx, s.height * .27), s.width * .13, p);
      c.drawCircle(Offset(cx - s.width * .045, s.height * .25), 6, p); c.drawCircle(Offset(cx + s.width * .045, s.height * .25), 6, p);
      c.drawArc(Rect.fromLTWH(cx - 30, s.height * .27, 60, 35), 0, pi, false, p);
      c.drawOval(Rect.fromLTWH(s.width * .17, s.height * .41, s.width * .20, s.height * .16), p); c.drawOval(Rect.fromLTWH(s.width * .63, s.height * .41, s.width * .20, s.height * .16), p);
    } else if (page == 1) {
      c.drawOval(Rect.fromCenter(center: Offset(cx, s.height * .5), width: 130, height: 200), p);
      c.drawOval(Rect.fromCenter(center: Offset(cx - 95, s.height * .5), width: 150, height: 90), p);
      c.drawOval(Rect.fromCenter(center: Offset(cx + 95, s.height * .5), width: 150, height: 90), p);
      c.drawCircle(Offset(cx, s.height * .32), 50, p); c.drawLine(Offset(cx - 30, s.height * .28), Offset(cx - 70, s.height * .16), p); c.drawLine(Offset(cx + 30, s.height * .28), Offset(cx + 70, s.height * .16), p);
    } else if (page == 2) {
      c.drawRect(Rect.fromLTWH(cx - 70, s.height * .55, 140, 160), p); c.drawPath(Path()..moveTo(cx - 110, s.height * .55)..lineTo(cx, s.height * .30)..lineTo(cx + 110, s.height * .55), p); c.drawCircle(Offset(cx - 80, s.height * .28), 55, p); c.drawCircle(Offset(cx + 75, s.height * .34), 70, p); c.drawCircle(Offset(cx + 5, s.height * .20), 65, p); c.drawRect(Rect.fromLTWH(cx - 25, s.height * .65, 50, 50), p);
    } else {
      c.drawRect(Rect.fromLTWH(cx - 130, s.height * .40, 260, 250), p); c.drawPath(Path()..moveTo(cx - 155, s.height * .40)..lineTo(cx, s.height * .18)..lineTo(cx + 155, s.height * .40), p); c.drawRect(Rect.fromLTWH(cx - 35, s.height * .52, 70, 130), p); c.drawCircle(Offset(cx + 85, s.height * .49), 25, p); c.drawRect(Rect.fromLTWH(cx - 90, s.height * .48, 55, 55), p);
    }
  }
  @override
  bool shouldRepaint(covariant ColoringOutlinePainter oldDelegate) => oldDelegate.page != page;
}

class DrawingGame extends StatefulWidget { const DrawingGame({super.key}); @override State<DrawingGame> createState() => _DrawingGameState(); }
class _DrawingGameState extends State<DrawingGame> {
  final points = <Offset>[];
  Color color = burgundy;
  double width = 7;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('الرسم الحر'), backgroundColor: burgundy, foregroundColor: Colors.white, actions: [IconButton(onPressed: () => setState(points.clear), icon: const Icon(Icons.delete))]), body: Column(children: [Expanded(child: GestureDetector(onPanUpdate: (d) => setState(() => points.add(d.localPosition)), onPanEnd: (_) => setState(() => points.add(Offset.infinite)), child: CustomPaint(painter: DrawPainter(points, color, width), child: const SizedBox.expand()))), Row(children: [IconButton(onPressed: () => setState(() => color = Colors.red), icon: const Icon(Icons.circle, color: Colors.red)), IconButton(onPressed: () => setState(() => color = Colors.blue), icon: const Icon(Icons.circle, color: Colors.blue)), IconButton(onPressed: () => setState(() => color = Colors.green), icon: const Icon(Icons.circle, color: Colors.green)), Expanded(child: Slider(value: width, min: 2, max: 25, onChanged: (v) => setState(() => width = v)))]) ]));
}
class DrawPainter extends CustomPainter { DrawPainter(this.points, this.color, this.width); final List<Offset> points; final Color color; final double width; @override void paint(Canvas canvas, Size size) { final p = Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round; for (var i=0;i<points.length-1;i++) { if(points[i].isInfinite||points[i+1].isInfinite) continue; canvas.drawLine(points[i],points[i+1],p); } } @override bool shouldRepaint(covariant DrawPainter oldDelegate)=>true; }

class Animal {
  const Animal(this.name, this.kind, this.soundUrl, this.fact);
  final String name, kind, soundUrl, fact;
}

const animalList = [
  Animal('القطة', 'cat', 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Meow_domestic_cat.ogg', 'القطة تقول: مياو!'),
  Animal('الكلب', 'dog', 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Barking_of_a_dog.ogg', 'الكلب ينبح: هو هو!'),
  Animal('البقرة', 'cow', 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Single_Cow_Moo.ogg', 'البقرة تقول: موو!'),
  Animal('الأسد', 'lion', 'https://commons.wikimedia.org/wiki/Special:Redirect/file/Lion_raring-sound1TamilNadu178.ogg', 'الأسد يزأر: غرااا!'),
];

class AnimalGame extends StatefulWidget { const AnimalGame({super.key}); @override State<AnimalGame> createState()=>_AnimalGameState(); }
class _AnimalGameState extends State<AnimalGame> {
  final player = AudioPlayer();
  int index = 0;
  bool playing = false;
  @override void dispose(){player.dispose();super.dispose();}
  Future<void> playAnimal() async { setState(()=>playing=true); try { await player.stop(); await player.play(UrlSource(animalList[index].soundUrl), volume: 1.0); } finally { if(mounted) setState(()=>playing=false); } }
  @override Widget build(BuildContext context){ final a=animalList[index]; return Scaffold(appBar: AppBar(title: const Text('أصوات الحيوانات'), backgroundColor: burgundy, foregroundColor: Colors.white), body: Column(children:[
    Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
      Container(width: 310, height: 310, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow:[BoxShadow(color: Colors.black12, blurRadius: 12)]), child: CustomPaint(painter: AnimalPainter(a.kind))),
      const SizedBox(height: 18), Text(a.name, style: const TextStyle(fontSize: 32,fontWeight: FontWeight.bold,color: burgundy)), Text(a.fact, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 20), FilledButton.icon(onPressed: playAnimal, icon: Icon(playing?Icons.graphic_eq:Icons.volume_up), label: const Text('اسمع صوت الحيوان', style: TextStyle(fontSize: 20))),
    ]))),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children:[IconButton(onPressed:()=>setState(()=>index=(index-1+animalList.length)%animalList.length), icon: const Icon(Icons.arrow_back_ios,size:32)), const Text('حيوان آخر',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)), IconButton(onPressed:()=>setState(()=>index=(index+1)%animalList.length), icon: const Icon(Icons.arrow_forward_ios,size:32))]), const SizedBox(height:15),
  ])); }
}

class AnimalPainter extends CustomPainter {
  AnimalPainter(this.kind); final String kind;
  @override void paint(Canvas c, Size s){ final p=Paint()..style=PaintingStyle.fill; final o=Offset(s.width/2,s.height/2); p.color=kind=='lion'?const Color(0xFFC98B2E):kind=='cow'?Colors.white:kind=='dog'?const Color(0xFF9A6A4B):const Color(0xFFE6B5C8); c.drawCircle(Offset(o.dx,s.height*.50),s.width*.28,p); p.color=Colors.black; if(kind=='cat'){c.drawCircle(Offset(s.width*.35,s.height*.18),s.width*.16,p);c.drawCircle(Offset(s.width*.65,s.height*.18),s.width*.16,p);c.drawCircle(Offset(s.width*.43,s.height*.47),8,p);c.drawCircle(Offset(s.width*.57,s.height*.47),8,p);p.color=Colors.pink;c.drawCircle(Offset(o.dx,s.height*.56),9,p);} else if(kind=='dog'){c.drawOval(Rect.fromCenter(center:Offset(s.width*.28,s.height*.45),width:s.width*.22,height:s.height*.45),p);c.drawOval(Rect.fromCenter(center:Offset(s.width*.72,s.height*.45),width:s.width*.22,height:s.height*.45),p);p.color=Colors.black;c.drawCircle(Offset(s.width*.43,s.height*.47),8,p);c.drawCircle(Offset(s.width*.57,s.height*.47),8,p);p.color=Colors.brown;c.drawCircle(Offset(o.dx,s.height*.56),14,p);} else if(kind=='cow'){p.color=Colors.black;c.drawCircle(Offset(s.width*.38,s.height*.38),28,p);c.drawCircle(Offset(s.width*.62,s.height*.52),32,p);p.color=Colors.black;c.drawCircle(Offset(s.width*.43,s.height*.47),8,p);c.drawCircle(Offset(s.width*.57,s.height*.47),8,p);p.color=Colors.pink;c.drawOval(Rect.fromCenter(center:Offset(o.dx,s.height*.60),width:80,height:40),p);} else {p.color=const Color(0xFFD9A441);c.drawCircle(o,s.width*.38,p);p.color=Colors.black;c.drawCircle(Offset(s.width*.43,s.height*.47),8,p);c.drawCircle(Offset(s.width*.57,s.height*.47),8,p);p.color=Colors.white;c.drawCircle(Offset(o.dx,s.height*.59),32,p);p.color=Colors.black;c.drawOval(Rect.fromCenter(center:Offset(o.dx,s.height*.59),width:35,height:18),p);} }
  @override bool shouldRepaint(covariant AnimalPainter oldDelegate)=>oldDelegate.kind!=kind;
}

class MatchingGame extends StatefulWidget { const MatchingGame({super.key}); @override State<MatchingGame> createState()=>_MatchingGameState(); }
class _MatchingGameState extends State<MatchingGame>{ final pairs=[['🍎','🍎'],['🐱','🐱'],['⭐','⭐'],['🚗','🚗']]; final selected=<int>{}; @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('لعبة المطابقة'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('طابق كل صورة مع مثلها',style:TextStyle(fontSize:20),textAlign:TextAlign.center),...List.generate(pairs.length,(i)=>Card(child:ListTile(leading:Text(pairs[i][0],style:const TextStyle(fontSize:42)),trailing:FilledButton(onPressed:()=>setState(()=>selected.add(i)),child:Text(selected.contains(i)?'أحسنت!':'طابق',style:const TextStyle(fontSize:20))))))])); }

class IslamicHub extends StatelessWidget {
  const IslamicHub({super.key, required this.child}); final Child child;
  static const lessons = [
    ['🕌','الصلاة',['نحافظ على الصلاة في وقتها.','نقف بهدوء ونستمع جيداً.','نرتب صلاتنا ونحاول أن نكون خاشعين.','بعد الصلاة نشكر الله على نعمه.']],
    ['💧','آداب الوضوء',['نبدأ بهدوء ونحافظ على الماء.','نغسل أعضاء الوضوء كما تعلمنا.','لا نسرف في الماء.','نرتب مكان الوضوء بعد الانتهاء.']],
    ['🤲','آداب الصلاة',['نتوضأ قبل الصلاة.','نرتدي لباساً نظيفاً ومحتشماً.','نضع الهاتف والألعاب جانباً ونركز في الصلاة.','نصلي بأدب ولا نؤذي من حولنا.']],
    ['🌷','الأخلاق الإسلامية',['نقول الصدق.','نساعد من يحتاج المساعدة.','نقول كلاماً طيباً.','نعتذر إذا أخطأنا.']],
    ['🕌','آداب المسجد',['ندخل بهدوء.','نحافظ على نظافة المسجد.','لا نرفع أصواتنا ونحترم المصلين.','نضع الأحذية في مكانها.']],
    ['🍽️','آداب الطعام',['نغسل أيدينا.','نذكر اسم الله قبل الطعام.','نأكل بأدب ولا نهدر الطعام.','نحمد الله بعد الطعام.']],
    ['🌙','آداب النوم',['نرتب مكاننا.','نغسل أسناننا ونستعد للنوم.','نذكر الله وننام بهدوء.','نستيقظ بنشاط ونبدأ يومنا بالخير.']],
    ['❤️','بر الوالدين',['نحترم ماما وبابا.','نساعدهما بما نستطيع.','نقول كلاماً جميلاً.','ندعو لهما بالخير.']],
  ];
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('التعلم الإسلامي'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView.builder(padding:const EdgeInsets.all(14),itemCount:lessons.length,itemBuilder:(context,i){final l=lessons[i];return Card(child:ListTile(leading:Text(l[0] as String,style:const TextStyle(fontSize:34)),title:Text(l[1] as String,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),subtitle:const Text('نصيحة وراء نصيحة + 5 نقاط'),trailing:const Icon(Icons.arrow_forward_ios),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>IslamicLesson(child:child,title:l[1] as String,tips:List<String>.from(l[2] as List))))));}));
}

class IslamicLesson extends StatefulWidget {
  const IslamicLesson({super.key, required this.child, required this.title, required this.tips});
  final Child child;
  final String title;
  final List<String> tips;
  @override
  State<IslamicLesson> createState() => _IslamicLessonState();
}

class _IslamicLessonState extends State<IslamicLesson> {
  int i = 0;
  bool done = false;

  Future<void> complete() async {
    if (done) return;
    done = true;
    await AppStore.addPoints(widget.child, 5);
    if (!mounted) return;
    await Voice.speak('أحسنت يا ${widget.child.name}! حصلت على خمس نقاط');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة 5 نقاط 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = i == widget.tips.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Mosque(size: 120),
            Text(widget.title, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.bold, color: burgundy)),
            const SizedBox(height: 25),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Card(
                key: ValueKey(i),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('نصيحة ${i + 1} من ${widget.tips.length}', style: const TextStyle(color: burgundy, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 18),
                      Text(widget.tips[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, height: 1.7)),
                      const SizedBox(height: 18),
                      IconButton(
                        onPressed: () => Voice.speak(widget.tips[i]),
                        icon: const Icon(Icons.volume_up, size: 34, color: burgundy),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (i > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => i--),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('السابق'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => last ? complete() : setState(() => i++),
                    icon: Icon(last ? Icons.check : Icons.arrow_back),
                    label: Text(last ? 'أنهيت الدرس +5 نقاط' : 'النصيحة التالية'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class AiFriendPage extends StatefulWidget {
  const AiFriendPage({super.key, required this.child});
  final Child child;
  @override
  State<AiFriendPage> createState() => _AiFriendPageState();
}

class _AiFriendPageState extends State<AiFriendPage> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[
    {'role': 'assistant', 'text': 'مرحباً! أنا نور 🌟 اسألني أي سؤال مناسب للأطفال.'},
  ];
  bool loading = false;
  String endpoint = '';
  @override
  void initState() { super.initState(); _loadEndpoint(); }
  Future<void> _loadEndpoint() async {
    final value = await AppStore.loadAiEndpoint();
    if (mounted) setState(() => endpoint = value);
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  Future<void> send() async {
    final question = controller.text.trim();
    if (question.isEmpty || loading) return;
    controller.clear();
    setState(() { messages.add({'role': 'user', 'text': question}); loading = true; });
    final answer = await AiFriendService.ask(question, endpoint: endpoint);
    if (!mounted) return;
    setState(() { messages.add({'role': 'assistant', 'text': answer}); loading = false; });
    await Voice.speak(answer);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('صديقي نور'), backgroundColor: burgundy, foregroundColor: Colors.white),
    body: Column(children: [
      const SizedBox(height: 12),
      const FriendAvatar(size: 135, girl: true),
      const Text('نور 🌟', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: burgundy)),
      const Text('صديقك الذي يساعدك على التعلم', style: TextStyle(fontSize: 17)),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final isUser = m['role'] == 'user';
          return Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: Card(
            color: isUser ? const Color(0xFFE8F1F7) : Colors.white,
            child: Padding(padding: const EdgeInsets.all(14), child: Text(m['text'] ?? '', style: const TextStyle(fontSize: 18))),
          ));
        },
      )),
      if (loading) const Padding(padding: EdgeInsets.all(6), child: Text('نور يفكر... 💭')),
      SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'اكتب سؤالك يا بطل...', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        FilledButton(onPressed: loading ? null : send, child: const Icon(Icons.send)),
      ]))),
    ]),
  );
}

class RewardsPage extends StatefulWidget { const RewardsPage({super.key,required this.child}); final Child child; @override State<RewardsPage> createState()=>_RewardsPageState(); }
class _RewardsPageState extends State<RewardsPage>{double value=0;@override void initState(){super.initState();load();}Future<void>load()async{final v=await AppStore.loadPointValue();if(mounted)setState(()=>value=v);}@override Widget build(BuildContext context){final total=widget.child.points*value;return Scaffold(appBar:AppBar(title:const Text('مكافآتي'),backgroundColor:burgundy,foregroundColor:Colors.white),body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Text('🎁',style:TextStyle(fontSize:90)),Text('${widget.child.points} نقطة',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:burgundy)),const SizedBox(height:12),Text('قيمة النقاط: ${total.toStringAsFixed(2)}',style:const TextStyle(fontSize:22))])));}}

class ParentSettings extends StatefulWidget { const ParentSettings({super.key}); @override State<ParentSettings> createState()=>_ParentSettingsState(); }
class _ParentSettingsState extends State<ParentSettings>{final controller=TextEditingController();final endpointController=TextEditingController();double value=0;List<Child>children=[];@override void initState(){super.initState();load();}Future<void>load()async{final c=await AppStore.loadChildren();final v=await AppStore.loadPointValue();final e=await AppStore.loadAiEndpoint();if(!mounted)return;setState((){children=c;value=v;controller.text=v.toString();endpointController.text=e;});} @override void dispose(){controller.dispose();endpointController.dispose();super.dispose();}Future<void>save()async{final v=double.tryParse(controller.text.replaceAll(',','.'))??0;await AppStore.savePointValue(v);await AppStore.saveAiEndpoint(endpointController.text);if(mounted){setState(()=>value=v);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الإعدادات')));}}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إعدادات الأهل'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('قيمة النقطة',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:8),TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(border:OutlineInputBorder())),const SizedBox(height:20),const Text('مساعد نور الذكي',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('يمكن للأهل وضع عنوان خادم آمن للمساعد. لا تضع مفتاح API داخل التطبيق عند نشره؛ الأفضل استخدام خادم وسيط.'),const SizedBox(height:8),TextField(controller:endpointController,decoration:const InputDecoration(labelText:'عنوان API اختياري',hintText:'https://example.com/v1/chat/completions',border:OutlineInputBorder())),const SizedBox(height:8),Text(aiApiKey.isEmpty?'وضع المساعد الحالي: إجابات محلية آمنة':'وضع المساعد الحالي: متصل بنموذج الذكاء الاصطناعي عند توفر العنوان',style:const TextStyle(color:burgundy,fontWeight:FontWeight.bold)),const SizedBox(height:10),FilledButton(onPressed:save,child:const Text('حفظ الإعدادات')),const SizedBox(height:25),const Text('الأطفال',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),...children.map((c)=>Card(child:ListTile(title:Text(c.name),subtitle:Text('${c.points} نقطة = ${(c.points*value).toStringAsFixed(2)}'))))]));}
