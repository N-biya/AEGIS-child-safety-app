// firmware/src/gps_manager.cpp
#include "gps_manager.h"
#include "crypto_utils.h"
#include "secrets.h"

#include <HardwareSerial.h>
#include <TinyGPSPlus.h>
#include <ArduinoJson.h>
#include <math.h>

static constexpr const char* GEOFENCE_PATH     = "/data/geofence.json";
static constexpr uint32_t    FIX_TIMEOUT_MS    = 5UL * 60UL * 1000UL; // 5 min
static constexpr uint32_t    POLL_WATCHDOG_MS  = 5000;

static HardwareSerial  s_gpsSerial(2);
static TinyGPSPlus     s_gps;
static GPSReading      s_lastFix     = {};
static Geofence        s_geofence    = {};
static uint32_t        s_lastFixTime = 0;

// ── Init ──────────────────────────────────────────────────────────────────────

void initGPS()
{
    s_gpsSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
    s_lastFix = {};
    loadGeofence();
}

// ── Poll ──────────────────────────────────────────────────────────────────────

GPSReading readGPS()
{
    uint32_t start = millis();
    while (s_gpsSerial.available() && (millis() - start) < POLL_WATCHDOG_MS) {
        if (s_gps.encode(s_gpsSerial.read())) {
            if (s_gps.location.isValid() && s_gps.location.isUpdated()) {
                s_lastFix.lat        = static_cast<float>(s_gps.location.lat());
                s_lastFix.lng        = static_cast<float>(s_gps.location.lng());
                s_lastFix.fixed      = true;
                s_lastFix.timestamp  = millis();
                // HDOP → rough accuracy estimate
                s_lastFix.accuracy_m = s_gps.hdop.isValid()
                                       ? s_gps.hdop.hdop() * 5.0f
                                       : 99.0f;
                s_lastFixTime        = millis();

#if DEBUG_MODE
                Serial.printf("[GPS] Lat=%.6f Lng=%.6f HDOP=%.1f\n",
                              s_lastFix.lat, s_lastFix.lng, s_gps.hdop.hdop());
#endif
            }
        }
    }
    return s_lastFix;
}

// ── Geofence ─────────────────────────────────────────────────────────────────

static constexpr float DEG2RAD = 3.14159265358979f / 180.0f;
static constexpr float EARTH_R = 6371000.0f;

float haversineDistance(float lat1, float lng1, float lat2, float lng2)
{
    float dlat = (lat2 - lat1) * DEG2RAD;
    float dlng = (lng2 - lng1) * DEG2RAD;
    float a = sinf(dlat / 2.0f) * sinf(dlat / 2.0f)
            + cosf(lat1 * DEG2RAD) * cosf(lat2 * DEG2RAD)
            * sinf(dlng / 2.0f) * sinf(dlng / 2.0f);
    float c = 2.0f * atan2f(sqrtf(a), sqrtf(1.0f - a));
    return EARTH_R * c;
}

bool isInsideGeofence(const GPSReading& reading)
{
    if (!s_geofence.valid) return true;   // no fence configured → treat as inside
    if (!reading.fixed)    return true;   // no fix → assume inside (safe default)
    float dist = haversineDistance(
        reading.lat, reading.lng,
        s_geofence.center_lat, s_geofence.center_lng);
    return dist <= s_geofence.radius_m;
}

bool saveGeofence(float centerLat, float centerLng, float radiusM)
{
    JsonDocument doc;
    doc["center_lat"] = centerLat;
    doc["center_lng"] = centerLng;
    doc["radius_m"]   = radiusM;
    // GPS coordinates in file are encrypted — privacy by design.
    String json;
    serializeJson(doc, json);

    if (!encryptToSPIFFS(GEOFENCE_PATH, json)) return false;

    s_geofence.center_lat = centerLat;
    s_geofence.center_lng = centerLng;
    s_geofence.radius_m   = radiusM;
    s_geofence.valid      = true;
    return true;
}

bool loadGeofence()
{
    String json = decryptFromSPIFFS(GEOFENCE_PATH);
    if (json.isEmpty()) return false;

    JsonDocument doc;
    if (deserializeJson(doc, json) != DeserializationError::Ok) return false;

    s_geofence.center_lat = doc["center_lat"] | 0.0f;
    s_geofence.center_lng = doc["center_lng"] | 0.0f;
    s_geofence.radius_m   = doc["radius_m"]   | 0.0f;
    s_geofence.valid      = (s_geofence.radius_m > 0.0f);
    return s_geofence.valid;
}

bool gpsHealthCheck()
{
    if (!s_lastFix.fixed)       return false;
    return (millis() - s_lastFixTime) < FIX_TIMEOUT_MS;
}

const Geofence& getGeofence()
{
    return s_geofence;
}
