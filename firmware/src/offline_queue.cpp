// firmware/src/offline_queue.cpp
//
// Storage: NDJSON (one JSON object per line) in /data/offline_queue.json.
// Each line: { "ts":<millis>, "type":"vitals", "data":"<b64-encrypted>", "hmac":"<hex>" }
// FIFO eviction at 288 entries.  48-hour pruning on boot.
//
#include "offline_queue.h"
#include "crypto_utils.h"
#include "wifi_firebase.h"
#include "secrets.h"

#include <SPIFFS.h>
#include <ArduinoJson.h>
#include <mbedtls/md.h>
#include <string.h>

static constexpr const char* QUEUE_PATH = "/data/offline_queue.json";

// ── HMAC-SHA256 helper ────────────────────────────────────────────────────────

static bool computeHMAC(const uint8_t* data, size_t dataLen,
                         char hexOut[65])  // 32 bytes × 2 hex + NUL
{
    uint8_t key[AES_KEY_BYTES];
    if (!cryptoGetKey(key)) return false;

    uint8_t mac[32];
    mbedtls_md_context_t ctx;
    mbedtls_md_init(&ctx);
    const mbedtls_md_info_t* info = mbedtls_md_info_from_type(MBEDTLS_MD_SHA256);
    int rc = mbedtls_md_setup(&ctx, info, 1);
    if (rc == 0) rc = mbedtls_md_hmac_starts(&ctx, key, AES_KEY_BYTES);
    if (rc == 0) rc = mbedtls_md_hmac_update(&ctx, data, dataLen);
    if (rc == 0) rc = mbedtls_md_hmac_finish(&ctx, mac);
    mbedtls_md_free(&ctx);
    explicit_bzero(key, sizeof(key));
    if (rc != 0) return false;

    for (int i = 0; i < 32; i++) snprintf(hexOut + i * 2, 3, "%02x", mac[i]);
    hexOut[64] = '\0';
    return true;
}

// ── File helpers ──────────────────────────────────────────────────────────────

// Count newlines in the queue file.
static int countLines()
{
    if (!SPIFFS.exists(QUEUE_PATH)) return 0;
    File f = SPIFFS.open(QUEUE_PATH, FILE_READ);
    if (!f) return 0;
    int count = 0;
    while (f.available()) {
        char c = f.read();
        if (c == '\n') count++;
    }
    f.close();
    return count;
}

// Drop the first N lines of the queue file (FIFO eviction).
static void dropFirstLines(int n)
{
    if (n <= 0) return;
    static uint8_t s_lineBuf[512];
    File src = SPIFFS.open(QUEUE_PATH, FILE_READ);
    File tmp = SPIFFS.open("/data/oq_tmp.json", FILE_WRITE);
    if (!src || !tmp) { if (src) src.close(); if (tmp) tmp.close(); return; }

    int skipped = 0;
    while (src.available()) {
        int len = src.readBytesUntil('\n', reinterpret_cast<char*>(s_lineBuf),
                                      sizeof(s_lineBuf) - 1);
        if (len <= 0) break;
        s_lineBuf[len] = '\0';
        if (skipped < n) { skipped++; continue; }
        tmp.write(s_lineBuf, len);
        tmp.write('\n');
    }
    src.close();
    tmp.close();
    SPIFFS.remove(QUEUE_PATH);
    SPIFFS.rename("/data/oq_tmp.json", QUEUE_PATH);
}

// ── Public API ────────────────────────────────────────────────────────────────

bool enqueueReading(const String& jsonPayload, const char* entryType)
{
    // Evict oldest if at capacity
    int current = countLines();
    if (current >= QUEUE_MAX_ENTRIES) dropFirstLines(1);

    // Encrypt payload
    String enc = encryptString(jsonPayload);
    if (enc.isEmpty()) return false;

    // HMAC over the encrypted bytes
    char hmac[65];
    if (!computeHMAC(reinterpret_cast<const uint8_t*>(enc.c_str()), enc.length(), hmac))
        return false;

    // Serialise entry as single-line JSON
    JsonDocument doc;
    doc["ts"]   = millis();
    doc["type"] = entryType;
    doc["data"] = enc;
    doc["hmac"] = hmac;
    String line;
    serializeJson(doc, line);

    File f = SPIFFS.open(QUEUE_PATH, FILE_APPEND);
    if (!f) return false;
    f.println(line);
    f.close();
    return true;
}

int flushQueue()
{
    if (!SPIFFS.exists(QUEUE_PATH)) return 0;
    File f = SPIFFS.open(QUEUE_PATH, FILE_READ);
    if (!f) return 0;

    static char s_line[2048];
    int flushed = 0;
    int batch   = 0;

    // Collect lines
    static String s_remaining;
    s_remaining = "";

    while (f.available()) {
        int len = f.readBytesUntil('\n', s_line, sizeof(s_line) - 1);
        if (len <= 0) break;
        s_line[len] = '\0';

        // Verify HMAC before upload
        JsonDocument doc;
        if (deserializeJson(doc, s_line) != DeserializationError::Ok) continue;
        const char* encData = doc["data"] | "";
        const char* storedHmac = doc["hmac"] | "";
        char computed[65];
        if (!computeHMAC(reinterpret_cast<const uint8_t*>(encData), strlen(encData), computed))
            continue;
        if (memcmp(computed, storedHmac, 64) != 0) {
#if DEBUG_MODE
            Serial.println("[QUEUE] HMAC mismatch — dropping entry");
#endif
            continue;  // tampered or corrupt, discard
        }

        // Decrypt and upload
        String plain = decryptString(String(encData));
        if (plain.isEmpty()) { s_remaining += s_line; s_remaining += '\n'; continue; }

        const char* type = doc["type"] | "vitals";
        bool ok = syncOfflineEntry(plain, type);
        if (ok) {
            flushed++;
            batch++;
        } else {
            s_remaining += s_line;
            s_remaining += '\n';
        }

        if (batch >= 10) break; // upload in batches of 10
    }

    // Append remaining lines (not yet uploaded) after current file position
    while (f.available()) {
        int len = f.readBytesUntil('\n', s_line, sizeof(s_line) - 1);
        if (len <= 0) break;
        s_line[len] = '\0';
        s_remaining += s_line;
        s_remaining += '\n';
    }
    f.close();

    // Rewrite file with remaining entries
    File out = SPIFFS.open(QUEUE_PATH, FILE_WRITE);
    if (out) { out.print(s_remaining); out.close(); }

    return flushed;
}

void pruneOldEntries()
{
    if (!SPIFFS.exists(QUEUE_PATH)) return;
    File f = SPIFFS.open(QUEUE_PATH, FILE_READ);
    if (!f) return;

    static char s_line[2048];
    static String s_kept;
    s_kept = "";
    uint32_t now = millis();

    while (f.available()) {
        int len = f.readBytesUntil('\n', s_line, sizeof(s_line) - 1);
        if (len <= 0) break;
        s_line[len] = '\0';

        JsonDocument doc;
        if (deserializeJson(doc, s_line) != DeserializationError::Ok) continue;
        uint32_t ts = doc["ts"] | 0U;
        // Keep entries that are within the 48-hour window.
        // millis() wraps at ~49 days; subtraction still correct for reasonable ages.
        uint32_t age = now - ts;
        if (age < QUEUE_MAX_AGE_MS) {
            s_kept += s_line;
            s_kept += '\n';
        }
    }
    f.close();

    File out = SPIFFS.open(QUEUE_PATH, FILE_WRITE);
    if (out) { out.print(s_kept); out.close(); }
}

int getQueueSize()
{
    return countLines();
}
