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
  String name;
  int points;
  List<String> completed;
  List<String> badges;
  ChildProfile({required this.name, this.points = 0, List<String>? completed, List<String>? badges})
      : completed = completed ?? [], badges = badges ?? [];
  Map<String, dynamic> toMap() => {'name': name, 'points': points, 'completed': completed, 'badges': badges};
  factory ChildProfile.fromMap(Map<String, dynamic> m) => ChildProfile(
    name: (m['name'] ?? 'طفلي').toString(), points: (m['points'] ?? 0) as int,
    completed: List<String>.from(m['completed'] ?? const []), badges: List<String>.from(m['badges'] ?? const []));
}

class Store {
  static const childrenKey = 'children_v2';
  static const valueKey = 'reward_value';
  static Future<List<ChildProfile>> children() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(childrenKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => ChildProfile.fromMap(Map<String, dynamic>.from(e))).toList();
  }
  static Future<void> saveChildren(List<ChildProfile> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(childrenKey, jsonEncode(list.map((e) => e.toMap()).toList()));
  }
  static Future<double> rewardValue() async => (await SharedPreferences.getInstance()).getDouble(valueKey) ?? 0.0;
  static Future<void> setRewardValue(double v) async => (await SharedPreferences.getInstance()).setDouble(valueKey, v);
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
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: burgundy, scaffoldBackgroundColor: cream, fontFamily: 'Tahoma'),
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
    home: const StartPage(),
  );
}

class Mosque extends StatelessWidget {
  final double size;
  const Mosque({super.key, this.size = 190});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * .8, child: CustomPaint(painter: MosquePainter()));
}
class MosquePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final body = Paint()..color = Colors.white;
    final roof = Paint()..color = burgundy;
    final goldPaint = Paint()..color = gold;
    final dark = Paint()..color = burgundy;
    c.drawRect(Rect.fromLTWH(s.width*.18, s.height*.48, s.width*.64, s.height*.38), body);
    c.drawArc(Rect.fromLTWH(s.width*.27, s.height*.18, s.width*.46, s.height*.62), pi, pi, true, roof);
    c.drawRect(Rect.fromLTWH(s.width*.06, s.height*.27, s.width*.11, s.height*.59), body);
    c.drawRect(Rect.fromLTWH(s.width*.83, s.height*.27, s.width*.11, s.height*.59), body);
    c.drawCircle(Offset(s.width*.115, s.height*.25), s.width*.055, roof);
    c.drawCircle(Offset(s.width*.885, s.height*.25), s.width*.055, roof);
    c.drawRect(Rect.fromLTWH(s.width*.49, s.height*.05, s.width*.02, s.height*.17), dark);
    c.drawCircle(Offset(s.width*.5, s.height*.04), s.width*.035, goldPaint);
    c.drawArc(Rect.fromLTWH(s.width*.42, s.height*.5, s.width*.16, s.height*.34), pi, pi, true, dark);
    c.drawCircle(Offset(s.width*.38, s.height*.6), s.width*.035, goldPaint);
    c.drawCircle(Offset(s.width*.62, s.height*.6), s.width*.035, goldPaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<ChildProfile>>(
    future: Store.children(), builder: (context, snap) {
      if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return snap.data!.isEmpty ? const SetupPage() : ChildChooser(children: snap.data!);
    });
}

class SetupPage extends StatefulWidget { const SetupPage({super.key}); @override State<SetupPage> createState() => _SetupPageState(); }
class _SetupPageState extends State<SetupPage> {
  final controller = TextEditingController();
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> enter() async {
    final name = controller.text.trim().isEmpty ? 'طفلي' : controller.text.trim();
    final child = ChildProfile(name: name);
    await Store.saveChildren([child]);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(profile: child, allChildren: [child])));
  }
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      const Mosque(),
      const SizedBox(height: 8),
      const Text('رياض الأطفال', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: burgundy)),
      const Text('تعلّم • العب • اكتشف • ابتسم', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 24),
      TextField(controller: controller, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'اكتب اسم الطفل', prefixIcon: Icon(Icons.child_care), border: OutlineInputBorder())),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: enter, icon: const Icon(Icons.rocket_launch), label: const Padding(padding: EdgeInsets.all(10), child: Text('دخول إلى رياض الأطفال', style: TextStyle(fontSize: 19)))),
      const SizedBox(height: 22),
      const Text('حقوق التطبيق محفوظة © حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold)),
    ]))));
}

