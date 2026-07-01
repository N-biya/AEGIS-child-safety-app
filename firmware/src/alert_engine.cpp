// firmware/src/alert_engine.cpp
#include "alert_engine.h"
#include "calibration.h"
#include "gsm_sms.h"
#include "wifi_firebase.h"
#include "crypto_utils.h"
#include "secrets.h"

#include <SPIFFS.h>
#include <ArduinoJson.h>
#include <esp_task_wdt.h>

static constexpr const char* ALERT_LOG_PATH    = "/data/alert_log.json";
static constexpr int         ALERT_LOG_MAX      = 100;
static constexpr uint32_t    COOLDOWN_MS        = 5UL * 60UL * 1000UL;  // 5 min
static constexpr float       LOW_SPO2_THRESHOLD = 90.0f;
static constexpr float       LOW_BAT_THRESHOLD  = 15.0f;
static constexpr int         SPO2_CONSEC_NEEDED = 3;

static constexpr int ALERT_TYPE_COUNT = 5;
static uint32_t s_lastAlert[ALERT_TYPE_COUNT] = {};
static bool     s_anyAlertRecent = false;
static uint32_t s_anyAlertTime  = 0;

static int  s_lowSpo2Count  = 0;  // consecutive low-SpO2 reading counter
static bool s_engineReady   = false;

// ── Vibration ─────────────────────────────────────────────────────────────────

void triggerVibration()
{
    // 3 × (500 ms ON / 200 ms OFF) — 2100 ms total
    ledcSetup(0, 5000, 8);          // channel 0, 5 kHz, 8-bit resolution
    ledcAttachPin(VIBRATION_PIN, 0);
    for (int i = 0; i < 3; i++) {
        ledcWrite(0, 200);          // ~78 % duty cycle
        delay(500);
        ledcWrite(0, 0);
        if (i < 2) delay(200);
    }
    ledcDetachPin(VIBRATION_PIN);
}

// ── Alert log (encrypted circular NDJSON) ─────────────────────────────────────

static void appendAlertLog(const char* type, uint32_t ts)
{
    // Count existing entries; if at max, drop oldest.
    int lineCount = 0;
    if (SPIFFS.exists(ALERT_LOG_PATH)) {
        File f = SPIFFS.open(ALERT_LOG_PATH, FILE_READ);
        if (f) {
            while (f.available()) { if (f.read() == '\n') lineCount++; }
            f.close();
        }
    }

    // Rewrite without first line if full.
    if (lineCount >= ALERT_LOG_MAX) {
        static char lineBuf[256];
        static String kept;
        kept = "";
        File src = SPIFFS.open(ALERT_LOG_PATH, FILE_READ);
        bool first = true;
        while (src && src.available()) {
            int len = src.readBytesUntil('\n', lineBuf, sizeof(lineBuf) - 1);
            lineBuf[len] = '\0';
            if (first) { first = false; continue; }  // skip oldest
            kept += lineBuf; kept += '\n';
        }
        if (src) src.close();
        File out = SPIFFS.open(ALERT_LOG_PATH, FILE_WRITE);
        if (out) { out.print(kept); out.close(); }
    }

    JsonDocument doc;
    doc["type"] = type;
    doc["ts"]   = ts;
    String line;
    serializeJson(doc, line);

    File f = SPIFFS.open(ALERT_LOG_PATH, FILE_APPEND);
    if (f) { f.println(line); f.close(); }
}

// ── Cooldown helper ───────────────────────────────────────────────────────────

static bool cooldownOK(AlertType t)
{
    int idx = static_cast<int>(t);
    if (idx < 0 || idx >= ALERT_TYPE_COUNT) return false;
    uint32_t now = millis();
    if ((now - s_lastAlert[idx]) < COOLDOWN_MS) return false;
    s_lastAlert[idx] = now;
    return true;
}

// ── Public API ────────────────────────────────────────────────────────────────

void initAlertEngine()
{
    if (s_engineReady) return;
    pinMode(VIBRATION_PIN, OUTPUT);
    digitalWrite(VIBRATION_PIN, LOW);
    s_engineReady = true;
}

bool isAlertActive()
{
    if (!s_anyAlertRecent) return false;
    return (millis() - s_anyAlertTime) < 60000UL;
}

void evaluateAlerts(const SensorReading& reading,
                    const StressResult&  result,
                    const GPSReading&    gps,
                    float                battPct)
{
    if (!isCalibrated()) return;

    uint32_t now = millis();

    // ── STRESS ────────────────────────────────────────────────────────────────
    if (result.state == InferenceState::STRESS) {
        if (cooldownOK(AlertType::STRESS)) {
            triggerVibration();
            sendAlertSMS(CHILD_NAME, "STRESS", gps.lat, gps.lng,
                         static_cast<int>(AlertType::STRESS));
            syncAlert("STRESS", gps, 4);
            appendAlertLog("STRESS", now);
            s_anyAlertRecent = true;
            s_anyAlertTime   = now;
        }
    }

    // ── GEOFENCE BREACH ───────────────────────────────────────────────────────
    if (gps.fixed && !isInsideGeofence(gps)) {
        if (cooldownOK(AlertType::GEOFENCE_BREACH)) {
            triggerVibration();
            sendAlertSMS(CHILD_NAME, "GEOFENCE BREACH", gps.lat, gps.lng,
                         static_cast<int>(AlertType::GEOFENCE_BREACH));
            syncAlert("GEOFENCE_BREACH", gps, 5);
            appendAlertLog("GEOFENCE_BREACH", now);
            s_anyAlertRecent = true;
            s_anyAlertTime   = now;
        }
    }

    // ── LOW SPO2 (3 consecutive readings < 90 %) ──────────────────────────────
    if (!(reading.error_mask & SENSOR_ERR_SPO2) && reading.spo2 < LOW_SPO2_THRESHOLD) {
        s_lowSpo2Count++;
    } else {
        s_lowSpo2Count = 0;
    }
    if (s_lowSpo2Count >= SPO2_CONSEC_NEEDED) {
        if (cooldownOK(AlertType::LOW_SPO2)) {
            sendAlertSMS(CHILD_NAME, "LOW SPO2", gps.lat, gps.lng,
                         static_cast<int>(AlertType::LOW_SPO2));
            syncAlert("LOW_SPO2", gps, 5);
            appendAlertLog("LOW_SPO2", now);
            s_lowSpo2Count = 0;
        }
    }

    // ── SENSOR FAILURE ────────────────────────────────────────────────────────
    if (reading.error_mask != 0) {
        if (cooldownOK(AlertType::SENSOR_FAILURE)) {
            syncAlert("SENSOR_FAILURE", gps, 2);
            appendAlertLog("SENSOR_FAILURE", now);
        }
    }

    // ── LOW BATTERY ───────────────────────────────────────────────────────────
    if (battPct < LOW_BAT_THRESHOLD) {
        if (cooldownOK(AlertType::LOW_BATTERY)) {
            syncAlert("LOW_BATTERY", gps, 1);
            appendAlertLog("LOW_BATTERY", now);
        }
    }
}
