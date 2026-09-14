import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const KindergartenApp());

const burgundy = Color(0xFF6B1F2A);
const cream = Color(0xFFFFF8F5);
const gold = Color(0xFFF2B84B);

class ChildProfile {
  final String id;
  String name;
  int points;
  List<String> completed;
  ChildProfile({required this.id, required this.name, this.points = 0, List<String>? completed}) : completed = completed ?? [];
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'points': points, 'completed': completed};
  factory ChildProfile.fromMap(Map<String, dynamic> m) => ChildProfile(
        id: (m['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
        name: (m['name'] ?? 'طفلي').toString(),
        points: (m['points'] is num) ? (m['points'] as num).toInt() : 0,
        completed: List<String>.from(m['completed'] ?? const []),
      );
}

class Store {
  static const childrenKey = 'children_v3';
  static const rewardKey = 'reward_value_v2';
  static Future<List<ChildProfile>> children() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(childrenKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ChildProfile.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  static Future<void> saveChildren(List<ChildProfile> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(childrenKey, jsonEncode(list.map((e) => e.toMap()).toList()));
  }
  static Future<double> rewardValue() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(rewardKey) ?? 0.0;
  }
  static Future<void> setRewardValue(double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(rewardKey, value);
  }
  static Future<void> addPoint(ChildProfile child, [int amount = 1]) async {
    child.points += amount;
    final all = await children();
    final i = all.indexWhere((x) => x.id == child.id);
    if (i >= 0) all[i] = child;
    await saveChildren(all);
  }
}

class Voice {
  static final tts = FlutterTts();
  static Future<void> say(String text, {bool english = false}) async {
    await tts.setLanguage(english ? 'en-US' : 'ar-SA');
    await tts.setSpeechRate(.42);
    await tts.setPitch(1.08);
    await tts.speak(text);
  }
}

class KindergartenApp extends StatelessWidget {
  const KindergartenApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'رياض الأطفال',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: burgundy, scaffoldBackgroundColor: cream),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
        home: const StartPage(),
      );
}

class Mosque extends StatelessWidget {
  final double size;
  const Mosque({super.key, this.size = 180});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * .72, child: CustomPaint(painter: MosquePainter()));
}
class MosquePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final white = Paint()..color = Colors.white;
    final maroon = Paint()..color = burgundy;
    final g = Paint()..color = gold;
    c.drawRect(Rect.fromLTWH(s.width * .18, s.height * .48, s.width * .64, s.height * .42), white);
    c.drawArc(Rect.fromLTWH(s.width * .28, s.height * .12, s.width * .44, s.height * .68), pi, pi, true, maroon);
    c.drawRect(Rect.fromLTWH(s.width * .04, s.height * .25, s.width * .12, s.height * .65), white);
    c.drawRect(Rect.fromLTWH(s.width * .84, s.height * .25, s.width * .12, s.height * .65), white);
    c.drawCircle(Offset(s.width * .10, s.height * .23), s.width * .055, maroon);
    c.drawCircle(Offset(s.width * .90, s.height * .23), s.width * .055, maroon);
    c.drawRect(Rect.fromLTWH(s.width * .49, s.height * .02, s.width * .02, s.height * .17), maroon);
    c.drawCircle(Offset(s.width * .50, s.height * .02), s.width * .035, g);
    c.drawArc(Rect.fromLTWH(s.width * .42, s.height * .54, s.width * .16, s.height * .36), pi, pi, true, maroon);
    c.drawCircle(Offset(s.width * .38, s.height * .64), s.width * .035, g);
    c.drawCircle(Offset(s.width * .62, s.height * .64), s.width * .035, g);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<ChildProfile>>(
        future: Store.children(),
        builder: (context, snap) {
          if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return snap.data!.isEmpty ? const SetupPage() : ChildChooser(children: snap.data!);
        },
      );
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  @override State<SetupPage> createState() => _SetupPageState();
}
class _SetupPageState extends State<SetupPage> {
  final controller = TextEditingController();
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> enter() async {
    final name = controller.text.trim().isEmpty ? 'طفلي' : controller.text.trim();
    final child = ChildProfile(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    await Store.saveChildren([child]);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(profile: child, allChildren: [child])));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
          const Mosque(),
          const Text('رياض الأطفال', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: burgundy)),
          const SizedBox(height: 8),
          const Text('تعلّم • العب • اكتشف • ابتسم', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 25),
          TextField(controller: controller, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'اكتب اسم الطفل', prefixIcon: Icon(Icons.child_care), border: OutlineInputBorder())),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: enter, icon: const Icon(Icons.rocket_launch), label: const Padding(padding: EdgeInsets.all(10), child: Text('دخول إلى رياض الأطفال', style: TextStyle(fontSize: 19)))),
          const SizedBox(height: 24),
          const Text('© جميع الحقوق محفوظة — حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold)),
        ]))));
}

