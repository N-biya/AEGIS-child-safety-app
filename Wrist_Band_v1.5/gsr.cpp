#include <Arduino.h>
#include <math.h>

#include "features.h"
#include "gsr.h"

#define GSR_PIN 4

#define GSR_WINDOW_SIZE 50
#define GSR_SPIKE_THRESHOLD 120.0f

/* Noise control for the MVP veroboard GSR:
 *  - OVERSAMPLE: average many raw ADC reads per sample (the ESP32 ADC is
 *    very noisy; averaging removes most of the jitter).
 *  - EMA: lightly smooth across samples so slow skin-conductance changes
 *    come through but electrical spikes don't. Buffer-free (one float). */
#define GSR_OVERSAMPLE     16
#define GSR_EMA_ALPHA      0.30f

static float gsrFiltered = -1.0f;

static float gsrBuffer[GSR_WINDOW_SIZE];

static uint16_t sampleCount = 0;

/* One clean GSR sample: oversample the ADC, then EMA-smooth. */
static float ReadGSR(void)
{
    uint32_t sum = 0;
    for(int i = 0; i < GSR_OVERSAMPLE; i++)
        sum += analogRead(GSR_PIN);

    float raw = (float)sum / GSR_OVERSAMPLE;

    if(gsrFiltered < 0.0f)
        gsrFiltered = raw;                  // seed on first read
    else
        gsrFiltered = gsrFiltered * (1.0f - GSR_EMA_ALPHA)
                      + raw * GSR_EMA_ALPHA; // smooth

    return gsrFiltered;
}

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

static uint32_t CountSpikes(float *data, int size)
{
    uint32_t count = 0;

    for(int i=1;i<size;i++)
    {
        float diff =
            data[i] - data[i-1];

        if(diff > GSR_SPIKE_THRESHOLD)
            count++;
    }

    return count;
}

void GSR_Init(void)
{
    pinMode(
        GSR_PIN,
        INPUT
    );

    analogReadResolution(12);
}

void GSR_Task(void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    while(true)
    {
        float gsr =
            ReadGSR();

        gsrBuffer[sampleCount] =
            gsr;

        sampleCount++;

        if(sampleCount >= GSR_WINDOW_SIZE)
        {
            float gsr_mean =
                Mean(
                    gsrBuffer,
                    GSR_WINDOW_SIZE
                );

            float gsr_std =
                Std(
                    gsrBuffer,
                    GSR_WINDOW_SIZE
                );

            float gsr_max =
                Max(
                    gsrBuffer,
                    GSR_WINDOW_SIZE
                );

            float gsr_slope =
                (gsrBuffer[GSR_WINDOW_SIZE-1]
                - gsrBuffer[0])
                /
                (GSR_WINDOW_SIZE-1);

            uint32_t gsr_spike_count =
                CountSpikes(
                    gsrBuffer,
                    GSR_WINDOW_SIZE
                );

            Features.gsr_mean =
                gsr_mean;

            Features.gsr_std =
                gsr_std;

            Features.gsr_max =
                gsr_max;

            Features.gsr_slope =
                gsr_slope;

            Features.gsr_spike_count =
                gsr_spike_count;

            sampleCount = 0;
        }

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(200)
        );
    }
}