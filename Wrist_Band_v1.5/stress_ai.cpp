#include <Arduino.h>

#include "features.h"
#include "stress_ai.h"
#include "aegis_model.h"
#include "baseline.h"

#define STRESS_WINDOW_SIZE      6
#define STRESS_TRIGGER_COUNT    3   // demo-sensitive: 3-of-6 (was 4) flips faster

/* Activity gate: an elevated heart rate only counts as STRESS when the child
 * is at REST. If the accelerometer shows movement, a high HR is just physical
 * activity (running, playing) — not stress — so the reading is forced to
 * NOT-stress. At rest acc_std ~ 0.02 and acc_max ~ 10 (gravity); during
 * movement acc_std and acc_max rise well above these. */
#define MOVEMENT_ACC_STD_THRESHOLD   1.0f
#define MOVEMENT_ACC_MAX_THRESHOLD   13.0f

/**************************************************************
 * Personal baseline tables (14 features, model order)
 *
 * For features we have a personal baseline for, the live reading
 * is converted to a personal z-score and re-mapped into the
 * model's WESAD scale, so the model judges the child against
 * THEIR OWN normal instead of generic dataset averages.
 *
 * Features without a baseline keep the model's default scaling.
 *
 * Index order:
 *  0 hr_mean   1 hrv       2 rmssd
 *  3 eda_mean  4 eda_std   5 eda_max   6 eda_slope  7 spike_count
 *  8 temp_mean 9 temp_std 10 temp_slope
 * 11 acc_mean 12 acc_std  13 acc_max
 **************************************************************/
static const bool PERSONALIZE[14] =
{
    true,  false, false,
    true,  false, true,  false, false,
    true,  false, false,
    true,  false, true
};

static const float BASE_MEAN[14] =
{
    BASE_HR_MEAN,   0.0f, 0.0f,
    BASE_GSR_MEAN,  0.0f, BASE_GSR_MEAN, 0.0f, 0.0f,
    BASE_TEMP_MEAN, 0.0f, 0.0f,
    BASE_ACC_MEAN,  0.0f, BASE_ACC_MEAN
};

static const float BASE_STD[14] =
{
    BASE_HR_STD,   1.0f, 1.0f,
    BASE_GSR_STD,  1.0f, BASE_GSR_STD, 1.0f, 1.0f,
    BASE_TEMP_STD, 1.0f, 1.0f,
    BASE_ACC_STD,  1.0f, BASE_ACC_STD
};

static uint8_t predictionWindow[STRESS_WINDOW_SIZE];

static uint8_t predictionIndex = 0;
static uint8_t predictionCount = 0;

static void AddPrediction(
    uint8_t prediction)
{
    predictionWindow[predictionIndex] =
        prediction;

    predictionIndex++;

    if(predictionIndex >= STRESS_WINDOW_SIZE)
        predictionIndex = 0;

    if(predictionCount < STRESS_WINDOW_SIZE)
        predictionCount++;
}

static uint8_t CountStress(void)
{
    uint8_t count = 0;

    for(int i=0;i<predictionCount;i++)
    {
        if(predictionWindow[i] == 1)
            count++;
    }

    return count;
}

#define VIBRATOR_PIN 13
#define MAX_VIBRATE_MS 5000   // cap each buzz so a stuck/sustained stress flag can't vibrate endlessly

static unsigned long vibrateStartMs = 0;   // when the current buzz started
static uint8_t       vibPrevAlert   = 0;   // previous stress_alert, for rising-edge detection

void StressAI_Init(void)
{
    pinMode(VIBRATOR_PIN, OUTPUT);
    digitalWrite(VIBRATOR_PIN, LOW);

    Features.stress_state = 0;
    Features.stress_alert = 0;

    predictionIndex = 0;
    predictionCount = 0;

    for(int i=0;i<STRESS_WINDOW_SIZE;i++)
        predictionWindow[i] = 0;
}

