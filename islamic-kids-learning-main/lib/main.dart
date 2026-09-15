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
const kidBlue = Color(0xFF3B82C4);
const kidGreen = Color(0xFF39A96B);
const kidPurple = Color(0xFF8B5CF6);
const kidOrange = Color(0xFFF59E0B);
const kidPink = Color(0xFFE85D9E);
const kidTeal = Color(0xFF20A9A6);

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
      // نبدأ باللهجة السورية، ثم ننتقل تلقائياً لأقرب صوت عربي متاح على الهاتف.
      try {
        await tts.setLanguage('ar-SY');
      } catch (_) {
        try {
          await tts.setLanguage('ar-LB');
        } catch (_) {
          try {
            await tts.setLanguage('ar-JO');
          } catch (_) {
            try { await tts.setLanguage('ar-SA'); } catch (_) {}
          }
        }
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
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kidPurple,
          scaffoldBackgroundColor: cream,
          fontFamily: 'sans',
          appBarTheme: const AppBarTheme(backgroundColor: burgundy, foregroundColor: Colors.white, centerTitle: true),
          cardTheme: CardThemeData(elevation: 3, margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)))),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18)), borderSide: BorderSide(color: kidPurple, width: 2))),
        ),
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

class NoorImage extends StatelessWidget {
  const NoorImage({super.key, this.size = 120});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .20),
      child: Stack(children: [
        Positioned(right: 0, top: 0, width: size * 2.75, height: size, child: Image.asset('assets/images/children_logo.png', fit: BoxFit.cover)),
      ]),
    ),
  );
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
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage>{
  @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_)=>_welcome());}
  Future<void>_welcome()async{await Voice.speak('أهلاً يا ${widget.child.name}! أنا نور، خلينا نتعلم ونلعب سوا.');if(!mounted)return;}
  void open(Widget page)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>page)).then((_){if(mounted)setState((){});});
  Widget tile(String icon,String title,Color color,Widget page)=>Card(color:color,clipBehavior:Clip.antiAlias,child:InkWell(onTap:()=>open(page),child:Padding(padding:const EdgeInsets.all(12),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(icon,style:const TextStyle(fontSize:36)),const SizedBox(height:6),Text(title,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold))]))));
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text('أهلاً ${widget.child.name} 🌟'),actions:[IconButton(onPressed:()=>open(const ParentSettings()),icon:const Icon(Icons.family_restroom))]),
    body:ListView(padding:const EdgeInsets.fromLTRB(12,10,12,18),children:[
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFEDE9FE),Color(0xFFFFEAF4)]),borderRadius:BorderRadius.circular(28)),child:Row(children:[const NoorImage(size:110),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('أنا نور 🌷',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold,color:burgundy)),const SizedBox(height:4),Text('رحلتنا اليوم: تعلّم + لعب + نجوم',style:const TextStyle(fontSize:16)),const SizedBox(height:10),LinearProgressIndicator(value:(widget.child.points%100)/100,minHeight:10,borderRadius:BorderRadius.circular(10)),const SizedBox(height:4),Text('${widget.child.points} نقطة ⭐',style:const TextStyle(fontWeight:FontWeight.bold,color:burgundy))]))]),),
      const SizedBox(height:10),
      FilledButton.icon(onPressed:()=>open(LearningPathPage(child:widget.child)),icon:const Icon(Icons.map),label:const Padding(padding:EdgeInsets.all(10),child:Text('رحلتي التعليمية اليوم',style:TextStyle(fontSize:18)))),
      const SizedBox(height:8),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.12,children:[
        tile('أب','الحروف العربية',kidTeal,LettersPage(child:widget.child)),tile('ABC','الحروف الإنجليزية',kidBlue,EnglishLettersPage()),tile('١٢٣','الأرقام العربية',kidPurple,NumbersPage(english:false)),tile('＋−×÷','الرياضيات',kidOrange,MathChallenge(child:widget.child)),tile('🎨','الرسم والتلوين',kidPink,const GameHub()),tile('🐾','عالم الحيوانات',kidGreen,const AnimalGame()),tile('🕌','آداب الإسلام',burgundy,IslamicHub(child:widget.child)),tile('❓','اختبار إسلامي',const Color(0xFF8A5A44),IslamicQuiz(child:widget.child)),tile('🌷','صديقتي نور',const Color(0xFF7C5CC4),AiFriendPage(child:widget.child)),tile('🎁','مكافآتي',const Color(0xFFE08A2E),RewardsPage(child:widget.child)),
      ]),
      const SizedBox(height:8),
      OutlinedButton.icon(onPressed:()=>open(const GameHub()),icon:const Icon(Icons.sports_esports),label:const Text('مركز الألعاب التعليمية')),
      const SizedBox(height:8),
      const Center(child:Text('© حمزة أبو الفاتح',style:TextStyle(color:burgundy,fontWeight:FontWeight.bold))),
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
    final values = List.generate(100, (i) => i + 1);
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
        gameCard(context, '🧮', 'تحدي الجمع والطرح والضرب', const MathChallenge()),
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

