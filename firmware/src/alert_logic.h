// Hardware-independent alert formatting + dispatch logic, shared by every
// alert source on the ESP32 (geofence breach today; stress/SpO2 detection
// once that pipeline exists). Kept separate from geofence_logic.h because
// alerts are not geofence-specific — the Alerts tab in the app
// (app/lib/screens/alerts_screen.dart) renders STRESS, GEOFENCE, SPO2 and
// ELEVATED alerts through the exact same AlertModel shape.
//
// IMPORTANT: the JSON shape produced here must match what
// AlertModel.fromMap (app/lib/models/alert_model.dart) parses:
//   { type, timestamp, vitals: {hr, spo2}, location: {lat, lng}, resolved }
// Missing any of those fields will make the Alerts screen throw when it
// reads the document back.
#pragma once

#include <string>

namespace aegis {

struct GpsFix {
    double lat = 0.0;
    double lng = 0.0;
    bool valid = false; // false if no GPS lock yet
};

// Mirrors the vitals doc shape (app/lib/models/vital_model.dart) and what
// the Alerts screen needs out of it (hr, spo2 — gsr/temp are carried along
// for parity with the vitals collection but aren't read by AlertModel today).
struct VitalsSnapshot {
    int hr = 0;
    int spo2 = 0;
    double gsr = 0.0;
    double temp = 0.0;
    bool valid = false; // false if no sensor reading is available yet
};

// Backed by SIM800L AT-command UART driver in real firmware; a mock that
// just records calls in tests/simulation.
class ISmsSender {
public:
    virtual ~ISmsSender() = default;
    virtual void send(const std::string& toPhoneNumber, const std::string& body) = 0;
};

// Backed by Firestore REST/Firebase-ESP32 client in real firmware; writes to
// children/{childId}/alerts/{alertId}. Best-effort — if WiFi is down the
// implementation should just no-op (SMS already covers the offline case,
// per the brief).
class IAlertPublisher {
public:
    virtual ~IAlertPublisher() = default;
    virtual void publish(const std::string& childId, const std::string& alertJson) = 0;
};

// Builds the SMS body sent over the SIM800L. Format fixed by the project
// brief (AEGIS_PROJECT_BRIEF.md):
//   [AEGIS Alert]
//   Status: STRESS / LOCATION BREACH / LOW SPO2
//   Location: lat, lng
//   Time: timestamp
std::string formatAlertSms(const std::string& statusLabel, const GpsFix& fix,
                            const std::string& timestampIso);

// Builds the JSON body pushed to children/{childId}/alerts/{alertId}.
// `type` must be one of the values AlertModel.typeLabel switches on:
// "STRESS", "GEOFENCE", "SPO2", "ELEVATED". New alerts are unresolved by
// default — a parent/app action resolves them later.
std::string formatAlertFirestorePayload(const std::string& type,
                                         const VitalsSnapshot& vitals,
                                         const GpsFix& fix,
                                         const std::string& timestampIso,
                                         bool resolved = false);

// Sends the SMS and publishes the matching Firestore alert doc in one call.
// Every alert source (geofence breach, future stress/SpO2 detection) should
// raise alerts through this single function so the two channels can never
// drift out of sync with each other.
void raiseAlert(ISmsSender& sms, IAlertPublisher& alertPublisher,
                 const std::string& childId, const std::string& parentPhone,
                 const std::string& type, const std::string& smsStatusLabel,
                 const VitalsSnapshot& vitals, const GpsFix& fix,
                 const std::string& timestampIso);

} // namespace aegis
