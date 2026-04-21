import 'dart:async';
import 'dart:math';
import '../models/vital_model.dart';
import '../models/alert_model.dart';
import '../models/child_model.dart';

class DummyDataService {
  static final Random _rand = Random();

  static Stream<VitalModel> get vitalStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield _generateVital();
    }
  }

  static VitalModel _generateVital() => VitalModel(
        heartRate:   75 + _rand.nextInt(20),
        spo2:        97 + _rand.nextInt(3),
        gsr:         2.1 + _rand.nextDouble() * 1.2,
        temperature: 32.5 + _rand.nextDouble() * 1.5,
        movement:    0.3 + _rand.nextDouble() * 0.8,
        status:      _randomStatus(),
        latitude:    31.5204 + (_rand.nextDouble() * 0.001),
        longitude:   74.3587 + (_rand.nextDouble() * 0.001),
        timestamp:   DateTime.now(),
      );

  static String _randomStatus() {
    final roll = _rand.nextDouble();
    if (roll < 0.80) return 'NORMAL';
    if (roll < 0.92) return 'ELEVATED';
    return 'NORMAL';
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
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
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

  static List<VitalModel> get historicalVitals {
    final List<VitalModel> history = [];
    for (int day = 6; day >= 0; day--) {
      for (int hour = 8; hour <= 20; hour += 2) {
        history.add(VitalModel(
          heartRate:   72 + _rand.nextInt(25),
          spo2:        96 + _rand.nextInt(4),
          gsr:         1.8 + _rand.nextDouble() * 2.0,
          temperature: 32.0 + _rand.nextDouble() * 2.0,
          movement:    0.2 + _rand.nextDouble() * 1.5,
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

  static List<double> sparklineFor(String vitalType) {
    return List.generate(10, (_) {
      switch (vitalType) {
        case 'hr':   return 72.0 + _rand.nextInt(25);
        case 'spo2': return 96.0 + _rand.nextInt(4);
        case 'gsr':  return 1.8 + _rand.nextDouble() * 1.5;
        case 'temp': return 32.5 + _rand.nextDouble() * 1.5;
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
