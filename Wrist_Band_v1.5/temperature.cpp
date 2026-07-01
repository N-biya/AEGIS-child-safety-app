#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MLX90614.h>
#include <math.h>

#include "features.h"
#include "temperature.h"

#define TEMP_WINDOW_SIZE 30

static Adafruit_MLX90614 mlx;

static float tempBuffer[TEMP_WINDOW_SIZE];

static uint8_t sampleCount = 0;

static float Mean(float *data, int size)
{
    float sum = 0;

    for(int i=0;i<size;i++)
        sum += data[i];

    return sum / size;
}

static float Std(float *data, int size)
{
    float mean = Mean(data,size);

    float variance = 0;

    for(int i=0;i<size;i++)
    {
        float diff = data[i] - mean;
        variance += diff * diff;
    }

    variance /= size;

    return sqrtf(variance);
}

void Temperature_Init(void)
{
    if(!mlx.begin())
    {
        Serial.println("MLX90614 not detected");

        while(1);
    }
}

void Temperature_Task(void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    while(true)
    {
        float temp =
            mlx.readObjectTempC();
            
            // Serial.print("TEMP_RAW: ");
            // Serial.println(
            //     temp,
            //     3
            // );

        if(!isnan(temp))
        {
            tempBuffer[sampleCount] = temp;

            sampleCount++;

            if(sampleCount >= TEMP_WINDOW_SIZE)
            {
                float temp_mean =
                    Mean(
                        tempBuffer,
                        TEMP_WINDOW_SIZE
                    );

                float temp_std =
                    Std(
                        tempBuffer,
                        TEMP_WINDOW_SIZE
                    );

                float temp_slope =
                    (tempBuffer[TEMP_WINDOW_SIZE-1]
                    - tempBuffer[0])
                    /
                    (TEMP_WINDOW_SIZE-1);

                Features.temp_mean =
                    temp_mean;

                Features.temp_std =
                    temp_std;

                Features.temp_slope =
                    temp_slope;

                sampleCount = 0;
            }
        }

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(1000)
        );
    }
}