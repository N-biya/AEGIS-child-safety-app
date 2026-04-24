import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/dummy_data_service.dart';
import '../models/vital_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/section_header.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool showBackButton;
  const AnalyticsScreen({super.key, this.showBackButton = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = '7 Days';
  static const _periods = ['Today', '7 Days', '30 Days'];

  List<VitalModel> get _history {
    final all = DummyDataService.historicalVitals;
    switch (_period) {
      case 'Today':
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        return all.where((v) => v.timestamp.isAfter(cutoff)).toList();
      case '30 Days':
        // Repeat 7-day data ~4x to simulate 30 days
        return [...all, ...all, ...all, ...all];
      default:
        return all;
    }
  }

  List<FlSpot> _spots(String type) {
    final history = _history;
    return history.asMap().entries.map((e) {
      double y;
      switch (type) {
        case 'hr':   y = e.value.heartRate.toDouble(); break;
        case 'spo2': y = e.value.spo2.toDouble(); break;
        case 'gsr':  y = e.value.gsr; break;
        default:     y = 0;
      }
      return FlSpot(e.key.toDouble(), y);
    }).toList();
  }

  Widget _trendChart({
    required String type,
    required Color lineColor,
    required String title,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
          decoration: BoxDecoration(
            color: AegisColors.card(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: aegisPink.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _spots(type),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        lineColor.withOpacity(0.2),
                        lineColor.withOpacity(0),
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
                  color: AegisColors.warm(context),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, _) => Text(
                      val.toInt().toString(),
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AegisColors.card(context),
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} $unit',
                            AppTextStyles.caption.copyWith(color: lineColor),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stressBarChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = [1.0, 0.0, 2.0, 0.0, 1.0, 3.0, 0.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Stress Frequency'),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
          decoration: BoxDecoration(
            color: AegisColors.card(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: aegisPink.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              barGroups: counts.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: aegisPeach,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]);
              }).toList(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AegisColors.warm(context),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, _) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        days[val.toInt()],
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (val, _) => Text(
                      val.toInt().toString(),
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AegisColors.card(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.arrowLeft,
                            size: 18, color: aegisPinkDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text('Analytics', style: AppTextStyles.h2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Period pills ────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _period == _periods[i];
                  return GestureDetector(
                    onTap: () => setState(() => _period = _periods[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? aegisPink
                            : AegisColors.pinkLight(context),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _periods[i],
                        style: AppTextStyles.label.copyWith(
                          color: active
                              ? Colors.white
                              : AegisColors.textMid(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Charts ─────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _trendChart(
                    type: 'hr',
                    lineColor: aegisPinkDark,
                    title: 'Heart Rate',
                    unit: 'bpm',
                  ),
                  const SizedBox(height: 24),
                  _trendChart(
                    type: 'gsr',
                    lineColor: aegisLavender,
                    title: 'Skin Response (GSR)',
                    unit: 'µS',
                  ),
                  const SizedBox(height: 24),
                  _trendChart(
                    type: 'spo2',
                    lineColor: statusSafe,
                    title: 'SpO2',
                    unit: '%',
                  ),
                  const SizedBox(height: 24),
                  _stressBarChart(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