class ChildChooser extends StatelessWidget {
  final List<ChildProfile> children;
  const ChildChooser({super.key, required this.children});
  Future<void> add(BuildContext context) async {
    final c = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('إضافة طفل'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'اسم الطفل')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () async {
      final name = c.text.trim(); if (name.isEmpty) return; final all = [...children, ChildProfile(name: name)]; await Store.saveChildren(all); if (context.mounted) { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChildChooser(children: all))); }
    }, child: const Text('إضافة'))]));
    c.dispose();
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('من سيبدأ اليوم؟'), backgroundColor: burgundy, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Mosque(size: 140),
      ...children.asMap().entries.map((e) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: burgundy, child: Text(e.value.name.substring(0, 1), style: const TextStyle(color: Colors.white))), title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), subtitle: Text('${e.value.points} نقطة'), trailing: const Icon(Icons.play_circle_fill, color: burgundy), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(profile: e.value, allChildren: children))))),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => add(context), icon: const Icon(Icons.person_add), label: const Text('إضافة طفل جديد')),
      const SizedBox(height: 25),
      const Center(child: Text('حقوق التطبيق محفوظة © حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold))),
    ]));
}

class HomePage extends StatefulWidget {
  final ChildProfile profile; final List<ChildProfile> allChildren;
  const HomePage({super.key, required this.profile, required this.allChildren});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => welcome()); }
  Future<void> welcome() async {
    await Voice.say('أهلاً وسهلاً يا ${widget.profile.name}! ما شاء الله، نورت رياض الأطفال');
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: const Center(child: Text('🎉 أهلاً بك يا بطل! 🎉', style: TextStyle(color: burgundy))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('🌟 ⭐ 🌙 ⭐ 🌟', style: TextStyle(fontSize: 32)), const SizedBox(height: 10), Text('يا ${widget.profile.name}، سعيدون بوجودك معنا!\nهيا نتعلم ونلعب ونفرح معاً 💕', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))]),
      actions: [Center(child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('هيا نبدأ!')))],
    ));
  }
  void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) { if (mounted) setState(() {}); });
  Widget card(String icon, String title, Color color, VoidCallback onTap) => Card(color: color, clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 38)), const SizedBox(height: 6), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))]))));
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: burgundy, foregroundColor: Colors.white, title: Text('أهلاً ${widget.profile.name} 🌟'), actions: [IconButton(tooltip: 'الأهل', onPressed: () => open(const ParentSettings()), icon: const Icon(Icons.family_restroom))]),
    body: Column(children: [
      const SizedBox(height: 5),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Mosque(size: 75), Column(children: [Text('رياض الأطفال', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: burgundy)), Text('${widget.profile.points} نقطة مكافأة', style: const TextStyle(fontSize: 15))])]),
      Expanded(child: GridView.count(padding: const EdgeInsets.all(15), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
        card('🔤', 'الحروف العربية', Colors.teal, () => open(LettersPage(profile: widget.profile, english: false))),
        card('🇬🇧', 'English Letters', Colors.blue, () => open(LettersPage(profile: widget.profile, english: true))),
        card('١٢٣', 'الأرقام العربية', Colors.indigo, () => open(NumbersPage(profile: widget.profile, english: false))),
        card('123', 'English Numbers', Colors.deepOrange, () => open(NumbersPage(profile: widget.profile, english: true))),
        card('🎮', 'الألعاب التعليمية', Colors.orange, () => open(GameHub(profile: widget.profile))),
        card('🕌', 'التعلم الإسلامي', burgundy, () => open(IslamicHub(profile: widget.profile))),
        card('🎁', 'مكافآتي', Colors.pink, () => open(RewardsPage(profile: widget.profile))),
        card('👨‍👩‍👧', 'الأطفال والأهل', Colors.deepPurple, () => open(ParentSettings(children: widget.allChildren))),
      ])),
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('© جميع الحقوق محفوظة — حمزة أبو الفاتح', style: TextStyle(color: burgundy, fontWeight: FontWeight.bold))),
    ]));
}

