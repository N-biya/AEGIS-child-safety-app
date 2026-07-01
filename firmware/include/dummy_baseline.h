// firmware/include/dummy_baseline.h
//
// MVP-only helper: seeds a plausible resting baseline for a primary-school-age
// child so the full z-score + inference pipeline runs immediately, without a
// real 7-day calibration. Kept entirely separate from calibration.cpp so the
// production calibration path stays untouched — delete this module (and its
// call in main.cpp) to require a genuine calibration run.
#pragma once

#include <Arduino.h>

// Toggle: 1 = seed the dummy baseline when no real profile exists (MVP),
//         0 = require a real 7-day calibration. Override in build flags if needed.
#ifndef SEED_DUMMY_BASELINE
#define SEED_DUMMY_BASELINE 1
#endif

/**
 * @brief Write an encrypted dummy CalibrationProfile to SPIFFS in the exact
 *        format loadProfile() expects, then it can be loaded as if real.
 *
 * @return true if the profile was written successfully.
 */
bool seedDummyBaseline();
