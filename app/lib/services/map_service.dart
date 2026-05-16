import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class NominatimResult {
  final String displayName; // full string from API
  final String shortName;   // bold area / neighbourhood name
  final String subTitle;    // "City, Province" shown in textDim
  final LatLng position;

  NominatimResult({
    required this.displayName,
    required this.shortName,
    required this.subTitle,
    required this.position,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> j) {
    final display = j['display_name'] as String;
    final addr    = j['address'] as Map<String, dynamic>? ?? {};

    // Most specific name available
    final name = addr['neighbourhood']      as String? ??
        addr['suburb']                      as String? ??
        addr['village']                     as String? ??
        addr['road']                        as String? ??
        addr['town']                        as String? ??
        addr['city']                        as String? ??
        j['name']                           as String? ??
        display.split(',').first.trim();

    final city = addr['city']     as String? ??
        addr['town']              as String? ??
        addr['village']           as String? ?? '';
    final province = addr['state']     as String? ??
        addr['province']               as String? ?? '';

    final subParts = [
      if (city.isNotEmpty) city,
      if (province.isNotEmpty) province,
    ];

    return NominatimResult(
      displayName: display,
      shortName:   name,
      subTitle:    subParts.isNotEmpty ? subParts.join(', ') : display,
      position:    LatLng(
        double.parse(j['lat'] as String),
        double.parse(j['lon'] as String),
      ),
    );
  }
}

class RouteOption {
  final int index;
  final List<LatLng> points;
  final double distanceM;
  final double durationS;
  final bool isStraightLine;

  RouteOption({
    required this.index,
    required this.points,
    required this.distanceM,
    required this.durationS,
    this.isStraightLine = false,
  });

  String get distanceLabel {
    if (distanceM >= 1000) return '${(distanceM / 1000).toStringAsFixed(1)} km';
    return '${distanceM.toStringAsFixed(0)} m';
  }

  // Walking time: ~80 m/min (~4.8 km/h)
  String get walkingDurationLabel {
    final mins = (distanceM / 80).round().clamp(1, 9999);
    if (mins < 60) return '🚶 $mins min';
    return '🚶 ${mins ~/ 60}h ${mins % 60}m';
  }
}

class FavouriteLocation {
  final String id;
  final String name;
  final String address;
  final LatLng position;

  FavouriteLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
  });

  factory FavouriteLocation.fromJson(Map<String, dynamic> j) => FavouriteLocation(
        id:       j['id'] as String,
        name:     j['name'] as String,
        address:  j['address'] as String,
        position: LatLng(
          (j['lat'] as num).toDouble(),
          (j['lng'] as num).toDouble(),
        ),
      );

  Map<String, dynamic> toJson() => {
        'id':      id,
        'name':    name,
        'address': address,
        'lat':     position.latitude,
        'lng':     position.longitude,
      };
}

// ── Nominatim service ─────────────────────────────────────────────────────────

class NominatimService {
  static const _searchBase  = 'https://nominatim.openstreetmap.org/search';
  static const _reverseBase = 'https://nominatim.openstreetmap.org/reverse';
  static const _headers     = {'User-Agent': 'AegisApp/1.0'};