Future<void> complete(ChildProfile p, String id, {int points = 5}) async {
  if (!p.completed.contains(id)) { p.completed.add(id); p.points += points; }
  final all = await Store.children();
  final i = all.indexWhere((x) => x.name == p.name);
  if (i >= 0) all[i] = p; else all.add(p);
  await Store.saveChildren(all);
}

class LettersPage extends StatefulWidget { final ChildProfile profile; final bool english; const LettersPage({super.key, required this.profile, required this.english}); @override State<LettersPage> createState() => _LettersPageState(); }
class _LettersPageState extends State<LettersPage> {
  final seen = <int>{}; late final List<String> letters;
  @override void initState() { super.initState(); letters = widget.english ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('') : 'أ ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي'.split(' '); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.english ? 'English Letters' : 'الحروف العربية'), backgroundColor: burgundy, foregroundColor: Colors.white), body: Column(children: [Padding(padding: const EdgeInsets.all(15), child: Text('اضغط على الحرف لسماعه 🔊  •  ${seen.length}/${letters.length}', style: const TextStyle(fontSize: 17))), Expanded(child: GridView.builder(padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: letters.length, itemBuilder: (_, i) => InkWell(onTap: () async { await Voice.say(letters[i], english: widget.english); setState(() => seen.add(i)); }, child: Container(decoration: BoxDecoration(color: seen.contains(i) ? Colors.green : Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(letters[i], style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: seen.contains(i) ? Colors.white : burgundy)))))))]));
}

class NumbersPage extends StatefulWidget { final ChildProfile profile; final bool english; const NumbersPage({super.key, required this.profile, required this.english}); @override State<NumbersPage> createState() => _NumbersPageState(); }
class _NumbersPageState extends State<NumbersPage> {
  final seen = <int>{};
  @override Widget build(BuildContext context) { final n = widget.english ? List.generate(20, (i) => '${i + 1}') : ['١','٢','٣','٤','٥','٦','٧','٨','٩','١٠','١١','١٢','١٣','١٤','١٥','١٦','١٧','١٨','١٩','٢٠']; return Scaffold(appBar: AppBar(title: Text(widget.english ? 'English Numbers' : 'الأرقام العربية'), backgroundColor: burgundy, foregroundColor: Colors.white), body: GridView.builder(padding: const EdgeInsets.all(18), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: n.length, itemBuilder: (_, i) => InkWell(onTap: () async { await Voice.say(n[i], english: widget.english); setState(() => seen.add(i)); }, child: Container(decoration: BoxDecoration(color: seen.contains(i) ? gold : Colors.white, border: Border.all(color: burgundy, width: 2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(n[i], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: burgundy)))))); }
}

class GameHub extends StatelessWidget { final ChildProfile profile; const GameHub({super.key, required this.profile}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('اختر لعبة'), backgroundColor: burgundy, foregroundColor: Colors.white), body: ListView(padding: const EdgeInsets.all(18), children: [gameTile(context, '🎨', 'تلوين الشخصيات', 'لوّن شخصيتك باللون الذي تحبه', Colors.pink, const ColoringGame()), gameTile(context, '✏️', 'الرسم الحر', 'ارسم بأصابعك ثم امسح وابدأ من جديد', Colors.teal, const DrawingGame()), gameTile(context, '🐾', 'خمن الحيوان من الصوت', 'اسمع الصوت واختر الحيوان الصحيح', Colors.orange, const AnimalSoundGame()), gameTile(context, '🧩', 'لعبة المطابقة', 'طابق الشكل مع الشكل نفسه', Colors.indigo, const MatchingGame())])); }
Widget gameTile(BuildContext c, String icon, String title, String sub, Color color, Widget page) => Card(color: color, child: ListTile(contentPadding: const EdgeInsets.all(14), leading: Text(icon, style: const TextStyle(fontSize: 42)), title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), subtitle: Text(sub, style: const TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_back_ios, color: Colors.white), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)));

