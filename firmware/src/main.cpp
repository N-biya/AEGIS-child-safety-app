// firmware/src/main.cpp
//
// AEGIS — Adaptive Edge-Intelligence Guardian and Safety System
// FreeRTOS orchestration: three tasks across two cores.
//
//  Core 1  priority 3: SensorInferenceAlertTask — time-critical, 10-second cycle
//  Core 0  priority 2: GSMTask                  — AT command blocking
//  Core 0  priority 1: WiFiFirebaseTask          — network I/O
//
// All physiological/location data processed on-device. Never delegated to cloud.
//
#include <Arduino.h>
#include <SPIFFS.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>
#include <freertos/queue.h>
#include <esp_task_wdt.h>

#include "secrets.h"
#include "crypto_utils.h"
#include "sensors.h"
#include "calibration.h"
#include "inference.h"
#include "gps_manager.h"
#include "gsm_sms.h"
#include "wifi_firebase.h"
#include "offline_queue.h"
#include "alert_engine.h"
#include "ble_pairing.h"
#include "power_manager.h"

// ── Watchdog ──────────────────────────────────────────────────────────────────
static constexpr uint32_t WDT_TIMEOUT_S = 30;

// ── Shared state ──────────────────────────────────────────────────────────────

struct SharedState {
    SensorReading  latestReading;
    StressResult   latestStress;
    GPSReading     latestGPS;
    float          batteryPct;
    bool           geofenceBreachRecent;
};

static SharedState        s_state   = {};
static SemaphoreHandle_t  s_stateMx = nullptr;

// ── Alert queue (sensor task → GSM task) ─────────────────────────────────────

struct AlertMsg {
    char   status[32];
    float  lat, lng;
    int    alertType;
};
static QueueHandle_t s_alertQ = nullptr;

// ── Device ID derived from MAC ────────────────────────────────────────────────

static String s_deviceId;

