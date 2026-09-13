import 'package:flutter/material.dart';
import '../models/child_profile.dart';

// ============================================================
// شاشة سجل المتابعة لولي الأمر أو الطفل:
// تعرض الأنشطة المكتملة، عدد النجوم، وملخصاً تشجيعياً عاماً
// ============================================================
class ProgressScreen extends StatelessWidget {
  final ChildProfile profile;
  const ProgressScreen({super.key, required this.profile});

  // قاموس لترجمة مفاتيح الأنشطة إلى أسماء واضحة للعرض
  static const Map<String, String> _activityLabels = {
    'arabic_letters': 'الحروف العربية',
    'english_letters': 'English Letters',
    'numbers': 'الأرقام',
  };

  // بناء نص ملخص تحفيزي حسب عدد الأنشطة المكتملة
  String _buildSummary() {
    final count = profile.completedActivities.length;
    if (count == 0) {
      return 'لم يبدأ ${profile.name} أي نشاط بعد. هيا بنا نبدأ أول رحلة تعلّم!';
    } else if (count < 3) {
      return 'بداية رائعة يا ${profile.name}! أكملت $count نشاط. استمر بارك الله فيك.';
    } else {
      return 'ما شاء الله يا ${profile.name}! أكملت جميع الأنشطة المتاحة بتفوق. أنت نجم حقيقي! ⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(title: const Text('سجل المتابعة'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة ملخص عام
            Card(
              color: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(width: 6),
                        Text('${profile.stars} نجمة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_buildSummary(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('الأنشطة المكتملة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // قائمة الأنشطة المكتملة
            Expanded(
              child: profile.completedActivities.isEmpty
                  ? const Center(child: Text('لا يوجد نشاط مكتمل بعد', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: profile.completedActivities.length,
                      itemBuilder: (context, index) {
                        final key = profile.completedActivities[index];
                        final label = _activityLabels[key] ?? key;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(label),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
