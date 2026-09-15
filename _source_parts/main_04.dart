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

class RewardsPage extends StatefulWidget { const RewardsPage({super.key,required this.child}); final Child child; @override State<RewardsPage> createState()=>_RewardsPageState(); }
class _RewardsPageState extends State<RewardsPage>{double value=0;@override void initState(){super.initState();load();}Future<void>load()async{final v=await AppStore.loadPointValue();if(mounted)setState(()=>value=v);}@override Widget build(BuildContext context){final total=widget.child.points*value;return Scaffold(appBar:AppBar(title:const Text('مكافآتي'),backgroundColor:burgundy,foregroundColor:Colors.white),body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Text('🎁',style:TextStyle(fontSize:90)),Text('${widget.child.points} نقطة',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold,color:burgundy)),const SizedBox(height:12),Text('قيمة النقاط: ${total.toStringAsFixed(2)}',style:const TextStyle(fontSize:22))])));}}

class ParentSettings extends StatefulWidget { const ParentSettings({super.key}); @override State<ParentSettings> createState()=>_ParentSettingsState(); }
class _ParentSettingsState extends State<ParentSettings>{final controller=TextEditingController();final endpointController=TextEditingController();double value=0;List<Child>children=[];@override void initState(){super.initState();load();}Future<void>load()async{final c=await AppStore.loadChildren();final v=await AppStore.loadPointValue();final e=await AppStore.loadAiEndpoint();if(!mounted)return;setState((){children=c;value=v;controller.text=v.toString();endpointController.text=e;});} @override void dispose(){controller.dispose();endpointController.dispose();super.dispose();}Future<void>save()async{final v=double.tryParse(controller.text.replaceAll(',','.'))??0;await AppStore.savePointValue(v);await AppStore.saveAiEndpoint(endpointController.text);if(mounted){setState(()=>value=v);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الإعدادات')));}}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إعدادات الأهل'),backgroundColor:burgundy,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('قيمة النقطة',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:8),TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(border:OutlineInputBorder())),const SizedBox(height:20),const Text('مساعد نور الذكي',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:6),const Text('يمكن للأهل وضع عنوان خادم آمن للمساعد. لا تضع مفتاح API داخل التطبيق عند نشره؛ الأفضل استخدام خادم وسيط.'),const SizedBox(height:8),TextField(controller:endpointController,decoration:const InputDecoration(labelText:'عنوان API اختياري',hintText:'https://example.com/v1/chat/completions',border:OutlineInputBorder())),const SizedBox(height:8),Text(aiApiKey.isEmpty?'وضع المساعد الحالي: إجابات محلية آمنة':'وضع المساعد الحالي: متصل بنموذج الذكاء الاصطناعي عند توفر العنوان',style:const TextStyle(color:burgundy,fontWeight:FontWeight.bold)),const SizedBox(height:10),FilledButton(onPressed:save,child:const Text('حفظ الإعدادات')),const SizedBox(height:25),const Text('الأطفال',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),...children.map((c)=>Card(child:ListTile(title:Text(c.name),subtitle:Text('${c.points} نقطة = ${(c.points*value).toStringAsFixed(2)}'))))]));}
