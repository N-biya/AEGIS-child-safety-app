import 'package:fl_chart/fl_chart.dart';
import '../models/vital_model.dart';
import '../models/alert_model.dart';

double _valueFor(VitalModel v, String vitalType) {
  switch (vitalType) {
    case 'hr':   return v.heartRate.toDouble();
    case 'spo2': return v.spo2.toDouble();
    case 'gsr':  return v.gsr;
    case 'temp': return v.temperature;
    default:     return 0;
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Daily average FlSpots for weekly trend charts (x=0..6, Mon→Sun).
List<FlSpot> weeklySpots(List<VitalModel> history, String vitalType) {
  final Map<int, List<double>> byDay = {};

  for (final v in history) {
    final daysAgo = DateTime.now().difference(v.timestamp).inDays;
    final dayIdx = 6 - daysAgo.clamp(0, 6);
    byDay.putIfAbsent(dayIdx, () => []);
    byDay[dayIdx]!.add(_valueFor(v, vitalType));
  }

  final spots = byDay.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return FlSpot(e.key.toDouble(), avg);
  }).toList()
    ..sort((a, b) => a.x.compareTo(b.x));

  return spots;
}

/// Hourly average FlSpots for a single day (x=hour of day, 0..23).
List<FlSpot> dailySpots(List<VitalModel> history, String vitalType, {DateTime? day}) {
  final target = day ?? DateTime.now();
  final Map<int, List<double>> byHour = {};

  for (final v in history) {
    if (!_isSameDay(v.timestamp, target)) continue;
    byHour.putIfAbsent(v.timestamp.hour, () => []);
    byHour[v.timestamp.hour]!.add(_valueFor(v, vitalType));
  }

  final spots = byHour.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return FlSpot(e.key.toDouble(), avg);
  }).toList()
    ..sort((a, b) => a.x.compareTo(b.x));

  return spots;
}

/// Weekly average FlSpots across the last ~4 weeks (x=0..3, oldest→newest).
List<FlSpot> monthlySpots(List<VitalModel> history, String vitalType) {
  final Map<int, List<double>> byWeek = {};

  for (final v in history) {
    final daysAgo = DateTime.now().difference(v.timestamp).inDays;
    if (daysAgo > 27) continue;
    final weekIdx = 3 - (daysAgo ~/ 7).clamp(0, 3);
    byWeek.putIfAbsent(weekIdx, () => []);
    byWeek[weekIdx]!.add(_valueFor(v, vitalType));
  }

  final spots = byWeek.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return FlSpot(e.key.toDouble(), avg);
  }).toList()
    ..sort((a, b) => a.x.compareTo(b.x));

  return spots;
}

/// Average of [vitalType] over the trailing [within] window. Null if no data.
double? averageFor(List<VitalModel> history, String vitalType, {required Duration within}) {
  final cutoff = DateTime.now().subtract(within);
  final vals = history
      .where((v) => v.timestamp.isAfter(cutoff))
      .map((v) => _valueFor(v, vitalType))
      .toList();
  if (vals.isEmpty) return null;
  return vals.reduce((a, b) => a + b) / vals.length;
}

/// Number of alerts logged within the trailing [within] window.
int alertCountFor(List<AlertModel> alerts, {required Duration within}) {
  final cutoff = DateTime.now().subtract(within);
  return alerts.where((a) => a.timestamp.isAfter(cutoff)).length;
}

/// One calendar day's worth of vitals + alerts, used by the stress heatmap
/// and its tap-to-expand day detail sheet.
class DaySummary {
  final DateTime date;
  final List<VitalModel> vitals;
  final List<AlertModel> alerts;
  const DaySummary({required this.date, required this.vitals, required this.alerts});

  double? get avgHr {
    if (vitals.isEmpty) return null;
    return vitals.map((v) => v.heartRate).reduce((a, b) => a + b) / vitals.length;
  }

  double? get avgSpo2 {
    if (vitals.isEmpty) return null;
    return vitals.map((v) => v.spo2).reduce((a, b) => a + b) / vitals.length;
  }

  int get stressCount => alerts.where((a) => a.type == 'STRESS' || a.type == 'ELEVATED').length;
  bool get hasStress => stressCount > 0;
}

/// Buckets vitals & alerts into the last 7 calendar days (oldest → newest).
List<DaySummary> last7Days(List<VitalModel> history, List<AlertModel> alerts) {
  final now = DateTime.now();
  return List.generate(7, (i) {
    final daysAgo = 6 - i;
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
    final dayVitals = history.where((v) => _isSameDay(v.timestamp, date)).toList();
    final dayAlerts = alerts.where((a) => _isSameDay(a.timestamp, date)).toList();
    return DaySummary(date: date, vitals: dayVitals, alerts: dayAlerts);
  });
}

enum InsightLevel { calm, watch, concern }

class PeriodInsight {
  final String headline;
  final String body;
  final InsightLevel level;
  const PeriodInsight({required this.headline, required this.body, required this.level});
}

const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

String _hourLabel(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h $period';
}

/// Builds a parent-facing insight for the trailing [within] window —
/// what (if anything) stood out, and what it might mean for the child.
PeriodInsight buildInsight(
  List<AlertModel> alerts, {
  required Duration within,
  required String periodLabel,
  String childName = 'Your child',
}) {
  final cutoff = DateTime.now().subtract(within);
  final inPeriod = alerts.where((a) => a.timestamp.isAfter(cutoff)).toList();
  final concerning = inPeriod
      .where((a) => a.type == 'STRESS' || a.type == 'ELEVATED' || a.type == 'SPO2')
      .toList();

  if (concerning.isEmpty) {
    return PeriodInsight(
      headline: 'All calm',
      body: 'No stress spikes or vital concerns detected ${periodLabel.toLowerCase()} — '
          '$childName seems to be doing well.',
      level: InsightLevel.calm,
    );
  }

  final Map<String, List<AlertModel>> buckets = {};
  for (final a in concerning) {
    final key = '${a.timestamp.weekday}-${a.timestamp.hour}';
    buckets.putIfAbsent(key, () => []).add(a);
  }
  final topEntry = buckets.entries.reduce((a, b) => a.value.length >= b.value.length ? a : b);
  final example = topEntry.value.first;
  final count = topEntry.value.length;
  final isMultiDay = within.inDays > 1;
  final headline = isMultiDay
      ? '${_weekdayNames[example.timestamp.weekday - 1]}s around ${_hourLabel(example.timestamp.hour)}'
      : 'Today around ${_hourLabel(example.timestamp.hour)}';

  String recommendation;
  switch (example.type) {
    case 'SPO2':
      recommendation = 'keep an eye on their breathing and check with a doctor if this continues';
      break;
    case 'ELEVATED':
      recommendation = 'a short calming routine or check-in around that time may help';
      break;
    default:
      recommendation = 'a calming routine around that time could help';
  }

  final body = '$count ${example.typeLabel.toLowerCase()} alert${count == 1 ? '' : 's'} '
      '${isMultiDay ? 'were most common' : 'happened'} around this time '
      '${periodLabel.toLowerCase()} — $recommendation.';

  return PeriodInsight(
    headline: headline,
    body: body,
    level: concerning.length >= 3 ? InsightLevel.concern : InsightLevel.watch,
  );
}