static String buildDeviceId()
{
    uint8_t mac[6];
    esp_efuse_mac_get_default(mac);
    char buf[13];
    snprintf(buf, sizeof(buf), "%02X%02X%02X%02X%02X%02X",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    return String(buf);
}

// ── PAIR_BUTTON long-press detection ─────────────────────────────────────────

static constexpr uint32_t LONG_PRESS_MS = 3000;

static bool checkPairButton()
{
    if (digitalRead(PAIR_BUTTON_PIN) != LOW) return false;
    uint32_t start = millis();
    while (digitalRead(PAIR_BUTTON_PIN) == LOW) {
        if ((millis() - start) >= LONG_PRESS_MS) return true;
        delay(50);
    }
    return false;
}

// ── Task: Sensor + Inference + Alert (Core 1, priority 3) ───────────────────

static void SensorInferenceAlertTask(void* /*param*/)
{
    esp_task_wdt_add(NULL);

    static uint32_t lastGPSPoll  = 0;
    static uint32_t lastFirebase = 0;
    static constexpr uint32_t FIREBASE_INTERVAL_MS = 5UL * 60UL * 1000UL; // 5 min

    while (true) {
        esp_task_wdt_reset();

        // ── 1. Read sensors ───────────────────────────────────────────────────
        SensorReading r = readAllSensors();
        float battPct   = getBatteryPercent();

        // ── 2. GPS (duty-cycled) ──────────────────────────────────────────────
        bool breachRecent = false;
        if (xSemaphoreTake(s_stateMx, pdMS_TO_TICKS(100)) == pdTRUE) {
            breachRecent = s_state.geofenceBreachRecent;
            xSemaphoreGive(s_stateMx);
        }
        GPSReading gps;
        uint32_t gpsInterval = gpsPollingIntervalMs(breachRecent);
        if ((millis() - lastGPSPoll) >= gpsInterval) {
            gps = readGPS();
            lastGPSPoll = millis();
        } else {
            gps = readGPS();  // non-blocking, returns cached if no new data
        }

        // ── 3. Calibration cycle (if not yet calibrated) ──────────────────────
        if (!isCalibrated()) {
            if (r.valid) {
                runCalibrationCycle(r.hr, r.gsr, r.temp, r.acc_mag);
            }
            // Notify BLE app of progress
            notifyCalibrationProgress(getDaysCollected(), 7);

            // Update shared state
            if (xSemaphoreTake(s_stateMx, pdMS_TO_TICKS(100)) == pdTRUE) {
                s_state.latestReading = r;
                s_state.latestGPS     = gps;
                s_state.batteryPct    = battPct;
                xSemaphoreGive(s_stateMx);
            }
            lightSleepMs(8000);
            continue;
        }

        // ── 4. Inference ──────────────────────────────────────────────────────
        int bufCount = 0;
        const SensorReading* buf = getSensorBuffer(bufCount);
        StressResult stressResult = { InferenceState::NORMAL, 0.0f, 0 };
        if (bufCount == SENSOR_BUFFER_SIZE) {
            const CalibrationProfile* prof = getProfile();
            if (prof) stressResult = runInference(buf, bufCount, prof);
        }

        // ── 5. Alert evaluation ────────────────────────────────────────────────
        evaluateAlerts(r, stressResult, gps, battPct);

        // ── 6. Update shared state (protected) ────────────────────────────────
        if (xSemaphoreTake(s_stateMx, pdMS_TO_TICKS(100)) == pdTRUE) {
            s_state.latestReading       = r;
            s_state.latestStress        = stressResult;
            s_state.latestGPS           = gps;
            s_state.batteryPct          = battPct;
            s_state.geofenceBreachRecent = (gps.fixed && !isInsideGeofence(gps));
            xSemaphoreGive(s_stateMx);
        }

        // ── 7. Periodic Firebase vitals sync ──────────────────────────────────
        if ((millis() - lastFirebase) >= FIREBASE_INTERVAL_MS) {
            lastFirebase = millis();
            syncVitals(r, stressResult, gps, battPct);
        }

        // ── 8. Check pair button ───────────────────────────────────────────────
        if (checkPairButton() && !isPaired()) {
            startPairing(s_deviceId);
        }

        esp_task_wdt_reset();
        // Light sleep fills the remainder of the 10-second cycle.
        lightSleepMs(8000);
    }
}

// ── Task: GSM/SMS (Core 0, priority 2) ───────────────────────────────────────

static void GSMTask(void* /*param*/)
{
    esp_task_wdt_add(NULL);

    while (!initGSM()) {
        esp_task_wdt_reset();
        vTaskDelay(pdMS_TO_TICKS(5000));
    }

    while (true) {
        esp_task_wdt_reset();

        AlertMsg msg;
        // Block up to 5 s for an alert message
        if (xQueueReceive(s_alertQ, &msg, pdMS_TO_TICKS(5000)) == pdTRUE) {
            esp_task_wdt_reset();
            sendAlertSMS(CHILD_NAME, msg.status, msg.lat, msg.lng, msg.alertType);
        }

        // Re-check GSM health every ~60 s (handled implicitly by send watchdog)
        esp_task_wdt_reset();
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// ── Task: WiFi + Firebase (Core 0, priority 1) ────────────────────────────────

static void WiFiFirebaseTask(void* /*param*/)
{
    esp_task_wdt_add(NULL);

    static uint32_t lastFlush    = 0;
    static uint32_t lastBatLog   = 0;
    static constexpr uint32_t FLUSH_INTERVAL  = 60UL * 1000UL;      // 1 min
    static constexpr uint32_t BAT_LOG_INTERVAL = 5UL * 60UL * 1000UL; // 5 min

    initWiFi();

    while (true) {
        esp_task_wdt_reset();

        // Attempt to reconnect if disconnected
        if (getWiFiStatus() != WiFiStatus::CONNECTED) {
            initWiFi();
        }

        // Flush offline queue periodically
        if ((millis() - lastFlush) >= FLUSH_INTERVAL) {
            lastFlush = millis();
            if (getWiFiStatus() == WiFiStatus::CONNECTED) {
                flushQueue();
            }
        }

        // Log battery to Firebase every 5 minutes
        if ((millis() - lastBatLog) >= BAT_LOG_INTERVAL) {
            lastBatLog = millis();
            float bat = 0.0f;
            if (xSemaphoreTake(s_stateMx, pdMS_TO_TICKS(100)) == pdTRUE) {
                bat = s_state.batteryPct;
                xSemaphoreGive(s_stateMx);
            }
            if (getWiFiStatus() == WiFiStatus::CONNECTED) {
                JsonDocument doc;
                doc["battery"] = bat;
                doc["ts"]      = millis();
                String plain; serializeJson(doc, plain);
                enqueueReading(plain, "battery");
                flushQueue();
            }
        }

        esp_task_wdt_reset();
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

// ── setup() ───────────────────────────────────────────────────────────────────

void setup()
{
    Serial.begin(115200);

    // 1. Watchdog
    esp_task_wdt_init(WDT_TIMEOUT_S, true);

    // 2. SPIFFS
    if (!SPIFFS.begin(true)) {
#if DEBUG_MODE
        Serial.println("[MAIN] SPIFFS mount failed — formatting");
#endif
        SPIFFS.format();
        SPIFFS.begin(true);
    }

    // 3. Crypto (must precede all encrypted SPIFFS access)
    if (!cryptoInit()) {
#if DEBUG_MODE
        Serial.println("[MAIN] FATAL: crypto init failed");
#endif
        // Watchdog will reset device
        while (true) {}
    }

    // 4. Data retention: prune entries older than 48 h
    pruneOldEntries();

    // 5. Load calibration profile (may already exist from prior session)
    loadProfile();

    // 6. Hardware init
    initPowerManager();
    pinMode(PAIR_BUTTON_PIN, INPUT_PULLUP);

    uint8_t sensorHealth = initSensors();
#if DEBUG_MODE
    Serial.println(getSensorHealthReport());
#endif

    initGPS();
    initAlertEngine();

    // 7. Device ID
    s_deviceId = buildDeviceId();

    // 8. BLE pairing — active on first boot (no config) or button press
    if (!isPaired() && !SPIFFS.exists("/data/device_config.json")) {
        startPairing(s_deviceId);
        // Block until pairing completes (max 5 min)
        uint32_t pairStart = millis();
        while (!isPaired() && (millis() - pairStart) < 300000UL) {
            delay(500);
        }
        stopPairing();
    }

    // 9. FreeRTOS shared resources
    s_stateMx = xSemaphoreCreateMutex();
    s_alertQ  = xQueueCreate(8, sizeof(AlertMsg));
    if (!s_stateMx || !s_alertQ) {
#if DEBUG_MODE
        Serial.println("[MAIN] FATAL: FreeRTOS resource creation failed");
#endif
        while (true) {}
    }

    // 10. Create tasks
    xTaskCreatePinnedToCore(SensorInferenceAlertTask, "SensorTask",
                            8192, nullptr, 3, nullptr, 1);  // Core 1
    xTaskCreatePinnedToCore(GSMTask, "GSMTask",
                            4096, nullptr, 2, nullptr, 0);  // Core 0
    xTaskCreatePinnedToCore(WiFiFirebaseTask, "WiFiTask",
                            8192, nullptr, 1, nullptr, 0);  // Core 0

#if DEBUG_MODE
    Serial.println("[MAIN] AEGIS started");
#endif
}

// loop() is unused — all work is in FreeRTOS tasks.
void loop()
{
    vTaskDelay(portMAX_DELAY);
}
