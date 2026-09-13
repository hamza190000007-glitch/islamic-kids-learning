import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_profile.dart';

// ============================================================
// خدمة إدارة الملف الشخصي: حفظ - تحميل - تحديث
// تستخدم SharedPreferences كقاعدة بيانات بسيطة محلية
// (لا تحتاج إنترنت، مناسبة لتطبيق أطفال بسيط)
// ============================================================
class ProfileService {
  static const _key = 'child_profile';

  // حفظ الملف الشخصي كنص JSON
  static Future<void> saveProfile(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  // تحميل الملف الشخصي إن وجد، وإلا يرجع null
  static Future<ChildProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return ChildProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // حذف الملف الشخصي (مثلاً لإنشاء طفل جديد)
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
