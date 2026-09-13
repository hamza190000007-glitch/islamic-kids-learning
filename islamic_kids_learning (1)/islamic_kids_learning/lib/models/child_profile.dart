// ============================================================
// نموذج بيانات "الملف الشخصي للطفل"
// يحتوي: الاسم، العمر، المستوى، عدد النجوم، والأنشطة المكتملة
// ============================================================
class ChildProfile {
  String name; // اسم الطفل
  int age; // عمر الطفل
  String level; // المستوى: مبتدئ / متوسط / متقدم
  int stars; // عدد النجوم المكتسبة (نظام تحفيزي)
  List<String> completedActivities; // سجل الأنشطة المكتملة

  ChildProfile({
    required this.name,
    required this.age,
    required this.level,
    this.stars = 0,
    List<String>? completedActivities,
  }) : completedActivities = completedActivities ?? [];

  // تحويل الكائن إلى Map لتخزينه محلياً (JSON)
  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'level': level,
        'stars': stars,
        'completedActivities': completedActivities,
      };

  // إعادة بناء الكائن من بيانات مخزّنة
  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        name: json['name'] as String,
        age: json['age'] as int,
        level: json['level'] as String,
        stars: json['stars'] as int? ?? 0,
        completedActivities:
            List<String>.from(json['completedActivities'] as List? ?? []),
      );

  // إضافة نشاط جديد إلى السجل (بدون تكرار)
  void addActivity(String activityName) {
    if (!completedActivities.contains(activityName)) {
      completedActivities.add(activityName);
    }
  }
}
