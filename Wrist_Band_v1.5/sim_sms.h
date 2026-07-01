#ifndef SIM_SMS_H
#define SIM_SMS_H

/**************************************************************
 * SIM800L SMS alerts
 *
 * Sends an SMS to the parent on stress / geofence breach,
 * including the child's GPS location. Checks for network
 * signal first, so under a jammer (no signal) it simply
 * skips the SMS instead of hanging — the WiFi/app alert
 * remains the primary channel.
 **************************************************************/

void SIM_Init(void);

// Send an alert SMS. reason is e.g. "STRESS" or "LOCATION BREACH".
// Returns true if the SIM accepted the message.
bool SIM_SendAlert(const char *reason);

#endif // SIM_SMS_H