class MathChallenge extends StatefulWidget {
  const MathChallenge({super.key, this.child});
  final Child? child;
  @override State<MathChallenge> createState()=>_MathChallengeState();
}

class _MathChallengeState extends State<MathChallenge> {
  final rng = Random();
  int a=3,b=2,answer=5,score=0,round=1,level=1;
  String op='+';
  List<int> choices=[];
  bool answered=false;

  @override void initState(){super.initState(); _next();}
  void _next(){
    answered=false;
    final maxValue=level==1?10:level==2?30:100;
    final ops=level==1?['+','-']:level==2?['+','-','×']:['+','-','×','÷'];
    op=ops[rng.nextInt(ops.length)];
    if(op=='×') { a=1+rng.nextInt(level==2?8:12); b=1+rng.nextInt(level==2?8:12); }
    else if(op=='÷') { b=1+rng.nextInt(10); answer=1+rng.nextInt(level==3?12:6); a=b*answer; }
    else { a=1+rng.nextInt(maxValue); b=1+rng.nextInt(maxValue); if(op=='-' && b>a){final t=a;a=b;b=t;} }
    answer=op=='+'?a+b:op=='-'?a-b:op=='×'?a*b:a~/b;
    final set=<int>{answer};
    while(set.length<4){set.add(max(0,answer+rng.nextInt(13)-6));}
    choices=set.toList()..shuffle();
  }
  Future<void> pick(int n) async {
    if(answered) return;
    answered=true;
    if(n==answer){
      score+=10;
      if(widget.child!=null) await AppStore.addPoints(widget.child!,10);
      await Voice.speak('أحسنت! الإجابة صحيحة، ممتاز يا بطل');
    } else { await Voice.speak('قريب! جرّب المسألة التالية'); }
    if(mounted)setState((){if(n==answer)round++;_next();});
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('رياضيات ممتعة')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('الجولة $round',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),Text('⭐ $score',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:kidOrange))])),
      const SizedBox(height:12),
      SegmentedButton<int>(segments:const [ButtonSegment(value:1,label:Text('سهل')),ButtonSegment(value:2,label:Text('متوسط')),ButtonSegment(value:3,label:Text('متقدم'))],selected:{level},onSelectionChanged:(v)=>setState((){level=v.first;round=1;score=0;_next();})),
      const SizedBox(height:24),
      const Text('حل المسألة',style:TextStyle(fontSize:22,color:burgundy,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
      const SizedBox(height:14),
      Container(padding:const EdgeInsets.symmetric(vertical:26,horizontal:12),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFEDE9FE),Color(0xFFFFEAF4)]),borderRadius:BorderRadius.circular(28)),child:Text('$a  $op  $b  =  ؟',textAlign:TextAlign.center,style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold,color:burgundy))),
      const SizedBox(height:22),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,children:[for(int i=0;i<choices.length;i++) FilledButton(onPressed:()=>pick(choices[i]),style:FilledButton.styleFrom(backgroundColor:[kidBlue,kidGreen,kidPurple,kidPink][i]),child:Text('${choices[i]}',style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold))) ]),
      const SizedBox(height:18),
      FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MathWordProblems(child:widget.child))),icon:const Icon(Icons.auto_stories),label:const Text('مسائل كلامية للأطفال')),
      const SizedBox(height:8),
      const Text('كل إجابة صحيحة = 10 نقاط ⭐',textAlign:TextAlign.center,style:TextStyle(fontSize:16)),
    ]),
  );
}

