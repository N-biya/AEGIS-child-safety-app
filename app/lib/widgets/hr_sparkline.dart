import 'package:flutter/material.dart';

/// ECG-style heart rate sparkline painted via CustomPainter.
/// Matches the HRSparkline component from the AEGIS design spec.
class HrSparkline extends StatelessWidget {
  final Color color;

  const HrSparkline({super.key, this.color = const Color(0xFF7C3AED)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: CustomPaint(painter: _HrPainter(color: color)),
    );
  }
}

class _HrPainter extends CustomPainter {
  final Color color;
  _HrPainter({required this.color});

  // Normalized ECG control points from spec (viewBox 0 0 120 40)
  static const _pts = [
    Offset(0, 24), Offset(12, 24), Offset(18, 18), Offset(24, 30),
    Offset(28, 8),  Offset(34, 36), Offset(40, 22), Offset(48, 24),
    Offset(60, 24), Offset(66, 22), Offset(72, 24), Offset(84, 24),
    Offset(90, 18), Offset(96, 28), Offset(102, 14), Offset(108, 30),
    Offset(114, 24), Offset(120, 24),
  ];

  Path _buildPath(Size size) {
    final sx = size.width / 120;
    final sy = size.height / 40;
    final path = Path();
    path.moveTo(_pts[0].dx * sx, _pts[0].dy * sy);
    for (int i = 1; i < _pts.length; i++) {
      path.lineTo(_pts[i].dx * sx, _pts[i].dy * sy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Area fill gradient
    final areaPath = _buildPath(size);
    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // Glow pass (wider, low opacity)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(_buildPath(size), glowPaint);

    // Main line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_buildPath(size), linePaint);

  }

  @override
  bool shouldRepaint(_HrPainter old) => old.color != color;
}
