import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'firestore_service.dart';

/// Periodically publishes the parent phone's real GPS location to the child
/// doc as `deviceLocation`. In SIMULATE_GPS demo mode the band reads this and
/// uses it as its own position, so a "current location" safe zone doesn't
/// false-alarm and a breach demo still works when the zone is moved away.
///
/// Purely additive: if location is unavailable/denied it silently no-ops.
class DeviceLocationService {
  DeviceLocationService._();
  static final DeviceLocationService instance = DeviceLocationService._();

  final _firestore = FirestoreService();
  Timer? _timer;
  String? _childId;
  bool _publishing = false;

  /// Starts publishing this child's location every 10s. Safe to call repeatedly.
  void start(String childId) {
    if (_childId == childId && _timer != null) return;
    _childId = childId;
    _timer?.cancel();
    _publish(); // push one immediately
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _publish());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _childId = null;
  }

  Future<void> _publish() async {
    final id = _childId;
    if (id == null || _publishing) return;
    _publishing = true;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
      await _firestore.updateDeviceLocation(id, pos.latitude, pos.longitude);
    } catch (_) {
      // No fix / denied / offline — leave the band on its last known point.
    } finally {
      _publishing = false;
    }
  }
}