class ColoringGame extends StatefulWidget { const ColoringGame({super.key}); @override State<ColoringGame> createState() => _ColoringGameState(); }
class _ColoringGameState extends State<ColoringGame> {
  Color selected = Colors.red; final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange]; int body = 0;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('🎨 تلوين الشخصيات'), backgroundColor: burgundy, foregroundColor: Colors.white), body: Column(children: [const Padding(padding: EdgeInsets.all(12), child: Text('اختر لوناً ثم اضغط على الشخصية', style: TextStyle(fontSize: 19))), Expanded(child: Center(child: GestureDetector(onTap: () => setState(() => body = selected.value), child: CustomPaint(size: const Size(280, 360), painter: CharacterPainter(body == 0 ? Colors.blue : Color(body))))),), Wrap(spacing: 8, children: colors.map((c) => GestureDetector(onTap: () => setState(() => selected = c), child: CircleAvatar(backgroundColor: c, child: selected == c ? const Icon(Icons.check, color: Colors.white) : null))).toList()), const SizedBox(height: 25)]));
}
class CharacterPainter extends CustomPainter { final Color color; CharacterPainter(this.color); @override void paint(Canvas c, Size s) { final skin = Paint()..color = const Color(0xFFFFD5B5); final body = Paint()..color = color; final dark = Paint()..color = burgundy; c.drawCircle(Offset(s.width*.5,s.height*.25),55,skin); c.drawRect(Rect.fromLTWH(s.width*.25,s.height*.4,s.width*.5,s.height*.45),body); c.drawCircle(Offset(s.width*.4,s.height*.24),5,dark); c.drawCircle(Offset(s.width*.6,s.height*.24),5,dark); c.drawArc(Rect.fromLTWH(s.width*.4,s.height*.28,s.width*.2,s.height*.1),0,pi,false,Paint()..color=dark.color..style=PaintingStyle.stroke..strokeWidth=3); c.drawLine(Offset(s.width*.35,s.height*.85),Offset(s.width*.3,s.height*.98),body..strokeWidth=15); c.drawLine(Offset(s.width*.65,s.height*.85),Offset(s.width*.7,s.height*.98),body..strokeWidth=15); } @override bool shouldRepaint(covariant CharacterPainter old) => old.color != color; }

class DrawingGame extends StatefulWidget { const DrawingGame({super.key}); @override State<DrawingGame> createState() => _DrawingGameState(); }
class _DrawingGameState extends State<DrawingGame> { final strokes = <List<Offset>>[]; Color color = burgundy; @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('✏️ الرسم الحر'), backgroundColor: burgundy, foregroundColor: Colors.white, actions: [IconButton(onPressed: () => setState(strokes.clear), icon: const Icon(Icons.delete))]), body: Column(children: [Expanded(child: GestureDetector(onPanStart: (d) => setState(() => strokes.add([d.localPosition])), onPanUpdate: (d) => setState(() => strokes.last.add(d.localPosition)), onPanEnd: (_) {}, child: CustomPaint(painter: DrawPainter(strokes, color), child: Container(color: Colors.white)))), Wrap(spacing: 8, children: [burgundy, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.black].map((x) => GestureDetector(onTap: () => setState(() => color = x), child: CircleAvatar(backgroundColor: x))).toList()), const SizedBox(height: 12)])); }
class DrawPainter extends CustomPainter { final List<List<Offset>> strokes; final Color color; DrawPainter(this.strokes,this.color); @override void paint(Canvas c, Size s) { final p=Paint()..color=color..strokeWidth=7..strokeCap=StrokeCap.round; for(final st in strokes){for(int i=1;i<st.length;i++) c.drawLine(st[i-1],st[i],p);}} @override bool shouldRepaint(covariant DrawPainter old)=>true; }

