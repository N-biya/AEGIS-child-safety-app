import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/status_badge.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onViewMap;

  const DashboardScreen({super.key, this.onViewMap});

  // Derive overall weekly status from averages
  String _weeklyStatus(Map<String, double> avg) {
    final hr = avg['hr'] ?? 80;
    final spo2 = avg['spo2'] ?? 98;
    if (spo2 < 95 || hr > 105) return 'ALERT';
    if (hr > 95) return 'ELEVATED';
    return 'NORMAL';
  }

  String _heroMessage(String status) {
    switch (status) {
      case 'ALERT':    return 'Some vitals need attention';
      case 'ELEVATED': return 'Slight elevation detected this week';
      default:         return 'All vitals normal this week';
    }
  }

  Color _heroStart(String status, BuildContext ctx) {
    switch (status) {
      case 'ALERT':    return aegisRoseLight;
      case 'ELEVATED': return aegisPeachLight;
      default:         return aegisMintLight;
    }
  }

  Color _heroEnd(String status) {
    switch (status) {
      case 'ALERT':    return aegisRose.withOpacity(0.3);
      case 'ELEVATED': return aegisPeach.withOpacity(0.3);
      default:         return aegisMint.withOpacity(0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = DummyDataService.dummyChild;
    final avg   = DummyDataService.weeklyAverages;
    final status = _weeklyStatus(avg);
    final v = DummyDataService.currentVital;

    return Scaffold(
      backgroundColor: AegisColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning,', style: AppTextStyles.caption),
                      Text(child.name, style: AppTextStyles.h3),
                    ],
                  ),
                  Row(
                    children: [
                      _StatusChip(
                        child: Row(
                          children: [
                            const Icon(LucideIcons.battery,
                                size: 14, color: statusSafe),
                            const SizedBox(width: 4),
                            Text('87%',
                                style: AppTextStyles.caption
                                    .copyWith(color: AegisColors.text(context))),
                          ],
                        ),
                        color: AegisColors.card(context),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        child: const Icon(LucideIcons.wifi,
                            size: 14, color: statusSafe),
                        color: AegisColors.card(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Status hero card ─────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _heroStart(status, context),
                            _heroEnd(status),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: aegisPink.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(status: status),
                          const SizedBox(height: 12),
                          Text(
                            status == 'NORMAL'
                                ? 'Healthy'
                                : status == 'ELEVATED'
                                    ? 'Elevated'
                                    : 'Alert',
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(_heroMessage(status), style: AppTextStyles.body),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(LucideIcons.calendarDays,
                                  size: 12, color: aegisTextSoft),
                              const SizedBox(width: 4),
                              Text(
                                'Based on this week\'s data',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Weekly Vital Trends ──────────────────────────────
                    SectionHeader(
                      title: 'Weekly Vital Trends',
                      actionLabel: 'Full report',
                      onAction: () =>
                          Navigator.of(context).pushNamed('/analytics'),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _TrendCard(
                            title: 'Heart Rate',
                            unit: 'bpm',
                            avg: avg['hr'] ?? 0,
                            spots: DummyDataService.weeklySpots('hr'),
                            lineColor: aegisPinkDark,
                            bgColor: aegisPinkLight,
                            icon: LucideIcons.heart,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TrendCard(
                            title: 'Blood Oxygen',
                            unit: '%',
                            avg: avg['spo2'] ?? 0,
                            spots: DummyDataService.weeklySpots('spo2'),
                            lineColor: statusSafe,
                            bgColor: aegisMintLight,
                            icon: LucideIcons.wind,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TrendCard(
                            title: 'Skin Response',
                            unit: 'µS',
                            avg: avg['gsr'] ?? 0,
                            spots: DummyDataService.weeklySpots('gsr'),
                            lineColor: aegisLavender,
                            bgColor: aegisLavenderLight,
                            icon: LucideIcons.activity,
                            decimals: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TrendCard(
                            title: 'Skin Temp',
                            unit: '°C',
                            avg: avg['temp'] ?? 0,
                            spots: DummyDataService.weeklySpots('temp'),
                            lineColor: aegisPeach,
                            bgColor: aegisPeachLight,
                            icon: LucideIcons.thermometer,
                            decimals: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Weekly Health Report ─────────────────────────────
                    const SectionHeader(title: 'Weekly Health Report'),
                    const SizedBox(height: 12),
                    _HealthReportCard(avg: avg),

                    const SizedBox(height: 24),

                    // ── Last Location ────────────────────────────────────
                    SectionHeader(
                      title: 'Last Location',
                      actionLabel: 'View map',
                      onAction: onViewMap,
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: onViewMap,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AegisColors.card(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: aegisPink.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: aegisMintLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(LucideIcons.mapPin,
                                  size: 20, color: statusSafe),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Within safe zone',
                                      style: AppTextStyles.bodyMid),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${v.latitude.toStringAsFixed(4)}, '
                                    '${v.longitude.toStringAsFixed(4)}',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(height: 2),
                                  Text('42m from home',
                                      style: AppTextStyles.caption
                                          .copyWith(color: statusSafe)),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight,
                                size: 16, color: aegisTextSoft),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
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

// ── Helpers ─────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final Widget child;
  final Color color;
  const _StatusChip({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String unit;
  final double avg;
  final List<FlSpot> spots;
  final Color lineColor;
  final Color bgColor;
  final IconData icon;
  final int decimals;

  const _TrendCard({
    required this.title,
    required this.unit,
    required this.avg,
    required this.spots,
    required this.lineColor,
    required this.bgColor,
    required this.icon,
    this.decimals = 0,
  });

  String get _avgLabel =>
      decimals > 0 ? avg.toStringAsFixed(decimals) : avg.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: lineColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: lineColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(title,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_avgLabel $unit',
            style: AppTextStyles.bodyMid
                .copyWith(fontSize: 16, color: lineColor),
          ),
          Text('7-day avg', style: AppTextStyles.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: _MiniChart(spots: spots, color: lineColor),
          ),
        ],
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  const _MiniChart({required this.spots, required this.color});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox();
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
                colors: [color.withOpacity(0.2), color.withOpacity(0)],
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

class _HealthReportCard extends StatelessWidget {
  final Map<String, double> avg;
  const _HealthReportCard({required this.avg});

  String _hrStatus(double hr) {
    if (hr < 60) return 'Low';
    if (hr > 100) return 'Elevated';
    return 'Normal';
  }

  String _spo2Status(double spo2) {
    if (spo2 < 95) return 'Low';
    if (spo2 >= 98) return 'Excellent';
    return 'Normal';
  }

  String _tempStatus(double temp) {
    if (temp < 31) return 'Low';
    if (temp > 35) return 'Elevated';
    return 'Normal';
  }

  String _gsrStatus(double gsr) {
    if (gsr > 3.5) return 'High';
    return 'Normal';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Low':
      case 'Elevated':
      case 'High':
        return statusElevated;
      case 'Excellent':
        return statusSafe;
      default:
        return statusSafe;
    }
  }

  String _overallText(Map<String, double> avg) {
    final stressCount = DummyDataService.weeklyStressCount;
    final hr = avg['hr'] ?? 80;
    final spo2 = avg['spo2'] ?? 98;
    if (spo2 < 95 || hr > 105) {
      return 'Some vitals need attention. Consider consulting a doctor.';
    }
    if (stressCount > 3 || hr > 95) {
      return 'Mild stress detected. Overall health looks manageable.';
    }
    return 'Sarah is doing well this week. All vitals are within normal range.';
  }

  @override
  Widget build(BuildContext context) {
    final hr   = avg['hr'] ?? 0;
    final spo2 = avg['spo2'] ?? 0;
    final gsr  = avg['gsr'] ?? 0;
    final temp = avg['temp'] ?? 0;
    final stressCount = DummyDataService.weeklyStressCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AegisColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: aegisPink.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportRow(
            icon: LucideIcons.heart,
            label: 'Heart Rate',
            value: '${hr.toStringAsFixed(0)} bpm avg',
            status: _hrStatus(hr),
            statusColor: _statusColor(_hrStatus(hr)),
          ),
          _divider(context),
          _ReportRow(
            icon: LucideIcons.wind,
            label: 'Blood Oxygen',
            value: '${spo2.toStringAsFixed(0)}% avg',
            status: _spo2Status(spo2),
            statusColor: _statusColor(_spo2Status(spo2)),
          ),
          _divider(context),
          _ReportRow(
            icon: LucideIcons.thermometer,
            label: 'Skin Temp',
            value: '${temp.toStringAsFixed(1)}°C avg',
            status: _tempStatus(temp),
            statusColor: _statusColor(_tempStatus(temp)),
          ),
          _divider(context),
          _ReportRow(
            icon: LucideIcons.activity,
            label: 'Skin Response',
            value: '${gsr.toStringAsFixed(1)} µS avg',
            status: _gsrStatus(gsr),
            statusColor: _statusColor(_gsrStatus(gsr)),
          ),
          _divider(context),
          _ReportRow(
            icon: LucideIcons.brain,
            label: 'Stress Episodes',
            value: '$stressCount this week',
            status: stressCount == 0
                ? 'None'
                : stressCount <= 2
                    ? 'Mild'
                    : 'Moderate',
            statusColor: stressCount == 0
                ? statusSafe
                : stressCount <= 2
                    ? statusElevated
                    : statusAlert,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: aegisMintLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.sparkles,
                    size: 16, color: statusSafe),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _overallText(avg),
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 0.8,
        color: AegisColors.warm(context),
      );
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color statusColor;

  const _ReportRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: aegisTextSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 1),
                Text(value, style: AppTextStyles.bodyMid.copyWith(fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
