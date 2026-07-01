import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../utils/location_parser.dart';
import '../utils/map_tiles.dart';
import '../utils/maps_launcher.dart';

/// Full-screen map picker. Returns the chosen [LatLng] via Navigator.pop,
/// or null if the user cancels.
class SafeZonePickerScreen extends StatefulWidget {
  const SafeZonePickerScreen({super.key});

  @override
  State<SafeZonePickerScreen> createState() => _SafeZonePickerScreenState();
}

class _SafeZonePickerScreenState extends State<SafeZonePickerScreen> {
  final MapController _mapController = MapController();

  LatLng? _selected;
  bool    _searching  = false;
  String? _searchErr;
  List<NominatimResult> _results = [];
  Timer?  _debounce;

  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();

  static const _defaultCenter = LatLng(31.5204, 74.3587);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Camera move ───────────────────────────────────────────────────────────
  void _moveMap(LatLng pos, [double zoom = 15]) {
    try {
      _mapController.move(pos, zoom);
    } catch (_) {}
  }

  // ── Search ────────────────────────────────────────────────────────────────
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _searchErr = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() { _searching = true; _searchErr = null; _results = []; });
    try {
      final res = await NominatimService.search(q);
      if (!mounted) return;
      setState(() {
        _results   = res;
        _searching = false;
        _searchErr = res.isEmpty ? 'No locations found. Try a different search.' : null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _searching = false; _searchErr = e.message ?? 'Search is unavailable right now. Try again.'; });
    } on NoInternetException {
      if (!mounted) return;
      setState(() { _searching = false; _searchErr = 'Search needs an internet connection.'; });
    } catch (e) {
      debugPrint('Search error: $e');
      if (!mounted) return;
      setState(() { _searching = false; _searchErr = 'Search is unavailable right now. Try again.'; });
    }
  }

  void _pickResult(NominatimResult r) {
    setState(() {
      _selected       = r.position;
      _results        = [];
      _searchCtrl.text = r.shortName;
      _searchFocus.unfocus();
    });
    _moveMap(r.position);
  }

  // Find the location in the real Google Maps app, then paste the result back.
  Future<void> _findViaGoogleMaps() async {
    final picked = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoogleMapsPasteSheet(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selected  = picked;
      _results   = [];
      _searchErr = null;
      _searchCtrl.clear();
      _searchFocus.unfocus();
    });
    _moveMap(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    final center = _selected ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          // ── Free OpenStreetMap (flutter_map) — no API key, no billing ──
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom:   14,
                minZoom:       3,
                maxZoom:       19,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _selected  = latLng;
                    _results   = [];
                    _searchErr = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:          MapTiles.urlFor(isDark),
                  userAgentPackageName: MapTiles.userAgent,
                  maxZoom:              19,
                ),
                if (_selected != null)
                  MarkerLayer(markers: [
                    Marker(
                      point:     _selected!,
                      width:     48,
                      height:    48,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: kAccent,
                        size: 48,
                        shadows: [Shadow(color: Color(0x667C3AED), blurRadius: 16)],
                      ),
                    ),
                  ]),
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

          // ── Top search bar ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? const Color(0xE62D1A4A)
                          : const Color(0xF5FFFFFF),
                      border: Border.all(color: AegisT.glassBorder(context)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: T),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                            style: AegisText.body(color: T)
                                .copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search for a location…',
                              hintStyle: AegisText.body(color: D)
                                  .copyWith(fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            cursorColor: kAccent,
                          ),
                        ),
                        if (_searching)
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
                          const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Find in Google Maps (uses Google's full search) ──────
                  GestureDetector(
                    onTap: _findViaGoogleMaps,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [kAccentLight, kAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x4D7C3AED), blurRadius: 14, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Find in Google Maps',
                              style: AegisText.label(color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  // ── Search results ───────────────────────────────────────
                  if (_searchErr != null || _results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDark
                            ? const Color(0xF02D1A4A)
                            : const Color(0xF5FFFFFF),
                        border: Border.all(color: AegisT.glassBorder(context)),
                      ),
                      child: _searchErr != null
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(_searchErr!,
                                  style: AegisText.body(color: D)
                                      .copyWith(fontSize: 13)),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _results.map((r) {
                                final isLast = r == _results.last;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _pickResult(r),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 18, color: kAccent),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(r.shortName,
                                                      style: AegisText.body(
                                                              color: T)
                                                          .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14)),
                                                  if (r.subTitle.isNotEmpty)
                                                    Text(r.subTitle,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: AegisText
                                                                .caption(
                                                                    color: D)
                                                            .copyWith(
                                                                fontSize:
                                                                    12)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        indent: 44,
                                        color: AegisT.glassBorder(context),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),

                  if (_selected == null &&
                      _results.isEmpty &&
                      _searchErr == null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDark
                            ? const Color(0xCC2D1A4A)
                            : const Color(0xCCFFFFFF),
                      ),
                      child: Text(
                        'Search above or tap the map to place a pin',
                        style: AegisText.caption(color: D)
                            .copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Confirm button ───────────────────────────────────────────────
          if (_selected != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(_selected),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: kAccent,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x667C3AED),
                          blurRadius: 22,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Confirm this location',
                      style: AegisText.title(color: Colors.white)
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
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
// "Find in Google Maps" paste sheet
//
// Google Maps can't return a location to a third-party app, so the parent:
//  1. opens Google Maps, finds the place,
//  2. long-presses it (or Share → Copy) to copy its coordinates/link,
//  3. pastes it here — we parse the lat/lng and hand it back to the picker.
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleMapsPasteSheet extends StatefulWidget {
  const _GoogleMapsPasteSheet();

  @override
  State<_GoogleMapsPasteSheet> createState() => _GoogleMapsPasteSheetState();
}

class _GoogleMapsPasteSheetState extends State<_GoogleMapsPasteSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() => _ctrl.text = data!.text!);
      _useInput();
    }
  }

  Future<void> _useInput() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Paste a Google Maps link or coordinates first.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final point = await LocationParser.parse(text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (point == null) {
      setState(() => _error =
          "Couldn't read a location from that. In Google Maps, long-press the "
          'spot and copy the coordinates, or tap Share → Copy link.');
      return;
    }
    Navigator.of(context).pop(point);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          color: isDark ? kDarkBg : Colors.white,
          border: Border.all(color: isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark ? const Color(0x26FFFFFF) : const Color(0x267C3AED),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Find in Google Maps',
                style: AegisText.h5(color: T).copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _step(D, '1', 'Open Google Maps and find your place.'),
            _step(D, '2', 'Long-press it (or tap Share → Copy) to copy its location.'),
            _step(D, '3', 'Come back and paste it below.'),
            const SizedBox(height: 14),

            // Open Google Maps
            GestureDetector(
              onTap: MapsLauncher.openSearch,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kAccent, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 18, color: kAccent),
                    const SizedBox(width: 8),
                    Text('Open Google Maps',
                        style: AegisText.label(color: kAccent).copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Paste field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? const Color(0x0FFFFFFF) : const Color(0x0F7C3AED),
                border: Border.all(color: AegisT.glassBorder(context)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: AegisText.body(color: T).copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Paste link or 31.5204, 74.3587',
                        hintStyle: AegisText.body(color: D).copyWith(fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      cursorColor: kAccent,
                      onSubmitted: (_) => _useInput(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pasteFromClipboard,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.content_paste_rounded, size: 18, color: kAccent),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: AegisText.caption(color: kAlert).copyWith(fontSize: 12)),
            ],
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _busy ? null : _useInput,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _busy ? kAccent.withValues(alpha: 0.5) : kAccent,
                ),
                child: Center(
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Use this location',
                          style: AegisText.title(color: Colors.white).copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(Color d, String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n. ', style: AegisText.body(color: kAccent).copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
          Expanded(child: Text(text, style: AegisText.body(color: d).copyWith(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
