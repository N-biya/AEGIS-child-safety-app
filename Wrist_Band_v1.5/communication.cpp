#include <Arduino.h>

#include "features.h"
#include "communication.h"

void Print_Features(void)
{
    Serial.println(
        "===== FEATURES ====="
    );

    /**************************************************************
     * Temperature
     **************************************************************/
    Serial.print("temp_mean: ");
    Serial.println(
        Features.temp_mean,
        3
    );

    Serial.print("temp_std : ");
    Serial.println(
        Features.temp_std,
        3
    );

    Serial.print("temp_slope: ");
    Serial.println(
        Features.temp_slope,
        6
    );

    Serial.println();

    /**************************************************************
     * Motion
     **************************************************************/
    Serial.print("acc_mean : ");
    Serial.println(
        Features.acc_mean,
        3
    );

    Serial.print("acc_std  : ");
    Serial.println(
        Features.acc_std,
        3
    );

    Serial.print("acc_max  : ");
    Serial.println(
        Features.acc_max,
        3
    );

    // Serial.println();

    /**************************************************************
     * GSR
     **************************************************************/
    Serial.print("gsr_mean : ");
    Serial.println(
        Features.gsr_mean,
        3
    );

    Serial.print("gsr_std  : ");
    Serial.println(
        Features.gsr_std,
        3
    );

    Serial.print("gsr_max  : ");
    Serial.println(
        Features.gsr_max,
        3
    );

    Serial.print("gsr_slope: ");
    Serial.println(
        Features.gsr_slope,
        6
    );

    Serial.print("gsr_spikes: ");
    Serial.println(
        Features.gsr_spike_count
    );

    /**************************************************************
     * HR sensor
     **************************************************************/

    Serial.print("hr_mean : ");
    Serial.println(
        Features.hr_mean,
        3
    );

    Serial.print("hrv     : ");
    Serial.println(
        Features.hrv,
        3
    );

    Serial.print("rmssd   : ");
    Serial.println(
        Features.rmssd,
        3
    );

    Serial.print("spo2    : ");
    Serial.println(
        Features.spo2,
        1
    );

    /**************************************************************
     * Stress
     **************************************************************/
    Serial.print("stress_state: ");
    Serial.println(
        Features.stress_state
    );

    Serial.print("stress_alert: ");
    Serial.println(
        Features.stress_alert
    );

    Serial.println();
}

void Communication_Task(
    void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    while(true)
    {
        Print_Features();

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(1000)
        );
    }
}