#include "geofence_logic.h"

#include <cmath>
#include <optional>

namespace aegis {

namespace {

constexpr double kEarthRadiusMeters = 6371000.0;
constexpr double kPi = 3.14159265358979323846;

double toRadians(double deg) { return deg * kPi / 180.0; }

// Minimal parser for the flat numeric JSON object we expect for the
// geofence doc, e.g. {"lat":31.52,"lng":74.36,"radiusMeters":300}.
// Deliberately not a general-purpose JSON parser — the real firmware
// extracts this flat shape from the Firestore document before handing it
// here, so we only ever need to read a handful of known numeric keys.
std::optional<double> extractNumberField(const std::string& json, const std::string& key) {
    const std::string needle = "\"" + key + "\"";
    auto pos = json.find(needle);
    if (pos == std::string::npos) return std::nullopt;

    pos = json.find(':', pos + needle.size());
    if (pos == std::string::npos) return std::nullopt;
    pos++;

    // Skip whitespace.
    while (pos < json.size() && std::isspace(static_cast<unsigned char>(json[pos]))) pos++;

    size_t start = pos;
    while (pos < json.size() &&
           (std::isdigit(static_cast<unsigned char>(json[pos])) || json[pos] == '-' ||
            json[pos] == '+' || json[pos] == '.' || json[pos] == 'e' || json[pos] == 'E')) {
        pos++;
    }
    if (pos == start) return std::nullopt;

    try {
        return std::stod(json.substr(start, pos - start));
    } catch (...) {
        return std::nullopt;
    }
}

} // namespace

double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const double dLat = toRadians(lat2 - lat1);
    const double dLng = toRadians(lng2 - lng1);
    const double a = std::sin(dLat / 2) * std::sin(dLat / 2) +
                      std::cos(toRadians(lat1)) * std::cos(toRadians(lat2)) *
                          std::sin(dLng / 2) * std::sin(dLng / 2);
    const double c = 2 * std::atan2(std::sqrt(a), std::sqrt(1 - a));
    return kEarthRadiusMeters * c;
}

bool isOutsideGeofence(const Geofence& zone, const GpsFix& fix) {
    if (!zone.valid || !fix.valid) return false;
    return haversineMeters(zone.lat, zone.lng, fix.lat, fix.lng) > zone.radiusMeters;
}

Geofence parseGeofenceJson(const std::string& json) {
    Geofence g;
    auto lat = extractNumberField(json, "lat");
    auto lng = extractNumberField(json, "lng");
    auto radius = extractNumberField(json, "radiusMeters");
    if (!lat || !lng || !radius) return g; // valid stays false

    g.lat = *lat;
    g.lng = *lng;
    g.radiusMeters = *radius;
    g.valid = true;
    return g;
}

GeofenceMonitor::GeofenceMonitor(IGpsProvider& gps, IVitalsProvider& vitals, ISmsSender& sms,
                                  IGeofenceFetcher& geofenceFetcher,
                                  IAlertPublisher& alertPublisher,
                                  std::string childId, std::string parentPhone)
    : gps_(gps),
      vitals_(vitals),
      sms_(sms),
      geofenceFetcher_(geofenceFetcher),
      alertPublisher_(alertPublisher),
      childId_(std::move(childId)),
      parentPhone_(std::move(parentPhone)) {}

void GeofenceMonitor::refreshGeofence() {
    const std::string json = geofenceFetcher_.fetchGeofenceJson(childId_);
    if (json.empty()) return; // no WiFi or no doc yet — keep last known geofence
    Geofence fresh = parseGeofenceJson(json);
    if (fresh.valid) cached_ = fresh;
}

bool GeofenceMonitor::checkAndAlertIfBreached(const std::string& timestampIso) {
    const GpsFix fix = gps_.read();
    const bool outside = isOutsideGeofence(cached_, fix);

    // Edge-trigger: alert only on the transition into "outside", not on
    // every tick while the child remains outside (matches the brief's
    // "Geofence breach" row — one alert per breach, not a spam loop).
    const bool shouldAlert = outside && !wasOutside_;
    wasOutside_ = outside;

    if (!shouldAlert) return false;

    raiseAlert(sms_, alertPublisher_, childId_, parentPhone_, "GEOFENCE",
               "LOCATION BREACH", vitals_.read(), fix, timestampIso);
    return true;
}

} // namespace aegis
