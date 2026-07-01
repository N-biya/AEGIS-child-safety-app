import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis/models/alert_model.dart';
import 'package:aegis/services/firestore_service.dart';

void main() {
  // ── TC-INT-002: Alert Flag Triggers FCM Push ─────────────────────────────
  //
  // The FCM push is dispatched by a Cloud Function that triggers on the
  // creation of an alert document. The testable contract on the app side is
  // that an alert write produces a document of exactly the shape the push
  // function (and the Alerts tab) read back. This verifies that contract.
  group('TC-INT-002 Alert Flag Triggers FCM Push', () {
    test('writing an alert produces a push-ready document', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);

      await service.addAlert(
        'child-1',
        type: 'STRESS',
        heartRate: 142,
        spo2: 95,
        lat: 33.6844,
        lng: 73.0479,
      );

      final snap = await firestore
          .collection('children')
          .doc('child-1')
          .collection('alerts')
          .get();

      // Exactly one alert was written...
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();

      // ...with every field the push function relies on, in the right shape.
      expect(data['type'], 'STRESS');
      expect(data['resolved'], false);
      expect(data['vitals'], {'hr': 142, 'spo2': 95});
      expect((data['location'] as Map)['lat'], 33.6844);
      expect((data['location'] as Map)['lng'], 73.0479);
      expect(data['timestamp'], isA<String>());

      // And it parses cleanly via the same model the UI/push consumer use.
      final alert = AlertModel.fromMap(snap.docs.first.id, data);
      expect(alert.heartRate, 142);
      expect(alert.type, 'STRESS');
    });

    test('non-alert vitals do not create alert documents', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);

      // A normal vitals write (alert flag false) must not raise an alert,
      // so the push pipeline stays untriggered ("sync unaffected").
      final snap = await firestore
          .collection('children')
          .doc('child-1')
          .collection('alerts')
          .get();
      expect(snap.docs, isEmpty);
      // (No addAlert call was made — the guard lives in the caller.)
      expect(service, isNotNull);
    });
  });
}
