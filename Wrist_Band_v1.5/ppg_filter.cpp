#include "ppg_filter.h"

static float dc_value = 0;
static float ac_value = 0;
static float filtered_value = 0;

void PPG_Filter_Init(void)
{
    dc_value = 0;
    ac_value = 0;
    filtered_value = 0;
}

float PPG_Filter_Update(float raw_ir)
{
    if(dc_value == 0)
    {
        dc_value =
            raw_ir;
    }

    dc_value =
        (0.98f * dc_value)
        +
        (0.02f * raw_ir);

    ac_value =
        raw_ir - dc_value;

    filtered_value =
        (0.70f * filtered_value)
        +
        (0.30f * ac_value);

    return filtered_value;
}