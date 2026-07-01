import '../models/vital_model.dart';
import '../models/alert_model.dart';
import '../models/child_model.dart';

/// A computed, read-only summary of a child's real sensor readings and alerts.
///
/// This is the single source of truth that both the Trends "AI insights" cards
/// and the on-device AEGIS Guard assistant read from, so the numbers a parent
/// sees on the chart always match what the assistant talks about. Everything
/// here is derived from data already streamed in from Firestore — no network
/// calls, no extra state.
class VitalsSnapshot {
  final ChildModel? child;
  final List<VitalModel> history; // newest-first, as returned by Firestore
  final List<AlertModel> alerts; // newest-first
  final DateTime now;

  VitalsSnapshot({
    required this.child,
    required this.history,
    required this.alerts,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  bool get hasData => history.isNotEmpty;

  String get childName => (child?.name.trim().isNotEmpty ?? false)
      ? child!.name.split(' ').first
      : 'your child';

  VitalModel? get latest => history.isEmpty ? null : history.first;

  Duration? get sinceLastReading =>
      latest == null ? null : now.difference(latest!.timestamp);

  bool get isLive {
    final s = sinceLastReading;
    return s != null && s.inSeconds < 60;
  }

  // ── Age-appropriate resting heart-rate band ───────────────────────────────
  // Pediatric resting HR varies a lot with age; these are widely-used awake
  // resting ranges (bpm). Used to phrase whether a reading is normal.
  ({int low, int high}) get hrRange {
    final age = child?.age ?? 8;
    if (age <= 1) return (low: 100, high: 160);
    if (age <= 2) return (low: 90, high: 150);
    if (age <= 5) return (low: 80, high: 140);
    if (age <= 12) return (low: 70, high: 110);
    return (low: 60, high: 100);
  }

  static const int spo2Low = 94; // app raises a Low-SpO2 alert below this
  static const double tempFever = 37.5; // app's fever-alert threshold (°C)

  // ── Windowed values ───────────────────────────────────────────────────────
  List<VitalModel> _within(Duration d) {
    final cutoff = now.subtract(d);
    return history.where((v) => v.timestamp.isAfter(cutoff)).toList();
  }

  List<AlertModel> alertsWithin(Duration d) {
    final cutoff = now.subtract(d);
    return alerts.where((a) => a.timestamp.isAfter(cutoff)).toList();
  }

  double? _avg(List<VitalModel> vs, double Function(VitalModel) sel) {
    if (vs.isEmpty) return null;
    return vs.map(sel).reduce((a, b) => a + b) / vs.length;
  }

  double? avgHr(Duration d) => _avg(_within(d), (v) => v.heartRate.toDouble());
  double? avgSpo2(Duration d) => _avg(_within(d), (v) => v.spo2.toDouble());
  double? avgTemp(Duration d) => _avg(_within(d), (v) => v.temperature);
  double? avgMovement(Duration d) => _avg(_within(d), (v) => v.movement);
  double? avgGsr(Duration d) => _avg(_within(d), (v) => v.gsr);

  ({double value, DateTime at})? peakHr(Duration d) {
    final vs = _within(d);
    if (vs.isEmpty) return null;
    final top = vs.reduce((a, b) => a.heartRate >= b.heartRate ? a : b);
    return (value: top.heartRate.toDouble(), at: top.timestamp);
  }

  ({double value, DateTime at})? lowestSpo2(Duration d) {
    final vs = _within(d);
    if (vs.isEmpty) return null;
    final low = vs.reduce((a, b) => a.spo2 <= b.spo2 ? a : b);
    return (value: low.spo2.toDouble(), at: low.timestamp);
  }

  // ── Trend direction (this period vs the one before it) ────────────────────
  // Returns avg-now minus avg-prior for [sel] over [window]; null if either
  // half lacks data. Positive = rising.
  double? _delta(Duration window, double Function(VitalModel) sel) {
    final nowAvg = _avg(_within(window), sel);
    final priorCutEnd = now.subtract(window);
    final priorCutStart = now.subtract(window * 2);
    final prior = history
        .where((v) =>
            v.timestamp.isAfter(priorCutStart) &&
            v.timestamp.isBefore(priorCutEnd))
        .toList();
    final priorAvg = _avg(prior, sel);
    if (nowAvg == null || priorAvg == null) return null;
    return nowAvg - priorAvg;
  }

  double? hrTrend(Duration window) => _delta(window, (v) => v.heartRate.toDouble());

  // ── Alerts ────────────────────────────────────────────────────────────────
  int stressCount(Duration d) => alertsWithin(d)
      .where((a) => a.type == 'STRESS' || a.type == 'ELEVATED')
      .length;

  AlertModel? get lastStressAlert {
    for (final a in alerts) {
      if (a.type == 'STRESS' || a.type == 'ELEVATED') return a;
    }
    return null;
  }

  /// The hour of day (0–23) at which stress/elevated alerts cluster most over
  /// the trailing [d], with how many fell in that hour. Null if none.
  ({int hour, int count})? stressPeakHour(Duration d) {
    final relevant = alertsWithin(d)
        .where((a) => a.type == 'STRESS' || a.type == 'ELEVATED')
        .toList();
    if (relevant.isEmpty) return null;
    final byHour = <int, int>{};
    for (final a in relevant) {
      byHour[a.timestamp.hour] = (byHour[a.timestamp.hour] ?? 0) + 1;
    }
    final top = byHour.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (hour: top.key, count: top.value);
  }
}

/// Overall at-a-glance safety used by the dashboard hero badge.
enum SafetyState { safe, danger, unknown }

// ── Small formatting helpers shared by insights & the assistant ─────────────
String formatHour(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h $period';
}

String formatAgo(Duration d) {
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

// ── Vital-based insight cards (Trends screen) ───────────────────────────────
enum VitalInsightTone { calm, watch, concern }

class VitalInsight {
  final String title;
  final String body;
  final VitalInsightTone tone;
  const VitalInsight({required this.title, required this.body, required this.tone});
}

/// Generates parent-facing insight cards from the *vital readings themselves*
/// (not just logged alerts) over the trailing [window]. Ordered most-important
/// first; returns a reassuring "all calm" card when nothing stands out.
List<VitalInsight> buildVitalInsights(VitalsSnapshot s, {required Duration window}) {
  final out = <VitalInsight>[];
  final name = s.childName;

  if (!s.hasData) {
    return [
      VitalInsight(
        title: 'Waiting for readings',
        body: "Once $name's band sends its first vitals, AEGIS Guard will start "
            'spotting patterns and trends here.',
        tone: VitalInsightTone.watch,
      ),
    ];
  }

  // SpO2 — most clinically important, surface first if low.
  final lowSpo2 = s.lowestSpo2(window);
  if (lowSpo2 != null && lowSpo2.value < VitalsSnapshot.spo2Low) {
    out.add(VitalInsight(
      title: 'Breathing dipped',
      body: "Oxygen briefly read ${lowSpo2.value.toStringAsFixed(0)}% around "
          "${formatHour(lowSpo2.at.hour)} — below the healthy 95% mark. If this "
          'keeps happening, mention it to your pediatrician.',
      tone: VitalInsightTone.concern,
    ));
  }

  // Temperature
  final avgTemp = s.avgTemp(window);
  if (avgTemp != null && avgTemp >= VitalsSnapshot.tempFever) {
    out.add(VitalInsight(
      title: 'Running warm',
      body: "$name's temperature has averaged ${avgTemp.toStringAsFixed(1)}°C — "
          'around the fever range. Keep them hydrated and watch for other '
          'symptoms.',
      tone: VitalInsightTone.watch,
    ));
  }

  // Heart rate — pattern around stress peak.
  final peakHour = s.stressPeakHour(window);
  if (peakHour != null) {
    final multiDay = window.inDays > 1;
    out.add(VitalInsight(
      title: 'Calmer ${formatHour(peakHour.hour)}s could help',
      body: '${peakHour.count} stress-related moment'
          '${peakHour.count == 1 ? '' : 's'} clustered around '
          '${formatHour(peakHour.hour)} ${multiDay ? 'on most days' : 'today'}. '
          'A quiet wind-down routine at that time often settles things.',
      tone: peakHour.count >= 3 ? VitalInsightTone.concern : VitalInsightTone.watch,
    ));
  }

  // HR trend direction
  final hrDelta = s.hrTrend(window);
  final avgHr = s.avgHr(window);
  if (avgHr != null) {
    final r = s.hrRange;
    final inRange = avgHr >= r.low && avgHr <= r.high;
    if (hrDelta != null && hrDelta.abs() >= 4) {
      out.add(VitalInsight(
        title: hrDelta > 0 ? 'Heart rate trending up' : 'Heart rate settling',
        body: "Average heart rate is ${hrDelta > 0 ? 'up' : 'down'} "
            '${hrDelta.abs().toStringAsFixed(0)} bpm versus the period before, now '
            'about ${avgHr.toStringAsFixed(0)} bpm '
            '(${inRange ? 'still in the normal band' : 'just outside the typical band'} '
            'for age ${s.child?.age ?? 8}).',
        tone: inRange ? VitalInsightTone.calm : VitalInsightTone.watch,
      ));
    }
  }

  if (out.isEmpty) {
    out.add(VitalInsight(
      title: 'All calm',
      body: 'Heart rate, oxygen and temperature have all stayed in healthy '
          "ranges — $name's readings look steady. Nice and settled.",
      tone: VitalInsightTone.calm,
    ));
  }

  return out;
}
