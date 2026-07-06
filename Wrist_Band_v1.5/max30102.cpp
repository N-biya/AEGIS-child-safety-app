#include <Arduino.h>
#include <Wire.h>

#include "MAX30105.h"

#include "features.h"
#include "max30102.h"
#include "ppg_filter.h"
#include "peak_detector.h"
#include "rr_processor.h"

MAX30105 MaxSensor;

/**************************************************************
 * MAX30102 Settings
 **************************************************************/
#define FINGER_ON_THRESHOLD       7000
#define FINGER_OFF_THRESHOLD      4000
#define FINGER_OFF_DEBOUNCE       15    // samples below threshold before "finger removed"

/**************************************************************
 * State
 **************************************************************/
static bool fingerPresent = false;
static int  fingerOffCount = 0;   // consecutive below-threshold samples (debounce)

/**************************************************************
 * SpO2 (ratio-of-ratios) — buffer-free, low-noise
 *
 * SpO2 = how much oxygen is in the blood. The MAX30102's RED and IR
 * LEDs are absorbed differently by oxygenated blood; the ratio of
 * their pulsatile (AC) to steady (DC) components gives SpO2.
 *
 * Memory-frugal: instead of storing sample buffers, we accumulate
 * running min/max/sum over a window, then compute once per window.
 * Heavily validated + smoothed so a weak MVP signal stays stable
 * instead of jumping around.
 **************************************************************/
#define SPO2_WINDOW          50       // ~2 s — attainable with finicky MVP contact
#define SPO2_MIN_DC          5000.0f  // need a real finger (strong DC)
#define SPO2_MIN_IR_AC       50.0f    // need a real pulse (AC amplitude)
#define SPO2_EMA_ALPHA       0.25f    // smoothing: lower = steadier

static uint16_t spo2Count = 0;
static uint32_t irSum = 0, redSum = 0;
static long     irMin = 0, irMax = 0, redMin = 0, redMax = 0;
static float    spo2Smoothed = 0.0f;

static void SpO2_Reset(void)
{
    spo2Count   = 0;
    irSum = redSum = 0;
    spo2Smoothed = 0.0f;
    Features.spo2 = 0;
}

/* Feed one (ir, red) sample; updates Features.spo2 once per full window. */
static void SpO2_Update(long ir, long red)
{
    if(spo2Count == 0)
    {
        irMin = irMax = ir;
        redMin = redMax = red;
        irSum = redSum = 0;
    }

    irSum  += ir;
    redSum += red;
    if(ir  < irMin)  irMin  = ir;
    if(ir  > irMax)  irMax  = ir;
    if(red < redMin) redMin = red;
    if(red > redMax) redMax = red;

    spo2Count++;
    if(spo2Count < SPO2_WINDOW) return;

    spo2Count = 0;

    float irDC  = (float)irSum  / SPO2_WINDOW;
    float redDC = (float)redSum / SPO2_WINDOW;
    float irAC  = (float)(irMax  - irMin);
    float redAC = (float)(redMax - redMin);

    // Reject weak/garbage windows so noise never reaches the output.
    if(irDC < SPO2_MIN_DC || irAC < SPO2_MIN_IR_AC || redDC <= 0.0f || redAC <= 0.0f)
        return;

    float R = (redAC / redDC) / (irAC / irDC);
    Serial.printf("SPO2_CALC: irDC=%.0f irAC=%.0f redDC=%.0f redAC=%.0f R=%.3f\n",
                  irDC, irAC, redDC, redAC, R);
    if(R < 0.3f || R > 1.3f) return;          // outside plausible range

    float raw = 104.0f - 17.0f * R;           // standard SpO2 calibration
    if(raw > 100.0f) raw = 100.0f;
    if(raw < 85.0f)  return;                   // implausible for a healthy child → drop

    if(spo2Smoothed < 1.0f) spo2Smoothed = raw;                       // seed
    else spo2Smoothed = spo2Smoothed * (1.0f - SPO2_EMA_ALPHA)
                        + raw * SPO2_EMA_ALPHA;                       // smooth

    Features.spo2 = spo2Smoothed;
}

/**************************************************************
 * Reset Processing
 **************************************************************/
static void ResetMAX30102(void)
{
    Features.hr_mean =
        0;

    Features.hrv =
        0;

    Features.rmssd =
        0;

    SpO2_Reset();

    PPG_Filter_Init();
    PeakDetector_Init();
    RRProcessor_Init();
}

/**************************************************************
 * Init
 **************************************************************/
void MAX30102_Init(void)
{
    if(!MaxSensor.begin(Wire, I2C_SPEED_STANDARD))
    {
        Serial.println(
            "MAX30102 not found"
        );

        return;
    }

    MaxSensor.setup(
        0x40,
        4,
        2,
        100,
        411,
        16384
    );

    MaxSensor.setPulseAmplitudeRed(
        0x30
    );

    MaxSensor.setPulseAmplitudeIR(
        0x40
    );

    MaxSensor.setPulseAmplitudeGreen(
        0
    );

    ResetMAX30102();

    Serial.println(
        "MAX30102 Initialized"
    );
}

/**************************************************************
 * Task
 **************************************************************/
void MAX30102_Task(void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    while(true)
    {
        MaxSensor.check();

        while(MaxSensor.available())
        {
            long ir =
                MaxSensor.getFIFOIR();

            long red =
                MaxSensor.getFIFORed();

            static uint32_t irDbg = 0;
            if(++irDbg % 50 == 0)
            {
                Serial.print("IR_RAW: ");
                Serial.println(ir);
            }

            if(!fingerPresent && ir > FINGER_ON_THRESHOLD)
            {
                fingerPresent =
                    true;

                fingerOffCount = 0;

                ResetMAX30102();
            }

            if(fingerPresent && ir < FINGER_OFF_THRESHOLD)
            {
                // Debounce: a brief dip (finger shifting) should NOT wipe the
                // beat pipeline — only a sustained absence counts as removal.
                fingerOffCount++;

                if(fingerOffCount >= FINGER_OFF_DEBOUNCE)
                {
                    fingerPresent =
                        false;

                    fingerOffCount = 0;

                    ResetMAX30102();
                }

                // Skip this (poor) sample either way, but keep the accumulated
                // beats through a momentary dip.
                MaxSensor.nextSample();

                continue;
            }

            if(fingerPresent)
                fingerOffCount = 0;   // signal recovered — clear the debounce

            if(!fingerPresent)
            {
                MaxSensor.nextSample();

                continue;
            }

            // Finger is present — update SpO2 from both channels.
            SpO2_Update(ir, red);

            float ppg =
                PPG_Filter_Update(
                    ir
                );

            PeakResult_t peak =
                PeakDetector_Update(
                    ppg
                );

            RRFeatures_t rrFeatures =
                RRProcessor_Update(
                    peak.beat_detected
                );

            Features.hr_mean =
                rrFeatures.hr_mean;

            Features.hrv =
                rrFeatures.hrv;

            Features.rmssd =
                rrFeatures.rmssd;

            MaxSensor.nextSample();
        }

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(10)
        );
    }
}