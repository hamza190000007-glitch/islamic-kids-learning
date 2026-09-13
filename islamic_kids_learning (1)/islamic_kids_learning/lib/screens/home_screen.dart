import 'package:flutter/material.dart';
import '../data/content_data.dart';
import '../models/child_profile.dart';
import '../widgets/mascot_widget.dart';
import 'learning_screen.dart';
import 'progress_screen.dart';

// ============================================================
// الشاشة الرئيسية: تعرض ترحيباً بالطفل وقائمة الأنشطة
// (حروف عربية - حروف إنجليزية - أرقام - سجل المتابعة)
// ============================================================
class HomeScreen extends StatelessWidget {
  final ChildProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('أهلاً ${profile.name} 🌟'),
        actions: [
          // عرض عدد النجوم المكتسبة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow),
                const SizedBox(width: 4),
                Text('${profile.stars}', style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const MascotWidget(size: 110),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _ActivityCard(
                  title: 'الحروف العربية',
                  icon: Icons.text_fields,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LearningScreen(
                        activityKey: 'arabic_letters',
                        title: 'الحروف العربية',
                        items: arabicLetters,
                        isArabic: true,
                        profile: profile,
                      ),
                    ),
                  ),
                ),
                _ActivityCard(
                  title: 'English Letters',
                  icon: Icons.abc,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LearningScreen(
                        activityKey: 'english_letters',
                        title: 'English Letters',
                        items: englishLetters,
                        isArabic: false,
                        profile: profile,
                      ),
                    ),
                  ),
                ),
                _ActivityCard(
                  title: 'الأرقام',
                  icon: Icons.numbers,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LearningScreen(
                        activityKey: 'numbers',
                        title: 'الأرقام',
                        items: arabicNumbers.map((n) => n['digit']!).toList(),
                        speakTexts: arabicNumbers.map((n) => n['name']!).toList(),
                        isArabic: true,
                        profile: profile,
                      ),
                    ),
                  ),
                ),
                _ActivityCard(
                  title: 'سجل المتابعة',
                  icon: Icons.bar_chart,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProgressScreen(profile: profile)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// بطاقة نشاط بسيطة وملونة تناسب الأطفال
class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
