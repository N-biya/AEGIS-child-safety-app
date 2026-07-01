// firmware/src/ble_pairing.cpp
#include "ble_pairing.h"
#include "crypto_utils.h"
#include "gps_manager.h"
#include "secrets.h"

#include <NimBLEDevice.h>
#include <SPIFFS.h>
#include <ArduinoJson.h>
#include <esp_system.h>

static constexpr const char* CONFIG_PATH     = "/data/device_config.json";
// UUIDs are device-class identifiers only — do not encode child PII.
static constexpr const char* SERVICE_UUID    = "4ae7-a5b3-bc00-0001";
static constexpr const char* WRITE_CHAR_UUID = "4ae7-a5b3-bc00-0002";
static constexpr const char* NOTIF_CHAR_UUID = "4ae7-a5b3-bc00-0003";

static NimBLEServer*         s_server  = nullptr;
static NimBLECharacteristic* s_writeCh = nullptr;
static NimBLECharacteristic* s_notifCh = nullptr;
static bool                  s_paired  = false;
static bool                  s_active  = false;
static uint32_t              s_passkey = 0;

// ── Config save ───────────────────────────────────────────────────────────────

static bool saveConfig(const JsonDocument& cfg)
{
    // Validate: store first name only; strip any surname tokens.
    String childName = cfg["child_name"] | "Child";
    // Trim to first space (first name isolation)
    int sp = childName.indexOf(' ');
    if (sp > 0) childName = childName.substring(0, sp);

    JsonDocument out;
    out["child_name"] = childName;
    out["center_lat"] = cfg["center_lat"] | 0.0f;
    out["center_lng"] = cfg["center_lng"] | 0.0f;
    out["radius_m"]   = cfg["radius_m"]   | 100.0f;
    out["phone1"]     = cfg["phone1"]     | "";
    out["phone2"]     = cfg["phone2"]     | "";
    out["phone3"]     = cfg["phone3"]     | "";
    // userId / childId stored encrypted — NEVER in Serial logs
    out["user_id"]    = cfg["user_id"]    | "";
    out["child_id"]   = cfg["child_id"]   | "";

    // Also write geofence to gps_manager
    float lat = out["center_lat"];
    float lng = out["center_lng"];
    float r   = out["radius_m"];
    if (r > 0.0f) saveGeofence(lat, lng, r);

    String json;
    serializeJson(out, json);
    return encryptToSPIFFS(CONFIG_PATH, json);
}

// ── NimBLE callbacks ──────────────────────────────────────────────────────────

class ServerCB : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) override {
#if DEBUG_MODE
        Serial.println("[BLE] Client connected");
#endif
    }
    void onDisconnect(NimBLEServer* pServer) override {
#if DEBUG_MODE
        Serial.println("[BLE] Client disconnected");
#endif
        if (!s_paired && s_active) pServer->startAdvertising();
    }
};

class WriteCB : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pChar) override {
        std::string val = pChar->getValue();
        if (val.empty()) return;

        JsonDocument doc;
        DeserializationError err = deserializeJson(doc, val.c_str(), val.size());
        if (err != DeserializationError::Ok) {
            if (s_notifCh)
                s_notifCh->setValue("{\"status\":\"parse_error\"}");
            if (s_notifCh) s_notifCh->notify();
            return;
        }

        if (saveConfig(doc)) {
            s_paired = true;
            if (s_notifCh) {
                s_notifCh->setValue("{\"status\":\"paired\"}");
                s_notifCh->notify();
            }
            // Stop BLE after short delay to let notify transmit
            delay(300);
            stopPairing();
        } else {
            if (s_notifCh) {
                s_notifCh->setValue("{\"status\":\"save_error\"}");
                s_notifCh->notify();
            }
        }
    }
};

// ── Public API ────────────────────────────────────────────────────────────────

void startPairing(const String& deviceId)
{
    if (s_active) return;

    // Generate 6-digit passkey via TRNG
    s_passkey = esp_random() % 900000 + 100000;  // 100000–999999

    String advName = "AEGIS-" + deviceId;  // device ID only, no child PII
    NimBLEDevice::init(advName.c_str());

    NimBLEDevice::setSecurityAuth(
        BLE_SM_PAIR_AUTHREQ_SC |
        BLE_SM_PAIR_AUTHREQ_MITM |
        BLE_SM_PAIR_AUTHREQ_BOND);
    NimBLEDevice::setSecurityPasskey(s_passkey);
    NimBLEDevice::setSecurityIOCap(BLE_HS_IO_DISPLAY_ONLY);

    s_server = NimBLEDevice::createServer();
    s_server->setCallbacks(new ServerCB());

    NimBLEService* svc = s_server->createService(SERVICE_UUID);

    s_writeCh = svc->createCharacteristic(
        WRITE_CHAR_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_ENC | NIMBLE_PROPERTY::WRITE_AUTHEN);
    s_writeCh->setCallbacks(new WriteCB());

    s_notifCh = svc->createCharacteristic(
        NOTIF_CHAR_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY |
        NIMBLE_PROPERTY::READ_ENC | NIMBLE_PROPERTY::READ_AUTHEN);

    svc->start();
    NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
    adv->addServiceUUID(SERVICE_UUID);
    adv->setScanResponse(false);
    adv->start();
    s_active = true;

#if DEBUG_MODE
    Serial.printf("[BLE] Pairing started. Passkey: %06lu\n",
                  static_cast<unsigned long>(s_passkey));
#endif
}

void stopPairing()
{
    if (!s_active) return;
    NimBLEDevice::getAdvertising()->stop();
    if (s_server) s_server->disconnect(0);
    NimBLEDevice::deinit(true);
    s_active   = false;
    s_server   = nullptr;
    s_writeCh  = nullptr;
    s_notifCh  = nullptr;
}

bool isPaired()
{
    return s_paired;
}

uint32_t getPairingPasskey()
{
    return s_active ? s_passkey : 0;
}

void notifyCalibrationProgress(int daysDone, int totalDays)
{
    if (!s_active || !s_notifCh) return;
    char buf[64];
    snprintf(buf, sizeof(buf),
             "{\"calibration\":{\"done\":%d,\"total\":%d}}",
             daysDone, totalDays);
    s_notifCh->setValue(buf);
    s_notifCh->notify();
}
