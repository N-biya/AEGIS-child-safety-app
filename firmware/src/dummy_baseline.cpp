// firmware/src/dummy_baseline.cpp
//
// See dummy_baseline.h. Writes a plausible child resting baseline straight to
// the encrypted profile file so loadProfile() picks it up as a normal profile.
#include "dummy_baseline.h"
#include "calibration.h"     // PROFILE_VERSION, CalibrationProfile field layout
#include "crypto_utils.h"

#include <ArduinoJson.h>

// MUST match PROFILE_PATH in calibration.cpp.
static constexpr const char* PROFILE_PATH = "/data/child_profile.json";

bool seedDummyBaseline()
{
    // Resting baseline measured from the actual hardware MVP (live serial capture,
    // band at rest). Replaces the earlier generic ~8-year-old estimates.
    //   HR   : ~80 bpm resting (steady MAX30102 fingertip reading)
    //   GSR  : ~11.3 raw units at rest (50-sample window mean)
    //   Temp : ~31.8 C skin/surface temperature (MLX90614)
    //   Acc  : ~9.87 m/s2 (= gravity + low-level motion)
    // Note: acc_std measured ~0.02 while dead-still; widened to 0.5 so normal
    // small movements don't blow up the z-score. hr_std is a resting estimate
    // (clean multi-sample HR spread was not captured).
    JsonDocument doc;
    doc["hr_mean"]   = 80.0f;   doc["hr_std"]   = 6.0f;
    doc["gsr_mean"]  = 11.29f;  doc["gsr_std"]  = 2.16f;
    doc["temp_mean"] = 31.8f;   doc["temp_std"] = 0.54f;
    doc["acc_mean"]  = 9.87f;   doc["acc_std"]  = 0.5f;
    doc["calibrated"]      = true;
    doc["days_collected"]  = 7;
    doc["profile_version"] = PROFILE_VERSION;
    doc["created_at"]      = static_cast<uint32_t>(millis() / 1000);

    String json;
    serializeJson(doc, json);
    return encryptToSPIFFS(PROFILE_PATH, json);
}
