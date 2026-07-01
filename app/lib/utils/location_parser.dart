import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Extracts a coordinate from text the parent pastes back from Google Maps.
///
/// Google Maps has no way to hand a picked location back to a third-party app,
/// so the flow is: open Maps → find the place → copy its coordinates or share
/// link → paste here. This understands the common shapes that copy produces:
///   • raw "31.5204, 74.3587"
///   • full URLs: .../maps/@31.52,74.35,15z  ·  ?q=31.52,74.35  ·  !3d31.52!4d74.35
///   • short links: https://maps.app.goo.gl/xxxx  (resolved via redirect)
class LocationParser {
  static final _dio = Dio(BaseOptions(
    followRedirects: true,
    maxRedirects: 5,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    validateStatus: (_) => true,
    headers: {'User-Agent': 'Mozilla/5.0 (AegisApp)'},
  ));

  /// Returns the parsed coordinate, or null if nothing usable was found.
  static Future<LatLng?> parse(String input) async {
    final text = input.trim();
    if (text.isEmpty) return null;

    // 1. Plain "lat, lng".
    final coords = _coordsIn(text);
    if (coords != null) return coords;

    // 2. A full Google Maps URL with coordinates embedded.
    final fromUrl = _urlCoords(text);
    if (fromUrl != null) return fromUrl;

    // 3. A short share link — follow the redirect, then parse the real URL.
    if (text.contains('goo.gl') || text.contains('app.goo.gl')) {
      final resolved = await _resolve(text);
      if (resolved != null) {
        return _urlCoords(resolved) ?? _coordsIn(resolved);
      }
    }

    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static LatLng? _coordsIn(String s) {
    final m = RegExp(r'^\s*(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)\s*$').firstMatch(s);
    if (m == null) return null;
    return _make(m.group(1), m.group(2));
  }

  static LatLng? _urlCoords(String url) {
    // Place URLs embed the exact point as !3d<lat>!4d<lng> — most precise.
    final bang = RegExp(r'!3d(-?\d{1,3}\.\d+)!4d(-?\d{1,3}\.\d+)').firstMatch(url);
    if (bang != null) return _make(bang.group(1), bang.group(2));

    // Query forms: ?q= / query= / ll= / destination=
    final q = RegExp(r'[?&](?:q|query|ll|destination)=(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)')
        .firstMatch(url);
    if (q != null) return _make(q.group(1), q.group(2));

    // Camera form: /@<lat>,<lng>,<zoom>
    final at = RegExp(r'@(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)').firstMatch(url);
    if (at != null) return _make(at.group(1), at.group(2));

    return null;
  }

  static Future<String?> _resolve(String url) async {
    try {
      final res = await _dio.get(url);
      final real = res.realUri.toString();
      if (real.isNotEmpty && real != url) return real;
      // Some shorteners put the target in a Location header instead.
      final loc = res.headers.value('location');
      return loc;
    } catch (_) {
      return null;
    }
  }

  static LatLng? _make(String? a, String? b) {
    final lat = double.tryParse(a ?? '');
    final lng = double.tryParse(b ?? '');
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }
}
