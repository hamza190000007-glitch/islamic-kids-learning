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
