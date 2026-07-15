#include <Arduino.h>
#include <math.h>

#include "rr_processor.h"

/**************************************************************
 * RR Processor Settings
 **************************************************************/
#define RR_MIN_MS             300
#define RR_MAX_MS             2000
#define RR_WINDOW_SIZE        10
#define OUTLIER_PCT           0.30f   // reject a beat whose interval jumps >30% from the recent rhythm

/**************************************************************
 * Buffers
 **************************************************************/
static float rrBuffer[RR_WINDOW_SIZE];
static float hrBuffer[RR_WINDOW_SIZE];

static uint8_t rrCount = 0;
static uint8_t hrCount = 0;

static unsigned long lastBeatTime = 0;
static float         refRR        = 0.0f;   // smoothed recent RR — the outlier-rejection reference

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
    refRR        = 0.0f;

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

    // Long gap (finger shifted/removed): restart timing here and drop the old
    // rhythm reference, so we don't average a bogus interval across the gap.
    if(rr > RR_MAX_MS)
    {
        lastBeatTime = now;
        refRR        = 0.0f;
        return FeaturesOut;
    }

    // Too-fast "beat" — noise or a leftover dicrotic notch. Ignore it WITHOUT
    // moving the reference, so the next real beat is still timed from the last
    // good beat (otherwise one false beat corrupts the following interval).
    if(rr < RR_MIN_MS)
        return FeaturesOut;

    // Outlier (rhythm-plausibility) rejection: once we have a reference RR,
    // drop any beat whose interval jumps more than OUTLIER_PCT from it — that
    // is almost always a false beat that would otherwise inflate the HR.
    if(refRR > 0.0f)
    {
        float lo = refRR * (1.0f - OUTLIER_PCT);
        float hi = refRR * (1.0f + OUTLIER_PCT);

        if(rr < lo || rr > hi)
            return FeaturesOut;   // reject; keep lastBeatTime & refRR intact
    }

    // Accept this beat.
    lastBeatTime =
        now;

    // Smoothly track the accepted rhythm as the reference for the next beat.
    if(refRR <= 0.0f) refRR = rr;
    else              refRR = 0.8f * refRR + 0.2f * rr;

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

    if(count < 2)   // was 3 — HR appears ~1 beat sooner (debounce + outlier reject keep it clean)
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