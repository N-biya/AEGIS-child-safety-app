#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <time.h>
#include <math.h>

#include "features.h"
#include "wifi_firebase.h"
#include "sim_sms.h"
#include "secrets.h"

/**************************************************************
 * State
 **************************************************************/
static String idToken      = "";
static String refreshToken = "";
static String deviceUid    = "";

static unsigned long tokenAcquiredMs = 0;
static const unsigned long TOKEN_LIFETIME_MS = 3000000UL; // ~50 min, refresh before 60

static bool timeReady = false;

/* Geofence (safe zone) cached from the cloud */
static bool   fenceValid  = false;
static double fenceLat    = 0.0;
static double fenceLng    = 0.0;
static double fenceRadius = 0.0;

static unsigned long lastGeofenceRefreshMs = 0;
static unsigned long lastBreachAlertMs     = 0;
static bool          wasOutside            = false;

/**************************************************************
 * Tiny JSON string extractor:  "key":"value"  ->  value
 * (avoids pulling in a JSON library for these known responses)
 **************************************************************/
static String jsonString(const String &src, const char *key)
{
    String pat = String("\"") + key + "\"";
    int i = src.indexOf(pat);
    if(i < 0) return "";
    i += pat.length();

    // skip ':' and any whitespace (handles pretty-printed JSON: "key": "value")
    while(i < (int)src.length())
    {
        char c = src.charAt(i);
        if(c == ':' || c == ' ' || c == '\t' || c == '\n' || c == '\r') { i++; continue; }
        break;
    }

    if(i >= (int)src.length() || src.charAt(i) != '\"') return "";
    i++; // past opening quote

    int j = src.indexOf('\"', i);
    if(j < 0) return "";
    return src.substring(i, j);
}

/* Extract a number that follows a Firestore field key, e.g.
 *   "lat":{"doubleValue":31.52}   or   "radiusMeters":{"integerValue":"200"}
 * Finds the key, then the next "...Value": and reads the number. */
static double jsonNumber(const String &src, const char *key, bool *ok)
{
    if(ok) *ok = false;

    int i = src.indexOf(String("\"") + key + "\"");
    if(i < 0) return 0.0;

    int v = src.indexOf("Value", i);
    if(v < 0) return 0.0;

    int colon = src.indexOf(':', v);
    if(colon < 0) return 0.0;

    int p = colon + 1;
    while(p < (int)src.length() &&
          (src.charAt(p) == ' ' || src.charAt(p) == '\"')) p++;

    int q = p;
    while(q < (int)src.length())
    {
        char c = src.charAt(q);
        if((c >= '0' && c <= '9') || c == '-' || c == '+' ||
           c == '.' || c == 'e' || c == 'E') q++;
        else break;
    }

    if(q == p) return 0.0;
    if(ok) *ok = true;
    return src.substring(p, q).toDouble();
}

/* Great-circle distance between two lat/lng points, in metres. */
static double haversine(double lat1, double lng1, double lat2, double lng2)
{
    const double R = 6371000.0; // earth radius (m)
    double dLat = (lat2 - lat1) * M_PI / 180.0;
    double dLng = (lng2 - lng1) * M_PI / 180.0;
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1 * M_PI / 180.0) * cos(lat2 * M_PI / 180.0) *
               sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/**************************************************************
 * WiFi
 **************************************************************/
static bool connectWiFi(void)
{
    if(WiFi.status() == WL_CONNECTED) return true;

    Serial.print("WiFi connecting to ");
    Serial.println(WIFI_SSID);

    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    for(int i=0; i<40 && WiFi.status() != WL_CONNECTED; i++)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println();

    if(WiFi.status() == WL_CONNECTED)
    {
        Serial.print("WiFi connected, IP: ");
        Serial.println(WiFi.localIP());
        return true;
    }

    Serial.println("WiFi connect FAILED");
    return false;
}

/**************************************************************
 * NTP time (needed for a real ISO-8601 timestamp)
 **************************************************************/
