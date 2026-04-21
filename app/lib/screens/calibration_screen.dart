import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  final int _daysComplete = 3;
  final int _totalDays = 7;

  String _hr = '--';
  String _spo2 = '--';
  String _gsr = '--';
  String _temp = '--';

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: _daysComplete / _totalDays,
    );

    DummyDataService.vitalStream.listen((v) {
      if (mounted) {
        setState(() {
          _hr   = '${v.heartRate} bpm';
          _spo2 = '${v.spo2}%';
          _gsr  = '${v.gsr.toStringAsFixed(2)} µS';
          _temp = '${v.temperature.toStringAsFixed(1)}°C';
        });
      }
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = DummyDataService.dummyChild;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [aegisPinkPale, aegisLavenderLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Getting to know',
                  style: AppTextStyles.h3
                      .copyWith(color: aegisTextMid),
                ),
                Text(
                  child.name,
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Progress ring
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(200, 200),
                        painter: _RingPainter(
                          progress: _daysComplete / _totalDays,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_daysComplete',
                            style: AppTextStyles.vitalNumber.copyWith(
                              fontSize: 52,
                              color: aegisPinkDark,
                            ),
                          ),
                          Text('of $_totalDays days',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Day $_daysComplete of $_totalDays complete',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 24),

                // Explanation card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: aegisCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: aegisPink.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.info,
                              size: 16, color: aegisPinkDark),
                          const SizedBox(width: 8),
                          Text('What is happening?',
                              style: AppTextStyles.bodyMid),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AEGIS is learning ${child.name.split(' ').first}\'s unique physiological baseline. '
                        'Every child is different — heart rate, skin response, and temperature vary naturally. '
                        'Once the 7-day profile is complete, the band will personalise its stress detection '
                        'specifically to ${child.name.split(' ').first}.',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Live readings
                Text('Live readings', style: AppTextStyles.label),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReadingChip(label: 'HR', value: _hr, color: aegisPinkLight),
                    _ReadingChip(label: 'SpO2', value: _spo2, color: aegisMintLight),
                    _ReadingChip(label: 'GSR', value: _gsr, color: aegisLavenderLight),
                    _ReadingChip(label: 'Temp', value: _temp, color: aegisPeachLight),
                  ],
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: aegisLavenderLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.clock,
                          size: 16, color: aegisLavender),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alerts will activate on Day 8',
                          style: AppTextStyles.body
                              .copyWith(color: aegisTextMid),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ReadingChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  ',
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(value,
                key: ValueKey(value), style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final bgPaint = Paint()
      ..color = aegisPinkLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [aegisPink, aegisPinkDark],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
