// firmware/include/gsm_sms.h
#pragma once

#include <Arduino.h>

/**
 * @brief Initialise the SIM800L GSM module on UART1.
 *
 * Sends AT, AT+CMGF=1 (text SMS mode), AT+CSCS="GSM", AT+CSQ.
 * Retries 3 times with 2-second delay between attempts.
 *
 * @return true if modem acknowledges all commands.
 */
bool initGSM();

/**
 * @brief Send an SMS via the SIM800L.
 *
 * Enforces a 160-character message limit (truncates if needed).
 * 30-second watchdog: returns false if the modem does not respond.
 * Rate limiter: maximum 3 SMS per alert type per 10-minute window.
 *
 * Privacy: @p childName must contain FIRST NAME ONLY — no surname or DOB.
 * @p phone must be in E.164 format.
 *
 * @param phone     Destination phone number (E.164 format).
 * @param message   Pre-formatted SMS body (≤ 160 chars recommended).
 * @return true on successful send acknowledgement from modem.
 */
bool sendSMS(const char* phone, const char* message);

/**
 * @brief Build and send the AEGIS standard alert SMS to all emergency contacts.
 *
 * Format:
 *   AEGIS ALERT
 *   Child: [firstName]
 *   Status: [status]
 *   Location: [lat],[lng]
 *   Time: [HH:MM DD/MM/YYYY]
 *
 * @param firstName  Child first name only (no surname).
 * @param status     Alert status string (e.g. "STRESS", "GEOFENCE BREACH").
 * @param lat        Latitude decimal degrees.
 * @param lng        Longitude decimal degrees.
 * @param alertType  Integer key for rate-limiting (matches AlertType enum values).
 */
void sendAlertSMS(const char* firstName, const char* status,
                  float lat, float lng, int alertType);

/**
 * @brief Query AT+CSQ and return RSSI value (0–31, 99 = unknown).
 */
int getSignalQuality();

/**
 * @brief Return true if the GSM modem is responsive and registered.
 */
bool isGSMReady();