static void syncTime(void)
{
    configTime(0, 0, "pool.ntp.org", "time.nist.gov");

    struct tm tm;
    for(int i=0; i<20; i++)
    {
        if(getLocalTime(&tm, 500) && (tm.tm_year + 1900) > 2023)
        {
            timeReady = true;
            Serial.println("Time synced (NTP)");
            return;
        }
        delay(500);
    }
    Serial.println("NTP sync FAILED (timestamps may be wrong)");
}

static void isoTimestamp(char *buf, size_t n)
{
    time_t now = time(nullptr);
    struct tm tm;
    gmtime_r(&now, &tm);
    strftime(buf, n, "%Y-%m-%dT%H:%M:%SZ", &tm);
}

/**************************************************************
 * Firebase Auth
 **************************************************************/
static bool firebaseSignIn(void)
{
    WiFiClientSecure client;
    client.setInsecure();
    client.setHandshakeTimeout(10);

    HTTPClient http;
    http.setConnectTimeout(8000);
    http.setTimeout(8000);

    String url =
        String("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=")
        + FIREBASE_API_KEY;

    if(!http.begin(client, url)) return false;
    http.useHTTP10(true);   // force non-chunked response (clean getString under TLS)
    http.addHeader("Content-Type", "application/json");

    String body =
        String("{\"email\":\"") + DEVICE_EMAIL +
        "\",\"password\":\"" + DEVICE_PASSWORD +
        "\",\"returnSecureToken\":true}";

    int code = http.POST(body);
    String resp = http.getString();
    http.end();

    Serial.printf("signin: code=%d bodyLen=%d\n", code, resp.length());
    Serial.print("signin HEX[0..24]: ");
    for(int i=0; i<24 && i<(int)resp.length(); i++)
        Serial.printf("%02X ", (uint8_t)resp.charAt(i));
    Serial.println();

    if(code == 200)
    {
        idToken      = jsonString(resp, "idToken");
        refreshToken = jsonString(resp, "refreshToken");
        deviceUid    = jsonString(resp, "localId");
        tokenAcquiredMs = millis();

        Serial.printf("parsed: idTokenLen=%d uid=%s\n", idToken.length(), deviceUid.c_str());
        return idToken.length() > 0;
    }

    Serial.print("Firebase sign-in FAILED, code ");
    Serial.println(code);
    Serial.println(resp);
    return false;
}

static bool firebaseRefresh(void)
{
    if(refreshToken.length() == 0) return firebaseSignIn();

    WiFiClientSecure client;
    client.setInsecure();
    client.setHandshakeTimeout(10);

    HTTPClient http;
    http.setConnectTimeout(8000);
    http.setTimeout(8000);

    String url =
        String("https://securetoken.googleapis.com/v1/token?key=") + FIREBASE_API_KEY;

    if(!http.begin(client, url)) return false;
    http.useHTTP10(true);
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    String body =
        String("grant_type=refresh_token&refresh_token=") + refreshToken;

    int code = http.POST(body);
    String resp = http.getString();
    http.end();

    if(code == 200)
    {
        idToken      = jsonString(resp, "id_token");
        refreshToken = jsonString(resp, "refresh_token");
        tokenAcquiredMs = millis();
        Serial.println("Firebase token refreshed");
        return idToken.length() > 0;
    }

    Serial.print("Token refresh FAILED, code ");
    Serial.println(code);
    return firebaseSignIn();
}

static bool ensureToken(void)
{
    if(idToken.length() == 0) return firebaseSignIn();
    if(millis() - tokenAcquiredMs > TOKEN_LIFETIME_MS) return firebaseRefresh();
    return true;
}

/**************************************************************
 * Vitals upload
 **************************************************************/
static const char* statusString(void)
{
    if(Features.stress_alert) return "STRESS";
    if(Features.stress_state) return "ELEVATED";
    return "NORMAL";
}

