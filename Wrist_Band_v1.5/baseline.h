#ifndef BASELINE_H
#define BASELINE_H

/**************************************************************
 * Personal resting baseline — AEGIS MVP
 *
 * Measured live from the actual hardware (band at rest) instead
 * of a real 7-day calibration. These are the child's "normal"
 * values; the stress AI compares live readings against them.
 *
 * To recalibrate later, just replace these 8 numbers.
 **************************************************************/

// Heart rate (MAX30102) — confirmed steady ~80 bpm
#define BASE_HR_MEAN     80.0f
#define BASE_HR_STD      6.0f

// GSR / skin sweat (raw ADC units) — measured ~11.3 at rest
#define BASE_GSR_MEAN    11.29f
#define BASE_GSR_STD     2.16f

// Skin/surface temperature (MLX90614, deg C) — measured ~31.8
#define BASE_TEMP_MEAN   31.8f
#define BASE_TEMP_STD    0.54f

// Acceleration magnitude (MPU6050, m/s^2) — measured ~9.87
#define BASE_ACC_MEAN    9.87f
#define BASE_ACC_STD     0.5f

#endif // BASELINE_H
