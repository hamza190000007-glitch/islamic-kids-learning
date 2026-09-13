import 'package:flutter/material.dart';
import 'models/child_profile.dart';
import 'services/profile_service.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';

void main() {
  runApp(const IslamicKidsLearningApp());
}

// ============================================================
// التطبيق الرئيسي
// ============================================================
class IslamicKidsLearningApp extends StatelessWidget {
  const IslamicKidsLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تعلّم وابتسم',
      debugShowCheckedModeBanner: false,
      // دعم اتجاه الكتابة من اليمين لليسار (مناسب للمحتوى العربي)
      locale: const Locale('ar'),
      theme: ThemeData(
        fontFamily: 'Tajawal', // يفضّل إضافة خط عربي ودّي للأطفال (اختياري)
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const _StartupRouter(),
    );
  }
}

// ============================================================
// يتحقق عند بدء التشغيل: هل يوجد ملف شخصي محفوظ مسبقاً؟
// إن وجد ← ينتقل للرئيسية مباشرة | إن لم يوجد ← شاشة التسجيل
// ============================================================
class _StartupRouter extends StatelessWidget {
  const _StartupRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChildProfile?>(
      future: ProfileService.loadProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snapshot.data;
        if (profile != null) {
          return HomeScreen(profile: profile);
        }
        return const ProfileSetupScreen();
      },
    );
  }
}
