// firmware/src/power_manager.cpp
#include "power_manager.h"
#include "wifi_firebase.h"
#include "secrets.h"

#include <esp_sleep.h>
#include <driver/adc.h>

static constexpr uint32_t GPS_NORMAL_INTERVAL_MS = 60000;
static constexpr uint32_t GPS_ALERT_INTERVAL_MS  = 10000;

void initPowerManager()
{
    pinMode(CHRG_PIN, INPUT_PULLUP);
    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);
}

void lightSleepMs(uint32_t ms)
{
    if (ms == 0) return;
    esp_sleep_enable_timer_wakeup(static_cast<uint64_t>(ms) * 1000ULL);
    esp_light_sleep_start();
}

float batteryPercent()
{
    return getBatteryPercent();
}

bool isCharging()
{
    return digitalRead(CHRG_PIN) == LOW;
}

void enterDeepSleep()
{
    esp_deep_sleep_start();
}

uint32_t gpsPollingIntervalMs(bool geofenceBreachRecent)
{
    return geofenceBreachRecent ? GPS_ALERT_INTERVAL_MS : GPS_NORMAL_INTERVAL_MS;
}
