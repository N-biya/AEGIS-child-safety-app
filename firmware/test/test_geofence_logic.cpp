// Hardware-free simulation/test for geofence_logic + alert_logic. No ESP32,
// no real GPS/sensors, no real GSM module needed — run with:
//   g++ -std=c++17 -I../src test_geofence_logic.cpp ../src/geofence_logic.cpp ../src/alert_logic.cpp -o test_geofence
//   ./test_geofence
#include "../src/geofence_logic.h"

#include <cassert>
#include <iostream>
#include <vector>

using namespace aegis;

namespace {

// ── Mocks ───────────────────────────────────────────────────────────────────

class ScriptedGpsProvider : public IGpsProvider {
public:
    explicit ScriptedGpsProvider(std::vector<GpsFix> fixes) : fixes_(std::move(fixes)) {}
    GpsFix read() override {
        if (index_ >= fixes_.size()) return fixes_.back();
        return fixes_[index_++];
    }

private:
    std::vector<GpsFix> fixes_;
    size_t index_ = 0;
};

class FixedVitalsProvider : public IVitalsProvider {
public:
    explicit FixedVitalsProvider(VitalsSnapshot v) : v_(v) {}
    VitalsSnapshot read() override { return v_; }

private:
    VitalsSnapshot v_;
};

class RecordingSmsSender : public ISmsSender {
public:
    void send(const std::string& toPhoneNumber, const std::string& body) override {
        sent.push_back({toPhoneNumber, body});
    }
    std::vector<std::pair<std::string, std::string>> sent;
};

class FixedGeofenceFetcher : public IGeofenceFetcher {
public:
    explicit FixedGeofenceFetcher(std::string json) : json_(std::move(json)) {}
    std::string fetchGeofenceJson(const std::string&) override { return json_; }

private:
    std::string json_;
};

class RecordingAlertPublisher : public IAlertPublisher {
public:
    void publish(const std::string& childId, const std::string& alertJson) override {
        published.push_back({childId, alertJson});
    }
    std::vector<std::pair<std::string, std::string>> published;
};

void expect(bool cond, const std::string& msg) {
    if (!cond) {
        std::cerr << "FAILED: " << msg << "\n";
        std::exit(1);
    }
    std::cout << "ok: " << msg << "\n";
}

bool contains(const std::string& haystack, const std::string& needle) {
    return haystack.find(needle) != std::string::npos;
}

} // namespace

