#ifndef PEAK_DETECTOR_H
#define PEAK_DETECTOR_H

#include <stdint.h>

typedef struct
{
    bool beat_detected;
    float pulse_amplitude;
} PeakResult_t;

void PeakDetector_Init(void);
PeakResult_t PeakDetector_Update(float ppg_value);

#endif