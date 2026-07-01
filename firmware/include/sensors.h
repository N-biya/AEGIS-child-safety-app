// firmware/include/sensors.h
#pragma once

#include <Arduino.h>

// ── Error-mask bit positions ──────────────────────────────────────────────────
static constexpr uint8_t SENSOR_ERR_HR    = 0x01;
static constexpr uint8_t SENSOR_ERR_SPO2  = 0x02;
static constexpr uint8_t SENSOR_ERR_GSR   = 0x04;
static constexpr uint8_t SENSOR_ERR_TEMP  = 0x08;
static constexpr uint8_t SENSOR_ERR_ACCEL = 0x10;

// ── Validation ranges ─────────────────────────────────────────────────────────
static constexpr float HR_MIN     = 40.0f;
static constexpr float HR_MAX     = 200.0f;
static constexpr float SPO2_MIN   = 70.0f;
static constexpr float SPO2_MAX   = 100.0f;
static constexpr float GSR_MIN    = 0.1f;
static constexpr float GSR_MAX    = 20.0f;
static constexpr float TEMP_MIN   = 25.0f;
static constexpr float TEMP_MAX   = 40.0f;
static constexpr float ACC_MIN    = 0.0f;
static constexpr float ACC_MAX    = 200.0f;

static constexpr int SENSOR_BUFFER_SIZE = 6; ///< Circular buffer depth

/**
 * @brief One fused sensor snapshot.
 *
 * error_mask bits are set for any channel that failed validation.
 * valid is true only when ALL channels within range.
 */
struct SensorReading {
    float    hr;         ///< Heart rate (BPM), 40–200
    float    spo2;       ///< Peripheral oxygen saturation (%), 70–100
    float    gsr;        ///< Galvanic skin response (µS), 0.1–20
    float    temp;       ///< Wrist skin temperature (°C), 25–40
    float    acc_mag;    ///< Acceleration magnitude (m/s²), 0–200
    bool     valid;      ///< All channels validated
    uint8_t  error_mask; ///< Bitmask of failed channels
    uint32_t timestamp;  ///< millis() at sample time
};

/**
 * @brief Initialise all sensors.
 *
 * Starts I²C (MAX30102, MPU6050), OneWire (DS18B20) and configures ADC (GSR).
 * Must be called once before readAllSensors().
 *
 * @return Bitwise health mask: 0x00 = all OK; bits mirror SENSOR_ERR_* for
 *         any sensor that failed initialisation.
 */
uint8_t initSensors();

/**
 * @brief Acquire one SensorReading from all channels.
 *
 * Attempts to read MAX30102, MPU6050, DS18B20 and GSR ADC.
 * Sets error_mask bits for any channel out of range or unresponsive.
 * Also pushes the reading into the module-internal 6-entry circular buffer.
 *
 * @return Populated SensorReading; check valid and error_mask before use.
 */
SensorReading readAllSensors();

/**
 * @brief Return pointer to the internal circular buffer array.
 *
 * Array has SENSOR_BUFFER_SIZE entries ordered oldest-to-newest at the time
 * of the last readAllSensors() call.  Entries before the first full rotation
 * are zero-filled.
 *
 * @param[out] count Number of valid entries currently held (≤ SENSOR_BUFFER_SIZE).
 * @return Pointer to static array; do not free.
 */
const SensorReading* getSensorBuffer(int& count);

/**
 * @brief Build a human-readable sensor health report.
 *
 * @return String describing which sensors are OK / failed.
 */
String getSensorHealthReport();
