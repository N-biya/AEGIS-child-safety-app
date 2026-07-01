import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../models/child_model.dart';
import '../models/vital_model.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/vitals_analytics.dart' as analytics;
import '../utils/vitals_snapshot.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';
import 'aegis_guard_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodIndex = 1; // 0=Day, 1=Week, 2=Month
  static const _periods = ['Day', 'Week', 'Month'];

  final _firestore = FirestoreService();
  ChildModel? _child;
  List<VitalModel> _history = [];
  List<AlertModel> _alerts = [];

  StreamSubscription<ChildModel?>? _childSub;
  StreamSubscription<VitalModel?>? _vitalSub;
  StreamSubscription<List<AlertModel>>? _alertSub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _childSub?.cancel();
    _vitalSub?.cancel();
    _alertSub?.cancel();
    super.dispose();
  }

  Duration get _periodDuration {
    switch (_periodIndex) {
      case 0:  return const Duration(days: 1);
      case 2:  return const Duration(days: 30);
      default: return const Duration(days: 7);
    }
  }

  // Watches the linked child, then keeps trends in sync with live readings:
  // new vitals are prepended as they arrive and alerts re-pulled on change, so
  // the charts and insights reflect the real sensor stream without a reload.
  void _subscribe() {
    final uid = context.read<AuthService>().userId;
    if (uid.isEmpty) return;
    _childSub = _firestore.watchChildForUser(uid).listen((child) async {
      if (!mounted || child == null) return;
      final history = await _firestore.getHistory(child.id);
      final alerts = await _firestore.getAlerts(child.id);
      if (!mounted) return;
      setState(() {
        _child = child;
        _history = history;
        _alerts = alerts;
      });
      _listenLive(child.id);
    });
  }

  void _listenLive(String childId) {
    _vitalSub?.cancel();
    _vitalSub = _firestore.latestVitalStream(childId).listen((v) {
      if (!mounted || v == null) return;
      // Skip if it's the reading we already have at the front.
      if (_history.isNotEmpty && _history.first.timestamp == v.timestamp) return;
      setState(() => _history = [v, ..._history]);
    });

    _alertSub?.cancel();
    _alertSub = _firestore.watchAlerts(childId).listen((_) async {
      final full = await _firestore.getAlerts(childId);
      if (!mounted) return;
      setState(() => _alerts = full);
    });
  }

  Future<void> _refresh() async {
    final child = _child;
    if (child == null) return;
    final history = await _firestore.getHistory(child.id);
    final alerts = await _firestore.getAlerts(child.id);
    if (!mounted) return;
    setState(() {
      _history = history;
      _alerts = alerts;
    });
  }

  void _openGuard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AegisGuardScreen()),
    );
  }

  List<FlSpot> get _hrSpots {
    switch (_periodIndex) {
      case 0:  return analytics.dailySpots(_history, 'hr');
      case 2:  return analytics.monthlySpots(_history, 'hr');
      default: return analytics.weeklySpots(_history, 'hr');
    }
  }

  List<String> get _chartLabels {
    switch (_periodIndex) {
      case 0:  return const ['12a', '4a', '8a', '12p', '4p', '8p'];
      case 2:  return const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      default: return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }

  String get _periodSubtitle {
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0:  return 'Today · ${_fmtDate(now)}';
      case 2:  return 'This month · ${_monthName(now.month)}';
      default:
        final start = now.subtract(const Duration(days: 6));
        return 'This week · ${_fmtDate(start)} – ${_fmtDate(now)}';
    }
  }

  void _openDayDetail(analytics.DaySummary day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayDetailSheet(day: day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    final avgHr   = analytics.averageFor(_history, 'hr', within: _periodDuration);
    final avgSpo2 = analytics.averageFor(_history, 'spo2', within: _periodDuration);
    final alertCount = analytics.alertCountFor(_alerts, within: _periodDuration);
    final days = analytics.last7Days(_history, _alerts);
    final insight = analytics.buildInsight(
      _alerts,
      within: _periodDuration,
      periodLabel: _periods[_periodIndex],
      childName: _child?.name ?? 'Your child',
    );

    // Reading-based "AI" insights, computed from the same live snapshot the
    // AEGIS Guard assistant reads from.
    final snapshot = VitalsSnapshot(
      child: _child,
      history: _history,
      alerts: _alerts,
    );
    final vitalInsights = buildVitalInsights(snapshot, window: _periodDuration);

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: kAccent,
              backgroundColor: AegisT.card(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 60, 18, kNavBarHeight + 24),
                children: [
                // ── Header ──────────────────────────────────────────────
                Text('Trends',
                    style: AegisText.h2(color: T)
                        .copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.05)),
                const SizedBox(height: 4),
                Text(_periodSubtitle,
                    style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                const SizedBox(height: 18),

                // ── Period selector ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0F7C3AED),
                  ),
                  child: Row(
                    children: List.generate(_periods.length, (i) {
                      final active = i == _periodIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _periodIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: active ? kAccent : Colors.transparent,
                              boxShadow: active
                                  ? const [BoxShadow(color: Color(0x4D7C3AED), blurRadius: 12, offset: Offset(0, 4))]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                _periods[i],
                                style: AegisText.label(
                                  color: active ? Colors.white : D,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 18),

                // ── HR trend chart ───────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Heart Rate Trend',
                                  style: AegisText.label(color: D)
                                      .copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(avgHr != null ? avgHr.toStringAsFixed(0) : '—',
                                      style: AegisText.numDisplay(color: T)
                                          .copyWith(fontSize: 32, fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 4),
                                  Text('avg bpm',
                                      style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 140,
                        child: _HRAreaChart(spots: _hrSpots, isDark: isDark),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _chartLabels
                            .map((d) => Text(d, style: AegisText.micro(color: D).copyWith(fontSize: 10)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Metric mini cards ────────────────────────────────────
                Row(children: [
                  Expanded(child: _MetricMini(
                    label: 'Avg HR',
                    value: avgHr != null ? avgHr.toStringAsFixed(0) : '—',
                    unit: 'bpm',
                    color: kAlert,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricMini(
                    label: 'Alerts',
                    value: '$alertCount',
                    unit: _periods[_periodIndex] == 'Day' ? 'today' : 'this ${_periods[_periodIndex].toLowerCase()}',
                    color: kStress,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricMini(
                    label: 'Avg SpO₂',
                    value: avgSpo2 != null ? avgSpo2.toStringAsFixed(0) : '—',
                    unit: '%',
                    color: const Color(0xFF5EEAD4),
                  )),
                ]),
                const SizedBox(height: 14),

                // ── Stress heatmap ───────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stress · 7 days',
                          style: AegisText.h5(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Tap a day to see details',
                          style: AegisText.caption(color: D).copyWith(fontSize: 11)),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(7, (i) {
                          final day = days[i];
                          final c = day.hasStress ? kStress : kSafe;
                          final label = _weekdayLetter(day.date.weekday);
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                              child: GestureDetector(
                                onTap: () => _openDayDetail(day),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: c.withValues(alpha: 0.19),
                                      border: Border.all(color: c.withValues(alpha: 0.33)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(label,
                                            style: AegisText.micro9(color: D).copyWith(fontSize: 9)),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: c,
                                            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Insight card ─────────────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            gradient: LinearGradient(
                              colors: _insightColors(insight.level),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(_insightIcon(insight.level),
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('${_periods[_periodIndex]} insight',
                            style: AegisText.h5(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: AegisText.body(color: T).copyWith(fontSize: 13, height: 1.45),
                          children: [
                            TextSpan(
                              text: insight.headline,
                              style: AegisText.body(color: T).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            TextSpan(text: ' — ${insight.body}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── AEGIS Guard reading-based insights ──────────────────
                _GuardInsightsSection(insights: vitalInsights),
                const SizedBox(height: 12),

                // ── Talk with AEGIS Guard ───────────────────────────────
                _TalkToGuardButton(onTap: _openGuard),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _insightColors(analytics.InsightLevel level) {
    switch (level) {
      case analytics.InsightLevel.concern: return [kAlert, const Color(0xFFB91C3C)];
      case analytics.InsightLevel.watch:   return [kStress, const Color(0xFFD97706)];
      case analytics.InsightLevel.calm:    return [kAccentLight, kAccent];
    }
  }

  IconData _insightIcon(analytics.InsightLevel level) {
    switch (level) {
      case analytics.InsightLevel.concern: return Icons.priority_high_rounded;
      case analytics.InsightLevel.watch:   return Icons.visibility_outlined;
      case analytics.InsightLevel.calm:    return Icons.wb_sunny_outlined;
    }
  }

  String _weekdayLetter(int weekday) {
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[weekday - 1];
  }

  String _fmtDate(DateTime d) => '${_monthName(d.month)} ${d.day}';

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }
}

// ── Day detail sheet ────────────────────────────────────────────────────────
class _DayDetailSheet extends StatelessWidget {
  final analytics.DaySummary day;
  const _DayDetailSheet({required this.day});

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final title = '${weekdays[day.date.weekday - 1]}, ${months[day.date.month - 1]} ${day.date.day}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: isDark ? kDarkBg : Colors.white,
        border: Border.all(color: isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark ? const Color(0x26FFFFFF) : const Color(0x267C3AED),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AegisText.h2(color: T).copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _MetricMini(
                label: 'Avg HR',
                value: day.avgHr != null ? day.avgHr!.toStringAsFixed(0) : '—',
                unit: 'bpm',
                color: kAlert,
              )),
              const SizedBox(width: 8),
              Expanded(child: _MetricMini(
                label: 'Avg SpO₂',
                value: day.avgSpo2 != null ? day.avgSpo2!.toStringAsFixed(0) : '—',
                unit: '%',
                color: const Color(0xFF5EEAD4),
              )),
              const SizedBox(width: 8),
              Expanded(child: _MetricMini(
                label: 'Alerts',
                value: '${day.alerts.length}',
                unit: 'logged',
                color: kStress,
              )),
            ]),
            const SizedBox(height: 18),
            Text('Alerts that day',
                style: AegisText.label(color: D).copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
            const SizedBox(height: 8),
            if (day.alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No alerts were recorded this day.',
                    style: AegisText.caption(color: D).copyWith(fontSize: 12)),
              )
            else
              ...day.alerts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: a.resolved ? kSafe : kAlert,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(a.typeLabel,
                              style: AegisText.body(color: T).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Text(_fmtTime(a.timestamp),
                            style: AegisText.caption(color: D).copyWith(fontSize: 11)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

// ── HR area chart ──────────────────────────────────────────────────────────
class _HRAreaChart extends StatelessWidget {
  final List<FlSpot> spots;
  final bool isDark;

  const _HRAreaChart({required this.spots, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots.isNotEmpty ? spots : [const FlSpot(0, 80), const FlSpot(6, 88)],
            isCurved: true,
            color: kAccent,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  kAccent.withValues(alpha: 0.5),
                  kAccent.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0A2D1A4A),
            dashArray: [3, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => kAccent,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${s.y.toStringAsFixed(0)} bpm',
              AegisText.label(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Metric mini card ───────────────────────────────────────────────────────
class _MetricMini extends StatelessWidget {
  final String label, value, unit;
  final Color color;

  const _MetricMini({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: AegisText.micro9(color: D)
                    .copyWith(letterSpacing: 0.4, textBaseline: TextBaseline.alphabetic),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(value, style: AegisText.numMedium(color: T).copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(unit, style: AegisText.micro(color: D).copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ── AEGIS Guard insights section ────────────────────────────────────────────
class _GuardInsightsSection extends StatelessWidget {
  final List<VitalInsight> insights;
  const _GuardInsightsSection({required this.insights});

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: const LinearGradient(
                colors: [kAccentLight, kAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Text('AEGIS Guard insights',
              style: AegisText.h5(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ...insights.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VitalInsightCard(insight: i),
            )),
      ],
    );
  }
}

class _VitalInsightCard extends StatelessWidget {
  final VitalInsight insight;
  const _VitalInsightCard({required this.insight});

  Color get _tone {
    switch (insight.tone) {
      case VitalInsightTone.concern: return kAlert;
      case VitalInsightTone.watch:   return kStress;
      case VitalInsightTone.calm:    return kSafe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _tone,
              boxShadow: [BoxShadow(color: _tone.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: AegisText.body(color: T).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(insight.body,
                    style: AegisText.body(color: D).copyWith(fontSize: 12.5, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Talk-with-AEGIS-Guard button ────────────────────────────────────────────
class _TalkToGuardButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TalkToGuardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [kAccentLight, kAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x667C3AED), blurRadius: 22, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Talk with AEGIS Guard',
                style: AegisText.title(color: Colors.white)
                    .copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
