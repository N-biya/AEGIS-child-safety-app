import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../router/app_router.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodIndex = 1; // 0=Day, 1=Week, 2=Month
  static const _periods = ['Day', 'Week', 'Month'];

  List<FlSpot> get _hrSpots => DummyDataService.weeklySpots('hr');

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);
    // 7-day stress heat colors
    const heatColors = [kSafe, kSafe, kStress, kSafe, kStress, kSafe, kSafe];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(18, 60, 18, kNavBarHeight + 24),
              children: [
                // ── Header ──────────────────────────────────────────────
                Text('Trends',
                    style: AegisText.h2(color: T)
                        .copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.05)),
                const SizedBox(height: 4),
                Text('This week · May 3 – May 9',
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
                                  Text('92',
                                      style: AegisText.numDisplay(color: T)
                                          .copyWith(fontSize: 32, fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 4),
                                  Text('avg bpm',
                                      style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0x2634D399),
                            ),
                            child: Text('↓ 4% vs last week',
                                style: AegisText.micro(color: kSafe)
                                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
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
                        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                            .map((d) => Text(d, style: AegisText.micro(color: D).copyWith(fontSize: 10)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Metric mini cards ────────────────────────────────────
                Row(children: [
                  Expanded(child: _MetricMini(label: 'Avg HR', value: '92', unit: 'bpm', color: kAlert)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricMini(label: 'Stress eps', value: '3', unit: 'this wk', color: kStress)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricMini(label: 'Avg SpO₂', value: '98', unit: '%', color: const Color(0xFF5EEAD4))),
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
                          final c = heatColors[i];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
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
                                      Text(days[i],
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
                            gradient: const LinearGradient(
                              colors: [kAccentLight, kAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.wb_sunny_outlined,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Insight',
                            style: AegisText.h5(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: AegisText.body(color: T).copyWith(fontSize: 13, height: 1.45),
                          children: [
                            TextSpan(
                              text: 'Tuesday at 3 PM',
                              style: AegisText.body(color: T).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const TextSpan(
                              text: ' showed the highest stress spike this week — likely after-school transition. Consider a calming routine in that window.',
                            ),
                          ],
                        ),
                      ),
                    ],
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
