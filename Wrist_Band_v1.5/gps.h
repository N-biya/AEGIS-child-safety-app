#ifndef GPS_H
#define GPS_H

/**************************************************************
 * NEO-6M GPS reader (UART, TinyGPS++)
 *
 * Reads location from the GPS module and updates
 * Features.lat / Features.lng / Features.gps_fix.
 **************************************************************/

void GPS_Init(void);
void GPS_Task(void *pvParameters);

#endif // GPS_H