class MathWordProblems extends StatefulWidget {
  const MathWordProblems({super.key,this.child});
  final Child? child;
  @override State<MathWordProblems> createState()=>_MathWordProblemsState();
}
class _MathWordProblemsState extends State<MathWordProblems>{
  final rng=Random(); int a=3,b=2,answer=5,score=0; String text=''; List<int> choices=[];
  @override void initState(){super.initState();next();}
  void next(){final add=rng.nextBool();a=2+rng.nextInt(8);b=1+rng.nextInt(7);answer=add?a+b:max(0,a-b);text=add?'مع نور $a نجوم ثم حصلت على $b نجوم أخرى. كم نجمة أصبحت؟':'كان لدى نور $a تفاحات وأعطت $b لصديقتها. كم تفاحة بقيت؟';final set=<int>{answer};while(set.length<4)set.add(max(0,answer+rng.nextInt(7)-3));choices=set.toList()..shuffle();}
  Future<void>pick(int n)async{if(n==answer){score+=10;if(widget.child!=null)await AppStore.addPoints(widget.child!,10);await Voice.speak('ممتاز! فهمت المسألة');}else await Voice.speak('فكر بهدوء وحاول مرة ثانية');if(mounted)setState(next);}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('مسائل كلامية')),body:Padding(padding:const EdgeInsets.all(18),child:Column(children:[Text('⭐ $score نقطة',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:kidOrange)),const SizedBox(height:25),Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(25)),child:Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:25,height:1.6))),const SizedBox(height:25),...choices.map((n)=>Padding(padding:const EdgeInsets.only(bottom:10),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>pick(n),child:Text('$n',style:const TextStyle(fontSize:24))))))])));
}

class Animal {
  const Animal(this.name, this.kind, this.soundUrl, this.fact, this.emoji);
  final String name, kind, soundUrl, fact, emoji;
}

const animalList = [
  Animal('القطة','cat','https://commons.wikimedia.org/wiki/Special:Redirect/file/Meow_domestic_cat.ogg','القطة حيوان أليف، وصوتها مياو.','🐱'),
  Animal('الكلب','dog','https://commons.wikimedia.org/wiki/Special:Redirect/file/Barking_of_a_dog.ogg','الكلب ينبح ويحرس ويحتاج إلى رعاية ورحمة.','🐶'),
  Animal('البقرة','cow','https://commons.wikimedia.org/wiki/Special:Redirect/file/Single_Cow_Moo.ogg','البقرة من الحيوانات التي تعطينا الحليب، وصوتها موو.','🐮'),
  Animal('الأسد','lion','https://commons.wikimedia.org/wiki/Special:Redirect/file/Lion_raring-sound1TamilNadu178.ogg','الأسد حيوان قوي يعيش في البرية ويزأر.','🦁'),
];

