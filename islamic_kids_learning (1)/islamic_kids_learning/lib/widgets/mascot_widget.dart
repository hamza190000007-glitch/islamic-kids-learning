import 'package:flutter/material.dart';

// ============================================================
// شخصية كرتونية بسيطة (رسم أصلي بأشكال هندسية بسيطة)
// ترتدي حجاباً وثوباً محتشماً بألوان مبهجة تناسب الأطفال
// يمكن استبدالها لاحقاً بصور SVG/PNG احترافية من مصمم
// ============================================================
class MascotWidget extends StatelessWidget {
  final double size;
  final Color scarfColor; // لون الحجاب
  final Color dressColor; // لون الثوب

  const MascotWidget({
    super.key,
    this.size = 140,
    this.scarfColor = const Color(0xFF4CAF50),
    this.dressColor = const Color(0xFFFFC107),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(scarfColor: scarfColor, dressColor: dressColor),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final Color scarfColor;
  final Color dressColor;
  _MascotPainter({required this.scarfColor, required this.dressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final facePaint = Paint()..color = const Color(0xFFFFE0B2); // لون بشرة دافئ
    final scarfPaint = Paint()..color = scarfColor;
    final dressPaint = Paint()..color = dressColor;
    final blackPaint = Paint()..color = Colors.black87;
    final cheekPaint = Paint()..color = Colors.pink.shade100;

    // الجسم / الثوب (شكل مثلث محتشم يغطي الجسد بالكامل)
    final dressPath = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.15, h * 1.0)
      ..lineTo(w * 0.85, h * 1.0)
      ..close();
    canvas.drawPath(dressPath, dressPaint);

    // الوجه
    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.22, facePaint);

    // الحجاب (يغطي الرأس والكتفين بالكامل)
    final scarfPath = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..quadraticBezierTo(w * 0.15, h * 0.15, w * 0.12, h * 0.55)
      ..lineTo(w * 0.3, h * 0.55)
      ..quadraticBezierTo(w * 0.32, h * 0.3, w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.68, h * 0.3, w * 0.7, h * 0.55)
      ..lineTo(w * 0.88, h * 0.55)
      ..quadraticBezierTo(w * 0.85, h * 0.15, w * 0.5, h * 0.08)
      ..close();
    canvas.drawPath(scarfPath, scarfPaint);

    // الخدود
    canvas.drawCircle(Offset(w * 0.38, h * 0.38), w * 0.035, cheekPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.38), w * 0.035, cheekPaint);

    // العينان
    canvas.drawCircle(Offset(w * 0.42, h * 0.33), w * 0.02, blackPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.33), w * 0.02, blackPaint);

    // ابتسامة
    final smilePath = Path()
      ..moveTo(w * 0.42, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.48, w * 0.58, h * 0.42);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => false;
}
