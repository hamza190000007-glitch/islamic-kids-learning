import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const burgundy = Color(0xFF6B1F2A);
const cream = Color(0xFFFFF8F5);
const gold = Color(0xFFF2B84B);

void main() {
  runApp(const KindergartenApp());
}

class Child {
  Child({required this.id, required this.name, this.points = 0});

  final String id;
  String name;
  int points;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'points': points,
      };

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'طفلي',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppStore {
  static const childrenKey = 'children_v4';
  static const rewardKey = 'reward_value_v3';

  static Future<List<Child>> loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(childrenKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => Child.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChildren(List<Child> children) async {
    final prefs = await SharedPreferences.getInstance();
    final data = children.map((e) => e.toJson()).toList();
    await prefs.setString(childrenKey, jsonEncode(data));
  }

  static Future<double> loadPointValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(rewardKey) ?? 0;
  }

  static Future<void> savePointValue(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(rewardKey, value);
  }

  static Future<void> addPoints(Child child, int amount) async {
    child.points += amount;
    final children = await loadChildren();
    final index = children.indexWhere((item) => item.id == child.id);
    if (index >= 0) {
      children[index] = child;
      await saveChildren(children);
    }
  }
}

class Voice {
  static final FlutterTts tts = FlutterTts();

  static Future<void> speak(String text, {bool english = false}) async {
    await tts.setLanguage(english ? 'en-US' : 'ar-SA');
    await tts.setSpeechRate(0.42);
    await tts.setPitch(1.08);
    await tts.speak(text);
  }
}

class KindergartenApp extends StatelessWidget {
  const KindergartenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رياض الأطفال',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: burgundy,
        scaffoldBackgroundColor: cream,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const StartPage(),
    );
  }
}

class Mosque extends StatelessWidget {
  const Mosque({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.72,
      child: CustomPaint(painter: MosquePainter()),
    );
  }
}

class MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = burgundy;
    final yellow = Paint()..color = gold;

    canvas.drawRect(
      Rect.fromLTWH(size.width * .18, size.height * .48, size.width * .64,
          size.height * .42),
      white,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * .28, size.height * .12, size.width * .44,
          size.height * .68),
      pi,
      pi,
      true,
      red,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .04, size.height * .25, size.width * .12,
          size.height * .65),
      white,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .84, size.height * .25, size.width * .12,
          size.height * .65),
      white,
    );
    canvas.drawCircle(
        Offset(size.width * .10, size.height * .23), size.width * .055, red);
    canvas.drawCircle(
        Offset(size.width * .90, size.height * .23), size.width * .055, red);
    canvas.drawRect(
      Rect.fromLTWH(size.width * .49, size.height * .02, size.width * .02,
          size.height * .17),
      red,
    );
    canvas.drawCircle(
        Offset(size.width * .50, size.height * .02), size.width * .035, yellow);
    canvas.drawArc(
      Rect.fromLTWH(size.width * .42, size.height * .54, size.width * .16,
          size.height * .36),
      pi,
      pi,
      true,
      red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Child>>(
      future: AppStore.loadChildren(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.isEmpty) return const SetupPage();
        return ChildChooser(children: snapshot.data!);
      },
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> enter() async {
    final name = controller.text.trim().isEmpty ? 'طفلي' : controller.text.trim();
    final child = Child(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    await AppStore.saveChildren([child]);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(child: child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Mosque(),
                const Text(
                  'رياض الأطفال',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: burgundy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('تعلّم • العب • اكتشف • ابتسم', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 28),
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'اكتب اسم الطفل',
                    prefixIcon: Icon(Icons.child_care),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: enter,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('دخول إلى رياض الأطفال', style: TextStyle(fontSize: 19)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '© جميع الحقوق محفوظة — حمزة أبو الفاتح',
                  style: TextStyle(color: burgundy, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChildChooser extends StatelessWidget {
  const ChildChooser({super.key, required this.children});

  final List<Child> children;

  Future<void> addChild(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة طفل جديد'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم الطفل'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final all = [
                  ...children,
                  Child(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                  ),
                ];
                await AppStore.saveChildren(all);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('من سيبدأ اليوم؟'),
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Mosque(size: 140),
          ...children.map(
            (child) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: burgundy,
                  child: Text(
                    child.name.characters.first,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  child.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${child.points} نقطة'),
                trailing: const Icon(Icons.play_circle_fill, color: burgundy),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomePage(child: child)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => addChild(context),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة طفل جديد'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '© حمزة أبو الفاتح',
              style: TextStyle(color: burgundy, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.child});

  final Child child;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcome();
    });
  }

  Future<void> _welcome() async {
    await Voice.speak('أهلاً وسهلاً يا ${widget.child.name}! ما شاء الله، نورت رياض الأطفال');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Center(
            child: Text('🎉 أهلاً بك يا بطل! 🎉', style: TextStyle(color: burgundy)),
          ),
          content: Text(
            '🌟 ⭐ 🌙 ⭐ 🌟\n\nيا ${widget.child.name}، سعيدون بوجودك معنا!\nهيا نتعلم ونلعب ونفرح معاً 💕',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('هيا نبدأ!'),
              ),
            ),
          ],
        );
      },
    );
  }

  void open(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget tile(String icon, String title, Color color, Widget page) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => open(page),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: burgundy,
        foregroundColor: Colors.white,
        title: Text('أهلاً ${widget.child.name} 🌟'),
        actions: [
          IconButton(
            onPressed: () => open(ParentSettings()),
            icon: const Icon(Icons.family_restroom),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Mosque(size: 75),
              Column(
                children: [
                  const Text(
                    'رياض الأطفال',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: burgundy),
                  ),
                  Text('${widget.child.points} نقطة مكافأة'),
                ],
              ),
            ],
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(14),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                tile('🔤', 'الحروف العربية', Colors.teal, LettersPage(child: widget.child)),
                tile('🇬🇧', 'English Letters', Colors.blue, EnglishLettersPage()),
                tile('١٢٣', 'الأرقام العربية', Colors.indigo, NumbersPage(english: false)),
                tile('123', 'English Numbers', Colors.deepOrange, NumbersPage(english: true)),
                tile('🎮', 'الألعاب التعليمية', Colors.orange, GameHub()),
                tile('🕌', 'التعلم الإسلامي', burgundy, IslamicHub(child: widget.child)),
                tile('🎁', 'مكافآتي', Colors.pink, RewardsPage(child: widget.child)),
                tile('👨‍👩‍👧', 'الأهل والأطفال', Colors.deepPurple, ParentSettings()),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 7),
            child: Text(
              '© حمزة أبو الفاتح',
              style: TextStyle(color: burgundy, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class LettersPage extends StatelessWidget {
  const LettersPage({super.key, required this.child});

  final Child child;
  static const letters = ['أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحروف العربية'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => Voice.speak(letters[index]),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: burgundy, width: 2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(letters[index], style: const TextStyle(fontSize: 36, color: burgundy, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EnglishLettersPage extends StatelessWidget {
  EnglishLettersPage({super.key});

  final List<String> letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('English Letters'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => Voice.speak(letters[index], english: true),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(18)),
              child: Center(child: Text(letters[index], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue))),
            ),
          );
        },
      ),
    );
  }
}

class NumbersPage extends StatelessWidget {
  const NumbersPage({super.key, required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) {
    final values = List.generate(20, (i) => i + 1);
    final arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return Scaffold(
      appBar: AppBar(title: Text(english ? 'English Numbers' : 'الأرقام العربية'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemCount: values.length,
        itemBuilder: (context, index) {
          final number = values[index];
          final text = english ? number.toString() : number.toString().split('').map((c) => arabic[int.parse(c)]).join();
          return InkWell(
            onTap: () => Voice.speak(number.toString(), english: english),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)),
              child: Center(child: Text(text, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: burgundy))),
            ),
          );
        },
      ),
    );
  }
}