int main() {
    // Lahore, ~0m and ~500m away, used as readable round-trip test points.
    constexpr double kHomeLat = 31.5204, kHomeLng = 74.3587;

    // ── Haversine sanity ────────────────────────────────────────────────────
    {
        const double d = haversineMeters(kHomeLat, kHomeLng, kHomeLat, kHomeLng);
        expect(d < 0.001, "distance from a point to itself is ~0");
    }
    {
        // ~0.0045 deg lat ~= 500m
        const double d = haversineMeters(kHomeLat, kHomeLng, kHomeLat + 0.0045, kHomeLng);
        expect(d > 400 && d < 600, "0.0045 deg lat is roughly 500m");
    }

    // ── JSON parsing ────────────────────────────────────────────────────────
    {
        const Geofence g = parseGeofenceJson(
            R"({"lat":31.5204,"lng":74.3587,"radiusMeters":300})");
        expect(g.valid, "well-formed geofence JSON parses as valid");
        expect(g.lat == 31.5204 && g.lng == 74.3587 && g.radiusMeters == 300,
               "parsed fields match input");
    }
    {
        const Geofence g = parseGeofenceJson("");
        expect(!g.valid, "empty JSON (no geofence set yet) parses as invalid");
    }

    // ── Breach detection ────────────────────────────────────────────────────
    {
        Geofence zone{kHomeLat, kHomeLng, 300, true};
        const GpsFix inside{kHomeLat, kHomeLng, true};
        const GpsFix outside{kHomeLat + 0.01, kHomeLng, true}; // ~1.1km away
        const GpsFix noLock{0, 0, false};

        expect(!isOutsideGeofence(zone, inside), "point inside radius is not a breach");
        expect(isOutsideGeofence(zone, outside), "point well outside radius is a breach");
        expect(!isOutsideGeofence(zone, noLock), "no GPS lock never triggers a breach");

        Geofence noZone; // valid == false, parent hasn't set one yet
        expect(!isOutsideGeofence(noZone, outside), "no geofence set never triggers a breach");
    }

    // ── Alert payload shape must match AlertModel.fromMap exactly ──────────
    // (app/lib/models/alert_model.dart reads type, timestamp, vitals.hr,
    // vitals.spo2, location.lat, location.lng, resolved.)
    {
        const VitalsSnapshot v{82, 97, 4.1, 36.6, true};
        const GpsFix fix{kHomeLat, kHomeLng, true};
        const std::string payload =
            formatAlertFirestorePayload("GEOFENCE", v, fix, "2026-06-28T10:00:10Z");

        expect(contains(payload, "\"type\":\"GEOFENCE\""), "payload has type field");
        expect(contains(payload, "\"timestamp\":\"2026-06-28T10:00:10Z\""),
               "payload has timestamp field");
        expect(contains(payload, "\"vitals\":{\"hr\":82,\"spo2\":97"),
               "payload has vitals.hr and vitals.spo2 (required by AlertModel.fromMap)");
        expect(contains(payload, "\"location\":{\"lat\":31.520400,\"lng\":74.358700}"),
               "payload has location.lat/lng (required by AlertModel.fromMap)");
        expect(contains(payload, "\"resolved\":false"),
               "payload has resolved field (required by AlertModel.fromMap), defaults false");
    }

    // ── End-to-end monitor: stays inside, then breaches, then leaves a
    //    breach (should only fire once, on the transition) ───────────────────
    {
        ScriptedGpsProvider gps({
            {kHomeLat, kHomeLng, true},          // tick 1: inside
            {kHomeLat + 0.01, kHomeLng, true},   // tick 2: breach (~1.1km out)
            {kHomeLat + 0.011, kHomeLng, true},  // tick 3: still outside — no new alert
            {kHomeLat, kHomeLng, true},          // tick 4: back inside
        });
        FixedVitalsProvider vitals(VitalsSnapshot{88, 96, 3.8, 36.9, true});
        RecordingSmsSender sms;
        FixedGeofenceFetcher fetcher(
            R"({"lat":31.5204,"lng":74.3587,"radiusMeters":300})");
        RecordingAlertPublisher publisher;

        GeofenceMonitor monitor(gps, vitals, sms, fetcher, publisher, "child123",
                                 "+923001234567");
        monitor.refreshGeofence();
        expect(monitor.currentGeofence().valid, "monitor picked up geofence from fetcher");

        expect(!monitor.checkAndAlertIfBreached("2026-06-28T10:00:00Z"), "tick 1: no breach");
        expect(monitor.checkAndAlertIfBreached("2026-06-28T10:00:10Z"), "tick 2: breach fires");
        expect(!monitor.checkAndAlertIfBreached("2026-06-28T10:00:20Z"),
               "tick 3: still outside, but already alerted — no repeat");
        expect(!monitor.checkAndAlertIfBreached("2026-06-28T10:00:30Z"), "tick 4: back inside");

        expect(sms.sent.size() == 1, "exactly one SMS sent across the whole sequence");
        expect(sms.sent[0].first == "+923001234567", "SMS went to the parent's number");
        expect(publisher.published.size() == 1, "exactly one Firestore alert published");
        expect(publisher.published[0].first == "child123", "alert published under the right childId");
        expect(contains(publisher.published[0].second, "\"hr\":88"),
               "breach alert carries the real vitals snapshot, not zeros");

        std::cout << "\nSample SMS body:\n" << sms.sent[0].second << "\n";
        std::cout << "\nSample Firestore alert payload:\n" << publisher.published[0].second << "\n";
    }

    std::cout << "\nAll geofence_logic + alert_logic tests passed.\n";
    return 0;
}
