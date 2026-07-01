// firmware/include/offline_queue.h
#pragma once

#include <Arduino.h>

static constexpr int QUEUE_MAX_ENTRIES = 288;  ///< ~24 h at 5-min intervals
static constexpr uint32_t QUEUE_MAX_AGE_MS = 48UL * 60UL * 60UL * 1000UL; // 48 h

/**
 * @brief Append an encrypted, HMAC-authenticated entry to the offline queue.
 *
 * If the queue is full (288 entries), the oldest entry is evicted (FIFO).
 * The @p jsonPayload is encrypted with AES-128-CBC and an HMAC-SHA256
 * (keyed with the device AES key) is appended for tamper detection.
 *
 * @param jsonPayload Plaintext JSON string to queue.
 * @param entryType   Short type tag (e.g. "vitals", "alert").
 * @return true on success.
 */
bool enqueueReading(const String& jsonPayload, const char* entryType);

/**
 * @brief Upload queued entries to Firebase in batches of 10.
 *
 * Called by the WiFi/Firebase task when connectivity is restored.
 * Entries that upload successfully are removed; others remain for retry.
 *
 * @return Number of entries successfully flushed.
 */
int flushQueue();

/**
 * @brief Delete entries older than 48 hours from the queue.
 *
 * Must be called once on boot (data retention / storage limitation policy).
 */
void pruneOldEntries();

/**
 * @brief Return the number of entries currently in the queue.
 */
int getQueueSize();