class ChildChooser extends StatelessWidget {
  final List<ChildProfile> children;
  const ChildChooser({super.key, required this.children});
  Future<void> add(BuildContext context) async {
    final c = TextEditingController();
    await showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('إضافة طفل جديد'),
      content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'اسم الطفل')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          final name = c.text.trim();
          if (name.isEmpty) return;
          final all = [...children, ChildProfile(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name)];
          await Store.saveChildren(all);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
          if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChildChooser(children: all)));
        }, child: const Text('إضافة')),
      ],
    ));
    c.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('من سيبدأ اليوم؟'), backgroundColor: burgundy, foregroundColor: Colors.white),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Mosque(size: 140),
          ...children.map((child) => Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: burgundy, child: Text(child.name.substring(0, 1), style: const TextStyle(color: Colors.white))),
                title: Text(child.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Text('${child.points} نقطة'),
                trailing: const Icon(Icons.play_circle_fill, color: burgundy),
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(profile: child, allChildren: children))),
              ))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => add(context), icon: const Icon(Icons.person_add), label: const Text('إضافة طفل جديد')),
          const SizedBox(height: 24),
          const Center(child: Text('© حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold))),
        ],
      );
}

class HomePage extends StatefulWidget {
  final ChildProfile profile;
  final List<ChildProfile> allChildren;
  const HomePage({super.key, required this.profile, required this.allChildren});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _welcome()); }
  Future<void> _welcome() async {
    await Voice.say('أهلاً وسهلاً يا ${widget.profile.name}! ما شاء الله، نورت رياض الأطفال');
    if (!mounted) return;
    await showDialog(context: context, barrierDismissible: false, builder: (d) => AlertDialog(
      title: const Center(child: Text('🎉 أهلاً بك يا بطل! 🎉', style: TextStyle(color: burgundy))),
      content: Text('🌟 ⭐ 🌙 ⭐ 🌟\n\nيا ${widget.profile.name}، سعيدون بوجودك معنا!\nهيا نتعلم ونلعب ونفرح معاً 💕', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
      actions: [Center(child: FilledButton(onPressed: () => Navigator.pop(d), child: const Text('هيا نبدأ!')))],
    ));
  }
  void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) { if (mounted) setState(() {}); });
  Widget tile(String icon, String title, Color color, Widget page) => Card(color: color, clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => open(page), child: Padding(padding: const EdgeInsets.all(10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 38)), const SizedBox(height: 6), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))]))));
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: burgundy, foregroundColor: Colors.white, title: Text('أهلاً ${widget.profile.name} 🌟'), actions: [IconButton(onPressed: () => open(ParentSettings(children: widget.allChildren)), icon: const Icon(Icons.family_restroom))]),
        body: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Mosque(size: 75), Column(children: [const Text('رياض الأطفال', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: burgundy)), Text('${widget.profile.points} نقطة مكافأة')])]),
          Expanded(child: GridView.count(padding: const EdgeInsets.all(14), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
            tile('🔤', 'الحروف العربية', Colors.teal, LettersPage(profile: widget.profile, english: false)),
            tile('🇬🇧', 'English Letters', Colors.blue, LettersPage(profile: widget.profile, english: true)),
            tile('١٢٣', 'الأرقام العربية', Colors.indigo, NumbersPage(profile: widget.profile, english: false)),
            tile('123', 'English Numbers', Colors.deepOrange, NumbersPage(profile: widget.profile, english: true)),
            tile('🎮', 'الألعاب التعليمية', Colors.orange, GameHub()),
            tile('🕌', 'التعلم الإسلامي', burgundy, IslamicHub(profile: widget.profile)),
            tile('🎁', 'مكافآتي', Colors.pink, RewardsPage(profile: widget.profile)),
            tile('👨‍👩‍👧', 'الأهل والأطفال', Colors.deepPurple, ParentSettings(children: widget.allChildren)),
          ])),
          const Padding(padding: EdgeInsets.only(bottom: 7), child: Text('© حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold))),
        ]),
      );
}

