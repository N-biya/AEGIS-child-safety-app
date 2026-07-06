#ifndef FEATURES_H
#define FEATURES_H

#include <stdint.h>

typedef struct
{
    /**************************************************************
     * Temperature Features
     **************************************************************/
    float temp_mean;
    float temp_std;
    float temp_slope;

    /**************************************************************
     * Motion Features
     **************************************************************/
    float acc_mean;
    float acc_std;
    float acc_max;

    /**************************************************************
     * GSR Features
     **************************************************************/
    float gsr_mean;
    float gsr_std;
    float gsr_max;
    float gsr_slope;

    uint32_t gsr_spike_count;

    /**************************************************************
    * MAX30102 Features
    **************************************************************/
    float hr_mean;
    float hrv;
    float rmssd;
    float spo2;

    /**************************************************************
    * GPS / Location
    **************************************************************/
    double  lat;
    double  lng;
    uint8_t gps_fix;     // 1 = valid GPS fix available

    // Parent's phone location, pushed up by the app. In SIMULATE_GPS demo
    // mode the band uses this as its own position so it mirrors the phone
    // (a "current location" safe zone then never false-alarms).
    double  phone_lat;
    double  phone_lng;
    uint8_t phone_loc_valid;  // 1 = a phone location has been received

    /**************************************************************
    * AI Features
    **************************************************************/
    uint8_t stress_state;
    uint8_t stress_alert;

} FeatureVector_t;

extern FeatureVector_t Features;

#endif