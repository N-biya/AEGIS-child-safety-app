// firmware/include/crypto_utils.h
//
// Threat model
// ─────────────────────────────────────────────────────────────────────────────
// PROTECTS AGAINST:
//   • Passive SPIFFS read via USB if device is lost/stolen (attacker reads
//     flash but does not know the per-device key).
//   • Passive BLE sniffing of JSON payloads sent during pairing or notify.
//   • Casual offline queue inspection by plugging device into a PC.
//
// DOES NOT PROTECT AGAINST:
//   • Sophisticated physical extraction: an attacker with a heat gun, BGA
//     re-baller, and SPI programmer can dump raw flash bytes.  The derived
//     AES key lives in efuse OTP (factory-burned, not readable via software
//     after eFuse read-protect is set), but the efuse read-protect must be
//     explicitly programmed in production — this firmware does not do that
//     step automatically.
//   • Key extraction via JTAG/OCD if debug fuses are not blown.
//   • Active BLE MITM if pairing MITM protection is bypassed (handled
//     separately in ble_pairing.cpp with NimBLE SC+MITM bonding).
// ─────────────────────────────────────────────────────────────────────────────

#pragma once

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

static constexpr size_t AES_KEY_BYTES   = 16;   ///< AES-128 key length
static constexpr size_t AES_IV_BYTES    = 16;   ///< CBC IV length
static constexpr size_t AES_BLOCK_BYTES = 16;   ///< AES block size
/// Maximum plaintext length accepted by encrypt/decrypt helpers.
static constexpr size_t CRYPTO_MAX_PLAIN = 3072;

/**
 * @brief Initialise the crypto subsystem.
 *
 * Must be called once from setup() before any task starts.
 * Derives the AES-128 key from the ESP32 efuse MAC via SHA-256 (first 16 bytes)
 * and creates the internal FreeRTOS mutex that serialises all crypto calls.
 *
 * @return true on success, false if key derivation or mutex creation failed.
 */
bool cryptoInit();

/**
 * @brief Copy the derived 16-byte AES key into @p key.
 *
 * Useful for HMAC computation in the offline queue module.
 * cryptoInit() must have succeeded before calling this.
 *
 * @param[out] key Buffer of at least AES_KEY_BYTES bytes.
 * @return true on success.
 */
bool cryptoGetKey(uint8_t key[AES_KEY_BYTES]);

/**
 * @brief AES-128-CBC encrypt a String.
 *
 * A fresh 16-byte IV is generated via esp_random() on every call.
 * Output format: base64( IV(16) || ciphertext ).
 * PKCS#7 padding is applied to the plaintext.
 *
 * @param plaintext Source data; must be ≤ CRYPTO_MAX_PLAIN bytes.
 * @return base64-encoded ciphertext String, or empty on failure.
 */
String encryptString(const String& plaintext);

/**
 * @brief AES-128-CBC decrypt a String produced by encryptString().
 *
 * @param b64cipher base64( IV || ciphertext ) as returned by encryptString().
 * @return Recovered plaintext, or empty String on failure / padding error.
 */
String decryptString(const String& b64cipher);

/**
 * @brief Encrypt @p content and write ciphertext to a SPIFFS file.
 *
 * Creates or overwrites the file at @p path.
 *
 * @param path    SPIFFS absolute path (e.g. "/data/child_profile.json").
 * @param content Plaintext to encrypt and store.
 * @return true on success.
 */
bool encryptToSPIFFS(const char* path, const String& content);

/**
 * @brief Read and decrypt a SPIFFS file written by encryptToSPIFFS().
 *
 * @param path SPIFFS absolute path.
 * @return Plaintext content, or empty String if file missing or decryption fails.
 */
String decryptFromSPIFFS(const char* path);