class AnimalGame extends StatefulWidget { const AnimalGame({super.key}); @override State<AnimalGame> createState()=>_AnimalGameState(); }
class _AnimalGameState extends State<AnimalGame> {
  final player=AudioPlayer(); int index=0; bool playing=false;
  @override void dispose(){player.dispose();super.dispose();}
  Future<void> playAnimal() async {
    if(playing)return;
    setState(()=>playing=true);
    try { await player.stop(); await player.play(UrlSource(animalList[index].soundUrl),volume:1.0); } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('لم يتم تشغيل الصوت. تأكد من اتصال الإنترنت.')));
    } finally { if(mounted)setState(()=>playing=false); }
  }
  @override Widget build(BuildContext context){final a=animalList[index];return Scaffold(appBar:AppBar(title:const Text('عالم الحيوانات')),body:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,14,16,4),child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Row(children:[Text(a.emoji,style:const TextStyle(fontSize:54)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.name,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold,color:burgundy)),Text(a.fact,style:const TextStyle(fontSize:16,height:1.4))]))]))),
    Expanded(child:Center(child:Container(width:330,height:330,padding:const EdgeInsets.all(12),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFEAF7FF),Color(0xFFFFF8F5)]),borderRadius:BorderRadius.circular(42),boxShadow:[BoxShadow(color:Colors.black12,blurRadius:12)]),child:CustomPaint(painter:AnimalPainter(a.kind))))),
    FilledButton.icon(onPressed:playAnimal,icon:Icon(playing?Icons.graphic_eq_rounded:Icons.volume_up_rounded),label:Text(playing?'جاري تشغيل الصوت...':'اسمع صوت ${a.name}',style:const TextStyle(fontSize:20))),
    const SizedBox(height:12),
    Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[IconButton(onPressed:()=>setState(()=>index=(index-1+animalList.length)%animalList.length),icon:const Icon(Icons.arrow_back_ios_rounded,size:30)),Text('${index+1} / ${animalList.length}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),IconButton(onPressed:()=>setState(()=>index=(index+1)%animalList.length),icon:const Icon(Icons.arrow_forward_ios_rounded,size:30))]),const SizedBox(height:15),
  ]));}
}

class AnimalPainter extends CustomPainter {
  AnimalPainter(this.kind); final String kind;
  @override void paint(Canvas c,Size s){
    final p=Paint()..style=PaintingStyle.fill; final w=s.width; final h=s.height;
    void eye(double x,double y){p.color=Colors.black;c.drawCircle(Offset(x,y),8,p);p.color=Colors.white;c.drawCircle(Offset(x-2,y-3),2.5,p);}
    if(kind=='cat'){
      p.color=const Color(0xFFF2A7C7); c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.57),width:w*.56,height:h*.50),p); c.drawPath(Path()..moveTo(w*.25,h*.40)..lineTo(w*.30,h*.15)..lineTo(w*.44,h*.34)..close(),p); c.drawPath(Path()..moveTo(w*.75,h*.40)..lineTo(w*.70,h*.15)..lineTo(w*.56,h*.34)..close(),p); eye(w*.42,h*.50);eye(w*.58,h*.50); p.color=Colors.pink;c.drawCircle(Offset(w*.5,h*.59),7,p); p.color=Colors.black;c.drawArc(Rect.fromLTWH(w*.43,h*.60,w*.14,h*.10),0,pi,false,p..style=PaintingStyle.stroke..strokeWidth=4); p.style=PaintingStyle.fill;
    } else if(kind=='dog'){
      p.color=const Color(0xFFB9825B); c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.56),width:w*.58,height:h*.54),p); p.color=const Color(0xFF7D5137);c.drawOval(Rect.fromCenter(center:Offset(w*.25,h*.50),width:w*.20,height:h*.42),p);c.drawOval(Rect.fromCenter(center:Offset(w*.75,h*.50),width:w*.20,height:h*.42),p);eye(w*.42,h*.49);eye(w*.58,h*.49);p.color=Colors.black;c.drawCircle(Offset(w*.5,h*.60),16,p);
    } else if(kind=='cow'){
      p.color=Colors.white;c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.56),width:w*.62,height:h*.50),p);p.color=Colors.black;c.drawOval(Rect.fromCenter(center:Offset(w*.35,h*.50),width:55,height:70),p);c.drawOval(Rect.fromCenter(center:Offset(w*.65,h*.61),width:60,height:65),p);eye(w*.42,h*.47);eye(w*.58,h*.47);p.color=const Color(0xFFFFA9B7);c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.62),width:100,height:55),p);p.color=Colors.black;c.drawCircle(Offset(w*.46,h*.62),6,p);c.drawCircle(Offset(w*.54,h*.62),6,p);
    } else if(kind=='lion'){
      p.color=const Color(0xFFB87926);c.drawCircle(Offset(w*.5,h*.52),w*.34,p);p.color=const Color(0xFFFFC857);c.drawCircle(Offset(w*.5,h*.55),w*.23,p);eye(w*.43,h*.51);eye(w*.57,h*.51);p.color=Colors.black;c.drawCircle(Offset(w*.5,h*.60),12,p);
    } else if(kind=='elephant'){
      p.color=const Color(0xFF9AA7B2);c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.55),width:w*.62,height:h*.45),p);c.drawCircle(Offset(w*.32,h*.43),w*.16,p);c.drawCircle(Offset(w*.68,h*.43),w*.16,p);eye(w*.42,h*.48);eye(w*.58,h*.48);p.style=PaintingStyle.stroke;p.strokeWidth=28;p.strokeCap=StrokeCap.round;c.drawArc(Rect.fromLTWH(w*.42,h*.50,w*.16,h*.30),pi/2,pi/2,false,p);p.style=PaintingStyle.fill;
    } else {
      p.color=const Color(0xFF9B6A4A);c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.57),width:w*.60,height:h*.42),p);p.color=const Color(0xFFE8C9A8);c.drawOval(Rect.fromCenter(center:Offset(w*.5,h*.45),width:w*.35,height:h*.30),p);eye(w*.44,h*.44);eye(w*.56,h*.44);p.color=Colors.black;c.drawArc(Rect.fromLTWH(w*.45,h*.48,w*.10,h*.08),0,pi,false,p..style=PaintingStyle.stroke..strokeWidth=3);p.style=PaintingStyle.fill;
    }
  }
  @override bool shouldRepaint(covariant AnimalPainter oldDelegate)=>oldDelegate.kind!=kind;
}

