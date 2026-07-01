#include <Arduino.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include "features.h"
#include "bluetooth.h"

/**************************************************************
 * BLE UUIDs
 **************************************************************/
#define BLE_DEVICE_NAME        "AEGIS_BAND"

#define SERVICE_UUID           "12345678-1234-1234-1234-1234567890ab"
#define FEATURE_CHAR_UUID      "abcdefab-1234-5678-1234-abcdefabcdef"

/**************************************************************
 * BLE Objects
 **************************************************************/
static BLEServer *pServer = NULL;
static BLECharacteristic *pFeatureCharacteristic = NULL;

static bool deviceConnected = false;

/**************************************************************
 * Server Callback
 **************************************************************/
class ServerCallbacks: public BLEServerCallbacks
{
    void onConnect(BLEServer *pServer)
    {
        deviceConnected =
            true;
    }

    void onDisconnect(BLEServer *pServer)
    {
        deviceConnected =
            false;

        pServer->startAdvertising();
    }
};

/**************************************************************
 * Init
 **************************************************************/
void Bluetooth_Init(void)
{
    BLEDevice::init(
        BLE_DEVICE_NAME
    );

    pServer =
        BLEDevice::createServer();

    pServer->setCallbacks(
        new ServerCallbacks()
    );

    BLEService *pService =
        pServer->createService(
            SERVICE_UUID
        );

    pFeatureCharacteristic =
        pService->createCharacteristic(
            FEATURE_CHAR_UUID,
            BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_NOTIFY
        );

    pFeatureCharacteristic->addDescriptor(
        new BLE2902()
    );

    pService->start();

    BLEAdvertising *pAdvertising =
        BLEDevice::getAdvertising();

    pAdvertising->addServiceUUID(
        SERVICE_UUID
    );

    pAdvertising->setScanResponse(
        true
    );

    pAdvertising->setMinPreferred(
        0x06
    );

    pAdvertising->setMinPreferred(
        0x12
    );

    BLEDevice::startAdvertising();

    Serial.println(
        "BLE Initialized"
    );
}

/**************************************************************
 * Task
 **************************************************************/
void Bluetooth_Task(
    void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    char jsonBuffer[768];

    while(true)
    {
        if(deviceConnected)
        {
            snprintf(
                jsonBuffer,
                sizeof(jsonBuffer),
                "{"
                "\"temp_mean\":%.3f,"
                "\"temp_std\":%.3f,"
                "\"temp_slope\":%.6f,"
                "\"acc_mean\":%.3f,"
                "\"acc_std\":%.3f,"
                "\"acc_max\":%.3f,"
                "\"gsr_mean\":%.3f,"
                "\"gsr_std\":%.3f,"
                "\"gsr_max\":%.3f,"
                "\"gsr_slope\":%.6f,"
                "\"gsr_spike_count\":%lu,"
                "\"hr_mean\":%.3f,"
                "\"hrv\":%.3f,"
                "\"rmssd\":%.3f,"
                "\"stress_state\":%u,"
                "\"stress_alert\":%u"
                "}",
                Features.temp_mean,
                Features.temp_std,
                Features.temp_slope,

                Features.acc_mean,
                Features.acc_std,
                Features.acc_max,

                Features.gsr_mean,
                Features.gsr_std,
                Features.gsr_max,
                Features.gsr_slope,
                (unsigned long)Features.gsr_spike_count,

                Features.hr_mean,
                Features.hrv,
                Features.rmssd,

                Features.stress_state,
                Features.stress_alert
            );

            pFeatureCharacteristic->setValue(
                jsonBuffer
            );

            pFeatureCharacteristic->notify();
        }

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(1000)
        );
    }
}