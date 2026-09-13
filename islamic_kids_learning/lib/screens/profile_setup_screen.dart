import 'package:flutter/material.dart';
import '../models/child_profile.dart';
import '../services/profile_service.dart';
import '../widgets/mascot_widget.dart';
import 'home_screen.dart';

// ============================================================
// شاشة تسجيل بيانات الطفل: الاسم، العمر، المستوى
// تُعرض عند أول تشغيل للتطبيق أو عند إنشاء ملف جديد
// ============================================================
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _age = 5; // العمر الافتراضي
  String _level = 'مبتدئ'; // المستوى الافتراضي

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ChildProfile(
      name: _nameController.text.trim(),
      age: _age,
      level: _level,
    );
    await ProfileService.saveProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotWidget(size: 150),
                  const SizedBox(height: 12),
                  const Text(
                    'مرحباً بك في رحلة التعلّم!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // حقل الاسم
                  TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'اسم الطفل',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم' : null,
                  ),
                  const SizedBox(height: 16),

                  // اختيار العمر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('العمر: ', style: TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                        onPressed: () => setState(() => _age = (_age > 2) ? _age - 1 : _age),
                      ),
                      Text('$_age', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => setState(() => _age = (_age < 12) ? _age + 1 : _age),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // اختيار المستوى
                  DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: InputDecoration(
                      labelText: 'المستوى',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'مبتدئ', child: Text('مبتدئ')),
                      DropdownMenuItem(value: 'متوسط', child: Text('متوسط')),
                      DropdownMenuItem(value: 'متقدم', child: Text('متقدم')),
                    ],
                    onChanged: (v) => setState(() => _level = v ?? 'مبتدئ'),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('ابدأ المغامرة!', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