class MatchingGame extends StatefulWidget { const MatchingGame({super.key}); @override State<MatchingGame> createState()=>_MatchingGameState(); }
class _MatchingGameState extends State<MatchingGame>{ final pairs=[['🍎','🍎'],['🐱','🐱'],['⭐','⭐'],['🚗','🚗']]; final selected=<int>{}; @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('لعبة المطابقة'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('طابق كل صورة مع مثلها',style:TextStyle(fontSize:20),textAlign:TextAlign.center),...List.generate(pairs.length,(i)=>Card(child:ListTile(leading:Text(pairs[i][0],style:const TextStyle(fontSize:42)),trailing:FilledButton(onPressed:()=>setState(()=>selected.add(i)),child:Text(selected.contains(i)?'أحسنت!':'طابق',style:const TextStyle(fontSize:20))))))])); }

class IslamicHub extends StatelessWidget {
  const IslamicHub({super.key, required this.child}); final Child child;
  static const lessons = [
    ['🕋','الإيمان بالله',['نعرف أن الله خالقنا ونشكره على نعمه.','نحب الخير ونبتعد عن الأذى.','نقول الحمد لله عندما نتذكر نعمه.','نسأل أهلنا عندما لا نعرف جواباً دينياً.']],
    ['📖','آداب القرآن',['نغسل أيدينا ونحافظ على نظافة المصحف.','نستمع بهدوء ولا نعبث أثناء التلاوة.','نقرأ ونتعلم حسب قدرتنا.','نحاول أن نعمل بالأخلاق الجميلة التي نتعلمها.']],
    ['🕌','آداب الصلاة',['نتوضأ ونرتدي لباساً نظيفاً ومحتشماً.','نحافظ على الصلاة في وقتها مع أهلنا.','نقف بهدوء ونحاول التركيز في الصلاة.','بعد الصلاة نحمد الله ونسأل الخير.']],
    ['💧','آداب الوضوء',['نبدأ بهدوء ونحافظ على الماء.','نتعلم ترتيب الوضوء من أهلنا.','لا نسرف في الماء.','نرتب مكان الوضوء بعد الانتهاء.']],
    ['🕌','آداب المسجد',['ندخل بهدوء ونحافظ على نظافته.','لا نرفع أصواتنا ولا نزعج المصلين.','نضع الأحذية في مكانها.','نحترم الكبير والصغير في المسجد.']],
    ['🍽️','آداب الطعام والشراب',['نغسل أيدينا قبل الطعام.','نذكر اسم الله قبل الطعام.','نأكل بهدوء ولا نهدر الطعام.','نحمد الله بعد الطعام ونحافظ على النظافة.']],
    ['🌙','آداب النوم والاستيقاظ',['نرتب مكان النوم وننظف أسناننا.','نستعد للنوم بهدوء ونذكر الله.','ننام بوقت مناسب لنستيقظ نشيطين.','نبدأ يومنا بالسلام والحمد والنشاط.']],
    ['❤️','بر الوالدين',['نحترم ماما وبابا ونسمع كلامهما في الخير.','نساعدهما بما نستطيع.','نقول كلاماً طيباً ولا نرفع صوتنا عليهما.','ندعو لهما ونشكرهما.']],
    ['🌷','الأخلاق والصدق',['نقول الحقيقة حتى لو أخطأنا.','إذا أخطأنا نعتذر ونحاول إصلاح الخطأ.','نساعد الآخرين ونشاركهم الخير.','لا نسخر من أحد ولا نؤذيه.']],
    ['🤝','آداب التعامل مع الآخرين',['نبدأ بالسلام.','نحترم دور الآخرين ونستأذن قبل أخذ شيء.','نحافظ على مشاعر أصدقائنا.','نساعد من يحتاج المساعدة.']],
    ['🏠','آداب البيت والمدرسة',['نرتب ألعابنا وأغراضنا بعد استخدامها.','نحافظ على الهدوء عندما يحتاج الآخرون للراحة.','نحترم المعلم ونستمع إليه.','نحافظ على أدواتنا ومكاننا نظيفاً.']],
    ['👕','النظافة واللباس',['نغسل أيدينا ونستحم وننظف أسناننا.','نرتدي ملابس نظيفة ومناسبة.','نحافظ على أظافرنا وشعرنا نظيفين.','نحافظ على نظافة المكان من حولنا.']],
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
  @override State<AiFriendPage> createState() => _AiFriendPageState();
}

class _AiFriendPageState extends State<AiFriendPage> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[
    {'role': 'assistant', 'text': 'مرحباً! أنا نور 🌟 اسألني عن الدرس أو اللعبة أو أي سؤال مناسب للأطفال.'},
  ];
  bool loading = false;
  String endpoint = '';
  @override void initState() { super.initState(); _loadEndpoint(); }
  Future<void> _loadEndpoint() async { final value = await AppStore.loadAiEndpoint(); if (mounted) setState(() => endpoint = value); }
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> send() async {
    final question = controller.text.trim();
    if (question.isEmpty || loading) return;
    controller.clear();
    setState(() { messages.add({'role':'user','text':question}); loading = true; });
    final answer = await AiFriendService.ask(question, endpoint: endpoint);
    if (!mounted) return;
    setState(() { messages.add({'role':'assistant','text':answer}); loading = false; });
    await Voice.speak(answer);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('صديقتي نور 🌷')),
    body: Column(children: [
      Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFFFFEAF4),Color(0xFFEDE9FE)]), borderRadius: BorderRadius.circular(26)), child: Row(children:[const NoorImage(size:105), const SizedBox(width:12), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[const Text('نور',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold,color:burgundy)), const SizedBox(height:4), Text('مساعدة لطيفة تتكلم معك وتشرح الدروس بطريقة بسيطة.',style:TextStyle(fontSize:16,height:1.4)), const SizedBox(height:6), Text('يمكنك أن تسأليني عن الرياضيات أو الحيوانات أو آداب الإسلام.',style:TextStyle(fontSize:14,color:Colors.black87))]))]),),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal:12), itemCount: messages.length, itemBuilder:(context,i){ final m=messages[i]; final user=m['role']=='user'; return Align(alignment:user?Alignment.centerRight:Alignment.centerLeft, child: Container(margin:const EdgeInsets.symmetric(vertical:5), padding:const EdgeInsets.all(14), constraints:const BoxConstraints(maxWidth:330), decoration:BoxDecoration(color:user?const Color(0xFFE1F0FF):Colors.white, borderRadius:BorderRadius.circular(20)), child:Text(m['text']??'',style:const TextStyle(fontSize:18,height:1.45))));})),
      if (loading) const Padding(padding:EdgeInsets.all(4),child:Text('نور يفكر... 💭')),
      SafeArea(child: Padding(padding:const EdgeInsets.all(10), child:Row(children:[Expanded(child:TextField(controller:controller,textInputAction:TextInputAction.send,onSubmitted:(_)=>send(),decoration:const InputDecoration(hintText:'اكتب سؤالك يا بطل...'))),const SizedBox(width:8),FilledButton(onPressed:loading?null:send,child:const Icon(Icons.send_rounded))]))),
    ]),
  );
}