void StressAI_Task(
    void *pvParameters)
{
    TickType_t xLastWakeTime =
        xTaskGetTickCount();

    while(true)
    {
        /* Validity guard:
         * Only run the model when every core sensor has a real,
         * in-range reading. A 0 or out-of-range value (sensor still
         * warming up, or no skin contact on the HR sensor) would turn
         * into a huge fake deviation after baseline scaling and trip a
         * false STRESS alert. In that case we hold the last good state
         * and skip this cycle instead of feeding garbage to the model. */
        bool sensorsValid =
            (Features.hr_mean   >= 30.0f  && Features.hr_mean   <= 220.0f) &&
            (Features.temp_mean >= 20.0f  && Features.temp_mean <= 45.0f)  &&
            (Features.gsr_mean  >  0.0f   && Features.gsr_mean   < 4096.0f) &&
            (Features.acc_mean  >  0.5f   && Features.acc_mean   < 60.0f);

        if(!sensorsValid)
        {
            // No valid reading (e.g. finger off the HR sensor) — we can't
            // assert stress, so never leave the wrist buzzing here.
            digitalWrite(VIBRATOR_PIN, LOW);

            vTaskDelayUntil(
                &xLastWakeTime,
                pdMS_TO_TICKS(2000)
            );

            continue;
        }

        float raw_features[14] =
        {
            Features.hr_mean,
            Features.hrv,
            Features.rmssd,

            Features.gsr_mean,
            Features.gsr_std,
            Features.gsr_max,
            Features.gsr_slope,
            (float)Features.gsr_spike_count,

            Features.temp_mean,
            Features.temp_std,
            Features.temp_slope,

            Features.acc_mean,
            Features.acc_std,
            Features.acc_max
        };

        /* Apply the personal baseline before the model runs.
         * personal z = (reading - child_mean) / child_std
         * re-map into the model's own scale so its internal
         * scaler reproduces exactly that personal z-score. */
        float personalized[14];

        for(int i=0;i<14;i++)
        {
            if(PERSONALIZE[i] && BASE_STD[i] > 0.0001f)
            {
                float z =
                    (raw_features[i] - BASE_MEAN[i])
                    / BASE_STD[i];

                personalized[i] =
                    SCALER_MEANS[i] + z * SCALER_STDS[i];
            }
            else
            {
                personalized[i] =
                    raw_features[i];
            }
        }

        int result =
            aegis_predict(
                personalized
            );

        /* Activity gate — only count stress when the child is at rest.
         * If the accelerometer shows movement, an elevated HR is exercise,
         * not stress, so this reading is forced to NOT-stress (0). */
        bool moving =
            (Features.acc_std > MOVEMENT_ACC_STD_THRESHOLD) ||
            (Features.acc_max > MOVEMENT_ACC_MAX_THRESHOLD);

        if(moving && result == 1)
        {
            Serial.println("Activity detected (moving) - stress suppressed");
            result = 0;
        }

        // Demo insurance: sustained elevated heart rate while at rest = stress,
        // even if the model is unsure (GSR/temp may not rise in a quick demo).
        if(!moving && Features.hr_mean > (BASE_HR_MEAN + 5.0f))
            result = 1;

        Features.stress_state =
            result;

        AddPrediction(
            result
        );

        /* Demo-sensitive trigger: don't wait for the full 6-reading window —
         * as soon as TRIGGER_COUNT (3) of the readings so far are STRESS,
         * raise the alert. With the 10s cycle that's ~30s instead of ~60s. */
        if(predictionCount >= STRESS_TRIGGER_COUNT &&
           CountStress() >= STRESS_TRIGGER_COUNT)
        {
            Features.stress_alert =
                1;
        }
        else
        {
            Features.stress_alert =
                0;
        }

        // Demo insurance: high HR at rest fires the alert immediately,
        // no need to wait for the 3-of-6 window.
        if(!moving && Features.hr_mean > (BASE_HR_MEAN + 5.0f))
            Features.stress_alert = 1;

        // Buzz the wrist when a stress alert STARTS, but cap it to
        // MAX_VIBRATE_MS so a sustained/stuck alert can't vibrate endlessly.
        if(Features.stress_alert == 1 && vibPrevAlert == 0)
            vibrateStartMs = millis();   // new episode — (re)start the buzz timer
        vibPrevAlert = Features.stress_alert;

        bool buzz = (Features.stress_alert == 1) &&
                    (millis() - vibrateStartMs < MAX_VIBRATE_MS);
        digitalWrite(VIBRATOR_PIN, buzz ? HIGH : LOW);

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(10000)
        );
    }
}