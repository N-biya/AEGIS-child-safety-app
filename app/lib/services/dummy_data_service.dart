import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../models/vital_model.dart';
import '../models/alert_model.dart';
import '../models/child_model.dart';

class DummyDataService {

  // Cached historical data so weekly charts are stable across rebuilds
  static final List<VitalModel> _cachedHistory = _buildHistory();

  static Stream<VitalModel> get vitalStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield _generateVital();
    }
  }

  static VitalModel _generateVital() {
    final r = Random();
    return VitalModel(
      heartRate:   75 + r.nextInt(20),
      spo2:        97 + r.nextInt(3),
      gsr:         2.1 + r.nextDouble() * 1.2,
      temperature: 32.5 + r.nextDouble() * 1.5,
      movement:    0.3 + r.nextDouble() * 0.8,
      status:      'NORMAL',
      latitude:    31.5204 + (r.nextDouble() * 0.001),
      longitude:   74.3587 + (r.nextDouble() * 0.001),
      timestamp:   DateTime.now(),
    );
  }

  static VitalModel get currentVital => _generateVital();

  static List<AlertModel> get dummyAlerts => [
        AlertModel(
          id: '1',
          type: 'GEOFENCE',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          heartRate: 88,
          spo2: 98,
          latitude: 31.5210,
          longitude: 74.3592,
          resolved: true,
        ),
        AlertModel(
          id: '2',
          type: 'ELEVATED',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          heartRate: 102,
          spo2: 97,
          latitude: 31.5204,
          longitude: 74.3587,
          resolved: true,
        ),
        AlertModel(
          id: '3',
          type: 'STRESS',
          timestamp:
              DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          heartRate: 115,
          spo2: 96,
          latitude: 31.5198,
          longitude: 74.3580,
          resolved: true,
        ),
        AlertModel(
          id: '4',
          type: 'SPO2',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          heartRate: 90,
          spo2: 89,
          latitude: 31.5204,
          longitude: 74.3587,
          resolved: true,
        ),
      ];

  static List<VitalModel> get historicalVitals => _cachedHistory;

  static List<VitalModel> _buildHistory() {
    final List<VitalModel> history = [];
    final r = Random(42);
    for (int day = 6; day >= 0; day--) {
      for (int hour = 8; hour <= 20; hour += 2) {
        history.add(VitalModel(
          heartRate:   72 + r.nextInt(25),
          spo2:        96 + r.nextInt(4),
          gsr:         1.8 + r.nextDouble() * 2.0,
          temperature: 32.0 + r.nextDouble() * 2.0,
          movement:    0.2 + r.nextDouble() * 1.5,
          status:      'NORMAL',
          latitude:    31.5204,
          longitude:   74.3587,
          timestamp:   DateTime.now()
              .subtract(Duration(days: day))
              .copyWith(hour: hour),
        ));
      }
    }
    return history;
  }

  /// Daily average FlSpots for weekly trend charts (x=0..6, Mon→Sun).
  static List<FlSpot> weeklySpots(String vitalType) {
    final Map<int, List<double>> byDay = {};

    for (final v in _cachedHistory) {
      final daysAgo = DateTime.now().difference(v.timestamp).inDays;
      final dayIdx = 6 - daysAgo.clamp(0, 6);
      byDay.putIfAbsent(dayIdx, () => []);
      double val;
      switch (vitalType) {
        case 'hr':   val = v.heartRate.toDouble(); break;
        case 'spo2': val = v.spo2.toDouble(); break;
        case 'gsr':  val = v.gsr; break;
        case 'temp': val = v.temperature; break;
        default:     val = 0;
      }
      byDay[dayIdx]!.add(val);
    }

    final spots = byDay.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return FlSpot(e.key.toDouble(), avg);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }

  /// Averages across the entire 7-day history.
  static Map<String, double> get weeklyAverages {
    final h = _cachedHistory;
    if (h.isEmpty) return {};
    return {
      'hr':   h.map((v) => v.heartRate.toDouble()).reduce((a, b) => a + b) / h.length,
      'spo2': h.map((v) => v.spo2.toDouble()).reduce((a, b) => a + b) / h.length,
      'gsr':  h.map((v) => v.gsr).reduce((a, b) => a + b) / h.length,
      'temp': h.map((v) => v.temperature).reduce((a, b) => a + b) / h.length,
    };
  }

  /// Stress episode count from dummy alerts.
  static int get weeklyStressCount =>
      dummyAlerts.where((a) => a.type == 'STRESS').length;

  static List<double> sparklineFor(String vitalType) {
    return List.generate(10, (_) {
      final r = Random();
      switch (vitalType) {
        case 'hr':   return 72.0 + r.nextInt(25);
        case 'spo2': return 96.0 + r.nextInt(4);
        case 'gsr':  return 1.8 + r.nextDouble() * 1.5;
        case 'temp': return 32.5 + r.nextDouble() * 1.5;
        default:     return 0;
      }
    });
  }

  static ChildModel get dummyChild => const ChildModel(
        id: 'child_001',
        name: 'Sarah Ahmed',
        age: 8,
        deviceId: 'AEGIS-001',
        geofence: GeofenceModel(
          lat: 31.5204,
          lng: 74.3587,
          radiusMeters: 300,
        ),
        emergencyContacts: ['+923001234567', '+923009876543'],
        calibrated: true,
        daysCollected: 7,
      );
}