class LearningPathPage extends StatelessWidget {
  const LearningPathPage({super.key,required this.child}); final Child child;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('رحلتي التعليمية')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(colors:[kidPurple,kidBlue]),borderRadius:BorderRadius.circular(26)),child:Column(children:[const Text('⭐ رحلة نور اليومية',style:TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('كل خطوة صغيرة تصنع تقدماً كبيراً يا ${child.name}',style:const TextStyle(color:Colors.white,fontSize:17),textAlign:TextAlign.center)])),
    const SizedBox(height:12),
    _path(context,'🔤','الحروف العربية','تعلّم الحروف مع الصوت',LettersPage(child:child),kidTeal),
    _path(context,'🔢','الأرقام والرياضيات','عدّ وحساب ومسائل كلامية',MathChallenge(child:child),kidOrange),
    _path(context,'🕌','الإسلام والأخلاق','آداب الصلاة والوضوء والطعام والنوم وغيرها',IslamicHub(child:child),burgundy),
    _path(context,'❓','اختبار سريع','أسئلة لطيفة لترسيخ ما تعلمناه',IslamicQuiz(child:child),kidGreen),
    _path(context,'🎨','الفن واللعب','الرسم والتلوين والمطابقة والحيوانات',const GameHub(),kidPink),
    _path(context,'🌷','نور','اسأل نور وتحدث معه عن الدروس',AiFriendPage(child:child),kidPurple),
  ]));
  Widget _path(BuildContext c,String icon,String title,String sub,Widget page,Color color)=>Card(child:ListTile(contentPadding:const EdgeInsets.all(12),leading:CircleAvatar(radius:28,backgroundColor:color,child:Text(icon,style:const TextStyle(fontSize:27))),title:Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),subtitle:Text(sub),trailing:const Icon(Icons.arrow_forward_ios),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page))));
}

