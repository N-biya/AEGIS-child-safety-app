#include <Arduino.h>
#include <math.h>

#include "rr_processor.h"

/**************************************************************
 * RR Processor Settings
 **************************************************************/
#define RR_MIN_MS             300
#define RR_MAX_MS             2000
#define RR_WINDOW_SIZE        10

/**************************************************************
 * Buffers
 **************************************************************/
static float rrBuffer[RR_WINDOW_SIZE];
static float hrBuffer[RR_WINDOW_SIZE];

static uint8_t rrCount = 0;
static uint8_t hrCount = 0;

static unsigned long lastBeatTime = 0;

static RRFeatures_t FeaturesOut;

/**************************************************************
 * Helper Functions
 **************************************************************/
static float Mean(float *data, int size)
{
    float sum = 0;

    for(int i=0;i<size;i++)
        sum += data[i];

    return sum / size;
}

static float Std(float *data, int size)
{
    float mean =
        Mean(data,size);

    float variance = 0;

    for(int i=0;i<size;i++)
    {
        float diff =
            data[i] - mean;

        variance +=
            diff * diff;
    }

    variance /= size;

    return sqrtf(variance);
}

static float RMSSD(float *data, int size)
{
    float sum = 0;

    for(int i=1;i<size;i++)
    {
        float diff =
            data[i] - data[i-1];

        sum +=
            diff * diff;
    }

    return sqrtf(
        sum / (size-1)
    );
}

/**************************************************************
 * Init
 **************************************************************/
void RRProcessor_Init(void)
{
    rrCount = 0;
    hrCount = 0;

    lastBeatTime = 0;

    FeaturesOut.hr_mean = 0;
    FeaturesOut.hrv = 0;
    FeaturesOut.rmssd = 0;
}

/**************************************************************
 * Update
 **************************************************************/
RRFeatures_t RRProcessor_Update(bool beat_detected)
{
    if(!beat_detected)
        return FeaturesOut;

    unsigned long now =
        millis();

    if(lastBeatTime == 0)
    {
        lastBeatTime =
            now;

        return FeaturesOut;
    }

    float rr =
        now - lastBeatTime;

    lastBeatTime =
        now;

    if(rr < RR_MIN_MS || rr > RR_MAX_MS)
        return FeaturesOut;

    float hr =
        60000.0f / rr;

    rrBuffer[rrCount] =
        rr;

    hrBuffer[hrCount] =
        hr;

    rrCount++;
    hrCount++;

    if(rrCount >= RR_WINDOW_SIZE)
        rrCount = 0;

    if(hrCount >= RR_WINDOW_SIZE)
        hrCount = 0;

    uint8_t count =
        rrCount;

    if(count < 3)
        return FeaturesOut;

    FeaturesOut.hr_mean =
        Mean(
            hrBuffer,
            count
        );

    FeaturesOut.hrv =
        Std(
            rrBuffer,
            count
        );

    FeaturesOut.rmssd =
        RMSSD(
            rrBuffer,
            count
        );

    return FeaturesOut;
}