class LettersPage extends StatefulWidget {
  final ChildProfile profile; final bool english;
  const LettersPage({super.key, required this.profile, required this.english});
  @override State<LettersPage> createState() => _LettersPageState();
}
class _LettersPageState extends State<LettersPage> {
  final seen = <int>{};
  late final List<String> letters;
  @override void initState() { super.initState(); letters = widget.english ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('') : 'أ ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي'.split(' '); }
  @override Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.english ? 'English Letters' : 'الحروف العربية'), backgroundColor: burgundy, foregroundColor: Colors.white),
        body: Column(children: [
          Padding(padding: const EdgeInsets.all(14), child: Text('اضغط على الحرف لسماعه 🔊  •  ${seen.length}/${letters.length}')),
          Expanded(child: GridView.builder(padding: const EdgeInsets.all(14), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: letters.length, itemBuilder: (_, i) => InkWell(onTap: () async { await Voice.say(letters[i], english: widget.english); if (mounted) setState(() => seen.add(i)); }, child: Container(decoration: BoxDecoration(color: seen.contains(i) ? Colors.green : Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(letters[i], style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: seen.contains(i) ? Colors.white : burgundy))))))),
        ]),
      );
}

class NumbersPage extends StatefulWidget {
  final ChildProfile profile; final bool english;
  const NumbersPage({super.key, required this.profile, required this.english});
  @override State<NumbersPage> createState() => _NumbersPageState();
}
class _NumbersPageState extends State<NumbersPage> {
  final seen = <int>{};
  @override Widget build(BuildContext context) {
    final numbers = widget.english ? List.generate(20, (i) => '${i + 1}') : ['١','٢','٣','٤','٥','٦','٧','٨','٩','١٠','١١','١٢','١٣','١٤','١٥','١٦','١٧','١٨','١٩','٢٠'];
    return Scaffold(appBar: AppBar(title: Text(widget.english ? 'English Numbers' : 'الأرقام العربية'), backgroundColor: burgundy, foregroundColor: Colors.white), body: GridView.builder(padding: const EdgeInsets.all(18), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: numbers.length, itemBuilder: (_, i) => InkWell(onTap: () async { await Voice.say(numbers[i], english: widget.english); if (mounted) setState(() => seen.add(i)); }, child: Container(decoration: BoxDecoration(color: seen.contains(i) ? gold : Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(numbers[i], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: burgundy)))))));
  }
}

class GameHub extends StatelessWidget {
  const GameHub({super.key});
  Widget game(BuildContext c, String icon, String title, String sub, Color color, Widget page) => Card(color: color, child: ListTile(contentPadding: const EdgeInsets.all(14), leading: Text(icon, style: const TextStyle(fontSize: 42)), title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), subtitle: Text(sub, style: const TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_back_ios, color: Colors.white), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page))));
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('🎮 الألعاب التعليمية'), backgroundColor: burgundy, foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(18), children: [
    game(context, '🎨', 'تلوين الشخصيات', 'اختر اللون ولوّن الشخصية', Colors.pink, const ColoringGame()),
    game(context, '✏️', 'الرسم الحر', 'ارسم بأصابعك كما تحب', Colors.teal, const DrawingGame()),
    game(context, '🐾', 'خمن الحيوان من الصوت', 'اسمع الصوت واختر الحيوان', Colors.orange, const AnimalSoundGame()),
    game(context, '🧩', 'لعبة المطابقة', 'طابق الأشكال المتشابهة', Colors.indigo, const MatchingGame()),
  ]));
}