static bool uploadVital(void)
{
    char ts[32];
    isoTimestamp(ts, sizeof(ts));

    int    hr       = (int)Features.hr_mean;
    int    spo2     = (int)Features.spo2; // real SpO2 (0 until a valid reading)
    float  gsr      = Features.gsr_mean;
    float  temp     = Features.temp_mean;
    float  movement = Features.acc_std;   // movement proxy
    double lat      = Features.lat;       // real GPS (0 until a fix)
    double lng      = Features.lng;

    char body[640];
    snprintf(body, sizeof(body),
        "{\"fields\":{"
        "\"hr\":{\"integerValue\":\"%d\"},"
        "\"spo2\":{\"integerValue\":\"%d\"},"
        "\"gsr\":{\"doubleValue\":%.3f},"
        "\"temp\":{\"doubleValue\":%.3f},"
        "\"movement\":{\"doubleValue\":%.3f},"
        "\"status\":{\"stringValue\":\"%s\"},"
        "\"lat\":{\"doubleValue\":%.6f},"
        "\"lng\":{\"doubleValue\":%.6f},"
        "\"timestamp\":{\"stringValue\":\"%s\"}"
        "}}",
        hr, spo2, gsr, temp, movement, statusString(), lat, lng, ts);

    WiFiClientSecure client;
    client.setInsecure();
    client.setHandshakeTimeout(10);   // seconds — never hang on TLS

    HTTPClient http;
    http.setConnectTimeout(8000);     // ms
    http.setTimeout(8000);            // ms

    String url =
        String("https://firestore.googleapis.com/v1/projects/") + FIREBASE_PROJECT_ID +
        "/databases/(default)/documents/children/" + CHILD_ID + "/vitals";

    if(!http.begin(client, url)) return false;
    http.useHTTP10(true);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", String("Bearer ") + idToken);

    Serial.printf("Uploading vital... (freeHeap=%u)\n", ESP.getFreeHeap());
    int code = http.POST((uint8_t*)body, strlen(body));
    String resp = http.getString();
    http.end();

    if(code == 200)
    {
        Serial.print("Vital uploaded: HR=");
        Serial.print(hr);
        Serial.print(" status=");
        Serial.println(statusString());
        return true;
    }

    Serial.print("Vital upload FAILED, code ");
    Serial.println(code);
    Serial.println(resp);
    return false;
}

/**************************************************************
 * Geofence — read the parent's safe zone from the child doc.
 * The device account is allowed to READ the child document
 * (it's listed in linkedDevices), so this works under the rules.
 **************************************************************/
static void readGeofence(void)
{
    WiFiClientSecure client;
    client.setInsecure();
    client.setHandshakeTimeout(10);

    HTTPClient http;
    http.setConnectTimeout(8000);
    http.setTimeout(8000);

    String url =
        String("https://firestore.googleapis.com/v1/projects/") + FIREBASE_PROJECT_ID +
        "/databases/(default)/documents/children/" + CHILD_ID;

    if(!http.begin(client, url)) return;
    http.useHTTP10(true);
    http.addHeader("Authorization", String("Bearer ") + idToken);

    int code = http.GET();
    String resp = http.getString();
    http.end();

    if(code != 200) return;

    bool okLat, okLng, okRad;
    double la = jsonNumber(resp, "lat", &okLat);
    double ln = jsonNumber(resp, "lng", &okLng);
    double rd = jsonNumber(resp, "radiusMeters", &okRad);

    if(okLat && okLng && okRad && rd > 0.0)
    {
        fenceLat = la; fenceLng = ln; fenceRadius = rd;
        fenceValid = true;
        Serial.printf("Geofence: center=%.5f,%.5f r=%.0fm\n", fenceLat, fenceLng, fenceRadius);
    }
    else
    {
        fenceValid = false;
        Serial.println("Geofence: not set by parent yet");
    }
}

/* Raise an alert in Firestore (app reads it + can push a notification).
 * type is e.g. "STRESS" or "GEOFENCE". This is the WiFi alert channel —
 * always used, independent of SMS. */
