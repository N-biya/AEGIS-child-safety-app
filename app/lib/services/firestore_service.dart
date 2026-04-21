// Stub Firestore service — returns dummy data until Firebase is configured.
// Replace method bodies with real Firestore calls after flutterfire configure.
import '../models/child_model.dart';
import '../models/vital_model.dart';
import '../models/alert_model.dart';
import 'dummy_data_service.dart';

class FirestoreService {
  Future<ChildModel?> getChild(String userId, String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyDataService.dummyChild;
  }

  Stream<VitalModel> vitalStream(String userId, String childId) {
    return DummyDataService.vitalStream;
  }

  Future<List<AlertModel>> getAlerts(String userId, String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyDataService.dummyAlerts;
  }

  Future<List<VitalModel>> getHistory(String userId, String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyDataService.historicalVitals;
  }

  Future<void> updateGeofence(
    String userId,
    String childId,
    GeofenceModel geofence,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
