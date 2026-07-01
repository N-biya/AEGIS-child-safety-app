// firmware/src/gsm_sms.cpp
#include "gsm_sms.h"
#include "secrets.h"

#include <HardwareSerial.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

static HardwareSerial s_gsm(1);   // UART1

static constexpr uint32_t GSM_BAUD      = 9600;
static constexpr uint32_t CMD_TIMEOUT   = 5000;   // ms for regular AT commands
static constexpr uint32_t SEND_TIMEOUT  = 30000;  // ms for +CMGS send
static constexpr int      INIT_RETRIES  = 3;
static constexpr int      SMS_MAX_LEN   = 160;

// ── Rate limiter ──────────────────────────────────────────────────────────────
// Max 3 SMS per alert type per 10-minute window.
static constexpr int RATE_WINDOW_MS  = 10 * 60 * 1000;
static constexpr int RATE_MAX        = 3;
static constexpr int ALERT_TYPES     = 8;

static int      s_rateCount[ALERT_TYPES] = {};
static uint32_t s_rateStart[ALERT_TYPES] = {};

static bool rateLimitOK(int alertType)
{
    if (alertType < 0 || alertType >= ALERT_TYPES) return false;
    uint32_t now = millis();
    if ((now - s_rateStart[alertType]) >= static_cast<uint32_t>(RATE_WINDOW_MS)) {
        s_rateStart[alertType] = now;
        s_rateCount[alertType] = 0;
    }
    if (s_rateCount[alertType] >= RATE_MAX) return false;
    s_rateCount[alertType]++;
    return true;
}

// ── AT command helpers ────────────────────────────────────────────────────────

static void gsmFlush()
{
    while (s_gsm.available()) s_gsm.read();
}

static bool gsmWaitFor(const char* expected, uint32_t timeoutMs)
{
    String resp;
    uint32_t start = millis();
    while ((millis() - start) < timeoutMs) {
        while (s_gsm.available()) {
            char c = s_gsm.read();
            resp += c;
            if (resp.indexOf(expected) != -1) return true;
        }
        delay(10);
    }
    return false;
}

static bool gsmCmd(const char* cmd, const char* expectedResp, uint32_t timeoutMs = CMD_TIMEOUT)
{
    gsmFlush();
    s_gsm.println(cmd);
    return gsmWaitFor(expectedResp, timeoutMs);
}

// ── Public API ────────────────────────────────────────────────────────────────

bool initGSM()
{
    s_gsm.begin(GSM_BAUD, SERIAL_8N1, GSM_RX_PIN, GSM_TX_PIN);
    delay(1000);  // modem power-on settling

    for (int attempt = 0; attempt < INIT_RETRIES; attempt++) {
        gsmFlush();
        if (!gsmCmd("AT",          "OK", 2000)) { delay(2000); continue; }
        if (!gsmCmd("AT+CMGF=1",   "OK"))       { delay(2000); continue; }
        if (!gsmCmd("AT+CSCS=\"GSM\"", "OK"))   { delay(2000); continue; }
        // Check signal quality — proceed even if weak
        gsmCmd("AT+CSQ", "+CSQ");
#if DEBUG_MODE
        Serial.println("[GSM] init OK");
#endif
        return true;
    }
#if DEBUG_MODE
    Serial.println("[GSM] init FAIL after retries");
#endif
    return false;
}

bool sendSMS(const char* phone, const char* message)
{
    if (!phone || !message) return false;

    char truncated[SMS_MAX_LEN + 1];
    strncpy(truncated, message, SMS_MAX_LEN);
    truncated[SMS_MAX_LEN] = '\0';

    // AT+CMGS="<phone>"
    char atCmd[64];
    snprintf(atCmd, sizeof(atCmd), "AT+CMGS=\"%s\"", phone);
    gsmFlush();
    s_gsm.println(atCmd);

    // Wait for '>' prompt
    if (!gsmWaitFor(">", CMD_TIMEOUT)) {
#if DEBUG_MODE
        Serial.println("[GSM] No > prompt");
#endif
        return false;
    }

    // Send message body followed by Ctrl-Z (0x1A)
    s_gsm.print(truncated);
    s_gsm.write(0x1A);

    // Wait for +CMGS: or ERROR
    bool sent = gsmWaitFor("+CMGS:", SEND_TIMEOUT);
#if DEBUG_MODE
    Serial.printf("[GSM] sendSMS to %s: %s\n", phone, sent ? "OK" : "FAIL");
#endif
    return sent;
}

void sendAlertSMS(const char* firstName, const char* status,
                  float lat, float lng, int alertType)
{
    if (!rateLimitOK(alertType)) return;

    // Build time string from millis (wall clock not available without RTC,
    // so use elapsed millis as HH:MM and a placeholder date).
    uint32_t totalSec  = millis() / 1000;
    uint32_t hours     = (totalSec / 3600) % 24;
    uint32_t mins      = (totalSec / 60)   % 60;

    // Build location string.  Coordinates logged only in debug.
    char locBuf[32];
    snprintf(locBuf, sizeof(locBuf), "%.4f,%.4f", lat, lng);

    char msgBuf[SMS_MAX_LEN + 1];
    snprintf(msgBuf, sizeof(msgBuf),
             "AEGIS ALERT\nChild: %.20s\nStatus: %.20s\nLoc: %s\nTime: %02lu:%02lu",
             firstName, status, locBuf,
             static_cast<unsigned long>(hours),
             static_cast<unsigned long>(mins));

    const char* phones[] = { PARENT_PHONE_1, PARENT_PHONE_2, PARENT_PHONE_3 };
    for (const char* ph : phones) {
        if (ph && strlen(ph) > 3) {
            sendSMS(ph, msgBuf);
        }
    }
}

int getSignalQuality()
{
    gsmFlush();
    s_gsm.println("AT+CSQ");
    String resp;
    uint32_t start = millis();
    while ((millis() - start) < CMD_TIMEOUT) {
        while (s_gsm.available()) resp += static_cast<char>(s_gsm.read());
        if (resp.indexOf("+CSQ:") != -1) break;
        delay(10);
    }
    int idx = resp.indexOf("+CSQ:");
    if (idx == -1) return 99;
    int rssi = resp.substring(idx + 5).toInt();
    return rssi;
}

bool isGSMReady()
{
    return gsmCmd("AT", "OK", 2000);
}
