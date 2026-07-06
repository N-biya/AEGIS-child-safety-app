import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/child_model.dart';
import '../screens/map_screen.dart';
import '../utils/aegis_text.dart';
import '../utils/app_colors.dart';
import '../utils/app_globals.dart';
import '../utils/location_parser.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

/// Handles locations shared *into* AEGIS from another app's share sheet
/// (typically Google Maps → Share → AEGIS). The shared text is parsed into a
/// coordinate via [LocationParser]; the parent then chooses what to do with it:
/// set the safe zone, add a restricted (no-go) area, or just view it on the map.
class ShareIntakeService {
  ShareIntakeService._();
  static final ShareIntakeService instance = ShareIntakeService._();

  final _firestore = FirestoreService();
  StreamSubscription<List<SharedMediaFile>>? _sub;
  bool _initialized = false;
  bool _busy = false;

  void init() {
    if (_initialized) return;
    // The plugin only supports mobile; no-op elsewhere.
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    _initialized = true;
    try {
      // Shares that arrive while the app is already running.
      _sub = ReceiveSharingIntent.instance
          .getMediaStream()
          .listen(_handle, onError: (_) {});
      // A share that cold-started the app.
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _handle(files);
        ReceiveSharingIntent.instance.reset();
      });
    } catch (_) {/* plugin unavailable — ignore */}
  }

  void dispose() => _sub?.cancel();

  Future<void> _handle(List<SharedMediaFile> files) async {
    if (files.isEmpty || _busy) return;
    _busy = true;
    try {
      for (final f in files) {
        final text = f.path.trim();
        if (text.isEmpty) continue;
        final loc = await LocationParser.parse(text);
        if (loc != null) {
          await _present(loc);
          return;
        }
      }
      _toast("Couldn't read a location from that share.");
    } finally {
      _busy = false;
    }
  }

  Future<void> _present(LatLng loc) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final choice = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareLocationSheet(loc: loc),
    );
    if (choice == null) return;
    switch (choice) {
      case 'safe':
        await _setSafeZone(loc);
        break;
      case 'restricted':
        await _addRestricted(loc);
        break;
      case 'map':
        _showOnMap(loc);
        break;
    }
  }

  Future<ChildModel?> _loadChild() async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return null;
    final uid = ctx.read<AuthService>().userId;
    if (uid.isEmpty) return null;
    try {
      return await _firestore.watchChildForUser(uid).first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _setSafeZone(LatLng loc) async {
    final child = await _loadChild();
    if (child == null) {
      _toast('Log in and add a child first.');
      return;
    }
    await _firestore.updateGeofence(
      child.id,
      GeofenceModel(
        lat: loc.latitude,
        lng: loc.longitude,
        radiusMeters: child.geofence?.radiusMeters ?? 300,
      ),
    );
    _toast('Safe zone set here. Adjust the radius in Settings.');
  }

  Future<void> _addRestricted(LatLng loc) async {
    final child = await _loadChild();
    if (child == null) {
      _toast('Log in and add a child first.');
      return;
    }
    final zones = [
      ...child.forbiddenZones,
      ForbiddenZoneModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'Restricted area',
        lat: loc.latitude,
        lng: loc.longitude,
        radiusMeters: 80,
      ),
    ];
    await _firestore.updateForbiddenZones(child.id, zones);
    _toast('Restricted area added. Rename or resize it in Settings.');
  }

  void _showOnMap(LatLng loc) {
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => MapScreen(focusLocation: loc)),
    );
  }

  void _toast(String msg) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    messenger?.showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ── Chooser sheet ───────────────────────────────────────────────────────────
class _ShareLocationSheet extends StatelessWidget {
  final LatLng loc;
  const _ShareLocationSheet({required this.loc});

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: isDark ? kDarkBg : Colors.white,
        border: Border.all(
            color: isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isDark ? const Color(0x26FFFFFF) : const Color(0x267C3AED),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Shared location',
              style: AegisText.h5(color: T)
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
              style: AegisText.caption(color: D).copyWith(fontSize: 12)),
          const SizedBox(height: 18),
          _option(
            context,
            icon: Icons.shield_outlined,
            color: kSafe,
            title: 'Set as safe zone',
            subtitle: 'Alert if your child leaves this area',
            value: 'safe',
          ),
          const SizedBox(height: 10),
          _option(
            context,
            icon: Icons.block,
            color: kAlert,
            title: 'Add as restricted area',
            subtitle: 'Alert if your child goes here',
            value: 'restricted',
          ),
          const SizedBox(height: 10),
          _option(
            context,
            icon: Icons.map_outlined,
            color: kAccent,
            title: 'Show on map',
            subtitle: 'Just view this spot in AEGIS',
            value: 'map',
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11), color: color),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AegisText.body(color: T)
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: AegisText.caption(color: D).copyWith(fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: D),
          ],
        ),
      ),
    );
  }
}
