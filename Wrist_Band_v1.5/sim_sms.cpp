#include <Arduino.h>

#include "features.h"
#include "sim_sms.h"
#include "secrets.h"

#if SIM_ENABLED

static HardwareSerial SIMSerial(2);

/* Send one AT command, wait up to timeout ms, return the response. */
static String atCommand(const char *cmd, uint32_t timeout)
{
    while(SIMSerial.available()) SIMSerial.read();   // flush

    SIMSerial.print(cmd);
    SIMSerial.print("\r\n");

    String resp;
    unsigned long start = millis();
    while(millis() - start < timeout)
    {
        while(SIMSerial.available())
            resp += (char)SIMSerial.read();
        if(resp.indexOf("OK") >= 0 || resp.indexOf("ERROR") >= 0) break;
    }
    return resp;
}

void SIM_Init(void)
{
    SIMSerial.begin(SIM_BAUD, SERIAL_8N1, SIM_RX_PIN, SIM_TX_PIN);
    delay(1500);

    atCommand("AT", 1000);          // wake / auto-baud
    atCommand("ATE0", 1000);        // turn off echo
    atCommand("AT+CMGF=1", 1000);   // SMS text mode

    Serial.println("SIM800L initialized");
}

/* True only if the module is registered on a network with usable signal.
 * Under a jammer this returns false, so we skip SMS instead of hanging. */
static bool hasSignal(void)
{
    String csq = atCommand("AT+CSQ", 1500);   // +CSQ: <rssi>,<ber>
    int p = csq.indexOf("+CSQ:");
    if(p < 0) return false;

    int rssi = csq.substring(p + 5).toInt();
    // 99 = unknown/no signal; anything 1..31 is a real reading.
    return (rssi > 0 && rssi != 99);
}

bool SIM_SendAlert(const char *reason)
{
    if(!hasSignal())
    {
        Serial.println("SIM: no network signal (jammed?) - SMS skipped, app alert still sent");
        return false;
    }

    // Build the message with live GPS location.
    char msg[200];
    snprintf(msg, sizeof(msg),
        "AEGIS ALERT\nStatus: %s\nLocation: %.5f, %.5f\nMaps: https://maps.google.com/?q=%.5f,%.5f",
        reason, Features.lat, Features.lng, Features.lat, Features.lng);

    // Address the SMS.
    char cmd[40];
    snprintf(cmd, sizeof(cmd), "AT+CMGS=\"%s\"", PARENT_PHONE);

    while(SIMSerial.available()) SIMSerial.read();
    SIMSerial.print(cmd);
    SIMSerial.print("\r\n");
    delay(500);                       // wait for '>' prompt

    SIMSerial.print(msg);
    SIMSerial.write(26);              // Ctrl+Z = send

    // Wait for confirmation (sending can take several seconds).
    String resp;
    unsigned long start = millis();
    while(millis() - start < 10000)
    {
        while(SIMSerial.available())
            resp += (char)SIMSerial.read();
        if(resp.indexOf("+CMGS") >= 0 || resp.indexOf("OK") >= 0) break;
        if(resp.indexOf("ERROR") >= 0) break;
    }

    bool ok = (resp.indexOf("+CMGS") >= 0 || resp.indexOf("OK") >= 0);
    Serial.printf("SIM: SMS %s (%s)\n", ok ? "SENT" : "FAILED", reason);
    return ok;
}

#else  /* SIM disabled — no-op stubs so the rest of the firmware builds */

void SIM_Init(void) { Serial.println("SIM800L disabled (set SIM_ENABLED=1 + pins)"); }
bool SIM_SendAlert(const char *reason) { (void)reason; return false; }

#endif
