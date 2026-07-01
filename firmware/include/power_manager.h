// firmware/include/power_manager.h
#pragma once

#include <Arduino.h>

/**
 * @brief Initialise power management I/O.
 *
 * Configures CHRG_PIN (TP4056) as input with pull-up.
 * Configures BATTERY_PIN ADC.
 */
void initPowerManager();

/**
 * @brief Enter light sleep for 8 seconds.
 *
 * Used between 10-second sensor cycles: 2 seconds are consumed by sensing,
 * 8 seconds saved by light sleep.  FreeRTOS tick is suspended and resumed
 * automatically by ESP-IDF light sleep.
 */
void lightSleepMs(uint32_t ms);

/**
 * @brief Return battery percentage using the LiPo discharge curve.
 *
 * Delegates to wifi_firebase::getBatteryPercent().
 */
float batteryPercent();

/**
 * @brief Return true if the TP4056 CHRG pin indicates active charging.
 *
 * CHRG is active-low; internal pull-up assumed.
 */
bool isCharging();

/**
 * @brief Enter ESP32 deep sleep indefinitely (power exhausted / critical fault).
 *
 * Should only be called as a last resort.  Device must be reset by external
 * means to wake.
 */
void enterDeepSleep();

/**
 * @brief Return the GPS polling interval in milliseconds.
 *
 * Normal:   60 000 ms (60 s) when no geofence breach in last 30 minutes.
 * Alert:    10 000 ms (10 s) when a breach was detected recently.
 *
 * @param geofenceBreachRecent True if a geofence breach occurred recently.
 */
uint32_t gpsPollingIntervalMs(bool geofenceBreachRecent);