class AnimalSoundGame extends StatefulWidget { const AnimalSoundGame({super.key}); @override State<AnimalSoundGame> createState() => _AnimalSoundGameState(); }
class _AnimalSoundGameState extends State<AnimalSoundGame> { final animals = [{'name':'القطة','sound':'مياو مياو','icon':'🐱'},{'name':'البقرة','sound':'مووو','icon':'🐮'},{'name':'الخروف','sound':'ماء ماء','icon':'🐑'},{'name':'الأسد','sound':'زئير الأسد','icon':'🦁'}]; int question=0; bool? result; void newQuestion(){setState((){question=Random().nextInt(animals.length); result=null;}); Voice.say(animals[question]['sound']!);} @override void initState(){super.initState(); WidgetsBinding.instance.addPostFrameCallback((_){newQuestion();});} @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('🐾 خمن الحيوان من الصوت'),backgroundColor:burgundy,foregroundColor:Colors.white),body:Column(children:[const SizedBox(height:25),const Text('اسمع جيداً ثم اختر الحيوان 🔊',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),FilledButton.icon(onPressed:newQuestion,icon:const Icon(Icons.volume_up),label:const Text('تشغيل الصوت مرة أخرى')),Expanded(child:GridView.builder(padding:const EdgeInsets.all(18),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12),itemCount:animals.length,itemBuilder:(_,i)=>InkWell(onTap:(){final ok=i==question;setState(()=>result=ok);Voice.say(ok?'أحسنت! إجابة صحيحة':'حاول مرة أخرى');},child:Card(color:result==true&&i==question?Colors.green:Colors.white,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(animals[i]['icon']!,style:const TextStyle(fontSize:55)),Text(animals[i]['name']!,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))])))),if(result!=null)Padding(padding:const EdgeInsets.all(18),child:Text(result!?'ما شاء الله! أحسنت 🌟':'قريب جداً، حاول مرة أخرى 💪',style:TextStyle(fontSize:22,color:result!?Colors.green:burgundy,fontWeight:FontWeight.bold))) ])); }

class MatchingGame extends StatefulWidget { const MatchingGame({super.key}); @override State<MatchingGame> createState()=>_MatchingGameState(); }
class _MatchingGameState extends State<MatchingGame>{final icons=['⭐','🌙','❤️','🌸'];late List<String> cards;final opened=<int>[];final matched=<int>{};@override void initState(){super.initState();cards=[...icons,...icons]..shuffle();}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('🧩 المطابقة'),backgroundColor:burgundy,foregroundColor:Colors.white),body:GridView.builder(padding:const EdgeInsets.all(25),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:15,mainAxisSpacing:15),itemCount:cards.length,itemBuilder:(_,i)=>Card(child:InkWell(onTap:(){if(opened.length>=2||matched.contains(i))return;setState(()=>opened.add(i));if(opened.length==2){final a=opened[0],b=opened[1];if(cards[a]==cards[b]){setState((){matched.addAll([a,b]);opened.clear();});}else{Future.delayed(const Duration(milliseconds:650),(){if(mounted)setState(opened.clear);});}}},child:Center(child:Text((opened.contains(i)||matched.contains(i))?cards[i]:'?',style:const TextStyle(fontSize:48)))))));}