static bool writeAlert(const char *type)
{
    char ts[32];
    isoTimestamp(ts, sizeof(ts));

    char body[640];
    snprintf(body, sizeof(body),
        "{\"fields\":{"
        "\"type\":{\"stringValue\":\"%s\"},"
        "\"timestamp\":{\"stringValue\":\"%s\"},"
        "\"vitals\":{\"mapValue\":{\"fields\":{"
            "\"hr\":{\"integerValue\":\"%d\"},"
            "\"spo2\":{\"integerValue\":\"%d\"}}}},"
        "\"location\":{\"mapValue\":{\"fields\":{"
            "\"lat\":{\"doubleValue\":%.6f},"
            "\"lng\":{\"doubleValue\":%.6f}}}},"
        "\"resolved\":{\"booleanValue\":false}"
        "}}",
        type, ts, (int)Features.hr_mean, (int)Features.spo2, Features.lat, Features.lng);

    WiFiClientSecure client;
    client.setInsecure();
    client.setHandshakeTimeout(10);

    HTTPClient http;
    http.setConnectTimeout(8000);
    http.setTimeout(8000);

    String url =
        String("https://firestore.googleapis.com/v1/projects/") + FIREBASE_PROJECT_ID +
        "/databases/(default)/documents/children/" + CHILD_ID + "/alerts";

    if(!http.begin(client, url)) return false;
    http.useHTTP10(true);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", String("Bearer ") + idToken);

    int code = http.POST((uint8_t*)body, strlen(body));
    http.end();

    Serial.printf("Alert [%s] uploaded -> code %d\n", type, code);
    return code == 200;
}

/* Check current GPS against the safe zone; alert on breach (throttled). */
static void checkGeofence(void)
{
    if(!fenceValid || !Features.gps_fix) return;

    double dist = haversine(Features.lat, Features.lng, fenceLat, fenceLng);
    bool outside = dist > fenceRadius;

    Serial.printf("Geofence: dist=%.0fm radius=%.0fm -> %s\n",
                  dist, fenceRadius, outside ? "OUTSIDE" : "inside");

    if(outside)
    {
        bool justLeft = !wasOutside;
        bool reArm    = (millis() - lastBreachAlertMs) > GEOFENCE_REALERT_MS;

        if(justLeft || reArm)
        {
            writeAlert("GEOFENCE");              // WiFi -> app (primary)
            SIM_SendAlert("LOCATION BREACH");    // SMS backup (no-op if SIM off/no signal)
            lastBreachAlertMs = millis();
        }
    }

    wasOutside = outside;
}

/**************************************************************
 * Public init + task
 **************************************************************/
void WiFiFirebase_Init(void)
{
    if(connectWiFi())
    {
        syncTime();
        firebaseSignIn();
    }
}

void WiFiFirebase_Task(void *pvParameters)
{
    TickType_t xLastWakeTime = xTaskGetTickCount();

    while(true)
    {
        if(connectWiFi())
        {
            if(!timeReady) syncTime();

            if(ensureToken())
            {
                uploadVital();

                // On a fresh STRESS alert (rising edge only): write the cloud
                // alert (WiFi -> app, primary) and try SMS (backup).
                static uint8_t prevStressAlert = 0;
                if(Features.stress_alert == 1 && prevStressAlert == 0)
                {
                    writeAlert("STRESS");
                    SIM_SendAlert("STRESS");
                }
                prevStressAlert = Features.stress_alert;

                // Periodically refresh the parent's safe zone from cloud.
                if(lastGeofenceRefreshMs == 0 ||
                   millis() - lastGeofenceRefreshMs > GEOFENCE_REFRESH_MS)
                {
                    readGeofence();
                    lastGeofenceRefreshMs = millis();
                }

                // Check current location against the safe zone.
                checkGeofence();
            }
        }

        vTaskDelayUntil(
            &xLastWakeTime,
            pdMS_TO_TICKS(UPLOAD_INTERVAL_MS)
        );
    }
}