class GameHub extends StatelessWidget {
  const GameHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الألعاب التعليمية'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          gameCard(context, '🎨', 'تلوين الشخصيات', const ColoringGame()),
          gameCard(context, '✏️', 'الرسم الحر', const DrawingGame()),
          gameCard(context, '🐱', 'خمن صوت الحيوان', const AnimalGame()),
          gameCard(context, '🧩', 'لعبة المطابقة', const MatchingGame()),
          const SizedBox(height: 10),
          const Text('الألعاب للمتعة والتعلّم ولا تمنح نقاطاً.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: burgundy)),
        ],
      ),
    );
  }

  Widget gameCard(BuildContext context, String icon, String title, Widget page) {
    return Card(
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 36)),
        title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

class ColoringGame extends StatefulWidget {
  const ColoringGame({super.key});

  @override
  State<ColoringGame> createState() => _ColoringGameState();
}

class _ColoringGameState extends State<ColoringGame> {
  Color selected = Colors.red;

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return Scaffold(
      appBar: AppBar(title: const Text('تلوين الشخصيات'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(child: Center(child: Icon(Icons.pets, size: 190, color: selected))),
          Wrap(
            spacing: 12,
            children: colors.map((color) => GestureDetector(onTap: () => setState(() => selected = color), child: CircleAvatar(backgroundColor: color))).toList(),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

class DrawingGame extends StatefulWidget {
  const DrawingGame({super.key});

  @override
  State<DrawingGame> createState() => _DrawingGameState();
}

class _DrawingGameState extends State<DrawingGame> {
  final points = <Offset>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسم الحر'), backgroundColor: burgundy, foregroundColor: Colors.white, actions: [IconButton(onPressed: () => setState(points.clear), icon: const Icon(Icons.delete))]),
      body: GestureDetector(
        onPanUpdate: (details) => setState(() => points.add(details.localPosition)),
        onPanEnd: (_) => setState(() => points.add(Offset.infinite)),
        child: CustomPaint(painter: DrawPainter(points), child: const SizedBox.expand()),
      ),
    );
  }
}

class DrawPainter extends CustomPainter {
  DrawPainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = burgundy..strokeWidth = 6..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      if (points[i].isInfinite || points[i + 1].isInfinite) continue;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) => oldDelegate.points != points;
}

class AnimalGame extends StatefulWidget {
  const AnimalGame({super.key});

  @override
  State<AnimalGame> createState() => _AnimalGameState();
}

class _AnimalGameState extends State<AnimalGame> {
  final animals = ['قطة', 'كلب', 'بقرة', 'أسد'];
  String current = 'قطة';

  void next() {
    final index = animals.indexOf(current);
    setState(() => current = animals[(index + 1) % animals.length]);
    Voice.speak('ما اسم هذا الحيوان؟');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خمن صوت الحيوان'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔊', style: TextStyle(fontSize: 90)),
            Text(current, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: burgundy)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => Voice.speak('هذا صوت $current'), icon: const Icon(Icons.volume_up), label: const Text('اسمع الصوت')),
            OutlinedButton(onPressed: next, child: const Text('حيوان آخر')),
          ],
        ),
      ),
    );
  }
}

class MatchingGame extends StatefulWidget {
  const MatchingGame({super.key});

