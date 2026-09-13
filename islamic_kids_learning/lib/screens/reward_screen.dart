import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/profile_service.dart';
import '../services/tts_service.dart';
import '../widgets/mascot_widget.dart';
import 'home_screen.dart';

// ============================================================
// شاشة المكافأة: تظهر بعد إكمال أي نشاط تعليمي
// - رسالة تشجيعية إسلامية منطوقة
// - تأثير احتفالي (Confetti)
// - لعبة صغيرة بسيطة: "اضغط على النجوم قبل أن تختفي"
// - تحديث سجل الطفل (النجاط المكتمل + النجوم المكتسبة)
// ============================================================
class RewardScreen extends StatefulWidget {
  final ChildProfile profile;
  final String activityKey;
  final String congratsMessage;

  const RewardScreen({
    super.key,
    required this.profile,
    required this.activityKey,
    required this.congratsMessage,
  });

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  late ConfettiController _confettiController;
  int _starsTapped = 0;
  final int _starsTarget = 5; // عدد النجوم المطلوب التقاطها في اللعبة
  final Random _random = Random();
  Timer? _gameTimer;
  bool _gameFinished = false;

  // مواقع النجوم المتحركة (نسبة مئوية من عرض/ارتفاع الشاشة)
  double _starX = 0.5;
  double _starY = 0.5;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();

    // تسجيل النشاط كمكتمل وإضافة نجمة أساسية فور الوصول لهذه الشاشة
    widget.profile.addActivity(widget.activityKey);
    widget.profile.stars += 1;
    ProfileService.saveProfile(widget.profile);

    // نطق الرسالة التشجيعية بصوت عربي
    TtsService.speakArabic(widget.congratsMessage);

    _relocateStar();
  }

  void _relocateStar() {
    setState(() {
      _starX = 0.1 + _random.nextDouble() * 0.8;
      _starY = 0.1 + _random.nextDouble() * 0.6;
    });
  }

  void _onStarTap() async {
    setState(() => _starsTapped++);
    if (_starsTapped >= _starsTarget) {
      setState(() => _gameFinished = true);
      widget.profile.stars += 3; // مكافأة إضافية عند إكمال اللعبة
      await ProfileService.saveProfile(widget.profile);
      await TtsService.speakArabic('ممتاز! ربحت نجوماً إضافية');
    } else {
      _relocateStar();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // تأثير الاحتفال بالألوان
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.orange, Colors.blue, Colors.pink],
            ),

            Column(
              children: [
                const SizedBox(height: 16),
                const MascotWidget(size: 120),
                const SizedBox(height: 8),
                Text(
                  widget.congratsMessage,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _gameFinished
                      ? 'انتهت اللعبة! أحسنت 🎉'
                      : 'مكافأتك: العب لعبة التقاط النجوم! ($_starsTapped/$_starsTarget)',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            // منطقة اللعبة: نجمة واحدة تتحرك يضغط عليها الطفل
            if (!_gameFinished)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Positioned(
                    left: constraints.maxWidth * _starX,
                    top: constraints.maxHeight * _starY,
                    child: GestureDetector(
                      onTap: _onStarTap,
                      child: const Icon(Icons.star, color: Colors.amber, size: 60),
                    ),
                  );
                },
              ),

            // زر العودة للرئيسية بعد انتهاء اللعبة
            if (_gameFinished)
              Positioned(
                bottom: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(profile: widget.profile)),
                    (route) => false,
                  ),
                  child: const Text('العودة للرئيسية', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