  /// Search with Pakistan geographic bias. Automatically falls back to a
  /// global search if the PK-biased search returns 0 results.
  static Future<List<NominatimResult>> search(String query) async {
    // ── Pakistan-biased search ─────────────────────────────────────────────
    final pkUri = Uri.parse(
      '$_searchBase?q=${Uri.encodeComponent(query)}'
      '&format=json&limit=8&countrycodes=pk&addressdetails=1'
      '&accept-language=en'
      '&viewbox=60.872,23.694,77.840,37.084&bounded=0',
    );
    try {
      final res = await http
          .get(pkUri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        if (list.isNotEmpty) {
          return list
              .map((e) => NominatimResult.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // fall through to global
    }

    // ── Global fallback (border areas / international) ─────────────────────
    final globalUri = Uri.parse(
      '$_searchBase?q=${Uri.encodeComponent(query)}'
      '&format=json&limit=8&addressdetails=1&accept-language=en',
    );
    final res = await http
        .get(globalUri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final list = json.decode(res.body) as List;
    return list
        .map((e) => NominatimResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Reverse-geocode a coordinate to a human-readable address string.
  static Future<String> reverse(double lat, double lng) async {
    final uri = Uri.parse(
      '$_reverseBase?lat=$lat&lon=$lng&format=json&accept-language=en',
    );
    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['display_name'] as String? ??
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

// ── OSRM routing service ──────────────────────────────────────────────────────

class OsrmService {
  static const _base = 'https://router.project-osrm.org/route/v1/driving';

  static Future<List<RouteOption>> getRoutes(LatLng from, LatLng to) async {
    final url =
        '$_base/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?alternatives=true&geometries=geojson&overview=full&steps=true';
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    final body   = json.decode(res.body) as Map<String, dynamic>;
    final routes = body['routes'] as List? ?? [];
    return routes.asMap().entries.map((entry) {
      final i    = entry.key;
      final r    = entry.value as Map<String, dynamic>;
      final geom = r['geometry'] as Map<String, dynamic>;
      final coords = (geom['coordinates'] as List)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      return RouteOption(
        index:          i,
        points:         coords,
        distanceM:      (r['distance'] as num).toDouble(),
        durationS:      (r['duration'] as num).toDouble(),
        isStraightLine: false,
      );
    }).toList();
  }

  /// Straight-line fallback when OSRM has no road data for the area.
  static RouteOption straightLineFallback(LatLng from, LatLng to) {
    final distM = const Distance().as(LengthUnit.Meter, from, to);
    return RouteOption(
      index:          0,
      points:         [from, to],
      distanceM:      distM,
      durationS:      distM / 1.2, // approx walking speed
      isStraightLine: true,
    );
  }
}

// ── Map shared-preferences service ───────────────────────────────────────────

class MapPrefsService {
  static const _safeZoneKey   = 'safe_zone';
  static const _childLocKey   = 'child_location';
  static const _safeRouteKey  = 'safe_route';
  static const _favouritesKey = 'favourite_locations';

  // ── Safe zone ─────────────────────────────────────────────────────────────
  static Future<void> saveSafeZone(LatLng center, double radiusM) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _safeZoneKey,
      json.encode({
        'lat':    center.latitude,
        'lng':    center.longitude,
        'radius': radiusM,
      }),
    );
  }

  static Future<({LatLng center, double radius})?> loadSafeZone() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_safeZoneKey);
    if (s == null) return null;
    final d = json.decode(s) as Map<String, dynamic>;
    return (
      center: LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble()),
      radius: (d['radius'] as num).toDouble(),
    );
  }

  // ── Child location ────────────────────────────────────────────────────────
  static Future<void> saveChildLocation(LatLng loc) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _childLocKey,
      json.encode({'lat': loc.latitude, 'lng': loc.longitude}),
    );
  }

  static Future<LatLng?> loadChildLocation() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_childLocKey);
    if (s == null) return null;
    final d = json.decode(s) as Map<String, dynamic>;
    return LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());
  }

  // ── Safe route ────────────────────────────────────────────────────────────
  static Future<void> saveRoute(List<LatLng> points) async {
    final p = await SharedPreferences.getInstance();
    final list = points
        .map((pt) => {'lat': pt.latitude, 'lng': pt.longitude})
        .toList();
    await p.setString(_safeRouteKey, json.encode(list));
  }

  static Future<List<LatLng>?> loadRoute() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_safeRouteKey);
    if (s == null) return null;
    final list = json.decode(s) as List;
    return list
        .map((e) => LatLng(
              (e['lat'] as num).toDouble(),
              (e['lng'] as num).toDouble(),
            ))
        .toList();
  }

  // ── Favourites ────────────────────────────────────────────────────────────
  static Future<List<FavouriteLocation>> loadFavourites() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_favouritesKey);
    if (s == null) return [];
    final list = json.decode(s) as List;
    return list
        .map((e) => FavouriteLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveFavourites(List<FavouriteLocation> favs) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _favouritesKey, json.encode(favs.map((f) => f.toJson()).toList()));
  }
}