class IslamicHub extends StatelessWidget { final ChildProfile profile; const IslamicHub({super.key,required this.profile}); final lessons=const [['🕌','تعليم الصلاة','الصلاة خطوة جميلة نتعلمها مع الوالدين'],['💧','آداب الوضوء','النظافة والطهارة بهدوء وترتيب'],['🤲','آداب الصلاة','الهدوء والخشوع واحترام الصلاة'],['🌙','آداب الإسلام','السلام والصدق والرحمة والأمانة'],['🕌','آداب المسجد','ندخل بهدوء ونحافظ على نظافته'],['☀️','آداب الجمعة','نستعد للصلاة ونستمع للخطبة باهتمام'],['🍎','آداب الطعام','نسمي الله ونأكل باليمين ولا نسرف'],['😴','آداب النوم','نستعد للنوم بهدوء ونذكر الله'],['❤️','بر الوالدين','نحترم والدينا ونساعدهما ونحسن الكلام']]; @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('🕌 التعلم الإسلامي'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView.builder(padding:const EdgeInsets.all(15),itemCount:lessons.length,itemBuilder:(_,i){final x=lessons[i];return Card(child:ListTile(leading:Text(x[0],style:const TextStyle(fontSize:38)),title:Text(x[1],style:const TextStyle(fontWeight:FontWeight.bold,fontSize:19)),subtitle:Text(x[2]),trailing:const Icon(Icons.arrow_back_ios,color:burgundy),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>IslamicLesson(profile:profile,id:'islam$i',title:x[1],icon:x[0]))));})); }

class IslamicLesson extends StatefulWidget { final ChildProfile profile; final String id,title,icon; const IslamicLesson({super.key,required this.profile,required this.id,required this.title,required this.icon}); @override State<IslamicLesson> createState()=>_IslamicLessonState(); }
class _IslamicLessonState extends State<IslamicLesson>{late final List<String> lines;@override void initState(){super.initState();lines=_content(widget.id);}List<String> _content(String id){if(id=='islam0')return ['نستعد للصلاة مع الوالدين','نتوضأ ونلبس ملابس نظيفة','نقف باتجاه القبلة','نبدأ بتكبيرة الإحرام','نقرأ الفاتحة وما تيسر','نركع ثم نرفع ونقول ربنا ولك الحمد','نسجد ونقوم بين السجدتين','نكمل الصلاة ونسلم في نهايتها','الصلاة عبادة عظيمة، ونتعلمها بالتدرج مع أهلنا'];if(id=='islam1')return ['نبدأ بالنية','نغسل الكفين','نتمضمض ونستنشق','نغسل الوجه','نغسل اليدين إلى المرفقين','نمسح الرأس والأذنين','نغسل الرجلين','نتجنب الإسراف في الماء'];if(id=='islam2')return ['نحافظ على الهدوء','نستمع ولا نعبث','نحافظ على نظافة المكان','نقف ونصلي باحترام','نستأذن عند الحاجة'];if(id=='islam5')return ['نغتسل ونلبس ملابس نظيفة','نضع الطيب إن تيسر','نذهب للصلاة بهدوء','نستمع للخطبة','نكثر من الصلاة على النبي ﷺ','نحافظ على أدب المسجد'];if(id=='islam6')return ['نقول بسم الله','نأكل باليمين','نأكل مما أمامنا','لا نسرف في الطعام','نحمد الله بعد الطعام'];if(id=='islam7')return ['نتوضأ ونستعد للنوم','نرتب مكاننا','نقرأ أذكار النوم مع الوالدين','ننام على هدوء ونستيقظ بنشاط'];if(id=='islam8')return ['نتكلم بأدب','نساعد والدينا','نشكرهما','لا نرفع صوتنا عليهما','نطلب منهما الخير ونحسن إليهما'];return ['نقول السلام عليكم','نصدق في كلامنا','نحفظ الأمانة','نرحم الصغير ونحترم الكبير','نساعد من يحتاج','نحافظ على نظافة المكان'];}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('${widget.icon} ${widget.title}'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(20),children:[Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:lines.asMap().entries.map((e)=>ListTile(leading:CircleAvatar(backgroundColor:burgundy,foregroundColor:Colors.white,child:Text('${e.key+1}')),title:Text(e.value,style:const TextStyle(fontSize:18)),onTap:()=>Voice.say(e.value))).toList()))),FilledButton.icon(onPressed:()async{await complete(widget.profile,widget.id,points:5);if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ما شاء الله! أضفنا 5 نقاط للمكافأة 🌟')));},icon:const Icon(Icons.check_circle),label:const Text('أنهيت الدرس'))]));}

class RewardsPage extends StatefulWidget { final ChildProfile profile; const RewardsPage({super.key,required this.profile}); @override State<RewardsPage> createState()=>_RewardsPageState(); }
class _RewardsPageState extends State<RewardsPage>{double value=0;@override void initState(){super.initState();Store.rewardValue().then((v){if(mounted)setState(()=>value=v);});}@override Widget build(BuildContext c){final money=widget.profile.points*value;return Scaffold(appBar:AppBar(title:const Text('🎁 مكافآتي'),backgroundColor:burgundy,foregroundColor:Colors.white),body:Padding(padding:const EdgeInsets.all(22),child:Column(children:[const Text('هذه النقاط للمكافأة التي يحددها الأهل 💕',style:TextStyle(fontSize:20),textAlign:TextAlign.center),const SizedBox(height:25),Text('${widget.profile.points}',style:const TextStyle(fontSize:70,fontWeight:FontWeight.bold,color:burgundy)),const Text('نقطة',style:TextStyle(fontSize:22)),const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(18),child:Text('قيمة النقاط الحالية: ${money.toStringAsFixed(2)}',style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)))),const SizedBox(height:15),const Text('الألعاب التعليمية لا تخصم ولا تمنح نقاطاً؛ النقاط تأتي من الأنشطة التعليمية التي يختارها الأهل.',textAlign:TextAlign.center)]));}}

