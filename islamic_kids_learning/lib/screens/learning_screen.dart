import 'dart:math';
import 'package:flutter/material.dart';
import '../data/content_data.dart';
import '../models/child_profile.dart';
import '../services/tts_service.dart';
import 'reward_screen.dart';

// ============================================================
// شاشة تعليمية عامة تُستخدم لعرض (حروف عربية / إنجليزية / أرقام)
// كل عنصر عبارة عن بطاقة: بالضغط عليها يُنطق صوتياً ويُسجَّل
// كـ "تمت رؤيته". بعد المرور على كل العناصر تظهر لعبة المكافأة
// ============================================================
class LearningScreen extends StatefulWidget {
  final String activityKey; // مفتاح فريد للنشاط (لتخزينه في السجل)
  final String title;
  final List<String> items; // العناصر المعروضة (حرف أو رقم)
  final List<String>? speakTexts; // نص النطق إن اختلف عن العنصر المعروض (مثال: الأرقام)
  final bool isArabic;
  final ChildProfile profile;

  const LearningScreen({
    super.key,
    required this.activityKey,
    required this.title,
    required this.items,
    required this.isArabic,
    required this.profile,
    this.speakTexts,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final Set<int> _visited = {}; // فهرس العناصر التي ضغط عليها الطفل

  void _onTapItem(int index) async {
    final textToSpeak = widget.speakTexts != null ? widget.speakTexts![index] : widget.items[index];

    // نطق الحرف/الرقم بالصوت المناسب للغة
    if (widget.isArabic) {
      await TtsService.speakArabic(textToSpeak);
    } else {
      await TtsService.speakEnglish(textToSpeak);
    }

    setState(() => _visited.add(index));

    // عند إتمام كل العناصر ينتقل الطفل تلقائياً إلى لعبة المكافأة
    if (_visited.length == widget.items.length) {
      Future.delayed(const Duration(milliseconds: 600), _goToReward);
    }
  }

  void _goToReward() {
    final message = encouragingMessages[Random().nextInt(encouragingMessages.length)];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RewardScreen(
          profile: widget.profile,
          activityKey: widget.activityKey,
          congratsMessage: message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _visited.length / widget.items.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.teal),
      body: Column(
        children: [
          // شريط تقدّم بسيط يشجع الطفل على إكمال النشاط
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final visited = _visited.contains(index);
                return GestureDetector(
                  onTap: () => _onTapItem(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: visited ? Colors.green.shade300 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Center(
                      child: Text(
                        widget.items[index],
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: visited ? Colors.white : Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