class IslamicQuiz extends StatefulWidget {
  const IslamicQuiz({super.key,required this.child}); final Child child;
  @override State<IslamicQuiz> createState()=>_IslamicQuizState();
}
class _IslamicQuizState extends State<IslamicQuiz>{
  final qs=<Map<String,dynamic>>[
    {'q':'ماذا نقول قبل الطعام؟','a':'بسم الله','o':['بسم الله','تصبح على خير','إلى اللقاء']},
    {'q':'أين نصلّي مع الجماعة أحياناً؟','a':'المسجد','o':['الملعب','المسجد','المطبخ']},
    {'q':'ماذا نفعل عندما نخطئ؟','a':'نعتذر ونصلح الخطأ','o':['نخفي الخطأ','نضحك على غيرنا','نعتذر ونصلح الخطأ']},
    {'q':'كيف نتعامل مع الوالدين؟','a':'بالاحترام والكلام الطيب','o':['بالصراخ','بالاحترام والكلام الطيب','بتجاهلهما']},
    {'q':'لماذا نحافظ على الماء في الوضوء؟','a':'لأننا لا نسرف','o':['لأن الماء لعبة','لأننا لا نسرف','لأنه لا يجوز الشرب']},
    {'q':'ماذا نفعل في المسجد؟','a':'نحافظ على الهدوء والنظافة','o':['نرفع صوتنا','نركض','نحافظ على الهدوء والنظافة']},
    {'q':'ما الخُلُق الجميل؟','a':'الصدق','o':['الكذب','الصدق','الأذى']},
    {'q':'ماذا نقول بعد الطعام؟','a':'الحمد لله','o':['الحمد لله','صباح الخير','مع السلامة']},
  ];
  int i=0,score=0; bool locked=false;
  Future<void>answer(String x)async{if(locked)return;locked=true;final ok=x==qs[i]['a'];if(ok){score+=10;await AppStore.addPoints(widget.child,10);await Voice.speak('أحسنت! جواب رائع');}else await Voice.speak('لا بأس، نتعلم من المحاولة');if(!mounted)return;setState((){if(i<qs.length-1){i++;locked=false;}else locked=false;});}
  @override
  Widget build(BuildContext c) {
    final q = qs[i];
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار إسلامي لطيف')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('السؤال ${i + 1} من ${qs.length}   ⭐ $score', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: burgundy)),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: (i + 1) / qs.length, minHeight: 9, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Text(q['q'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.5)),
          ),
          const SizedBox(height: 22),
          ...(q['o'] as List<String>).map((x) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => answer(x), child: Padding(padding: const EdgeInsets.all(9), child: Text(x, style: const TextStyle(fontSize: 20)))),),
          )),
          if (i == qs.length - 1 && locked)
            const Padding(padding: EdgeInsets.all(15), child: Text('أحسنت! أنهيت الاختبار 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: burgundy))),
        ],
      ),
    );
  }
}

