// firmware/include/calibration.h
#pragma once

#include <Arduino.h>

static constexpr int PROFILE_VERSION = 1;
static constexpr int CALIBRATION_SAMPLE_INTERVAL_MS = 10000; // 10 s

/**
 * @brief Per-child baseline statistics stored after 7-day calibration.
 *
 * Privacy: only statistical aggregates are stored, never raw timestamped
 * sensor readings.  GPS coordinates are never included.
 */
struct CalibrationProfile {
    float hr_mean;      ///< Baseline mean HR (BPM)
    float hr_std;       ///< Baseline std-dev HR
    float gsr_mean;     ///< Baseline mean GSR (µS)
    float gsr_std;      ///< Baseline std-dev GSR
    float temp_mean;    ///< Baseline mean skin temperature (°C)
    float temp_std;     ///< Baseline std-dev temperature
    float acc_mean;     ///< Baseline mean acceleration magnitude (m/s²)
    float acc_std;      ///< Baseline std-dev acceleration
    bool  calibrated;   ///< True when full 7-day collection is complete
    int   days_collected;   ///< Number of complete calibration days elapsed
    int   profile_version;  ///< Must match PROFILE_VERSION
    uint32_t created_at;    ///< Unix timestamp of profile creation
};

/**
 * @brief Ingest one SensorReading into the running calibration statistics.
 *
 * Uses Welford's online algorithm — no raw samples are retained.
 * Call once per readAllSensors() during calibration phase.
 * No-op if already calibrated.
 */
void runCalibrationCycle(float hr, float gsr, float temp, float acc_mag);

/**
 * @brief Return true if the 7-day calibration is complete and a profile exists.
 */
bool isCalibrated();

/**
 * @brief Return the number of complete calibration days recorded so far.
 */
int getDaysCollected();

/**
 * @brief Return a pointer to the in-memory CalibrationProfile.
 *
 * The pointer is valid for the lifetime of the firmware.
 * Returns nullptr if not yet calibrated.
 */
const CalibrationProfile* getProfile();

/**
 * @brief Load and decrypt the child profile from SPIFFS.
 *
 * Validates all fields.  Resets in-memory state and returns false if the
 * file is missing, corrupt, or fails decryption.
 *
 * @return true on success.
 */
bool loadProfile();

/**
 * @brief Encrypt and save the current profile to SPIFFS.
 *
 * Only fields defined in CalibrationProfile are persisted — no raw readings.
 *
 * @return true on success.
 */
bool saveProfile();
