// firmware/include/ble_pairing.h
#pragma once

#include <Arduino.h>

/**
 * @brief Start BLE pairing advertisement.
 *
 * Uses NimBLE-Arduino with MITM-protected SC bonding (BLE_SM_PAIR_AUTHREQ_SC |
 * BLE_SM_PAIR_AUTHREQ_MITM | BLE_SM_PAIR_AUTHREQ_BOND) and a randomly
 * generated 6-digit display-only passkey.
 *
 * Advertisement payload: device ID only — NO child name, NO PII.
 *
 * WRITE characteristic: receive JSON config from parent app.
 *   Accepted fields: center_lat, center_lng, radius_m, child_name (first name only),
 *                    phone1, phone2, phone3, user_id, child_id.
 *
 * NOTIFY characteristic: send pairing status and calibration progress.
 *
 * On successful pairing: config saved to encrypted /data/device_config.json,
 * BLE stopped automatically.
 *
 * @param deviceId Short device identifier shown in BLE advertisement.
 */
void startPairing(const String& deviceId);

/**
 * @brief Stop BLE advertisement and disconnect all peers.
 */
void stopPairing();

/**
 * @brief Return true when a successful pairing has been completed.
 */
bool isPaired();

/**
 * @brief Return the 6-digit passkey currently displayed for pairing confirmation.
 *
 * Returns 0 if pairing is not active.
 */
uint32_t getPairingPasskey();

/**
 * @brief Send a calibration-progress notification over BLE NOTIFY.
 *
 * @param daysDone   Calibration days completed so far (0–7).
 * @param totalDays  Total calibration days required (7).
 */
void notifyCalibrationProgress(int daysDone, int totalDays);