class ParentSettings extends StatefulWidget { final List<ChildProfile> children; const ParentSettings({super.key,this.children=const []}); @override State<ParentSettings> createState()=>_ParentSettingsState(); }
class _ParentSettingsState extends State<ParentSettings>{final controller=TextEditingController();@override void initState(){super.initState();Store.rewardValue().then((v){if(mounted){controller.text=v.toString();setState((){});}});}@override void dispose(){controller.dispose();super.dispose();}Future<void> save()async{final v=double.tryParse(controller.text.replaceAll(',','.'))??0;await Store.setRewardValue(v);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ قيمة النقطة للمكافأة')));}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('👨‍👩‍👧 إعدادات الأهل'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(20),children:[Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('قيمة النقطة',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold,color:burgundy)),const SizedBox(height:8),const Text('حدد المبلغ الذي تساويه النقطة الواحدة. يمكنك استخدام أي عملة.'),const SizedBox(height:12),TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'مثال: 0.50',suffixText:'لكل نقطة',border:OutlineInputBorder())),const SizedBox(height:12),FilledButton.icon(onPressed:save,icon:const Icon(Icons.save),label:const Text('حفظ'))]))),const SizedBox(height:18),const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('نظام المكافآت\n• الألعاب لا تعطي نقاطاً.\n• يمكن للأنشطة والدروس أن تمنح نقاطاً.\n• الأهل يحددون قيمة النقطة.\n• كل طفل لديه ملف مستقل وتقدمه محفوظ بشكل منفصل.',style:TextStyle(fontSize:17,height:1.7)))),const SizedBox(height:18),const Card(child:Padding(padding:EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('حقوق التطبيق',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:burgundy)),SizedBox(height:8),Text('رياض الأطفال\n© جميع الحقوق محفوظة\nحمزة أبو الفاتح',style:TextStyle(fontSize:18,height:1.6))]))]));}
