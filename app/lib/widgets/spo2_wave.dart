import 'package:flutter/material.dart';

/// Smooth sine-style SpO2 wave painted via CustomPainter.
/// Matches the SpO2Wave component from the AEGIS design spec.
class Spo2Wave extends StatelessWidget {
  final Color color;

  const Spo2Wave({super.key, this.color = const Color(0xFF5EEAD4)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: CustomPaint(painter: _WavePainter(color: color)),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});

  Path _buildPath(Size size) {
    // SVG: "M0 22 Q15 8, 30 22 T60 22 T90 22 T120 22" in 120x40 viewBox
    final sx = size.width / 120;
    final sy = size.height / 40;
    final path = Path();
    path.moveTo(0, 22 * sy);
    // Q15 8, 30 22 → quadratic
    path.quadraticBezierTo(15 * sx, 8 * sy, 30 * sx, 22 * sy);
    // T60 22 → smooth quadratic (mirror of previous control)
    path.quadraticBezierTo(45 * sx, 36 * sy, 60 * sx, 22 * sy);
    // T90 22
    path.quadraticBezierTo(75 * sx, 8 * sy, 90 * sx, 22 * sy);
    // T120 22
    path.quadraticBezierTo(105 * sx, 36 * sy, 120 * sx, 22 * sy);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Area fill
    final areaPath = _buildPath(size);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_buildPath(size), linePaint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}
