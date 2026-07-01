// firmware/include/alert_engine.h
#pragma once

#include <Arduino.h>
#include "sensors.h"
#include "inference.h"
#include "gps_manager.h"

/**
 * @brief Alert types produced by the alert engine.
 */
enum class AlertType : uint8_t {
    STRESS          = 0,
    GEOFENCE_BREACH = 1,
    LOW_SPO2        = 2,
    SENSOR_FAILURE  = 3,
    LOW_BATTERY     = 4
};

/**
 * @brief Initialise alert engine I/O pins and load encrypted alert log.
 *
 * Sets VIBRATION_PIN as PWM output.
 * No-op if already initialised.
 */
void initAlertEngine();

/**
 * @brief Evaluate all alert conditions and dispatch actions.
 *
 * Thresholds:
 *  STRESS          — StressResult::state == STRESS
 *  GEOFENCE_BREACH — !isInsideGeofence(gps)
 *  LOW_SPO2        — spo2 < 90 % for 3 consecutive readings
 *  SENSOR_FAILURE  — reading.error_mask != 0
 *  LOW_BATTERY     — battPct < 15 %
 *
 * Actions:
 *  STRESS          → vibrate (3×500ms/200ms) + SMS + Firebase alert
 *  GEOFENCE_BREACH → vibrate + SMS + Firebase
 *  LOW_SPO2        → SMS + Firebase (no vibrate — child may be sleeping)
 *  SENSOR_FAILURE  → Firebase only
 *  LOW_BATTERY     → Firebase only
 *
 * No alerts are issued when calibration is not yet complete.
 * Each alert type has a minimum 5-minute cooldown between dispatches.
 *
 * @param reading   Latest sensor snapshot.
 * @param result    Latest inference result.
 * @param gps       Latest GPS fix.
 * @param battPct   Battery percentage.
 */
void evaluateAlerts(const SensorReading& reading,
                    const StressResult&  result,
                    const GPSReading&    gps,
                    float                battPct);

/**
 * @brief Fire the vibration motor pattern for the given alert type.
 *
 * Pattern: 3 × (500 ms ON / 200 ms OFF).
 * Implemented as PWM on VIBRATION_PIN.
 */
void triggerVibration();

/**
 * @brief Return true if any alert was dispatched within the last 60 seconds.
 */
bool isAlertActive();
