import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aegis/models/child_model.dart';
import 'package:aegis/services/firestore_service.dart';
import 'package:aegis/services/map_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── TC-APP-002: Define and Persist a Safe Zone ───────────────────────────
  group('TC-APP-002 Define and Persist a Safe Zone', () {
    test('GeofenceModel survives a serialize/deserialize round-trip', () {
      const zone = GeofenceModel(lat: 33.6844, lng: 73.0479, radiusMeters: 250);
      final restored = GeofenceModel.fromMap(zone.toMap());

      expect(restored.lat, zone.lat);
      expect(restored.lng, zone.lng);
      expect(restored.radiusMeters, zone.radiusMeters);
    });

    test('a saved safe zone reappears after restart (local persistence)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final center = LatLng(33.6844, 73.0479);

      await MapPrefsService.saveSafeZone(center, 250);
      final loaded = await MapPrefsService.loadSafeZone();

      expect(loaded, isNotNull);
      expect(loaded!.center.latitude, closeTo(center.latitude, 1e-9));
      expect(loaded.center.longitude, closeTo(center.longitude, 1e-9));
      expect(loaded.radius, 250);
    });

    test('a defined geofence is persisted to Firestore on the child doc',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);

      // A child profile exists for this parent.
      await service.createChild(
        'parent-uid',
        const ChildModel(
          id: 'child-1',
          name: 'Sam',
          age: 8,
          deviceId: 'AEGIS-001',
          emergencyContacts: [],
          calibrated: false,
          daysCollected: 0,
        ),
      );

      const zone = GeofenceModel(lat: 33.6844, lng: 73.0479, radiusMeters: 250);
      await service.updateGeofence('child-1', zone);

      final doc =
          await firestore.collection('children').doc('child-1').get();
      final saved =
          GeofenceModel.fromMap(doc.data()!['geofence'] as Map<String, dynamic>);
      expect(saved.lat, zone.lat);
      expect(saved.radiusMeters, 250);
    });
  });
}
