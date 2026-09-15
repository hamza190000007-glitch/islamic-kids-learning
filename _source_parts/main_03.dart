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
