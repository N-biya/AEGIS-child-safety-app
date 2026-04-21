import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/app_text_styles.dart';

class VitalCard extends StatelessWidget {
  final String vitalType;
  final String displayValue;
  final String unit;
  final List<double> sparklineData;
  final Color cardColor;
  final Color accentColor;

  const VitalCard({
    super.key,
    required this.vitalType,
    required this.displayValue,
    required this.unit,
    required this.sparklineData,
    required this.cardColor,
    required this.accentColor,
  });

  IconData get _icon {
    switch (vitalType) {
      case 'hr':   return LucideIcons.heart;
      case 'spo2': return LucideIcons.wind;
      case 'gsr':  return LucideIcons.activity;
      case 'temp': return LucideIcons.thermometer;
      default:     return LucideIcons.activity;
    }
  }

  String get _label {
    switch (vitalType) {
      case 'hr':   return 'Heart Rate';
      case 'spo2': return 'SpO2';
      case 'gsr':  return 'Skin Response';
      case 'temp': return 'Skin Temp';
      default:     return vitalType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
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
              Icon(_icon, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(_label, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              displayValue,
              key: ValueKey(displayValue),
              style: AppTextStyles.vitalNumber.copyWith(fontSize: 28),
            ),
          ),
          Text(unit, style: AppTextStyles.caption),
          const Spacer(),
          SizedBox(
            height: 32,
            child: _Sparkline(data: sparklineData, color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.25), color.withOpacity(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
