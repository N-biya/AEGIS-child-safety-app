// firmware/src/wifi_firebase.cpp
#include "wifi_firebase.h"
#include "offline_queue.h"
#include "secrets.h"

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include <ArduinoJson.h>

static constexpr uint32_t WIFI_TIMEOUT_MS = 20000;

static FirebaseData   s_fbdo;
static FirebaseAuth   s_fbAuth;
static FirebaseConfig s_fbConfig;
static WiFiStatus     s_status = WiFiStatus::DISCONNECTED;
static bool           s_fbReady = false;

// ── LiPo discharge curve lookup ───────────────────────────────────────────────
// Voltage (V) to percentage pairs.  BATTERY_PIN is behind a 1:2 divider.
static constexpr float LIPO_V[]   = { 4.20f, 4.05f, 3.90f, 3.75f, 3.60f, 3.40f, 3.00f };
static constexpr float LIPO_PCT[] = { 100.0f, 87.0f, 75.0f, 50.0f, 25.0f, 10.0f,  0.0f };
static constexpr int   LIPO_POINTS = 7;

float getBatteryPercent()
{
    int raw = analogRead(BATTERY_PIN);
    float vADC = (static_cast<float>(raw) / 4095.0f) * 3.3f;
    float vBat = vADC * 2.0f;   // un-divide the 1:2 divider

    if (vBat >= LIPO_V[0])                     return LIPO_PCT[0];
    if (vBat <= LIPO_V[LIPO_POINTS - 1])       return LIPO_PCT[LIPO_POINTS - 1];
    for (int i = 0; i < LIPO_POINTS - 1; i++) {
        if (vBat <= LIPO_V[i] && vBat > LIPO_V[i + 1]) {
            float t = (vBat - LIPO_V[i + 1]) / (LIPO_V[i] - LIPO_V[i + 1]);
            return LIPO_PCT[i + 1] + t * (LIPO_PCT[i] - LIPO_PCT[i + 1]);
        }
    }
    return 0.0f;
}

// ── Firebase Firestore JSON builder ───────────────────────────────────────────
// Converts a flat ArduinoJson doc into Firestore REST field format.
static String toFirestoreJson(const JsonDocument& src)
{
    JsonDocument fs;
    JsonObject fields = fs["fields"].to<JsonObject>();
    for (JsonPair kv : src.as<JsonObject>()) {
        const char* key = kv.key().c_str();
        JsonVariant v   = kv.value();
        if (v.is<bool>())        fields[key]["booleanValue"]  = v.as<bool>();
        else if (v.is<int>())    fields[key]["integerValue"]  = v.as<int>();
        else if (v.is<float>())  fields[key]["doubleValue"]   = v.as<float>();
        else                     fields[key]["stringValue"]   = v.as<String>();
    }
    String out;
    serializeJson(fs, out);
    return out;
}

// ── WiFi / Firebase init ──────────────────────────────────────────────────────

bool initWiFi()
{
    s_status = WiFiStatus::CONNECTING;
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    uint32_t start = millis();
    while (WiFi.status() != WL_CONNECTED && (millis() - start) < WIFI_TIMEOUT_MS) {
        delay(200);
    }

    if (WiFi.status() != WL_CONNECTED) {
        s_status = WiFiStatus::FAILED;
        return false;
    }
    s_status = WiFiStatus::CONNECTED;

    // Firebase
    s_fbConfig.api_key                    = FIREBASE_API_KEY;
    s_fbConfig.project_id                 = FIREBASE_PROJECT_ID;
    s_fbConfig.token_status_callback      = tokenStatusCallback;
    s_fbAuth.user.email                   = FIREBASE_USER_EMAIL;
    s_fbAuth.user.password                = FIREBASE_USER_PASSWORD;

    s_fbdo.setResponseSize(4096);
    Firebase.begin(&s_fbConfig, &s_fbAuth);
    Firebase.reconnectWiFi(true);

    // Enforce SSL cert verification via WiFiClientSecure (Firebase lib handles internally)
    s_fbReady = true;
    return true;
}

WiFiStatus getWiFiStatus()
{
    if (WiFi.status() == WL_CONNECTED) s_status = WiFiStatus::CONNECTED;
    else if (s_status == WiFiStatus::CONNECTED) s_status = WiFiStatus::DISCONNECTED;
    return s_status;
}

// ── Sync helpers ──────────────────────────────────────────────────────────────

static bool firestoreCreate(const String& docPath, const String& fsJson)
{
    if (!s_fbReady || WiFi.status() != WL_CONNECTED) return false;
    return Firebase.Firestore.createDocument(
        &s_fbdo, FIREBASE_PROJECT_ID, "",
        docPath.c_str(), fsJson.c_str());
}

// ── Public sync API ───────────────────────────────────────────────────────────

void syncVitals(const SensorReading& r, const StressResult& result,
                const GPSReading& gps, float battPct)
{
    JsonDocument doc;
    doc["hr"]         = r.hr;
    doc["spo2"]       = r.spo2;
    doc["gsr"]        = r.gsr;
    doc["temp"]       = r.temp;
    doc["acc_mag"]    = r.acc_mag;
    doc["stress"]     = static_cast<int>(result.state);
    doc["confidence"] = result.confidence;
    doc["battery"]    = battPct;
    doc["gps_fixed"]  = gps.fixed;
    // GPS coordinates are transmitted over HTTPS only; never in Serial.
    if (gps.fixed) {
        doc["lat"] = gps.lat;
        doc["lng"] = gps.lng;
    }
    doc["ts"] = r.timestamp;

    String plain;
    serializeJson(doc, plain);

    if (getWiFiStatus() != WiFiStatus::CONNECTED) {
        enqueueReading(plain, "vitals");
        return;
    }

    String docPath = String("users/") + USER_ID
                   + "/children/" + CHILD_ID
                   + "/vitals/" + String(r.timestamp);
    String fsJson = toFirestoreJson(doc);
    if (!firestoreCreate(docPath, fsJson)) {
        enqueueReading(plain, "vitals");
    }
}

void syncAlert(const char* alertType, const GPSReading& gps, int severity)
{
    JsonDocument doc;
    doc["alert_type"] = alertType;
    doc["severity"]   = severity;
    doc["gps_fixed"]  = gps.fixed;
    if (gps.fixed) {
        doc["lat"] = gps.lat;
        doc["lng"] = gps.lng;
    }
    doc["ts"] = millis();

    String plain;
    serializeJson(doc, plain);

    if (getWiFiStatus() != WiFiStatus::CONNECTED) {
        enqueueReading(plain, "alert");
        return;
    }

    String alertId = String("alert_") + String(millis());
    String docPath = String("users/") + USER_ID
                   + "/children/" + CHILD_ID
                   + "/alerts/" + alertId;
    String fsJson = toFirestoreJson(doc);
    if (!firestoreCreate(docPath, fsJson)) {
        enqueueReading(plain, "alert");
    }
}

bool syncOfflineEntry(const String& plainJson, const char* entryType)
{
    if (getWiFiStatus() != WiFiStatus::CONNECTED) return false;

    JsonDocument doc;
    if (deserializeJson(doc, plainJson) != DeserializationError::Ok) return false;

    String collection = (strcmp(entryType, "alert") == 0) ? "alerts" : "vitals";
    uint32_t ts = doc["ts"] | static_cast<uint32_t>(millis());
    String docPath = String("users/") + USER_ID
                   + "/children/" + CHILD_ID
                   + "/" + collection + "/" + String(ts);
    String fsJson = toFirestoreJson(doc);
    return firestoreCreate(docPath, fsJson);
}
