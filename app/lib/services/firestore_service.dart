import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import '../models/vital_model.dart';
import '../models/alert_model.dart';

class FirestoreService {
  /// [firestore] is injectable so tests can supply a fake instance;
  /// production uses the default [FirebaseFirestore.instance].
  FirestoreService({FirebaseFirestore? firestore})
      : _children =
            (firestore ?? FirebaseFirestore.instance).collection('children');

  final CollectionReference<Map<String, dynamic>> _children;

  /// The child linked to this parent's account. Null if none exists yet.
  Stream<ChildModel?> watchChildForUser(String uid) {
    return _children
        .where('linkedParents', arrayContains: uid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : ChildModel.fromMap(snap.docs.first.id, snap.docs.first.data()));
  }

  Stream<VitalModel?> latestVitalStream(String childId) {
    return _children
        .doc(childId)
        .collection('vitals')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : VitalModel.fromMap(snap.docs.first.data()));
  }

  Future<List<VitalModel>> getHistory(String childId, {int limit = 200}) async {
    final snap = await _children
        .doc(childId)
        .collection('vitals')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => VitalModel.fromMap(d.data())).toList();
  }

  Future<List<AlertModel>> getAlerts(String childId) async {
    final snap = await _children
        .doc(childId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => AlertModel.fromMap(d.id, d.data())).toList();
  }

  /// Live stream of alerts, newest first — used to fire local notifications.
  Stream<List<AlertModel>> watchAlerts(String childId) {
    return _children
        .doc(childId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AlertModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> addVital(String childId, VitalModel vital) async {
    await _children.doc(childId).collection('vitals').add(vital.toMap());
  }

  /// Raises an alert doc shaped to match [AlertModel.fromMap] exactly —
  /// the Alerts tab reads this directly, so field drift here breaks the UI.
  Future<void> addAlert(
    String childId, {
    required String type,
    required int heartRate,
    required int spo2,
    required double lat,
    required double lng,
  }) async {
    await _children.doc(childId).collection('alerts').add({
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'vitals': {'hr': heartRate, 'spo2': spo2},
      'location': {'lat': lat, 'lng': lng},
      'resolved': false,
    });
  }

  Future<void> updateGeofence(String childId, GeofenceModel geofence) async {
    await _children.doc(childId).update({'geofence': geofence.toMap()});
  }

  /// Replaces the child's list of forbidden (no-go) zones. The band reads this
  /// array from the child doc and does the on-device dwell check.
  Future<void> updateForbiddenZones(
      String childId, List<ForbiddenZoneModel> zones) async {
    await _children.doc(childId).update({
      'forbiddenZones': zones.map((z) => z.toMap()).toList(),
    });
  }

  /// Publishes the parent phone's current location to the child doc. In demo
  /// mode the band mirrors this as its own position, so setting the safe zone
  /// to "my current location" doesn't false-alarm while stationary.
  Future<void> updateDeviceLocation(
      String childId, double lat, double lng) async {
    await _children.doc(childId).update({
      'deviceLocation': {'lat': lat, 'lng': lng},
    });
  }

  /// Marks a single alert as resolved (handled) — keeps it in history.
  Future<void> resolveAlert(String childId, String alertId) =>
      _children.doc(childId).collection('alerts').doc(alertId)
          .update({'resolved': true});

  /// Permanently deletes a single alert.
  Future<void> deleteAlert(String childId, String alertId) =>
      _children.doc(childId).collection('alerts').doc(alertId).delete();

  /// Deletes every alert for a child — the "Clear all" action.
  Future<void> clearAllAlerts(String childId) async {
    final snap = await _children.doc(childId).collection('alerts').get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  /// Updates name/age/photo for a child profile. Pass only the fields that
  /// changed; omitted fields are left untouched.
  Future<void> updateChildProfile(
    String childId, {
    String? name,
    int? age,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (age != null) updates['age'] = age;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isEmpty) return;
    await _children.doc(childId).update(updates);
  }

  Future<void> updateEmergencyContacts(
    String childId,
    List<EmergencyContactModel> contacts,
  ) async {
    await _children.doc(childId).update({
      'emergencyContacts': contacts.map((c) => c.toMap()).toList(),
    });
  }

  /// Deletes a child's profile and its vitals/alerts subcollections.
  /// Used by the Privacy & Data screen's "delete my data" action.
  Future<void> deleteChild(String childId) async {
    final childRef = _children.doc(childId);
    for (final sub in ['vitals', 'alerts']) {
      final docs = await childRef.collection(sub).get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    }
    await childRef.delete();
  }

  /// Creates a new child profile owned by [uid]. Used until an onboarding
  /// screen exists to do this through the UI.
  Future<void> createChild(String uid, ChildModel child) async {
    await _children.doc(child.id).set({
      ...child.toMap(),
      'linkedParents': [uid],
    });
  }
}