class ColoringGame extends StatefulWidget { const ColoringGame({super.key}); @override State<ColoringGame> createState() => _ColoringGameState(); }
class _ColoringGameState extends State<ColoringGame> {
  Color selected = Colors.red; Color body = Colors.blue;
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('🎨 تلوين الشخصيات'), backgroundColor: burgundy, foregroundColor: Colors.white), body: Column(children: [
    const Padding(padding: EdgeInsets.all(14), child: Text('اختر لوناً ثم اضغط على الشخصية', style: TextStyle(fontSize: 19))),
    Expanded(child: Center(child: GestureDetector(onTap: () => setState(() => body = selected), child: CustomPaint(size: const Size(280, 360), painter: CharacterPainter(body))))),
    Wrap(spacing: 8, children: colors.map((c) => GestureDetector(onTap: () => setState(() => selected = c), child: CircleAvatar(backgroundColor: c, child: selected == c ? const Icon(Icons.check, color: Colors.white) : null))).toList()),
    const SizedBox(height: 25),
  ]));
}
class CharacterPainter extends CustomPainter {
  final Color color; CharacterPainter(this.color);
  @override void paint(Canvas c, Size s) { final skin = Paint()..color = const Color(0xFFFFD5B5); final body = Paint()..color = color; final dark = Paint()..color = burgundy; c.drawCircle(Offset(s.width*.5,s.height*.24),55,skin); c.drawRect(Rect.fromLTWH(s.width*.25,s.height*.4,s.width*.5,s.height*.45),body); c.drawCircle(Offset(s.width*.4,s.height*.23),5,dark); c.drawCircle(Offset(s.width*.6,s.height*.23),5,dark); c.drawLine(Offset(s.width*.35,s.height*.85),Offset(s.width*.3,s.height*.98),body..strokeWidth=15); c.drawLine(Offset(s.width*.65,s.height*.85),Offset(s.width*.7,s.height*.98),body..strokeWidth=15); }
  @override bool shouldRepaint(covariant CharacterPainter old) => old.color != color;
}

class DrawingGame extends StatefulWidget { const DrawingGame({super.key}); @override State<DrawingGame> createState() => _DrawingGameState(); }
class _DrawingGameState extends State<DrawingGame> {
  final strokes = <List<Offset>>[]; Color color = burgundy;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('✏️ الرسم الحر'), backgroundColor: burgundy, foregroundColor: Colors.white, actions: [IconButton(onPressed: () => setState(() { strokes.clear(); }), icon: const Icon(Icons.delete))]), body: Column(children: [
    Expanded(child: GestureDetector(onPanStart: (d) => setState(() => strokes.add([d.localPosition])), onPanUpdate: (d) { if (strokes.isNotEmpty) setState(() => strokes.last.add(d.localPosition)); }, child: CustomPaint(painter: DrawPainter(strokes, color), child: Container(color: Colors.white)))),
    Wrap(spacing: 8, children: [burgundy, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.black].map((x) => GestureDetector(onTap: () => setState(() => color = x), child: CircleAvatar(backgroundColor: x))).toList()),
    const SizedBox(height: 12),
  ]));
}
class DrawPainter extends CustomPainter {
  final List<List<Offset>> strokes; final Color color; DrawPainter(this.strokes, this.color);
  @override void paint(Canvas c, Size s) { final p = Paint()..color = color..strokeWidth = 7..strokeCap = StrokeCap.round; for (final stroke in strokes) { for (var i = 1; i < stroke.length; i++) { c.drawLine(stroke[i - 1], stroke[i], p); } } }
  @override bool shouldRepaint(covariant DrawPainter old) => true;
}

class AnimalSoundGame extends StatefulWidget { const AnimalSoundGame({super.key}); @override State<AnimalSoundGame> createState() => _AnimalSoundGameState(); }
class _AnimalSoundGameState extends State<AnimalSoundGame> {
  final animals = const [{'name':'القطة','sound':'مياو مياو','icon':'🐱'},{'name':'البقرة','sound':'مووو','icon':'🐮'},{'name':'الخروف','sound':'ماء ماء','icon':'🐑'},{'name':'الأسد','sound':'زئير الأسد','icon':'🦁'}];
  int question = 0; bool? result;
  void newQuestion() { setState(() { question = Random().nextInt(animals.length); result = null; }); Voice.say(animals[question]['sound']!); }
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => newQuestion()); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('🐾 خمن الحيوان من الصوت'), backgroundColor: burgundy, foregroundColor: Colors.white), body: Column(children: [
    const SizedBox(height: 22), const Text('اسمع جيداً ثم اختر الحيوان 🔊', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    FilledButton.icon(onPressed: newQuestion, icon: const Icon(Icons.volume_up), label: const Text('تشغيل الصوت')),
    Expanded(child: GridView.builder(padding: const EdgeInsets.all(18), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: animals.length, itemBuilder: (_, i) => InkWell(onTap: () { final ok = i == question; setState(() => result = ok); Voice.say(ok ? 'أحسنت! إجابة صحيحة' : 'حاول مرة أخرى'); }, child: Card(color: result == true && i == question ? Colors.green : Colors.white, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(animals[i]['icon']!, style: const TextStyle(fontSize: 55)), Text(animals[i]['name']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]))))),
    if (result != null) Padding(padding: const EdgeInsets.all(16), child: Text(result! ? 'ما شاء الله! أحسنت 🌟' : 'قريب جداً، حاول مرة أخرى 💪', style: TextStyle(fontSize: 21, color: result! ? Colors.green : burgundy, fontWeight: FontWeight.bold))),
  ]));
}

