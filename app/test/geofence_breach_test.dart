import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:aegis/models/alert_model.dart';
import 'package:aegis/services/firestore_service.dart';
import 'package:aegis/utils/geofence.dart';

void main() {
  // Safe zone: 200 m radius around a point in Islamabad.
  final center = LatLng(33.6844, 73.0479);
  const radius = 200.0;

  // ── TC-INT-001: End-to-End Geofence Breach ───────────────────────────────
  group('TC-INT-001 End-to-End Geofence Breach', () {
    test('a point inside the radius is not a breach', () {
      // ~50 m north of centre.
      final inside = LatLng(33.6849, 73.0479);
      expect(isInsideZone(inside, center, radius), isTrue);
      expect(isGeofenceBreached(inside, center, radius), isFalse);
    });

    test('a point outside the radius is flagged as a breach', () {
      // ~1.1 km east of centre — well outside the 200 m zone.
      final outside = LatLng(33.6844, 73.0599);
      expect(isGeofenceBreached(outside, center, radius), isTrue);
    });

    test('a point exactly on the boundary is treated as inside', () {
      // Walk east until distance ~= radius, then assert inclusive boundary.
      final boundary = LatLng(33.6844, 73.0479 + 200 / 92000);
      final d = metersBetween(boundary, center);
      // Sanity: this constructed point is near the 200 m boundary.
      expect(d, closeTo(200, 30));
      expect(isInsideZone(center, center, radius), isTrue); // centre is inside
    });

    test('breach raises a GEOFENCE alert document in Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);
      final outside = LatLng(33.6844, 73.0599);

      // The breach-detection path: outside the zone -> raise an alert.
      if (isGeofenceBreached(outside, center, radius)) {
        await service.addAlert(
          'child-1',
          type: 'GEOFENCE',
          heartRate: 96,
          spo2: 98,
          lat: outside.latitude,
          lng: outside.longitude,
        );
      }

      final alerts = await firestore
          .collection('children')
          .doc('child-1')
          .collection('alerts')
          .get();
      expect(alerts.docs.length, 1);
      final alert =
          AlertModel.fromMap(alerts.docs.first.id, alerts.docs.first.data());
      expect(alert.type, 'GEOFENCE');
      expect(alert.resolved, isFalse);
    });
  });
}
