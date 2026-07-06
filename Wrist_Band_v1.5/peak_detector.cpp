#include <Arduino.h>
#include "peak_detector.h"

/**************************************************************
 * Peak Detector Settings
 **************************************************************/
#define MIN_RISE_AMOUNT        20.0f
#define MIN_FALL_AMOUNT        20.0f
#define MIN_PULSE_AMPLITUDE    45.0f   // was 80 — accepts slightly weaker beats so HR locks sooner
#define REFRACTORY_MS          350

/**************************************************************
 * Detector Variables
 **************************************************************/
static float valleyValue = 0;
static float peakValue = 0;

static bool rising = false;
static bool detectorReady = false;

static unsigned long lastBeatTime = 0;

void PeakDetector_Init(void)
{
    valleyValue = 0;
    peakValue = 0;

    rising = false;
    detectorReady = false;

    lastBeatTime = 0;
}

PeakResult_t PeakDetector_Update(float ppg_value)
{
    PeakResult_t result;

    result.beat_detected =
        false;

    result.pulse_amplitude =
        0;

    if(!detectorReady)
    {
        valleyValue =
            ppg_value;

        peakValue =
            ppg_value;

        detectorReady =
            true;

        return result;
    }

    if(!rising)
    {
        if(ppg_value < valleyValue)
        {
            valleyValue =
                ppg_value;
        }

        if(ppg_value > valleyValue + MIN_RISE_AMOUNT)
        {
            rising =
                true;

            peakValue =
                ppg_value;
        }
    }
    else
    {
        if(ppg_value > peakValue)
        {
            peakValue =
                ppg_value;
        }

        if(ppg_value < peakValue - MIN_FALL_AMOUNT)
        {
            float pulseAmplitude =
                peakValue - valleyValue;

            unsigned long now =
                millis();

            if(pulseAmplitude >= MIN_PULSE_AMPLITUDE &&
               now - lastBeatTime >= REFRACTORY_MS)
            {
                result.beat_detected =
                    true;

                result.pulse_amplitude =
                    pulseAmplitude;

                lastBeatTime =
                    now;
            }

            rising =
                false;

            valleyValue =
                ppg_value;

            peakValue =
                ppg_value;
        }
    }

    return result;
}