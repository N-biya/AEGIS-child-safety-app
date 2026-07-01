#ifndef RR_PROCESSOR_H
#define RR_PROCESSOR_H

#include <stdint.h>

typedef struct
{
    float hr_mean;
    float hrv;
    float rmssd;
} RRFeatures_t;

void RRProcessor_Init(void);
RRFeatures_t RRProcessor_Update(bool beat_detected);

#endif