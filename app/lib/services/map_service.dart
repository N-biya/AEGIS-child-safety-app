import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Custom exceptions ─────────────────────────────────────────────────────────

class NoInternetException implements Exception {}

class ApiException implements Exception {
  final String? message;
  const ApiException([this.message]);
}

// ── Models ────────────────────────────────────────────────────────────────────

class NominatimResult {
  final String displayName;
  final String shortName;
  final String subTitle;
  final LatLng position;

  NominatimResult({
    required this.displayName,
    required this.shortName,
    required this.subTitle,
    required this.position,
  });

  factory NominatimResult.fromMapTiler(Map<String, dynamic> f) {
    final placeName = f['place_name'] as String? ?? '';
    final coords    = f['geometry']['coordinates'] as List;
    final lng       = (coords[0] as num).toDouble();
    final lat       = (coords[1] as num).toDouble();

    final parts     = placeName.split(',');
    final shortName = parts.isNotEmpty ? parts.first.trim() : placeName;
    final subTitle  = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    return NominatimResult(
      displayName: placeName,
      shortName:   shortName,
      subTitle:    subTitle,
      position:    LatLng(lat, lng),
    );
  }

  factory NominatimResult.fromNominatim(Map<String, dynamic> j) {
    final display = j['display_name'] as String? ?? '';
    final addr    = j['address'] as Map<String, dynamic>? ?? {};

    final name = addr['neighbourhood'] as String? ??
        addr['suburb']       as String? ??
        addr['village']      as String? ??
        addr['road']         as String? ??
        addr['town']         as String? ??
        addr['city']         as String? ??
        display.split(',').first.trim();

    final city     = addr['city']  as String? ?? addr['town']     as String? ?? addr['village'] as String? ?? '';
    final province = addr['state'] as String? ?? addr['province'] as String? ?? '';

    final sub = [if (city.isNotEmpty) city, if (province.isNotEmpty) province];

    return NominatimResult(
      displayName: display,
      shortName:   name,
      subTitle:    sub.isNotEmpty ? sub.join(', ') : display,
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

// ── MapTiler geocoding service ────────────────────────────────────────────────

class NominatimService {
  static const _apiKey  = 'xfVWfEOSoPUM4aEYz3mO';
  static const _mtBase  = 'https://api.maptiler.com/geocoding';
  static const _nomBase = 'https://nominatim.openstreetmap.org';

  static const _types =
      'address,neighbourhood,locality,municipality,place,poi,road,sublocality,village';

  static final _mtHeaders = {
    'Accept':       'application/json',
    'Content-Type': 'application/json',
  };

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static final _nomDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'AegisApp/1.0'},
  ));

  /// Four-strategy search.
  /// Throws [NoInternetException] or [ApiException] on hard failures.
  /// Returns [] if nothing found after all strategies.
  static Future<List<NominatimResult>> search(String query) async {
    // Strategy 1: MapTiler, country=pk
    var res = await _mapTilerSearch(query, country: 'pk');
    if (res != null && res.isNotEmpty) return res;

    // Strategy 2: MapTiler, no country restriction
    res = await _mapTilerSearch(query);
    if (res != null && res.isNotEmpty) return res;

    // Strategy 3: MapTiler, append "Pakistan"
    if (!query.toLowerCase().contains('pakistan')) {
      res = await _mapTilerSearch('$query Pakistan');
      if (res != null && res.isNotEmpty) return res;
    }

    // Strategy 4: Nominatim fallback
    res = await _nominatimSearch(query);
    if (res != null && res.isNotEmpty) return res;

    return [];
  }

