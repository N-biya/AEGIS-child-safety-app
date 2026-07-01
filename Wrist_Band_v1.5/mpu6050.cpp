#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <math.h>

#include "features.h"
#include "mpu6050.h"

#define ACC_WINDOW_SIZE 100

static Adafruit_MPU6050 mpu;

static float accBuffer[ACC_WINDOW_SIZE];

static uint16_t writeIndex = 0;
static bool bufferFull = false;

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

static float Max(float *data, int size)
{
    float maxValue = data[0];

    for(int i=1;i<size;i++)
    {
        if(data[i] > maxValue)
            maxValue = data[i];
    }

    return maxValue;
}

void MPU6050_Init(void)
{
    if(!mpu.begin())
    {
        Serial.println("MPU6050 not detected");

        while(1);
    }

    mpu.setAccelerometerRange(
        MPU6050_RANGE_2_G
    );

    mpu.setGyroRange(
        MPU6050_RANGE_250_DEG
    );

    mpu.setFilterBandwidth(
        MPU6050_BAND_21_HZ
    );
}

void MPU6050_Task(void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    uint32_t featureCounter = 0;

    while(true)
    {
        sensors_event_t a,g,t;

        mpu.getEvent(&a,&g,&t);

        float accMag =
            sqrtf(
                a.acceleration.x *
                a.acceleration.x +

                a.acceleration.y *
                a.acceleration.y +

                a.acceleration.z *
                a.acceleration.z
            );

        accBuffer[writeIndex] =
            accMag;

        writeIndex++;

        if(writeIndex >=
            ACC_WINDOW_SIZE)
        {
            writeIndex = 0;
            bufferFull = true;
        }

        featureCounter++;

        if(bufferFull &&
            featureCounter >= 50)
        {
            Features.acc_mean =
                Mean(
                    accBuffer,
                    ACC_WINDOW_SIZE
                );

            Features.acc_std =
                Std(
                    accBuffer,
                    ACC_WINDOW_SIZE
                );

            Features.acc_max =
                Max(
                    accBuffer,
                    ACC_WINDOW_SIZE
                );

            featureCounter = 0;
        }

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(20)
        );
    }
}