class RewardsPage extends StatefulWidget { const RewardsPage({super.key,required this.child}); final Child child; @override State<RewardsPage> createState()=>_RewardsPageState(); }
class _RewardsPageState extends State<RewardsPage>{double value=0;@override void initState(){super.initState();load();}Future<void>load()async{final v=await AppStore.loadPointValue();if(mounted)setState(()=>value=v);}@override Widget build(BuildContext context){final total=widget.child.points*value;return Scaffold(appBar:AppBar(title:const Text('مكافآتي'),backgroundColor:burgundy,foregroundColor:Colors.white),body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Text('🎁',style:TextStyle(fontSize:90)),Text('${widget.child.points} نقطة',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:burgundy)),const SizedBox(height:12),Text('قيمة النقاط: ${total.toStringAsFixed(2)}',style:const TextStyle(fontSize:22))])));}}

class ParentSettings extends StatefulWidget { const ParentSettings({super.key}); @override State<ParentSettings> createState()=>_ParentSettingsState(); }
class _ParentSettingsState extends State<ParentSettings>{final controller=TextEditingController();final endpointController=TextEditingController();double value=0;List<Child>children=[];@override void initState(){super.initState();load();}Future<void>load()async{final c=await AppStore.loadChildren();final v=await AppStore.loadPointValue();final e=await AppStore.loadAiEndpoint();if(!mounted)return;setState((){children=c;value=v;controller.text=v.toString();endpointController.text=e;});} @override void dispose(){controller.dispose();endpointController.dispose();super.dispose();}Future<void>save()async{final v=double.tryParse(controller.text.replaceAll(',','.'))??0;await AppStore.savePointValue(v);await AppStore.saveAiEndpoint(endpointController.text);if(mounted){setState(()=>value=v);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الإعدادات')));}}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إعدادات الأهل'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('قيمة النقطة',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:8),TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(border:OutlineInputBorder())),const SizedBox(height:20),const Text('مساعد نور الذكي',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('يمكن للأهل وضع عنوان خادم آمن للمساعد. لا تضع مفتاح API داخل التطبيق عند نشره؛ الأفضل استخدام خادم وسيط.'),const SizedBox(height:8),TextField(controller:endpointController,decoration:const InputDecoration(labelText:'عنوان API اختياري',hintText:'https://example.com/v1/chat/completions',border:OutlineInputBorder())),const SizedBox(height:8),Text(aiApiKey.isEmpty?'وضع المساعد الحالي: إجابات محلية آمنة':'وضع المساعد الحالي: متصل بنموذج الذكاء الاصطناعي عند توفر العنوان',style:const TextStyle(color:burgundy,fontWeight:FontWeight.bold)),const SizedBox(height:10),FilledButton(onPressed:save,child:const Text('حفظ الإعدادات')),const SizedBox(height:25),const Text('الأطفال',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),...children.map((c)=>Card(child:ListTile(title:Text(c.name),subtitle:Text('${c.points} نقطة = ${(c.points*value).toStringAsFixed(2)}'))))]));}
