import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _filterIndex = 0;
  static const _filters = ['All', 'Stress', 'Geofence', 'Normal'];

  static const _alerts = [
    _AlertData(
      type: 'alert',
      title: 'Geofence breach',
      desc: 'Aisha left Greenfield School zone',
      time: 'Today · 3:42 PM',
    ),
    _AlertData(
      type: 'stress',
      title: 'Stress spike detected',
      desc: 'Elevated heart rate · 124 bpm for 4 min',
      time: 'Today · 3:14 PM',
    ),
    _AlertData(
      type: 'safe',
      title: 'Returned to safe zone',
      desc: 'Back inside Home geofence',
      time: 'Today · 4:18 PM',
    ),
    _AlertData(
      type: 'stress',
      title: 'Mild stress',
      desc: 'Skin conductance trending up',
      time: 'Yesterday · 11:02 AM',
    ),
    _AlertData(
      type: 'safe',
      title: 'Calibration complete',
      desc: 'Day 7 baseline established',
      time: 'May 4',
    ),
  ];

  List<_AlertData> get _filtered {
    switch (_filterIndex) {
      case 1: return _alerts.where((a) => a.type == 'stress').toList();
      case 2: return _alerts.where((a) => a.type == 'alert').toList();
      case 3: return _alerts.where((a) => a.type == 'safe').toList();
      default: return _alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);
    final alerts = _filtered;

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 60, 18, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alerts',
                              style: AegisText.h2(color: T)
                                  .copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.05)),
                          Text('${alerts.length} events in the last 7 days',
                              style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? const Color(0x0FFFFFFF) : const Color(0xB3FFFFFF),
                          border: Border.all(color: AegisT.glassBorder(context)),
                        ),
                        child: Icon(Icons.tune_rounded, size: 18, color: T),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filter chips ───────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final active = i == _filterIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? kAccent
                                : (isDark ? const Color(0x0DFFFFFF) : const Color(0xB3FFFFFF)),
                            border: active
                                ? null
                                : Border.all(color: AegisT.glassBorder(context)),
                            boxShadow: active
                                ? const [BoxShadow(color: Color(0x4D7C3AED), blurRadius: 12, offset: Offset(0, 4))]
                                : null,
                          ),
                          child: Text(
                            active && i == 0
                                ? '${_filters[i]} · ${_alerts.length}'
                                : _filters[i],
                            style: AegisText.label(
                              color: active ? Colors.white : T,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Alert list ─────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, kNavBarHeight + 16),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _AlertTile(alert: alerts[i], isDark: isDark, T: T, D: D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert data model ──────────────────────────────────────────────────────
class _AlertData {
  final String type, title, desc, time;
  const _AlertData({required this.type, required this.title, required this.desc, required this.time});
}

// ── Single alert tile ─────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final _AlertData alert;
  final bool isDark;
  final Color T, D;

  const _AlertTile({required this.alert, required this.isDark, required this.T, required this.D});

  Color get _color {
    switch (alert.type) {
      case 'safe':   return kSafe;
      case 'stress': return kStress;
      default:       return kAlert;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case 'safe':   return Icons.check_rounded;
      case 'stress': return Icons.bolt_rounded;
      default:       return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: c,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: c.withValues(alpha: 0.13),
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: c,
                          ),
                          child: Icon(_icon, color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.title,
                              style: AegisText.h5(color: T)
                                  .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            alert.desc,
                            style: AegisText.caption(color: D).copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(alert.time,
                              style: AegisText.micro(color: D)
                                  .copyWith(fontSize: 10, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: D),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
