import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of an SOS attempt, so the UI can tell the parent what happened.
class SosOutcome {
  final bool locationAvailable;
  final double? lat;
  final double? lng;
  final bool smsLaunched;

  const SosOutcome({
    required this.locationAvailable,
    required this.smsLaunched,
    this.lat,
    this.lng,
  });

  String? get mapsLink => locationAvailable
      ? 'https://maps.google.com/?q=$lat,$lng'
      : null;
}

/// Emergency "share my location" flow — entirely free and offline-capable:
/// it uses the phone's own GPS (no Maps API key, no billing) and hands a plain
/// Google-Maps link to the SMS app.
///
/// Steps (matches the agreed spec):
///  1. Ask the phone's GPS for current coordinates at HIGH accuracy.
///  2. Wait up to 10 seconds for a fix.
///  3. On timeout/failure, fall back to the last known location on the phone.
///  4. Build a `https://maps.google.com/?q=lat,lng` link.
///  5. Open the SMS composer to the contact, pre-filled with the link.
///  6. If location permission is permanently denied (and there's no last-known
///     fix), the link is omitted but the SMS still goes out marked "unavailable".
class EmergencySosService {
  /// Resolves the phone's coordinates, or null if location is unavailable.
  static Future<({double lat, double lng})?> _resolveLocation() async {
    // Runtime permission — request if not yet decided.
    LocationPermission perm;
    try {
      perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
    } catch (_) {
      perm = LocationPermission.denied;
    }

    final denied = perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever;

    // Even when denied, a last-known fix may still be cached — try it so the
    // alert can still carry a location.
    if (denied) {
      return _lastKnown();
    }

    // Permission granted: high-accuracy fix, but never hang longer than 10s.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      // Timed out or GPS error — fall back to the last known location.
      return _lastKnown();
    }
  }

  static Future<({double lat, double lng})?> _lastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return (lat: last.latitude, lng: last.longitude);
    } catch (_) {}
    return null;
  }

  /// Runs the full SOS: get location → build link → open SMS to [contactPhone].
  /// The alert is sent even if location can't be resolved.
  static Future<SosOutcome> sendSos({
    required String contactPhone,
    required String childName,
  }) async {
    final loc = await _resolveLocation();

    final String body;
    if (loc != null) {
      final link = 'https://maps.google.com/?q=${loc.lat},${loc.lng}';
      body = 'EMERGENCY — $childName needs help. My location: $link';
    } else {
      body = 'EMERGENCY — $childName needs help. My location is currently '
          'unavailable, please call me.';
    }

    final smsUri = Uri(
      scheme: 'sms',
      path: contactPhone.trim(),
      queryParameters: {'body': body},
    );

    bool launched = false;
    try {
      launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    return SosOutcome(
      locationAvailable: loc != null,
      lat: loc?.lat,
      lng: loc?.lng,
      smsLaunched: launched,
    );
  }
}