class MatchingGame extends StatefulWidget { const MatchingGame({super.key}); @override State<MatchingGame> createState() => _MatchingGameState(); }
class _MatchingGameState extends State<MatchingGame> {
  final icons = const ['⭐','🌙','❤️','🌸']; late List<String> cards; final opened = <int>[]; final matched = <int>{};
  @override void initState() { super.initState(); cards = [...icons, ...icons]..shuffle(); }
  void tap(int i) { if (opened.length >= 2 || matched.contains(i) || opened.contains(i)) return; setState(() => opened.add(i)); if (opened.length == 2) { final a = opened[0], b = opened[1]; if (cards[a] == cards[b]) { setState(() { matched.addAll([a,b]); opened.clear(); }); } else { Future.delayed(const Duration(milliseconds: 650), () { if (mounted) setState(() => opened.clear()); }); } } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('🧩 لعبة المطابقة'), backgroundColor: burgundy, foregroundColor: Colors.white), body: GridView.builder(padding: const EdgeInsets.all(25), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15), itemCount: cards.length, itemBuilder: (_, i) => Card(child: InkWell(onTap: () => tap(i), child: Center(child: Text((opened.contains(i) || matched.contains(i)) ? cards[i] : '?', style: const TextStyle(fontSize: 48)))))));
}

class IslamicHub extends StatelessWidget {
  final ChildProfile profile; const IslamicHub({super.key, required this.profile});
  static const lessons = [
    ['🕌','تعليم الصلاة','نتعلم الصلاة خطوة خطوة مع الأهل'], ['💧','آداب الوضوء','نتعلم الطهارة وترتيب الوضوء'], ['🤲','آداب الصلاة','الهدوء والخشوع واحترام الصلاة'], ['🌙','آداب الإسلام','السلام والصدق والرحمة والأمانة'], ['🕌','آداب المسجد','ندخل بهدوء ونحافظ على النظافة'], ['☀️','آداب الجمعة','النظافة والاستعداد والاستماع للخطبة'], ['🍎','آداب الطعام','نسمي الله ونأكل باليمين ولا نسرف'], ['😴','آداب النوم','نستعد للنوم ونذكر الله'], ['❤️','بر الوالدين','نحترم والدينا ونحسن الكلام']
  ];
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('🕌 التعلم الإسلامي'), backgroundColor: burgundy, foregroundColor: Colors.white), body: ListView.builder(padding: const EdgeInsets.all(15), itemCount: lessons.length, itemBuilder: (_, i) { final x = lessons[i]; return Card(child: ListTile(leading: Text(x[0], style: const TextStyle(fontSize: 36)), title: Text(x[1], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), subtitle: Text(x[2]), trailing: const Icon(Icons.arrow_back_ios, color: burgundy), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IslamicLesson(profile: profile, id: i, title: x[1], icon: x[0])))); }));
}

