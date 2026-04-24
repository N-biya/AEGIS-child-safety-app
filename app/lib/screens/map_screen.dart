import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  LatLng _childPos = const LatLng(31.5204, 74.3587);
  bool _editingGeofence = false;

  static const _geofenceCenter = LatLng(31.5204, 74.3587);
  static const _geofenceRadius = 300.0;

  @override
  void initState() {
    super.initState();
    DummyDataService.vitalStream.listen((v) {
      if (mounted) {
        setState(() => _childPos = LatLng(v.latitude, v.longitude));
        _mapController.move(_childPos, _mapController.camera.zoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final child   = DummyDataService.dummyChild;
    final cardBg  = AegisColors.card(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _childPos,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aegis.aegis',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _geofenceCenter,
                    radius: _geofenceRadius,
                    useRadiusInMeter: true,
                    color: aegisMint.withOpacity(0.2),
                    borderColor: aegisMint,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _childPos,
                    width: 50,
                    height: 50,
                    child: _ChildMarker(initials: child.initials),
                  ),
                ],
              ),
            ],
          ),

          // ── Recenter button ───────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _FloatingIconButton(
              icon: LucideIcons.locate,
              cardBg: cardBg,
              onTap: () => _mapController.move(_childPos, 16),
            ),
          ),

          // ── Geofence edit button ──────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _FloatingIconButton(
              icon: LucideIcons.circleDashed,
              cardBg: cardBg,
              onTap: () =>
                  setState(() => _editingGeofence = !_editingGeofence),
              active: _editingGeofence,
            ),
          ),

          // ── Bottom info card ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_editingGeofence)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: aegisPink.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Drag to resize geofence',
                              style: AppTextStyles.caption),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _editingGeofence = false),
                            child: Text(
                              'Save',
                              style: AppTextStyles.label
                                  .copyWith(color: aegisPinkDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(child.name, style: AppTextStyles.h3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: aegisMintLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.mapPin,
                                    size: 12, color: statusSafe),
                                const SizedBox(width: 4),
                                Text('In zone',
                                    style: AppTextStyles.caption.copyWith(
                                        color: statusSafe,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_childPos.latitude.toStringAsFixed(5)}, '
                        '${_childPos.longitude.toStringAsFixed(5)}',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock,
                              size: 12, color: aegisTextSoft),
                          const SizedBox(width: 4),
                          Text('Updated just now',
                              style: AppTextStyles.caption),
                          const SizedBox(width: 16),
                          const Icon(LucideIcons.home,
                              size: 12, color: aegisTextSoft),
                          const SizedBox(width: 4),
                          Text('42m from home',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildMarker extends StatefulWidget {
  final String initials;
  const _ChildMarker({required this.initials});

  @override
  State<_ChildMarker> createState() => _ChildMarkerState();
}

class _ChildMarkerState extends State<_ChildMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: aegisPink,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: aegisPink.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color cardBg;
  final bool active;

  const _FloatingIconButton({
    required this.icon,
    required this.onTap,
    required this.cardBg,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? aegisPink : cardBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: aegisPink.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : AegisColors.text(context),
        ),
      ),
    );
  }
}
