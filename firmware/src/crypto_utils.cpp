// firmware/src/crypto_utils.cpp
#include "crypto_utils.h"

#include <SPIFFS.h>
#include <mbedtls/aes.h>
#include <mbedtls/sha256.h>
#include <mbedtls/base64.h>
#include <esp_efuse.h>
#include <esp_system.h>
#include <string.h>

// ── Module-level state ────────────────────────────────────────────────────────

static uint8_t          s_key[AES_KEY_BYTES]  = {};
static bool             s_initialised         = false;
static SemaphoreHandle_t s_mutex              = nullptr;

// Static scratch buffers — protected by s_mutex; never accessed concurrently.
static uint8_t s_padded  [CRYPTO_MAX_PLAIN + AES_BLOCK_BYTES];
static uint8_t s_cipher  [CRYPTO_MAX_PLAIN + AES_BLOCK_BYTES];
// combined = IV(16) + ciphertext
static uint8_t s_combined[AES_IV_BYTES + CRYPTO_MAX_PLAIN + AES_BLOCK_BYTES];
// base64 of combined: ceil(len/3)*4 + 1
static uint8_t s_b64buf  [(sizeof(s_combined) * 4 / 3) + 8];

// ── PKCS#7 helpers ────────────────────────────────────────────────────────────

static size_t pkcs7Pad(const uint8_t* in, size_t inLen,
                        uint8_t* out, size_t outMax)
{
    uint8_t pad = AES_BLOCK_BYTES - (inLen % AES_BLOCK_BYTES);
    size_t  out_len = inLen + pad;
    if (out_len > outMax) return 0;
    memcpy(out, in, inLen);
    memset(out + inLen, pad, pad);
    return out_len;
}

static size_t pkcs7Unpad(uint8_t* data, size_t dataLen)
{
    if (dataLen == 0 || dataLen % AES_BLOCK_BYTES != 0) return 0;
    uint8_t pad = data[dataLen - 1];
    if (pad == 0 || pad > AES_BLOCK_BYTES)               return 0;
    for (size_t i = dataLen - pad; i < dataLen; i++) {
        if (data[i] != pad) return 0;
    }
    return dataLen - pad;
}

// ── Public API ────────────────────────────────────────────────────────────────

bool cryptoInit()
{
    if (s_initialised) return true;

    // Derive key: SHA-256(efuse MAC), take first 16 bytes
    uint8_t mac[6] = {};
    if (esp_efuse_mac_get_default(mac) != ESP_OK) return false;

    uint8_t hash[32] = {};
    mbedtls_sha256_context ctx;
    mbedtls_sha256_init(&ctx);
    int rc  = mbedtls_sha256_starts_ret(&ctx, 0);
    rc     |= mbedtls_sha256_update_ret(&ctx, mac, sizeof(mac));
    rc     |= mbedtls_sha256_finish_ret(&ctx, hash);
    mbedtls_sha256_free(&ctx);
    if (rc != 0) return false;

    memcpy(s_key, hash, AES_KEY_BYTES);
    explicit_bzero(hash, sizeof(hash));   // scrub intermediate

    s_mutex = xSemaphoreCreateMutex();
    if (s_mutex == nullptr) return false;

    s_initialised = true;
    return true;
}

bool cryptoGetKey(uint8_t key[AES_KEY_BYTES])
{
    if (!s_initialised) return false;
    memcpy(key, s_key, AES_KEY_BYTES);
    return true;
}

String encryptString(const String& plaintext)
{
    if (!s_initialised) return "";
    size_t inLen = plaintext.length();
    if (inLen == 0 || inLen > CRYPTO_MAX_PLAIN) return "";

    if (xSemaphoreTake(s_mutex, pdMS_TO_TICKS(3000)) != pdTRUE) return "";

    String result;
    do {
        // Fresh random IV
        uint8_t iv[AES_IV_BYTES];
        for (int i = 0; i < AES_IV_BYTES; i += 4) {
            uint32_t r = esp_random();
            memcpy(iv + i, &r, 4);
        }

        // Pad plaintext
        size_t paddedLen = pkcs7Pad(
            reinterpret_cast<const uint8_t*>(plaintext.c_str()), inLen,
            s_padded, sizeof(s_padded));
        if (paddedLen == 0) break;

        // AES-128-CBC encrypt
        mbedtls_aes_context aes;
        mbedtls_aes_init(&aes);
        uint8_t iv_copy[AES_IV_BYTES];
        memcpy(iv_copy, iv, AES_IV_BYTES);
        int rc = mbedtls_aes_setkey_enc(&aes, s_key, 128);
        if (rc == 0)
            rc = mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_ENCRYPT,
                                        paddedLen, iv_copy,
                                        s_padded, s_cipher);
        mbedtls_aes_free(&aes);
        if (rc != 0) break;

        // Prepend IV
        size_t combinedLen = AES_IV_BYTES + paddedLen;
        memcpy(s_combined,              iv,       AES_IV_BYTES);
        memcpy(s_combined + AES_IV_BYTES, s_cipher, paddedLen);

        // Base64 encode
        size_t b64Len = 0;
        if (mbedtls_base64_encode(s_b64buf, sizeof(s_b64buf),
                                   &b64Len, s_combined, combinedLen) != 0) break;

        result = String(reinterpret_cast<char*>(s_b64buf)).substring(0, b64Len);
    } while (false);

    xSemaphoreGive(s_mutex);
    return result;
}

String decryptString(const String& b64cipher)
{
    if (!s_initialised || b64cipher.isEmpty()) return "";

    if (xSemaphoreTake(s_mutex, pdMS_TO_TICKS(3000)) != pdTRUE) return "";

    String result;
    do {
        // Base64 decode into s_combined
        size_t combinedLen = 0;
        if (mbedtls_base64_decode(
                s_combined, sizeof(s_combined), &combinedLen,
                reinterpret_cast<const uint8_t*>(b64cipher.c_str()),
                b64cipher.length()) != 0) break;

        if (combinedLen <= AES_IV_BYTES) break;

        uint8_t iv[AES_IV_BYTES];
        memcpy(iv, s_combined, AES_IV_BYTES);

        size_t cipherLen = combinedLen - AES_IV_BYTES;
        if (cipherLen % AES_BLOCK_BYTES != 0) break;
        if (cipherLen > sizeof(s_padded))     break;

        // AES-128-CBC decrypt
        mbedtls_aes_context aes;
        mbedtls_aes_init(&aes);
        int rc = mbedtls_aes_setkey_dec(&aes, s_key, 128);
        if (rc == 0)
            rc = mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_DECRYPT,
                                        cipherLen, iv,
                                        s_combined + AES_IV_BYTES, s_padded);
        mbedtls_aes_free(&aes);
        if (rc != 0) break;

        size_t plainLen = pkcs7Unpad(s_padded, cipherLen);
        if (plainLen == 0) break;

        s_padded[plainLen] = '\0';
        result = String(reinterpret_cast<char*>(s_padded));
    } while (false);

    xSemaphoreGive(s_mutex);
    return result;
}

bool encryptToSPIFFS(const char* path, const String& content)
{
    String enc = encryptString(content);
    if (enc.isEmpty()) return false;

    File f = SPIFFS.open(path, FILE_WRITE);
    if (!f) return false;
    size_t written = f.print(enc);
    f.close();
    return written == enc.length();
}

String decryptFromSPIFFS(const char* path)
{
    if (!SPIFFS.exists(path)) return "";
    File f = SPIFFS.open(path, FILE_READ);
    if (!f) return "";
    String b64 = f.readString();
    f.close();
    return decryptString(b64);
}