  /// Returns null = API/HTTP error (try next strategy).
  /// Returns [] = 0 results (try next strategy).
  /// Throws [NoInternetException] or [ApiException] to abort all strategies.
  static Future<List<NominatimResult>?> _mapTilerSearch(
    String query, {
    String? country,
  }) async {
    final encoded = Uri.encodeComponent(query.trim());
    final params  = <String, dynamic>{
      'key':      _apiKey,
      'language': 'en',
      'limit':    10,
      'types':    _types,
      if (country != null) 'country': country,
    };
    try {
      final res = await _dio.get(
        '$_mtBase/$encoded.json',
        queryParameters: params,
        options: Options(headers: _mtHeaders),
      );
      final sc = res.statusCode ?? 0;
      if (sc == 200) {
        final features = (res.data['features'] as List?) ?? [];
        return features
            .map((f) => NominatimResult.fromMapTiler(f as Map<String, dynamic>))
            .toList();
      } else if (sc == 401) {
        debugPrint('MapTiler 401: invalid API key');
        throw const ApiException('Invalid API key. Please check your MapTiler key.');
      } else if (sc == 429) {
        debugPrint('MapTiler 429: rate limited');
        throw const ApiException('Too many searches. Please wait a moment and try again.');
      } else {
        debugPrint('MapTiler unexpected status: $sc');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('MapTiler search error: $e');
      if (_isNetworkError(e)) throw NoInternetException();
      return null;
    }
  }

  static Future<List<NominatimResult>?> _nominatimSearch(String query) async {
    try {
      final res = await _nomDio.get(
        '$_nomBase/search',
        queryParameters: {
          'q':              query,
          'format':         'json',
          'limit':          5,
          'accept-language':'en',
          'addressdetails': 1,
        },
        options: Options(headers: _mtHeaders),
      );
      if (res.statusCode == 200) {
        final list = (res.data as List?) ?? [];
        return list
            .map((e) => NominatimResult.fromNominatim(e as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      return null;
    }
  }

  /// Reverse-geocode a coordinate to a human-readable address string.
  static Future<String> reverse(double lat, double lng) async {
    try {
      final res = await _dio.get(
        '$_mtBase/$lng,$lat.json',
        queryParameters: {'key': _apiKey, 'language': 'en'},
        options: Options(headers: _mtHeaders),
      );
      if (res.statusCode == 200) {
        final features = (res.data['features'] as List?) ?? [];
        if (features.isNotEmpty) {
          return (features[0] as Map<String, dynamic>)['place_name'] as String? ??
              _coords(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return _coords(lat, lng);
  }

  static String _coords(double lat, double lng) =>
      'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}';

  static bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout    ||
      e.type == DioExceptionType.connectionError   ||
      e.type == DioExceptionType.unknown;
}

// ── OSRM routing service ──────────────────────────────────────────────────────

class OsrmService {
  static const _base = 'https://router.project-osrm.org/route/v1/driving';
  static final _dio  = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<List<RouteOption>> getRoutes(LatLng from, LatLng to) async {
    final url =
        '$_base/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?alternatives=true&geometries=geojson&overview=full&steps=true';
    final res = await _dio.get(url);
    if (res.statusCode != 200) return [];
    final routes = (res.data['routes'] as List?) ?? [];
    return routes.asMap().entries.map((entry) {
      final i      = entry.key;
      final r      = entry.value as Map<String, dynamic>;
      final geom   = r['geometry'] as Map<String, dynamic>;
      final coords = (geom['coordinates'] as List)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
      return RouteOption(
        index:     i,
        points:    coords,
        distanceM: (r['distance'] as num).toDouble(),
        durationS: (r['duration'] as num).toDouble(),
      );
    }).toList();
  }

  static RouteOption straightLineFallback(LatLng from, LatLng to) {
    final distM = const Distance().as(LengthUnit.Meter, from, to);
    return RouteOption(
      index:          0,
      points:         [from, to],
      distanceM:      distM,
      durationS:      distM / 1.2,
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

  static Future<void> saveSafeZone(LatLng center, double radiusM) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_safeZoneKey, json.encode({
      'lat': center.latitude, 'lng': center.longitude, 'radius': radiusM,
    }));
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

  static Future<void> saveChildLocation(LatLng loc) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_childLocKey,
        json.encode({'lat': loc.latitude, 'lng': loc.longitude}));
  }

  static Future<LatLng?> loadChildLocation() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_childLocKey);
    if (s == null) return null;
    final d = json.decode(s) as Map<String, dynamic>;
    return LatLng((d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());
  }

  static Future<void> saveRoute(List<LatLng> points) async {
    final p    = await SharedPreferences.getInstance();
    final list = points.map((pt) => {'lat': pt.latitude, 'lng': pt.longitude}).toList();
    await p.setString(_safeRouteKey, json.encode(list));
  }

  static Future<List<LatLng>?> loadRoute() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_safeRouteKey);
    if (s == null) return null;
    final list = json.decode(s) as List;
    return list
        .map((e) => LatLng((e['lat'] as num).toDouble(), (e['lng'] as num).toDouble()))
        .toList();
  }

  static Future<List<FavouriteLocation>> loadFavourites() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_favouritesKey);
    if (s == null) return [];
    final list = json.decode(s) as List;
    return list.map((e) => FavouriteLocation.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveFavourites(List<FavouriteLocation> favs) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_favouritesKey, json.encode(favs.map((f) => f.toJson()).toList()));
  }
}
