// firmware/src/inference.cpp
#include "inference.h"
#include "aegis_model.h"

#include <math.h>
#include <string.h>

// ── Feature indices (must match training order exactly) ───────────────────────
static constexpr int F_HR_MEAN     =  0;
static constexpr int F_HRV         =  1;
static constexpr int F_RMSSD       =  2;
static constexpr int F_EDA_MEAN    =  3;
static constexpr int F_EDA_STD     =  4;
static constexpr int F_EDA_MAX     =  5;
static constexpr int F_EDA_SLOPE   =  6;
static constexpr int F_SPIKE_COUNT =  7;
static constexpr int F_TEMP_MEAN   =  8;
static constexpr int F_TEMP_STD    =  9;
static constexpr int F_TEMP_SLOPE  = 10;
static constexpr int F_ACC_MEAN    = 11;
static constexpr int F_ACC_STD     = 12;
static constexpr int F_ACC_MAX     = 13;
static constexpr int NUM_FEATURES  = 14;

// ── Sliding window of raw model outputs ──────────────────────────────────────
static constexpr int VOTE_WINDOW   = 6;
static constexpr int STRESS_THRESHOLD = 4;  // 4 of 6 votes = STRESS alert

static int  s_votes[VOTE_WINDOW] = {};
static int  s_voteHead           = 0;
static int  s_voteCount          = 0;

// ── Math helpers ──────────────────────────────────────────────────────────────

static float mean6(const float* v, int n)
{
    float s = 0.0f;
    for (int i = 0; i < n; i++) s += v[i];
    return (n > 0) ? s / n : 0.0f;
}

static float std6(const float* v, int n, float mu)
{
    if (n < 2) return 0.0f;
    float s = 0.0f;
    for (int i = 0; i < n; i++) { float d = v[i] - mu; s += d * d; }
    return sqrtf(s / n);
}

// Linear regression slope for indices 0..n-1, values in v[].
// For n=6: denominator = n*sum_x2 - sum_x^2 = 6*55 - 15^2 = 105.
static float slope6(const float* v, int n)
{
    if (n < 2) return 0.0f;
    float sum_x = 0, sum_y = 0, sum_xy = 0, sum_x2 = 0;
    for (int i = 0; i < n; i++) {
        float xi = static_cast<float>(i);
        sum_x  += xi;
        sum_y  += v[i];
        sum_xy += xi * v[i];
        sum_x2 += xi * xi;
    }
    float denom = n * sum_x2 - sum_x * sum_x;
    if (fabsf(denom) < 1e-9f) return 0.0f;
    return (n * sum_xy - sum_x * sum_y) / denom;
}

// Z-score with epsilon guard against zero std.
static float zscore(float x, float mu, float sigma)
{
    return (sigma < 1e-6f) ? 0.0f : (x - mu) / sigma;
}

// ── Feature extraction ────────────────────────────────────────────────────────

