import 'package:latlong2/latlong.dart';

/// Pure geofence math shared by the map UI and the breach-detection logic.
/// Kept free of Flutter/Firebase imports so it is unit-testable off-device.

/// Great-circle distance in metres between two coordinates.
double metersBetween(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b);

/// True when [child] is within (or exactly on) the safe-zone boundary.
bool isInsideZone(LatLng child, LatLng center, double radiusMeters) =>
    metersBetween(child, center) <= radiusMeters;

/// True when [child] has breached the safe zone (is strictly outside it).
bool isGeofenceBreached(LatLng child, LatLng center, double radiusMeters) =>
    !isInsideZone(child, center, radiusMeters);
