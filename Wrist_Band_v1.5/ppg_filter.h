#ifndef PPG_FILTER_H
#define PPG_FILTER_H

void PPG_Filter_Init(void);
float PPG_Filter_Update(float raw_ir);

#endif