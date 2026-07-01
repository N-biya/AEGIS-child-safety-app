// firmware/include/inference.h
#pragma once

#include <Arduino.h>
#include "sensors.h"
#include "calibration.h"

/**
 * @brief Inference output states.
 */
enum class InferenceState : uint8_t {
    NORMAL           = 0,
    ELEVATED         = 1,
    STRESS           = 2,
    PHYSICAL_ACTIVITY = 3
};

/**
 * @brief Result produced by runInference().
 */
struct StressResult {
    InferenceState state;       ///< Classified state
    float          confidence;  ///< windowVotes / windowSize (0.0–1.0)
    int            windowVotes; ///< Count of STRESS votes in sliding window
};

/**
 * @brief Run the on-device Random Forest stress-detection pipeline.
 *
 * Steps performed internally:
 *  1. Extract 14 features from the @p windowSize readings in @p window.
 *  2. Z-score-normalise using the child's CalibrationProfile.
 *  3. Run the micromlgen-exported Random Forest from aegis_model.h.
 *  4. Accumulate result in a 6-prediction sliding window.
 *  5. Apply activity filter: high acc_mag + low spike_count → PHYSICAL_ACTIVITY.
 *  6. Return StressResult with aggregated state and confidence.
 *
 * All inference executes on-device.  No data leaves the ESP32.
 *
 * @param window      Ordered array of SensorReading (oldest first).
 * @param windowSize  Number of entries in @p window (must equal SENSOR_BUFFER_SIZE).
 * @param profile     Calibration profile for Z-score normalisation.
 * @return StressResult; state = NORMAL and confidence = 0 if window invalid.
 */
StressResult runInference(const SensorReading* window, int windowSize,
                          const CalibrationProfile* profile);