static void extractFeatures(const SensorReading* w, int n,
                             const CalibrationProfile* prof,
                             float features[NUM_FEATURES])
{
    // Collect channel arrays
    static float hr_arr[SENSOR_BUFFER_SIZE];
    static float gsr_arr[SENSOR_BUFFER_SIZE];
    static float temp_arr[SENSOR_BUFFER_SIZE];
    static float acc_arr[SENSOR_BUFFER_SIZE];
    static float rr_arr[SENSOR_BUFFER_SIZE];   // RR intervals (ms)

    for (int i = 0; i < n; i++) {
        hr_arr[i]   = w[i].hr   > 0.0f ? w[i].hr   : prof->hr_mean;
        gsr_arr[i]  = w[i].gsr  > 0.0f ? w[i].gsr  : prof->gsr_mean;
        temp_arr[i] = w[i].temp > 0.0f ? w[i].temp : prof->temp_mean;
        acc_arr[i]  = w[i].acc_mag;
        rr_arr[i]   = (hr_arr[i] > 0.0f) ? 60000.0f / hr_arr[i] : 800.0f;
    }

    // HR mean
    float hr_mu   = mean6(hr_arr, n);
    float gsr_mu  = mean6(gsr_arr, n);
    float gsr_sig = std6(gsr_arr, n, gsr_mu);
    float gsr_max = gsr_arr[0];
    for (int i = 1; i < n; i++) if (gsr_arr[i] > gsr_max) gsr_max = gsr_arr[i];
    float temp_mu  = mean6(temp_arr, n);
    float acc_mu   = mean6(acc_arr, n);
    float acc_sig  = std6(acc_arr, n, acc_mu);
    float acc_max  = acc_arr[0];
    for (int i = 1; i < n; i++) if (acc_arr[i] > acc_max) acc_max = acc_arr[i];

    // HRV: std of RR intervals
    float rr_mu  = mean6(rr_arr, n);
    float hrv    = std6(rr_arr, n, rr_mu);

    // RMSSD: sqrt(mean(successive_diff²))
    float rmssd = 0.0f;
    if (n > 1) {
        float sumSq = 0.0f;
        for (int i = 0; i < n - 1; i++) {
            float d = rr_arr[i + 1] - rr_arr[i];
            sumSq += d * d;
        }
        rmssd = sqrtf(sumSq / (n - 1));
    }

    // EDA slope, temp slope
    float eda_slope  = slope6(gsr_arr, n);
    float temp_slope = slope6(temp_arr, n);

    // Spike count: GSR readings > gsr_mu + 1.5*gsr_sig
    int spikes = 0;
    float spike_thresh = gsr_mu + 1.5f * gsr_sig;
    for (int i = 0; i < n; i++) if (gsr_arr[i] > spike_thresh) spikes++;

    // Build raw feature vector
    float raw[NUM_FEATURES];
    raw[F_HR_MEAN]     = hr_mu;
    raw[F_HRV]         = hrv;
    raw[F_RMSSD]       = rmssd;
    raw[F_EDA_MEAN]    = gsr_mu;
    raw[F_EDA_STD]     = gsr_sig;
    raw[F_EDA_MAX]     = gsr_max;
    raw[F_EDA_SLOPE]   = eda_slope;
    raw[F_SPIKE_COUNT] = static_cast<float>(spikes);
    raw[F_TEMP_MEAN]   = temp_mu;
    raw[F_TEMP_STD]    = std6(temp_arr, n, temp_mu);
    raw[F_TEMP_SLOPE]  = temp_slope;
    raw[F_ACC_MEAN]    = acc_mu;
    raw[F_ACC_STD]     = acc_sig;
    raw[F_ACC_MAX]     = acc_max;

    // Z-score normalise per feature using calibration profile
    features[F_HR_MEAN]     = zscore(raw[F_HR_MEAN],   prof->hr_mean,   prof->hr_std);
    features[F_HRV]         = zscore(raw[F_HRV],       0.0f, 1.0f);   // no baseline → pass-through
    features[F_RMSSD]       = zscore(raw[F_RMSSD],     0.0f, 1.0f);
    features[F_EDA_MEAN]    = zscore(raw[F_EDA_MEAN],  prof->gsr_mean, prof->gsr_std);
    features[F_EDA_STD]     = zscore(raw[F_EDA_STD],   0.0f, 1.0f);
    features[F_EDA_MAX]     = zscore(raw[F_EDA_MAX],   prof->gsr_mean, prof->gsr_std);
    features[F_EDA_SLOPE]   = raw[F_EDA_SLOPE];   // slope is already relative
    features[F_SPIKE_COUNT] = raw[F_SPIKE_COUNT]; // count, no normalisation needed
    features[F_TEMP_MEAN]   = zscore(raw[F_TEMP_MEAN], prof->temp_mean, prof->temp_std);
    features[F_TEMP_STD]    = zscore(raw[F_TEMP_STD],  0.0f, 1.0f);
    features[F_TEMP_SLOPE]  = raw[F_TEMP_SLOPE];
    features[F_ACC_MEAN]    = zscore(raw[F_ACC_MEAN],  prof->acc_mean,  prof->acc_std);
    features[F_ACC_STD]     = zscore(raw[F_ACC_STD],   0.0f, 1.0f);
    features[F_ACC_MAX]     = zscore(raw[F_ACC_MAX],   prof->acc_mean,  prof->acc_std);
}

// ── Public API ────────────────────────────────────────────────────────────────

StressResult runInference(const SensorReading* window, int windowSize,
                          const CalibrationProfile* profile)
{
    StressResult result = { InferenceState::NORMAL, 0.0f, 0 };
    if (!window || windowSize < SENSOR_BUFFER_SIZE || !profile || !profile->calibrated)
        return result;

    float features[NUM_FEATURES];
    extractFeatures(window, windowSize, profile, features);

    // Run Random Forest
    static Eloquent::ML::Port::RandomForest s_model;
    int prediction = s_model.predict(features);  // 0 = NORMAL, 1 = STRESS

    // Push into sliding vote window
    s_votes[s_voteHead] = prediction;
    s_voteHead = (s_voteHead + 1) % VOTE_WINDOW;
    if (s_voteCount < VOTE_WINDOW) s_voteCount++;

    // Count STRESS votes in filled portion of window
    int stressVotes = 0;
    for (int i = 0; i < s_voteCount; i++) stressVotes += s_votes[i];
    result.windowVotes = stressVotes;
    result.confidence  = (s_voteCount > 0)
                         ? static_cast<float>(stressVotes) / s_voteCount
                         : 0.0f;

    // Determine state
    // Activity filter: high acc relative to baseline + few EDA spikes
    float acc_mu_feat = features[F_ACC_MEAN];  // already z-scored
    int   spikes      = static_cast<int>(features[F_SPIKE_COUNT]);
    // acc_mu_feat > 2.0 means > (baseline + 2σ) after z-scoring
    if (acc_mu_feat > 2.0f && spikes < 2) {
        result.state = InferenceState::PHYSICAL_ACTIVITY;
        return result;
    }

    if (stressVotes >= STRESS_THRESHOLD) {
        result.state = InferenceState::STRESS;
    } else if (stressVotes >= 2) {
        result.state = InferenceState::ELEVATED;
    } else {
        result.state = InferenceState::NORMAL;
    }
    return result;
}
