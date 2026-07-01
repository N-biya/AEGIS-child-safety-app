// firmware/src/calibration.cpp
#include "calibration.h"
#include "crypto_utils.h"
#include "secrets.h"

#include <SPIFFS.h>
#include <ArduinoJson.h>
#include <math.h>

static constexpr const char* PROFILE_PATH   = "/data/child_profile.json";
static constexpr int         SAMPLES_PER_DAY = 8640; // 86400 s / 10 s interval
static constexpr int         TOTAL_DAYS      = 7;

// ── Welford running state ─────────────────────────────────────────────────────

struct WelfordState {
    uint32_t n    = 0;
    double   mean = 0.0;
    double   M2   = 0.0;

    void update(double x) {
        n++;
        double delta  = x - mean;
        mean         += delta / n;
        double delta2 = x - mean;
        M2           += delta * delta2;
    }
    float getMean()  const { return static_cast<float>(mean); }
    float getStd()   const {
        return (n < 2) ? 0.0f : static_cast<float>(sqrt(M2 / n));
    }
};

static WelfordState s_hr, s_gsr, s_temp, s_acc;
static uint32_t     s_totalSamples = 0;

static CalibrationProfile s_profile = {};

// ── Helpers ───────────────────────────────────────────────────────────────────

static bool validateProfile(const CalibrationProfile& p)
{
    if (p.profile_version != PROFILE_VERSION) return false;
    if (!p.calibrated)                         return false;
    if (p.hr_std   < 0 || p.gsr_std < 0)      return false;
    if (p.temp_std < 0 || p.acc_std < 0)       return false;
    if (p.hr_mean  < 40.0f || p.hr_mean  > 200.0f) return false;
    if (p.temp_mean < 25.0f || p.temp_mean > 40.0f) return false;
    if (p.gsr_mean < 0.1f  || p.gsr_mean > 20.0f)  return false;
    return true;
}

// ── Public API ────────────────────────────────────────────────────────────────

void runCalibrationCycle(float hr, float gsr, float temp, float acc_mag)
{
    if (s_profile.calibrated) return;

    // Only ingest if values are plausible (not error readings)
    if (hr    <= 0.0f || gsr    <= 0.0f) return;
    if (temp  <= 0.0f || acc_mag < 0.0f) return;

    s_hr.update(hr);
    s_gsr.update(gsr);
    s_temp.update(temp);
    s_acc.update(acc_mag);
    s_totalSamples++;

    s_profile.days_collected = static_cast<int>(s_totalSamples / SAMPLES_PER_DAY);

    if (s_totalSamples >= static_cast<uint32_t>(SAMPLES_PER_DAY * TOTAL_DAYS)) {
        s_profile.hr_mean       = s_hr.getMean();
        s_profile.hr_std        = s_hr.getStd();
        s_profile.gsr_mean      = s_gsr.getMean();
        s_profile.gsr_std       = s_gsr.getStd();
        s_profile.temp_mean     = s_temp.getMean();
        s_profile.temp_std      = s_temp.getStd();
        s_profile.acc_mean      = s_acc.getMean();
        s_profile.acc_std       = s_acc.getStd();
        s_profile.calibrated    = true;
        s_profile.days_collected = TOTAL_DAYS;
        s_profile.profile_version = PROFILE_VERSION;
        s_profile.created_at    = static_cast<uint32_t>(millis() / 1000);
        saveProfile();
    }
}

bool isCalibrated()
{
    return s_profile.calibrated;
}

int getDaysCollected()
{
    return s_profile.days_collected;
}

const CalibrationProfile* getProfile()
{
    return s_profile.calibrated ? &s_profile : nullptr;
}

bool loadProfile()
{
    String json = decryptFromSPIFFS(PROFILE_PATH);
    if (json.isEmpty()) return false;

    JsonDocument doc;
    if (deserializeJson(doc, json) != DeserializationError::Ok) {
        // Corrupt file — reset Welford state
        s_hr = {}; s_gsr = {}; s_temp = {}; s_acc = {};
        s_totalSamples = 0;
        s_profile = {};
        return false;
    }

    CalibrationProfile p = {};
    p.hr_mean         = doc["hr_mean"]         | 0.0f;
    p.hr_std          = doc["hr_std"]          | 0.0f;
    p.gsr_mean        = doc["gsr_mean"]        | 0.0f;
    p.gsr_std         = doc["gsr_std"]         | 0.0f;
    p.temp_mean       = doc["temp_mean"]       | 0.0f;
    p.temp_std        = doc["temp_std"]        | 0.0f;
    p.acc_mean        = doc["acc_mean"]        | 0.0f;
    p.acc_std         = doc["acc_std"]         | 0.0f;
    p.calibrated      = doc["calibrated"]      | false;
    p.days_collected  = doc["days_collected"]  | 0;
    p.profile_version = doc["profile_version"] | 0;
    p.created_at      = doc["created_at"]      | 0U;

    if (!validateProfile(p)) {
        s_profile = {};
        return false;
    }

    s_profile = p;
    return true;
}

bool saveProfile()
{
    if (!s_profile.calibrated) return false;

    JsonDocument doc;
    doc["hr_mean"]         = s_profile.hr_mean;
    doc["hr_std"]          = s_profile.hr_std;
    doc["gsr_mean"]        = s_profile.gsr_mean;
    doc["gsr_std"]         = s_profile.gsr_std;
    doc["temp_mean"]       = s_profile.temp_mean;
    doc["temp_std"]        = s_profile.temp_std;
    doc["acc_mean"]        = s_profile.acc_mean;
    doc["acc_std"]         = s_profile.acc_std;
    doc["calibrated"]      = s_profile.calibrated;
    doc["days_collected"]  = s_profile.days_collected;
    doc["profile_version"] = s_profile.profile_version;
    doc["created_at"]      = s_profile.created_at;
    // GPS coordinates intentionally omitted — privacy by design.

    String json;
    serializeJson(doc, json);
    return encryptToSPIFFS(PROFILE_PATH, json);
}
