#include <Arduino.h>
#include <TinyGPS++.h>

#include "features.h"
#include "gps.h"
#include "secrets.h"

/**************************************************************
 * NEO-6M wiring: GPS TX -> ESP32 GPIO 6 (detected by scanner).
 * GPS RX (ESP TX) is unused (-1) — we only read, never configure.
 **************************************************************/
#define GPS_RX_PIN   6
#define GPS_TX_PIN   -1
#define GPS_BAUD     9600

static HardwareSerial GPSSerial(1);
static TinyGPSPlus gps;

void GPS_Init(void)
{
    GPSSerial.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

    Features.lat = 0.0;
    Features.lng = 0.0;
    Features.gps_fix = 0;

    Serial.println("GPS Initialized (GPIO 6 @ 9600)");
}

void GPS_Task(void *pvParameters)
{
    TickType_t xLastWakeTime = xTaskGetTickCount();

    while(true)
    {
        // Drain whatever the GPS has sent and feed the parser.
        while(GPSSerial.available())
            gps.encode(GPSSerial.read());

#if SIMULATE_GPS
        // Indoor-demo mode: pretend we have a fixed fix so the geofence
        // logic can be exercised without a sky view.
        Features.lat = SIM_LAT;
        Features.lng = SIM_LNG;
        Features.gps_fix = 1;
#else
        if(gps.location.isValid())
        {
            Features.lat = gps.location.lat();
            Features.lng = gps.location.lng();
            Features.gps_fix = 1;
        }
        else
        {
            Features.gps_fix = 0;
        }
#endif

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(1000)
        );
    }
}