class IslamicLesson extends StatefulWidget {
  final ChildProfile profile; final int id; final String title, icon;
  const IslamicLesson({super.key, required this.profile, required this.id, required this.title, required this.icon});
  @override State<IslamicLesson> createState() => _IslamicLessonState();
}
class _IslamicLessonState extends State<IslamicLesson> {
  late final List<String> lines;
  @override void initState() { super.initState(); lines = lessonContent[widget.id]; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('${widget.icon} ${widget.title}'), backgroundColor: burgundy, foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(18), children: [for (var i = 0; i < lines.length; i++) Card(child: ListTile(leading: CircleAvatar(backgroundColor: burgundy, foregroundColor: Colors.white, child: Text('${i + 1}')), title: Text(lines[i], style: const TextStyle(fontSize: 18)), onTap: () => Voice.say(lines[i]))), const SizedBox(height: 10), FilledButton.icon(onPressed: () async { await Store.addPoint(widget.profile, 5); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ما شاء الله! حصلت على 5 نقاط 🌟'))); } }, icon: const Icon(Icons.star), label: const Text('أنهيت الدرس'))]));
}
const lessonContent = [
  ['نتوضأ ونلبس ملابس نظيفة','نقف باتجاه القبلة','نبدأ بتكبيرة الإحرام','نقرأ الفاتحة وما تيسر','نركع ثم نرفع','نسجد ونقوم بين السجدتين','نكمل الصلاة ونسلم في نهايتها','نتعلم الصلاة بالتدرج مع أهلنا'],
  ['نبدأ بالنية','نغسل الكفين','نتمضمض ونستنشق','نغسل الوجه','نغسل اليدين إلى المرفقين','نمسح الرأس والأذنين','نغسل الرجلين','نتجنب الإسراف في الماء'],
  ['نحافظ على الهدوء','نستمع ولا نعبث','نحافظ على نظافة المكان','نقف ونصلي باحترام','نستأذن عند الحاجة'],
  ['نقول السلام عليكم','نصدق في كلامنا','نرحم الصغير ونوقر الكبير','نحفظ الأمانة','نساعد من يحتاج'],
  ['ندخل المسجد بهدوء','نحافظ على نظافته','لا نرفع الصوت','نحترم المصلين','نخرج بهدوء'],
  ['نغتسل ونلبس ملابس نظيفة','نستعد للصلاة','نذهب بهدوء','نستمع للخطبة باهتمام','نحافظ على نظافة المسجد'],
  ['نسمي الله','نأكل باليمين','نأكل مما يلينا','لا نسرف في الطعام','نحمد الله بعد الطعام'],
  ['نرتب مكان النوم','نغسل أيدينا وأسناننا','نذكر الله','ننام بهدوء','نستيقظ بنشاط'],
  ['نحترم والدينا','نساعدهما','نتكلم بأدب','لا نرفع صوتنا عليهما','نشكرهما ونحسن إليهما'],
];

class RewardsPage extends StatelessWidget {
  final ChildProfile profile; const RewardsPage({super.key, required this.profile});
  @override Widget build(BuildContext context) => FutureBuilder<double>(future: Store.rewardValue(), builder: (_, snap) { final value = snap.data ?? 0; final total = profile.points * value; return Scaffold(appBar: AppBar(title: const Text('🎁 مكافآتي'), backgroundColor: burgundy, foregroundColor: Colors.white), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('⭐', style: TextStyle(fontSize: 70)), Text('${profile.points}', style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: burgundy)), const Text('نقطة', style: TextStyle(fontSize: 20)), const SizedBox(height: 15), Text('قيمة النقطة: ${value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)), const SizedBox(height: 10), Text('إجمالي المكافأة: ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: burgundy))])))); });
}

class ParentSettings extends StatefulWidget {
  final List<ChildProfile> children; const ParentSettings({super.key, this.children = const []});
  @override State<ParentSettings> createState() => _ParentSettingsState();
}
class _ParentSettingsState extends State<ParentSettings> {
  late TextEditingController valueController;
  double value = 0;
  @override void initState() { super.initState(); valueController = TextEditingController(); _load(); }
  Future<void> _load() async { value = await Store.rewardValue(); valueController.text = value.toString(); if (mounted) setState(() {}); }
  @override void dispose() { valueController.dispose(); super.dispose(); }
  Future<void> save() async { final v = double.tryParse(valueController.text.replaceAll(',', '.')) ?? 0; await Store.setRewardValue(v); if (mounted) { setState(() => value = v); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ قيمة النقطة'))); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('👨‍👩‍👧 إعدادات الأهل'), backgroundColor: burgundy, foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('تحديد المكافأة المادية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: burgundy)),
    const SizedBox(height: 8),
    const Text('الأهل يحددون قيمة النقطة. الألعاب التعليمية لا تمنح نقاطاً؛ النقاط هنا للمسار التعليمي والإنجازات.'),
    const SizedBox(height: 18),
    TextField(controller: valueController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'قيمة النقطة', prefixText: ' ' , border: OutlineInputBorder())),
    const SizedBox(height: 12),
    FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('حفظ قيمة المكافأة')),
    const SizedBox(height: 28),
    const Text('ملفات الأطفال', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: burgundy)),
    const SizedBox(height: 8),
    ...widget.children.map((c) => Card(child: ListTile(leading: const Icon(Icons.child_care, color: burgundy), title: Text(c.name), subtitle: Text('${c.points} نقطة')))),
    const SizedBox(height: 25),
    const Center(child: Text('© جميع الحقوق محفوظة — حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold))),
  ]));
}
