// firmware/include/wifi_firebase.h
#pragma once

#include <Arduino.h>
#include "sensors.h"
#include "inference.h"
#include "gps_manager.h"

/**
 * @brief WiFi connection status.
 */
enum class WiFiStatus : uint8_t {
    DISCONNECTED = 0,
    CONNECTING   = 1,
    CONNECTED    = 2,
    FAILED       = 3
};

/**
 * @brief Initialise WiFi and Firebase.
 *
 * Non-blocking WiFi connect attempt with 20-second timeout.
 * HTTPS only — SSL certificate verification enforced.
 * Must be called once before any sync operation.
 *
 * @return true if connected and Firebase initialised.
 */
bool initWiFi();

/**
 * @brief Sync a vitals snapshot to Firestore.
 *
 * Path: /users/{userId}/children/{childId}/vitals/{timestamp}
 * All physiological fields are transmitted over HTTPS (TLS).
 * Enqueues to offline queue if WiFi unavailable.
 *
 * @param reading   Most-recent sensor reading.
 * @param result    Stress inference result.
 * @param gps       Most-recent GPS fix.
 * @param battPct   Battery percentage (0–100).
 */
void syncVitals(const SensorReading& reading, const StressResult& result,
                const GPSReading& gps, float battPct);

/**
 * @brief Sync an alert document to Firestore.
 *
 * Path: /users/{userId}/children/{childId}/alerts/{alertId}
 * Enqueues if offline.
 *
 * @param alertType  String label (e.g. "STRESS", "GEOFENCE_BREACH").
 * @param gps        GPS reading at alert time.
 * @param severity   Numeric severity (1–5).
 */
void syncAlert(const char* alertType, const GPSReading& gps, int severity);

/**
 * @brief Upload a pre-serialised JSON payload from the offline queue.
 *
 * Called by flushQueue() in offline_queue.cpp.
 * Returns false if WiFi is unavailable or upload fails.
 *
 * @param plainJson  Decrypted JSON string originally enqueued.
 * @param entryType  "vitals" or "alert".
 * @return true on success.
 */
bool syncOfflineEntry(const String& plainJson, const char* entryType);

/**
 * @brief Return the current WiFi connection status.
 */
WiFiStatus getWiFiStatus();

/**
 * @brief Read battery percentage from ADC using LiPo discharge curve.
 *
 * Voltage is read on BATTERY_PIN through a 1:2 voltage divider.
 * Uses a 7-point lookup table matching: 4.2V→100%, 3.7V→50%, 3.0V→0%.
 *
 * @return Battery percentage 0–100.
 */
float getBatteryPercent();
