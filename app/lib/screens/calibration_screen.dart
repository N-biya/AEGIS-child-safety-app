import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';
import '../widgets/aegis_animations.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen>
    with SingleTickerProviderStateMixin {
  static const _day   = 3;
  static const _total = 7;

  String _hr   = '--';
  String _spo2 = '--';
  String _gsr  = '--';
  String _temp = '--';

  final _firestore = FirestoreService();
  StreamSubscription? _childSub;
  StreamSubscription? _vitalSub;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthService>().userId;
    _childSub = _firestore.watchChildForUser(uid).listen((child) {
      _vitalSub?.cancel();
      if (child == null) return;
      _vitalSub = _firestore.latestVitalStream(child.id).listen((v) {
        if (v == null || !mounted) return;
        setState(() {
          _hr   = '${v.heartRate} bpm';
          _spo2 = '${v.spo2}%';
          _gsr  = '${v.gsr.toStringAsFixed(2)} µS';
          _temp = '${v.temperature.toStringAsFixed(1)}°C';
        });
      });
    });
  }

  @override
  void dispose() {
    _childSub?.cancel();
    _vitalSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);
    final pct    = _day / _total;

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 0, 18, kNavBarHeight + 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Top row: back btn + status badge ────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? const Color(0x0FFFFFFF) : const Color(0xB3FFFFFF),
                          border: Border.all(color: AegisT.glassBorder(context)),
                        ),
                        child: Icon(Icons.chevron_left_rounded, size: 22, color: T),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0x2EA78BFA),
                          border: Border.all(color: const Color(0x4DA78BFA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AegisPulseDot(size: 6, color: kCal),
                            const SizedBox(width: 5),
                            Text('ML CALIBRATING',
                                style: AegisText.label(color: kCal)
                                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Title ───────────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Learning Aisha's\nunique patterns",
                      style: AegisText.h2(color: T)
                          .copyWith(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'AEGIS is building a personal baseline so detection is accurate just for her.',
                      style: AegisText.body(color: D).copyWith(fontSize: 13, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Progress ring ────────────────────────────────────────
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(176, 176),
                          painter: _RingPainter(progress: pct, isDark: isDark),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('DAY',
                                style: AegisText.label(color: D)
                                    .copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                            Text('$_day',
                                style: AegisText.numDisplay(color: T)
                                    .copyWith(fontSize: 56, fontWeight: FontWeight.w800)),
                            Text('of $_total · ${(pct * 100).round()}%',
                                style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Steps ───────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: _CalStep(step: 1, title: 'Baseline', desc: 'Vitals captured', done: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _CalStep(step: 2, title: 'Building', desc: 'Pattern model', active: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _CalStep(step: 3, title: 'Ready', desc: 'Detection live')),
                  ]),
                  const SizedBox(height: 14),

                  // ── Sensor data collection ───────────────────────────────
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sensor data collection',
                            style: AegisText.h5(color: T)
                                .copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ...[
                          _SensorRow(name: 'Heart rate',       pct: 0.62, color: kAlert,    value: _hr),
                          _SensorRow(name: 'SpO₂',             pct: 0.45, color: const Color(0xFF5EEAD4), value: _spo2),
                          _SensorRow(name: 'Skin conductance', pct: 0.38, color: kStress,   value: _gsr),
                          _SensorRow(name: 'Skin temp',        pct: 0.55, color: kAccent,   value: _temp),
                          _SensorRow(name: 'Movement (IMU)',   pct: 0.71, color: kCal,      value: ''),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Learn more about calibration →',
                      style: AegisText.label(color: kAccent)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step card ──────────────────────────────────────────────────────────────
class _CalStep extends StatelessWidget {
  final int step;
  final String title, desc;
  final bool done, active;

  const _CalStep({required this.step, required this.title, required this.desc, this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final T    = AegisT.text(context);
    final D    = AegisT.textDim(context);
    final isDark = AegisT.isDark(context);
    final dotColor = done ? kSafe : active ? kAccent
        : (isDark ? const Color(0x1AFFFFFF) : const Color(0x1A7C3AED));

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: dotColor,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : Text('$step',
                      style: AegisText.label(color: Colors.white)
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: AegisText.h5(color: T).copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(desc, style: AegisText.micro(color: D).copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Sensor data row ────────────────────────────────────────────────────────
class _SensorRow extends StatelessWidget {
  final String name, value;
  final double pct;
  final Color color;

  const _SensorRow({required this.name, required this.pct, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    final T    = AegisT.text(context);
    final D    = AegisT.textDim(context);
    final isDark = AegisT.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: AegisText.body(color: T).copyWith(fontSize: 12))),
          SizedBox(
            width: 80,
            height: 5,
            child: Stack(children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark ? const Color(0x0FFFFFFF) : const Color(0x147C3AED),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: color,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '${(pct * 100).round()}%',
              style: AegisText.micro(color: D)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress ring painter ──────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  _RingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = size.width / 2 - 14;
    const strokeW = 10.0;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Background arc
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = isDark ? const Color(0x14FFFFFF) : const Color(0x147C3AED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Progress arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [kAccentLight, kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Tick marks
    const n = 7;
    for (int i = 0; i < n; i++) {
      final angle = (i / n) * 2 * math.pi - math.pi / 2;
      final r1 = radius + 14;
      final r2 = radius + 18;
      final x1 = cx + r1 * math.cos(angle);
      final y1 = cy + r1 * math.sin(angle);
      final x2 = cx + r2 * math.cos(angle);
      final y2 = cy + r2 * math.sin(angle);
      final done = i < 3; // _day = 3
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = done ? kAccent
              : (isDark ? const Color(0x26FFFFFF) : const Color(0x337C3AED))
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
