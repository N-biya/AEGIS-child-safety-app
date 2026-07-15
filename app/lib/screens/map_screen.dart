import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/child_model.dart';
import '../router/app_router.dart';
import '../screens/safe_zone_picker_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/map_service.dart';
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../utils/geofence.dart';
import '../utils/map_tiles.dart';
import '../utils/maps_launcher.dart';
import '../widgets/glass_card.dart';
import '../widgets/aegis_animations.dart';
import '../widgets/sos_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  /// When set (e.g. a location shared into AEGIS from Google Maps), the map
  /// opens centered on this point with a pin dropped there.
  final LatLng? focusLocation;

  const MapScreen({super.key, this.focusLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ── Map engine ────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  final _firestore = FirestoreService();

  // Map overlay objects, rebuilt from app state.
  List<CircleMarker> _circles   = [];
  List<Polyline>     _polylines = [];

  // ── Persisted state ───────────────────────────────────────────────────────
  LatLng?       _safeZoneCenter;
  double        _safeZoneRadius = 250;
  LatLng?       _childPos;
  List<LatLng>? _savedRoute;
  List<FavouriteLocation> _favourites = [];

  // ── Route state ───────────────────────────────────────────────────────────
  List<RouteOption> _routes           = [];
  int               _selectedRouteIdx = 0;
  bool              _loadingRoutes    = false;
  String?           _routeError;
  bool              _hasStraightLine  = false;

  // ── UI state ──────────────────────────────────────────────────────────────
  String  _locationLabel = 'Greenfield Primary School';
  String  _childName     = 'Aisha';
  String  _childInitial  = 'A';
  LatLng? _searchPin;

  // ── GPS loading overlay ───────────────────────────────────────────────────
  bool   _gpsLoading = false;
  String _gpsStatus  = 'Getting your location…';

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (widget.focusLocation != null) {
      _searchPin = widget.focusLocation;
      // Controller isn't attached on the first frame — move after layout.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _moveMap(widget.focusLocation!, 16));
    }
    _loadAll();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final sz  = await MapPrefsService.loadSafeZone();
    final cl  = await MapPrefsService.loadChildLocation();
    final rt  = await MapPrefsService.loadRoute();
    final fav = await MapPrefsService.loadFavourites();
    final cn  = await PrefsService.getChildName();
    if (!mounted) return;
    setState(() {
      if (sz != null) {
        _safeZoneCenter = sz.center;
        _safeZoneRadius = sz.radius;
      }
      _childPos     = cl;
      _savedRoute   = rt;
      _favourites   = fav;
      _childName    = cn.isEmpty ? 'Aisha' : cn;
      _childInitial = _childName[0].toUpperCase();
    });
    // Move map to loaded position (controller may not be attached yet — the
    // FlutterMap's initialCenter covers that first frame, so a throw is fine).
    // A shared-in focus location wins over the child/safe-zone default.
    if (widget.focusLocation != null) {
      _moveMap(widget.focusLocation!, 16);
    } else if (_childPos != null) {
      _moveMap(_childPos!);
    } else if (_safeZoneCenter != null) {
      _moveMap(_safeZoneCenter!);
    }

    if (_childPos != null && _safeZoneCenter != null && _savedRoute == null) {
      _fetchRoutes();
    }
    _refreshGeofence();
    _refreshRoutes();
  }

  // ── Camera helper ─────────────────────────────────────────────────────────
  void _moveMap(LatLng pos, [double zoom = 15]) {
    // Throws if the map isn't attached yet (e.g. during initial load); ignore.
    try {
      _mapController.move(pos, zoom);
    } catch (_) {}
  }

  // Opens the child's set location in the real Google Maps app (free, no key).
  Future<void> _openChildInGoogleMaps() async {
    final pos = _childPos;
    if (pos == null) return;
    final ok = await MapsLauncher.openLocation(pos.latitude, pos.longitude);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open Google Maps.',
            style: AegisText.body(color: Colors.white)),
        backgroundColor: kAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Geofence (flutter_map CircleMarker, radius in real metres) ────────────
  void _refreshGeofence() {
    if (_safeZoneCenter == null) {
      if (_circles.isNotEmpty && mounted) setState(() => _circles = []);
      return;
    }
    final circle = CircleMarker(
      point:             _safeZoneCenter!,
      radius:            _safeZoneRadius,
      useRadiusInMeter:  true,
      color:             kAccent.withValues(alpha: 0.18),
      borderColor:       kAccent,
      borderStrokeWidth: 2,
    );
    if (mounted) setState(() => _circles = [circle]);
  }

  // ── Route polylines (flutter_map Polylines) ───────────────────────────────
  void _refreshRoutes() {
    final polylines = <Polyline>[];

    // A previously saved route renders as a single solid line.
    if (_savedRoute != null && _routes.isEmpty) {
      polylines.add(Polyline(
        points:      _savedRoute!,
        color:       kAccent,
        strokeWidth: 6,
      ));
    }

    // Candidate routes — selected one solid (with a soft glow beneath),
    // the rest faded.
    for (final r in _routes) {
      if (r.index == _selectedRouteIdx) {
        polylines.add(Polyline(
          points:      r.points,
          color:       kAccent.withValues(alpha: 0.20),
          strokeWidth: 14,
        ));
        polylines.add(Polyline(
          points:      r.points,
          color:       kAccent,
          strokeWidth: 6,
        ));
      } else {
        polylines.add(Polyline(
          points:      r.points,
          color:       kAccent.withValues(alpha: 0.35),
          strokeWidth: 4,
        ));
      }
    }

    if (mounted) setState(() => _polylines = polylines);
  }

  // ── Search sheet ──────────────────────────────────────────────────────────
  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchSheet(
        onPicked: (r) {
          Navigator.of(ctx).pop();
          setState(() {
            _searchPin     = r.position;
            _locationLabel = r.shortName;
          });
          _moveMap(r.position);
        },
      ),
    );
  }

  // ── Favourites sheet ──────────────────────────────────────────────────────
  void _showFavouritesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FavouritesSheet(
        favourites: _favourites,
        onChanged: (favs) async {
          await MapPrefsService.saveFavourites(favs);
          if (mounted) setState(() => _favourites = favs);
        },
        onUse: (fav) {
          Navigator.of(ctx).pop();
          setState(() {
            _childPos      = fav.position;
            _locationLabel = fav.name;
            _searchPin     = null;
          });
          _moveMap(fav.position);
          MapPrefsService.saveChildLocation(fav.position);
          if (_safeZoneCenter != null) _fetchRoutes();
        },
      ),
    );
  }

  // ── Safe zone flow ────────────────────────────────────────────────────────
  Future<void> _startSafeZoneFlow() async {
    // Capture the uid before any awaits (no context across async gaps).
    final uid = context.read<AuthService>().userId;

    if (_safeZoneCenter != null) {
      final replace = await _showReplaceDialog();
      if (replace != true) return;
    }
    if (!mounted) return;
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const SafeZonePickerScreen()),
    );
    if (picked == null || !mounted) return;

    final radius = await _showRadiusSheet(picked);
    if (radius == null || !mounted) return;

    await MapPrefsService.saveSafeZone(picked, radius);
    // Mirror the safe zone to Firestore so the band can read it and raise
    // breach alerts (the firmware reads geofence lat/lng/radius from the child doc).
    if (uid.isNotEmpty) {
      try {
        final child = await _firestore.watchChildForUser(uid).first;
        if (child != null) {
          await _firestore.updateGeofence(
            child.id,
            GeofenceModel(
              lat: picked.latitude,
              lng: picked.longitude,
              radiusMeters: radius,
            ),
          );
        }
      } catch (_) {
        // Offline or no child yet — the local copy is still saved.
      }
    }
    if (!mounted) return;
    setState(() {
      _safeZoneCenter  = picked;
      _safeZoneRadius  = radius;
      _routes          = [];
      _savedRoute      = null;
      _hasStraightLine = false;
    });
    _moveMap(picked);
    _refreshGeofence();
    _refreshRoutes();
    await _showChildLocationSheet();
  }

  Future<bool?> _showReplaceDialog() => showDialog<bool>(
        context: context,
        builder: (ctx) {
          final T = AegisT.text(ctx);
          final D = AegisT.textDim(ctx);
          return AlertDialog(
            backgroundColor: AegisT.card(ctx),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Replace safe zone?',
                style:
                    AegisText.h5(color: T).copyWith(fontWeight: FontWeight.w700)),
            content: Text(
                'You already have a safe zone set. Would you like to replace it?',
                style: AegisText.body(color: D)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Keep existing',
                    style: AegisText.label(color: D)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Yes, replace',
                    style: AegisText.label(color: kAlert)),
              ),
            ],
          );
        },
      );

  Future<double?> _showRadiusSheet(LatLng center) {
    double radius = 250;
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = AegisT.isDark(ctx);
          final T      = AegisT.text(ctx);
          final D      = AegisT.textDim(ctx);
          return _ModalCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How large should the safe zone be?',
                    style: AegisText.h5(color: T)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text('This is the area your child should stay within.',
                    style: AegisText.body(color: D).copyWith(fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Safe zone radius',
                        style: AegisText.caption(color: D)
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text('${radius.toStringAsFixed(0)} metres',
                        style:
                            AegisText.h5(color: kAccent).copyWith(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor:   kAccent,
                    inactiveTrackColor: isDark
                        ? const Color(0x0FFFFFFF)
                        : const Color(0x147C3AED),
                    thumbColor:   Colors.white,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayColor: const Color(0x267C3AED),
                    trackHeight:  8,
                  ),
                  child: Slider(
                    value: radius,
                    min: 50,
                    max: 2000,
                    onChanged: (v) => setS(() => radius = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('50 m',   style: AegisText.micro(color: D)),
                    Text('2000 m', style: AegisText.micro(color: D)),
                  ],
                ),
                const SizedBox(height: 20),
                _AccentButton(
                  label: 'Save Safe Zone',
                  onTap: () => Navigator.of(ctx).pop(radius),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Child location sheet ──────────────────────────────────────────────────
  Future<void> _showChildLocationSheet() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChildLocationSheet(
        childName: _childName,
        onGps: () async {
          Navigator.of(ctx).pop();
          await _locateViaGps();
        },
        onSearch: () {
          Navigator.of(ctx).pop();
          _showSearchSheetForChild();
        },
      ),
    );
  }

  // ── GPS location ──────────────────────────────────────────────────────────
  Future<void> _locateViaGps() async {
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = false;
    }
    if (!serviceEnabled) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AegisT.card(ctx),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text("Location is turned off",
              style: AegisText.h5(color: AegisT.text(ctx))),
          content: Text(
              "Your phone's location is turned off. Please turn it on to use this feature.",
              style: AegisText.body(color: AegisT.textDim(ctx))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: AegisText.label(color: AegisT.textDim(ctx))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openLocationSettings();
              },
              child: Text('Open Location Settings',
                  style: AegisText.label(color: kAccent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    LocationPermission perm;
    try {
      perm = await Geolocator.checkPermission();
    } catch (_) {
      if (mounted) _showSearchSheetForChild();
      return;
    }

    if (perm == LocationPermission.denied) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AegisT.card(ctx),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Location access needed',
              style: AegisText.h5(color: AegisT.text(ctx))),
          content: Text(
              'AEGIS needs your location to show where your child is on the map.',
              style: AegisText.body(color: AegisT.textDim(ctx))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Not now',
                  style: AegisText.label(color: AegisT.textDim(ctx))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Allow',
                  style: AegisText.label(color: kAccent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AegisT.card(ctx),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Permission permanently denied',
              style: AegisText.h5(color: AegisT.text(ctx))),
          content: Text(
              'Location permission was denied. Please go to your phone settings and enable location for AEGIS.',
              style: AegisText.body(color: AegisT.textDim(ctx))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: AegisText.label(color: AegisT.textDim(ctx))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openAppSettings();
              },
              child: Text('Open Settings',
                  style: AegisText.label(color: kAccent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    if (perm == LocationPermission.denied) {
      if (mounted) _showSearchSheetForChild();
      return;
    }

    setState(() { _gpsLoading = true; _gpsStatus = 'Getting your location…'; });

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      final got = LatLng(pos.latitude, pos.longitude);

      if (mounted) setState(() => _gpsStatus = 'Getting address…');
      String address = 'Lat: ${got.latitude.toStringAsFixed(5)}, '
          'Lng: ${got.longitude.toStringAsFixed(5)}';
      try {
        address = await NominatimService.reverse(pos.latitude, pos.longitude);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _gpsLoading    = false;
        _childPos      = got;
        _searchPin     = null;
        _locationLabel = address;
      });
      await MapPrefsService.saveChildLocation(got);
      _moveMap(got);
      if (_safeZoneCenter != null) _fetchRoutes();

    } on TimeoutException {
      if (!mounted) return;
      setState(() => _gpsLoading = false);
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AegisT.card(ctx),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text("Couldn't get your location",
              style: AegisText.h5(color: AegisT.text(ctx))),
          content: Text(
              "Make sure location is turned on in your phone settings.",
              style: AegisText.body(color: AegisT.textDim(ctx))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('search'),
              child: Text('Search manually',
                  style: AegisText.label(color: AegisT.textDim(ctx))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('retry'),
              child: Text('Try Again',
                  style: AegisText.label(color: kAccent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == 'retry') _locateViaGps();
      if (action == 'search') _showSearchSheetForChild();

    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() => _gpsLoading = false);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AegisT.card(ctx),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text("Location is turned off",
              style: AegisText.h5(color: AegisT.text(ctx))),
          content: Text(
              "Your phone's location is turned off. Please turn it on to use this feature.",
              style: AegisText.body(color: AegisT.textDim(ctx))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: AegisText.label(color: AegisT.textDim(ctx))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openLocationSettings();
              },
              child: Text('Open Location Settings',
                  style: AegisText.label(color: kAccent)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

    } catch (_) {
      if (!mounted) return;
      setState(() => _gpsLoading = false);
      _showSearchSheetForChild();
    }
  }

  void _showSearchSheetForChild() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchSheet(
        onPicked: (r) {
          Navigator.of(ctx).pop();
          setState(() {
            _childPos      = r.position;
            _searchPin     = null;
            _locationLabel = r.shortName;
          });
          MapPrefsService.saveChildLocation(r.position);
          _moveMap(r.position);
          if (_safeZoneCenter != null) _fetchRoutes();
        },
      ),
    );
  }

  // ── Fit camera to show a full route ──────────────────────────────────────
  void _fitRouteBounds(List<RouteOption> routes) {
    if (routes.isEmpty) return;
    final allPts = routes.expand((r) => r.points).toList();
    if (allPts.isEmpty) return;

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(allPts),
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (_) {}
  }

  // ── Route fetching ────────────────────────────────────────────────────────
  Future<void> _fetchRoutes() async {
    if (_childPos == null || _safeZoneCenter == null) return;
    setState(() {
      _loadingRoutes   = true;
      _routes          = [];
      _routeError      = null;
      _hasStraightLine = false;
    });
    try {
      final routes = await OsrmService.getRoutes(_childPos!, _safeZoneCenter!);
      if (!mounted) return;
      if (routes.isEmpty) {
        final fallback =
            OsrmService.straightLineFallback(_childPos!, _safeZoneCenter!);
        setState(() {
          _routes          = [fallback];
          _selectedRouteIdx = 0;
          _loadingRoutes   = false;
          _hasStraightLine = true;
        });
      } else {
        setState(() {
          _routes           = routes;
          _selectedRouteIdx = 0;
          _loadingRoutes    = false;
        });
      }
      _refreshRoutes();
      _fitRouteBounds(_routes);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loadingRoutes = false;
        _routeError    = 'Route calculation is taking too long. '
            'Check your connection and try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRoutes = false;
        _routeError    = 'An internet connection is needed to calculate routes. '
            'Please try again when you\'re online.';
      });
    }
  }

  Future<void> _saveRoute() async {
    if (_routes.isEmpty) return;
    final pts = _routes[_selectedRouteIdx].points;
    await MapPrefsService.saveRoute(pts);
    setState(() {
      _savedRoute      = pts;
      _routes          = [];
      _hasStraightLine = false;
    });
    _refreshRoutes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Safe route saved!',
            style: AegisText.body(color: Colors.white)),
        backgroundColor: kSafe,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    final defaultCenter = widget.focusLocation ?? _childPos ?? _safeZoneCenter ?? const LatLng(31.5204, 74.3587);

    return Scaffold(
      body: Stack(
        children: [
          // ── Free OpenStreetMap (flutter_map) — no API key, no billing ──
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom:   14,
                minZoom:       3,
                maxZoom:       19,
              ),
              children: [
                TileLayer(
                  urlTemplate:          MapTiles.urlFor(isDark),
                  userAgentPackageName: MapTiles.userAgent,
                  maxZoom:              19,
                ),
                if (_circles.isNotEmpty) CircleLayer(circles: _circles),
                if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
                MarkerLayer(markers: [
                  if (_childPos != null)
                    Marker(
                      point:     _childPos!,
                      width:     48,
                      height:    48,
                      alignment: Alignment.center,
                      child:     _ChildMarker(initial: _childInitial),
                    ),
                  if (_searchPin != null)
                    Marker(
                      point:     _searchPin!,
                      width:     40,
                      height:    40,
                      alignment: Alignment.topCenter,
                      child:     const Icon(Icons.location_on, color: kAccent, size: 40),
                    ),
                ]),
                // Attribution (required by OSM / CARTO usage policy).
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 4, bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                    child: Text(MapTiles.attribution,
                        style: AegisText.micro9(color: D).copyWith(fontSize: 9)),
                  ),
                ),
              ],
            ),
          ),

          // ── Top bar ───────────────────────────────────────────────────
          Positioned(
            top:   MediaQuery.of(context).padding.top + 12,
            left:  16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: GestureDetector(
                  onTap: _showSearchSheet,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isDark
                          ? const Color(0xBF2D1A4A)
                          : const Color(0xD9FFFFFF),
                      border: Border.all(
                          color: AegisT.glassBorder(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: kAccent,
                          ),
                          child: const Icon(Icons.location_on_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Currently at',
                                  style: AegisText.micro(color: D)
                                      .copyWith(fontSize: 11)),
                              Text(_locationLabel,
                                  style: AegisText.title(color: T),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showFavouritesSheet,
                          child: Icon(Icons.star_outline_rounded,
                              size: 20, color: T),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showSearchSheet,
                          child: Icon(Icons.search_rounded, size: 20, color: T),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Emergency SOS button ──────────────────────────────────────
          Positioned(
            top:   MediaQuery.of(context).padding.top + 78,
            right: 16,
            child: const SosButton(),
          ),

          // ── "Open in Google Maps" (free link — full Google data) ──────
          // Stacked under the SOS button on the right so the map's floating
          // controls sit in one tidy column instead of split across corners.
          if (_childPos != null)
            Positioned(
              top:   MediaQuery.of(context).padding.top + 140,
              right: 16,
              child: GestureDetector(
                onTap: _openChildInGoogleMaps,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isDark ? const Color(0xE62D1A4A) : Colors.white,
                    border: Border.all(color: AegisT.glassBorder(context)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 18, color: kAccent),
                      const SizedBox(width: 6),
                      Text('Maps',
                          style: AegisText.label(color: T)
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(width: 3),
                      Icon(Icons.open_in_new_rounded, size: 13, color: AegisT.textDim(context)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Draggable bottom sheet ────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize:     0.18,
            maxChildSize:     0.80,
            snap:             true,
            snapSizes:        const [0.45],
            builder: (_, scrollCtrl) => _DraggablePanel(
              scrollCtrl:       scrollCtrl,
              isDark:           isDark,
              T:                T,
              D:                D,
              childName:        _childName,
              childInitial:     _childInitial,
              childPos:         _childPos,
              safeZoneCenter:   _safeZoneCenter,
              safeZoneRadius:   _safeZoneRadius,
              routes:           _routes,
              selectedRouteIdx: _selectedRouteIdx,
              loadingRoutes:    _loadingRoutes,
              routeError:       _routeError,
              hasStraightLine:  _hasStraightLine,
              onRadiusChanged:  (v) {
                setState(() => _safeZoneRadius = v);
                _refreshGeofence();
              },
              onRouteSelect: (i) {
                setState(() => _selectedRouteIdx = i);
                _refreshRoutes();
              },
              onSetSafeZone: _startSafeZoneFlow,
              onSetChildLoc: _showChildLocationSheet,
              onSaveRoute:   _saveRoute,
              onRetryRoutes: _fetchRoutes,
            ),
          ),

          // ── GPS loading overlay ───────────────────────────────────────
          if (_gpsLoading)
            Positioned.fill(
              child: Container(
                color: const Color(0x66000000),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    decoration: BoxDecoration(
                      color: AegisT.card(context),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 32,
                            offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: kAccent),
                        const SizedBox(height: 16),
                        Text(_gpsStatus,
                            style: AegisText.body(color: AegisT.text(context))
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Child marker on map
// ─────────────────────────────────────────────────────────────────────────────
class _ChildMarker extends StatelessWidget {
  final String initial;
  const _ChildMarker({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AegisPing(
        ringColor: kAccent,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [kAccentLight, kAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0xCC7C3AED), blurRadius: 16),
            ],
          ),
          child: Center(
            child: Text(initial,
                style: AegisText.label(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable panel
// ─────────────────────────────────────────────────────────────────────────────
class _DraggablePanel extends StatelessWidget {
  final ScrollController scrollCtrl;
  final bool isDark;
  final Color T, D;
  final String childName, childInitial;
  final LatLng? childPos, safeZoneCenter;
  final double safeZoneRadius;
  final List<RouteOption> routes;
  final int selectedRouteIdx;
  final bool loadingRoutes, hasStraightLine;
  final String? routeError;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<int> onRouteSelect;
  final VoidCallback onSetSafeZone, onSetChildLoc, onSaveRoute, onRetryRoutes;

  const _DraggablePanel({
    required this.scrollCtrl,
    required this.isDark,
    required this.T,
    required this.D,
    required this.childName,
    required this.childInitial,
    required this.childPos,
    required this.safeZoneCenter,
    required this.safeZoneRadius,
    required this.routes,
    required this.selectedRouteIdx,
    required this.loadingRoutes,
    required this.hasStraightLine,
    required this.routeError,
    required this.onRadiusChanged,
    required this.onRouteSelect,
    required this.onSetSafeZone,
    required this.onSetChildLoc,
    required this.onSaveRoute,
    required this.onRetryRoutes,
  });

  bool get _insideZone {
    if (childPos == null || safeZoneCenter == null) return false;
    return isInsideZone(childPos!, safeZoneCenter!, safeZoneRadius);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xE62D1A4A)
                : const Color(0xF5FFFFFF),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
                top: BorderSide(color: AegisT.glassBorder(context))),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                MediaQuery.of(context).padding.bottom + kNavBarHeight + 8),
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: isDark
                        ? const Color(0x4DF5E6FF)
                        : const Color(0x332D1A4A),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                            colors: [kAccentLight, kAccent]),
                      ),
                      child: Center(
                        child: Text(childInitial,
                            style: AegisText.label(color: Colors.white)
                                .copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(childName, style: AegisText.h5(color: T)),
                        Text(
                          childPos == null
                              ? 'Tap below to set location'
                              : 'Last seen · just now',
                          style: AegisText.caption(color: D)
                              .copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ]),
                  if (childPos != null && safeZoneCenter != null)
                    _StatusPill(inside: _insideZone),
                ],
              ),

              if (childPos != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: onSetChildLoc,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: kAccent.withValues(alpha: 0.10),
                        border: Border.all(color: kAccent.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_location_alt_outlined, size: 14, color: kAccent),
                          const SizedBox(width: 6),
                          Text('Change child location',
                              style: AegisText.label(color: kAccent)
                                  .copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              if (loadingRoutes) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator(color: kAccent)),
                const SizedBox(height: 8),
                Center(
                  child: Text('Finding routes…',
                      style: AegisText.caption(color: D)),
                ),
              ],

              if (routeError != null && !loadingRoutes) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kAlert.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kAlert.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: kAlert, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(routeError!,
                            style: AegisText.caption(color: T)
                                .copyWith(fontSize: 12)),
                      ),
                      if (routeError!.contains('try again'))
                        GestureDetector(
                          onTap: onRetryRoutes,
                          child: Text('Retry',
                              style: AegisText.label(color: kAccent)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ],

              if (routes.isNotEmpty && !loadingRoutes) ...[
                const SizedBox(height: 14),
                if (hasStraightLine)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kStress.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: kStress.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: kStress),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Exact road route unavailable for this area. Showing approximate path.',
                            style: AegisText.caption(color: T)
                                .copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (routes.length > 1)
                  _RouteCards(
                    routes:   routes,
                    selected: selectedRouteIdx,
                    isDark:   isDark,
                    onSelect: onRouteSelect,
                  ),
                const SizedBox(height: 10),
                _AccentButton(
                    label: 'Save as Safe Route', onTap: onSaveRoute),
              ],

              const SizedBox(height: 14),

              if (safeZoneCenter != null) ...[
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Geofence radius',
                              style: AegisText.caption(color: D).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          Text(
                              '${safeZoneRadius.toStringAsFixed(0)}m',
                              style: AegisText.h5(color: T)
                                  .copyWith(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: kAccent,
                          inactiveTrackColor: isDark
                              ? const Color(0x0FFFFFFF)
                              : const Color(0x147C3AED),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                          overlayColor: const Color(0x267C3AED),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          value: safeZoneRadius.clamp(50, 2000),
                          min: 50,
                          max: 2000,
                          onChanged: onRadiusChanged,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('50m',
                              style: AegisText.micro(color: D)
                                  .copyWith(fontSize: 10)),
                          Text('2000m',
                              style: AegisText.micro(color: D)
                                  .copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              GestureDetector(
                onTap: onSetSafeZone,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: kAccent,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x597C3AED),
                          blurRadius: 22,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        safeZoneCenter == null
                            ? Icons.add_rounded
                            : Icons.edit_location_alt_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        safeZoneCenter == null
                            ? 'Set as Safe Zone'
                            : 'Update Safe Zone',
                        style: AegisText.title(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route cards
// ─────────────────────────────────────────────────────────────────────────────
class _RouteCards extends StatelessWidget {
  final List<RouteOption> routes;
  final int selected;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _RouteCards({
    required this.routes,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: routes.length,
        itemBuilder: (_, i) {
          final r        = routes[i];
          final isActive = i == selected;

          final inactiveBg = isDark
              ? const Color(0x0FFFFFFF)
              : const Color(0xB3FFFFFF);
          final inactiveBorder = isDark
              ? const Color(0x1AFFFFFF)
              : const Color(0x1E7C3AED);

          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 140,
              height: 80,
              margin: EdgeInsets.only(
                  right: i < routes.length - 1 ? 10 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color:   isActive ? kAccent         : inactiveBg,
                  border:  isActive ? null             : Border.all(color: inactiveBorder),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color(0x737C3AED),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : [
                          const BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Route ${i + 1}',
                      style: AegisText.label(
                              color: isActive ? Colors.white : T)
                          .copyWith(
                              fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      r.distanceLabel,
                      style: AegisText.body(
                              color: isActive ? Colors.white : T)
                          .copyWith(
                              fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    Text(
                      r.walkingDurationLabel,
                      style: AegisText.body(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.80)
                                  : D)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final bool inside;
  const _StatusPill({required this.inside});

  @override
  Widget build(BuildContext context) {
    final color = inside ? kSafe : kAlert;
    final label = inside ? 'INSIDE ZONE' : 'OUTSIDE ZONE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AegisText.label(color: color)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bottom sheet  (MapTiler geocoding — 400 ms debounce)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchSheet extends StatefulWidget {
  final ValueChanged<NominatimResult> onPicked;
  const _SearchSheet({required this.onPicked});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  Timer?  _debounce;
  bool    _loading = false;
  String? _error;
  List<NominatimResult> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _error = null; });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() { _loading = true; _error = null; _results = []; });
    try {
      final res = await NominatimService.search(q);
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
        _error   = res.isEmpty
            ? 'No locations found. Try a different search.'
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.message ?? 'Search is unavailable right now. Try again.'; });
    } on NoInternetException {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Search needs an internet connection.'; });
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Search is unavailable right now. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    return _ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search for a location',
              style: AegisText.h5(color: T)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 14),

          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark
                  ? const Color(0x2E7C3AED)
                  : const Color(0x147C3AED),
              border: Border.all(color: kAccent, width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded, size: 18, color: D),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode:  _focus,
                    onChanged:  _onChanged,
                    style: AegisText.body(color: T).copyWith(fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Type a place name…',
                      hintStyle:
                          AegisText.body(color: D).copyWith(fontSize: 15),
                    ),
                    cursorColor: kAccent,
                  ),
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kAccent),
                    ),
                  )
                else
                  const SizedBox(width: 14),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!,
                  style: AegisText.body(color: D).copyWith(fontSize: 13)),
            ),

          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.35),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 44,
                  color: AegisT.glassBorder(context),
                ),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return GestureDetector(
                    onTap: () => widget.onPicked(r),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18, color: kAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.shortName,
                                    style: AegisText.body(color: T)
                                        .copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                if (r.subTitle.isNotEmpty)
                                  Text(r.subTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AegisText.caption(color: D)
                                          .copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Child location picker sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ChildLocationSheet extends StatelessWidget {
  final String childName;
  final VoidCallback onGps, onSearch;

  const _ChildLocationSheet({
    required this.childName,
    required this.onGps,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    return _ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Where is $childName right now?',
              style: AegisText.h5(color: T)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          _LocationOptionCard(
              emoji: '📍',
              title: 'Use my current location',
              subtitle: "Uses your phone's GPS",
              onTap: onGps),
          const SizedBox(height: 10),
          _LocationOptionCard(
              emoji: '🔍',
              title: 'Search for a location',
              subtitle: 'Find a place by name',
              onTap: onSearch),
        ],
      ),
    );
  }
}

class _LocationOptionCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final VoidCallback onTap;

  const _LocationOptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? const Color(0x1A7C3AED)
              : const Color(0x0F7C3AED),
          border: Border.all(color: AegisT.glassBorder(context)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AegisText.body(color: T)
                          .copyWith(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style: AegisText.caption(color: D)
                          .copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: D, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Favourites bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _FavouritesSheet extends StatefulWidget {
  final List<FavouriteLocation> favourites;
  final ValueChanged<List<FavouriteLocation>> onChanged;
  final ValueChanged<FavouriteLocation> onUse;

  const _FavouritesSheet({
    required this.favourites,
    required this.onChanged,
    required this.onUse,
  });

  @override
  State<_FavouritesSheet> createState() => _FavouritesSheetState();
}

class _FavouritesSheetState extends State<_FavouritesSheet> {
  late List<FavouriteLocation> _favs;

  @override
  void initState() {
    super.initState();
    _favs = List.from(widget.favourites);
  }

  void _delete(FavouriteLocation f) {
    setState(() => _favs.remove(f));
    widget.onChanged(_favs);
  }

  void _addNew() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddFavouriteSheet(
        existingAddresses: _favs.map((f) => f.address).toSet(),
        onSave: (fav) {
          Navigator.of(ctx).pop();
          if (_favs.length >= 20) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "You've reached the maximum of 20 favourite locations. "
                  'Please delete one to add a new one.',
                  style: AegisText.body(color: Colors.white)),
              backgroundColor: kAlert,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
            return;
          }
          setState(() => _favs.add(fav));
          widget.onChanged(_favs);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    return _ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Favourite Locations',
                  style: AegisText.h5(color: T)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
              GestureDetector(
                onTap: _addNew,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kAccent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: kAccent),
                      const SizedBox(width: 4),
                      Text('Add New',
                          style: AegisText.label(color: kAccent)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_favs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.star_border_rounded,
                      size: 48, color: D.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(
                    'No favourite locations yet.\nTap "+ Add New" to get started.',
                    style: AegisText.body(color: D).copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.35),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _favs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AegisT.glassBorder(context)),
                itemBuilder: (_, i) {
                  final f = _favs[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kAccent.withValues(alpha: 0.15),
                          ),
                          child: const Center(
                            child: Icon(Icons.location_on_outlined,
                                size: 16, color: kAccent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.name,
                                  style: AegisText.body(color: T).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(f.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AegisText.caption(color: D)
                                      .copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              size: 18, color: D),
                          color: isDark ? kDarkCard : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (v) {
                            if (v == 'use') widget.onUse(f);
                            if (v == 'delete') _delete(f);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'use',
                              child: Text('Use this location',
                                  style: AegisText.body(color: T)
                                      .copyWith(fontSize: 13)),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                  style: AegisText.body(color: kAlert)
                                      .copyWith(fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add favourite sheet  (400 ms debounce + updated error messages)
// ─────────────────────────────────────────────────────────────────────────────
class _AddFavouriteSheet extends StatefulWidget {
  final Set<String> existingAddresses;
  final ValueChanged<FavouriteLocation> onSave;

  const _AddFavouriteSheet({
    required this.existingAddresses,
    required this.onSave,
  });

  @override
  State<_AddFavouriteSheet> createState() => _AddFavouriteSheetState();
}

class _AddFavouriteSheetState extends State<_AddFavouriteSheet> {
  final _labelCtrl  = TextEditingController();
  final _labelFocus = FocusNode();
  final _searchCtrl = TextEditingController();
  final _searchFocus= FocusNode();
  Timer? _debounce;
  bool   _loading   = false;
  String? _dupError, _searchError;
  List<NominatimResult> _results     = [];
  NominatimResult?      _picked;

  @override
  void initState() {
    super.initState();
    _labelFocus.addListener(() => setState(() {}));
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _labelCtrl.dispose();   _labelFocus.dispose();
    _searchCtrl.dispose();  _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    setState(() { _picked = null; _dupError = null; });
    if (q.trim().isEmpty) {
      setState(() { _results = []; _searchError = null; });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() { _loading = true; _searchError = null; _results = []; });
    try {
      final res = await NominatimService.search(q);
      if (!mounted) return;
      setState(() {
        _results     = res;
        _loading     = false;
        _searchError = res.isEmpty
            ? 'No locations found. Try a different search.'
            : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _searchError = e.message ?? 'Search is unavailable right now. Try again.'; });
    } on NoInternetException {
      if (!mounted) return;
      setState(() { _loading = false; _searchError = 'Search needs an internet connection.'; });
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      setState(() { _loading = false; _searchError = 'Search is unavailable right now. Try again.'; });
    }
  }

  void _pickResult(NominatimResult r) {
    if (widget.existingAddresses.contains(r.displayName)) {
      setState(() =>
          _dupError = 'This location is already in your favourites.');
      return;
    }
    setState(() {
      _picked          = r;
      _searchCtrl.text = r.shortName;
      _results         = [];
      _dupError        = null;
      _searchFocus.unfocus();
    });
  }

  void _save() {
    if (_labelCtrl.text.trim().isEmpty || _picked == null) return;
    widget.onSave(FavouriteLocation(
      id:       DateTime.now().millisecondsSinceEpoch.toString(),
      name:     _labelCtrl.text.trim(),
      address:  _picked!.displayName,
      position: _picked!.position,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    return _ModalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a favourite location',
              style: AegisText.h5(color: T)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),

          Text('GIVE THIS PLACE A NAME',
              style: AegisText.micro(color: D)
                  .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _SimpleField(
            ctrl: _labelCtrl, focus: _labelFocus,
            hint: "e.g. Aisha's School",
            isDark: isDark, T: T, D: D,
            isFocused: _labelFocus.hasFocus,
          ),
          const SizedBox(height: 14),

          Text('LOCATION',
              style: AegisText.micro(color: D)
                  .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _SimpleField(
            ctrl: _searchCtrl, focus: _searchFocus,
            hint: 'Search for a place…',
            isDark: isDark, T: T, D: D,
            isFocused: _searchFocus.hasFocus,
            onChanged: _onSearchChanged,
            suffixLoading: _loading,
          ),

          if (_dupError != null) ...[
            const SizedBox(height: 6),
            Text(_dupError!,
                style: AegisText.caption(color: kAlert)
                    .copyWith(fontSize: 12)),
          ],
          if (_searchError != null) ...[
            const SizedBox(height: 6),
            Text(_searchError!,
                style: AegisText.caption(color: D).copyWith(fontSize: 12)),
          ],

          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.25),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AegisT.glassBorder(context)),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return GestureDetector(
                    onTap: () => _pickResult(r),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: kAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.shortName,
                                    style: AegisText.body(color: T)
                                        .copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                if (r.subTitle.isNotEmpty)
                                  Text(r.subTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AegisText.caption(color: D)
                                          .copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_picked != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: kSafe),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_picked!.shortName,
                      style: AegisText.caption(color: kSafe)
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),
          _AccentButton(
            label: 'Save Favourite',
            onTap: _picked != null && _labelCtrl.text.trim().isNotEmpty
                ? _save
                : null,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SimpleField extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final String hint;
  final bool isDark, isFocused;
  final Color T, D;
  final ValueChanged<String>? onChanged;
  final bool suffixLoading;

  const _SimpleField({
    required this.ctrl,
    required this.focus,
    required this.hint,
    required this.isDark,
    required this.isFocused,
    required this.T,
    required this.D,
    this.onChanged,
    this.suffixLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isFocused
            ? (isDark ? const Color(0x2E7C3AED) : const Color(0x147C3AED))
            : (isDark ? const Color(0x0FFFFFFF) : const Color(0x0F7C3AED)),
        border: Border.all(
          color: isFocused
              ? kAccent
              : (isDark ? const Color(0x14FFFFFF) : const Color(0x1A7C3AED)),
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode:  focus,
              onChanged:  onChanged,
              style: AegisText.body(color: T).copyWith(fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AegisText.body(color: D).copyWith(fontSize: 15),
              ),
              cursorColor: kAccent,
            ),
          ),
          if (suffixLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: kAccent),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _ModalCard extends StatelessWidget {
  final Widget child;
  const _ModalCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark     = AegisT.isDark(context);
    final cardBg     = isDark ? kDarkBg : Colors.white;
    final cardBorder =
        isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          color: cardBg,
          border: Border.all(color: cardBorder),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark
                      ? const Color(0x26FFFFFF)
                      : const Color(0x267C3AED),
                ),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _AccentButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onTap != null ? kAccent : kAccent.withValues(alpha: 0.4),
          boxShadow: onTap != null
              ? const [
                  BoxShadow(
                      color: Color(0x667C3AED),
                      blurRadius: 22,
                      offset: Offset(0, 8)),
                ]
              : null,
        ),
        child: Center(
          child: Text(label,
              style: AegisText.title(color: Colors.white)
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
