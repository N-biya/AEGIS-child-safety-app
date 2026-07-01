// Hardware-independent geofence sync + breach-detection logic.
//
// No Arduino/ESP32 headers here on purpose — this file compiles with any
// standard C++17 compiler so the logic can be written and tested before
// the board/GPS/GSM hardware is wired up. When the firmware project is
// ready, IGpsProvider/IVitalsProvider/ISmsSender get real implementations
// backed by the NEO-6M/sensors/SIM800L respectively; nothing in this file
// changes.
#pragma once

#include <string>

#include "alert_logic.h"

namespace aegis {

// Mirrors the app's GeofenceModel (app/lib/models/child_model.dart) and the
// Firestore field `children/{childId}.geofence`.
struct Geofence {
    double lat = 0.0;
    double lng = 0.0;
    double radiusMeters = 0.0;
    bool valid = false; // false until a geofence has been fetched at least once
};

// Distance in meters between two lat/lng points (Haversine formula).
double haversineMeters(double lat1, double lng1, double lat2, double lng2);

// True if `fix` lies outside `zone`. Always false if either input is invalid
// (no GPS lock yet, or no geofence has been set by the parent yet) — we
// never alert on incomplete data.
bool isOutsideGeofence(const Geofence& zone, const GpsFix& fix);

// Parses the flat geofence JSON the ESP32 reads back from Firestore, e.g.
//   {"lat":31.5204,"lng":74.3587,"radiusMeters":300}
// Returns Geofence.valid == false if the document is missing/malformed
// (e.g. parent hasn't set a geofence yet).
Geofence parseGeofenceJson(const std::string& json);

// ── Hardware interfaces (to be implemented once the board is ready) ───────

// Backed by NEO-6M UART parsing in real firmware; a deterministic mock in
// tests/simulation.
class IGpsProvider {
public:
    virtual ~IGpsProvider() = default;
    virtual GpsFix read() = 0;
};

// Backed by the live sensor pipeline (MAX30102 etc.) in real firmware; a
// deterministic mock in tests/simulation. Lets a geofence breach alert
// carry the child's actual vitals at that moment instead of zeros.
class IVitalsProvider {
public:
    virtual ~IVitalsProvider() = default;
    virtual VitalsSnapshot read() = 0;
};

// Backed by Firestore REST/Firebase-ESP32 client in real firmware; a mock
// that returns canned JSON in tests/simulation.
class IGeofenceFetcher {
public:
    virtual ~IGeofenceFetcher() = default;
    // Returns the raw geofence JSON for a given child, or "" if unavailable
    // (no WiFi, no document yet).
    virtual std::string fetchGeofenceJson(const std::string& childId) = 0;
};

// Ties the pieces together. This is what runs on every monitoring tick
// (brief: every 10s) once GPS + a cached geofence are available. Alerts
// are raised through alert_logic's raiseAlert(), the same path any future
// stress/SpO2 detector will use — so the Alerts tab in the app sees a
// consistent document shape no matter which sensor triggered it.
class GeofenceMonitor {
public:
    GeofenceMonitor(IGpsProvider& gps, IVitalsProvider& vitals, ISmsSender& sms,
                     IGeofenceFetcher& geofenceFetcher, IAlertPublisher& alertPublisher,
                     std::string childId, std::string parentPhone);

    // Call when WiFi is up to refresh the cached geofence. Safe to call
    // every tick — it's a cheap no-op if Firestore is unreachable.
    void refreshGeofence();

    // Call every monitoring tick regardless of WiFi state. Returns true if
    // a breach was detected and an alert was raised.
    bool checkAndAlertIfBreached(const std::string& timestampIso);

    const Geofence& currentGeofence() const { return cached_; }

private:
    IGpsProvider& gps_;
    IVitalsProvider& vitals_;
    ISmsSender& sms_;
    IGeofenceFetcher& geofenceFetcher_;
    IAlertPublisher& alertPublisher_;
    std::string childId_;
    std::string parentPhone_;
    Geofence cached_;
    bool wasOutside_ = false; // edge-triggers the alert: only fires on exit, not every tick
};

} // namespace aegis
