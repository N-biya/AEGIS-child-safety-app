#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include "features.h"
#include "temperature.h"
#include "mpu6050.h"
#include "gsr.h"
#include "max30102.h"
#include "communication.h"
#include "bluetooth.h"
#include "stress_ai.h"
#include "wifi_firebase.h"
#include "gps.h"
#include "sim_sms.h"

FeatureVector_t Features;

void setup()
{
    Serial.begin(115200);

    Wire.begin(8,9);
    Wire.setClock(100000);

    Temperature_Init();
    MPU6050_Init();
    GSR_Init();
    MAX30102_Init();
    // Bluetooth_Init();   // BLE disabled while using WiFi/cloud: frees ~60KB
                           // RAM for TLS and cuts heat. Re-enable for BLE pairing.
    StressAI_Init();
    GPS_Init();
    SIM_Init();
    WiFiFirebase_Init();

    xTaskCreatePinnedToCore(
        Temperature_Task,
        "Temperature_Task",
        4096,
        NULL,
        1,
        NULL,
        1
    );

    xTaskCreatePinnedToCore(
        MPU6050_Task,
        "MPU6050_Task",
        4096,
        NULL,
        1,
        NULL,
        1
    );

    xTaskCreatePinnedToCore(
        GSR_Task,
        "GSR_Task",
        4096,
        NULL,
        1,
        NULL,
        1
    );

    xTaskCreatePinnedToCore(
        Communication_Task,
        "Communication_Task",
        4096,
        NULL,
        1,
        NULL,
        0
    );

    xTaskCreatePinnedToCore(
        MAX30102_Task,
        "MAX30102_Task",
        8192,
        NULL,
        1,
        NULL,
        1
    );

    // BLE task disabled while using WiFi/cloud (see Bluetooth_Init above).
    // xTaskCreatePinnedToCore(
    //     Bluetooth_Task,
    //     "Bluetooth_Task",
    //     8192,
    //     NULL,
    //     1,
    //     NULL,
    //     0
    // );

    xTaskCreatePinnedToCore(
        StressAI_Task,
        "StressAI_Task",
        8192,
        NULL,
        1,
        NULL,
        0
    );

    xTaskCreatePinnedToCore(
        WiFiFirebase_Task,
        "WiFiFirebase_Task",
        24576,
        NULL,
        1,
        NULL,
        0
    );

    xTaskCreatePinnedToCore(
        GPS_Task,
        "GPS_Task",
        4096,
        NULL,
        1,
        NULL,
        1
    );
}

void loop()
{
}