  @override
  State<MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  final left = ['🍎', '🐱', '⭐', '🚗'];
  final right = ['⭐', '🚗', '🍎', '🐱'];
  int? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لعبة المطابقة'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('اختر الصورة ثم اختر الصورة المطابقة', style: TextStyle(fontSize: 18))),
          Expanded(
            child: ListView.builder(
              itemCount: left.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(left[index], style: const TextStyle(fontSize: 42)),
                      FilledButton(
                        onPressed: () {
                          setState(() => selected = index);
                          if (left[index] == right[index]) Voice.speak('أحسنت! مطابقة صحيحة');
                        },
                        child: Text(right[index], style: const TextStyle(fontSize: 30)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (selected != null) const Padding(padding: EdgeInsets.all(10), child: Text('ممتاز! استمر 👏', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class IslamicHub extends StatelessWidget {
  const IslamicHub({super.key, required this.child});

  final Child child;

  static const lessons = [
    ['🕌', 'الصلاة', 'نتعلم أن الصلاة صلة جميلة بالله ونحافظ على أوقاتها.'],
    ['💧', 'آداب الوضوء', 'نغسل أعضاء الوضوء بهدوء ولا نسرف في الماء.'],
    ['🤲', 'آداب الصلاة', 'نقف بأدب ونستمع ونحافظ على الهدوء.'],
    ['🌷', 'الأخلاق الإسلامية', 'نقول الصدق ونساعد الآخرين ونقول كلاماً طيباً.'],
    ['🕌', 'آداب المسجد', 'ندخل بأدب ونحافظ على نظافة المسجد وهدوئه.'],
    ['🌙', 'آداب يوم الجمعة', 'نحب يوم الجمعة ونكثر من الخير والصلاة على النبي.'],
    ['🍽️', 'آداب الطعام', 'نغسل أيدينا ونذكر اسم الله ولا نهدر الطعام.'],
    ['🌙', 'آداب النوم', 'نرتب مكاننا ونذكر الله وننام بهدوء.'],
    ['❤️', 'بر الوالدين', 'نحترم والدينا ونساعدهما ونقول لهما كلاماً جميلاً.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التعلم الإسلامي'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Card(
            child: ListTile(
              leading: Text(lesson[0], style: const TextStyle(fontSize: 34)),
              title: Text(lesson[1], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              subtitle: const Text('درس قصير + مكافأة 5 نقاط عند الإكمال'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IslamicLesson(child: child, title: lesson[1], text: lesson[2]))),
            ),
          );
        },
      ),
    );
  }
}

class IslamicLesson extends StatelessWidget {
  const IslamicLesson({super.key, required this.child, required this.title, required this.text});

  final Child child;
  final String title;
  final String text;

  Future<void> complete(BuildContext context) async {
    await AppStore.addPoints(child, 5);
    if (!context.mounted) return;
    await Voice.speak('أحسنت يا ${child.name}! حصلت على خمس نقاط');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة 5 نقاط 🎉')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Mosque(size: 150),
            Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: burgundy)),
            const SizedBox(height: 20),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 1.6)),
            const Spacer(),
            FilledButton.icon(onPressed: () => complete(context), icon: const Icon(Icons.check_circle), label: const Text('أنهيت الدرس +5 نقاط')),
          ],
        ),
      ),
    );
  }
}

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key, required this.child});

  final Child child;

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  double value = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await AppStore.loadPointValue();
    if (mounted) setState(() => value = result);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.child.points * value;
    return Scaffold(
      appBar: AppBar(title: const Text('مكافآتي'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 90)),
            Text('${widget.child.points} نقطة', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: burgundy)),
            const SizedBox(height: 12),
            Text('قيمة النقاط: ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            const Text('يحدد الأهل قيمة النقطة من الإعدادات.'),
          ],
        ),
      ),
    );
  }
}

class ParentSettings extends StatefulWidget {
  const ParentSettings({super.key});

  @override
  State<ParentSettings> createState() => _ParentSettingsState();
}

class _ParentSettingsState extends State<ParentSettings> {
  final controller = TextEditingController();
  double value = 0;
  List<Child> children = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final loadedChildren = await AppStore.loadChildren();
    final loadedValue = await AppStore.loadPointValue();
    if (!mounted) return;
    setState(() {
      children = loadedChildren;
      value = loadedValue;
      controller.text = loadedValue.toString();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final parsed = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    await AppStore.savePointValue(parsed);
    if (!mounted) return;
    setState(() => value = parsed);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ قيمة النقطة')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الأهل'), backgroundColor: burgundy, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('قيمة النقطة الواحدة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'قيمة')),
          const SizedBox(height: 10),
          FilledButton(onPressed: save, child: const Text('حفظ قيمة النقطة')),
          const SizedBox(height: 25),
          const Text('ملفات الأطفال', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children.map((child) => Card(child: ListTile(title: Text(child.name), subtitle: Text('${child.points} نقطة = ${(child.points * value).toStringAsFixed(2)}')))),
        ],
      ),
    );
  }
}
