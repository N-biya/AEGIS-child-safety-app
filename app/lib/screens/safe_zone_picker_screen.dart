import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';

/// Full-screen map picker. Returns the chosen [LatLng] via Navigator.pop,
/// or null if the user cancels.
class SafeZonePickerScreen extends StatefulWidget {
  const SafeZonePickerScreen({super.key});

  @override
  State<SafeZonePickerScreen> createState() => _SafeZonePickerScreenState();
}

class _SafeZonePickerScreenState extends State<SafeZonePickerScreen> {
  final _mapCtrl      = MapController();
  final _searchCtrl   = TextEditingController();
  final _searchFocus  = FocusNode();

  LatLng? _selected;
  bool    _searching  = false;
  String? _searchErr;
  List<NominatimResult> _results = [];
  Timer?  _debounce;

  static const _defaultCenter = LatLng(31.5204, 74.3587);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _searchErr = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _doSearch(q));
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchErr = 'No internet connection. Search is unavailable.';
      });
    }
  }

  void _pickResult(NominatimResult r) {
    setState(() {
      _selected = r.position;
      _results  = [];
      _searchCtrl.text = r.shortName;
      _searchFocus.unfocus();
    });
    _mapCtrl.move(r.position, 15);
  }

  void _onMapTap(TapPosition _, LatLng pt) {
    setState(() => _selected = pt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    final tileUrl = isDark
        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _selected ?? _defaultCenter,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 19,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.aegis.aegis',
              ),
              if (_selected != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _selected!,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: kAccent,
                      size: 48,
                      shadows: [Shadow(color: Color(0x667C3AED), blurRadius: 16)],
                    ),
                  ),
                ]),
            ],
          ),

          // Dark theme tint
          if (isDark)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: const Color(0x1A1A0F2E)),
              ),
            ),

          // ── Top search bar ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back + search row
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

                  // ── Search results ─────────────────────────────────────
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
                                                      style:
                                                          AegisText.body(color: T)
                                                              .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14)),
                                                  if (r.subTitle.isNotEmpty)
                                                    Text(r.subTitle,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: AegisText.caption(
                                                                color: D)
                                                            .copyWith(
                                                                fontSize: 12)),
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

                  // Hint when nothing is selected yet
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

          // ── Confirm button ────────────────────────────────────────────
          if (_selected != null)
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom + 24,
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
