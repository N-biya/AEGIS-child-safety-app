// firmware/include/gps_manager.h
#pragma once

#include <Arduino.h>

/**
 * @brief Most-recent GPS fix snapshot.
 *
 * Privacy: lat/lng MUST NOT appear in Serial logs in release builds.
 * All callers must guard coordinate logging with #if DEBUG_MODE.
 */
struct GPSReading {
    float    lat;        ///< Latitude  (decimal degrees)
    float    lng;        ///< Longitude (decimal degrees)
    float    accuracy_m; ///< HDOP-derived approximate accuracy (metres)
    bool     fixed;      ///< True when a valid fix is available
    uint32_t timestamp;  ///< millis() when fix was captured
};

/**
 * @brief Circular geofence definition.
 */
struct Geofence {
    float center_lat; ///< Geofence centre latitude
    float center_lng; ///< Geofence centre longitude
    float radius_m;   ///< Geofence radius (metres)
    bool  valid;      ///< True when loaded from SPIFFS
};

/**
 * @brief Initialise the NEO-6M GPS on UART2.
 *
 * Opens HardwareSerial(2) at 9600 baud and loads the saved geofence
 * from encrypted SPIFFS if available.
 */
void initGPS();

/**
 * @brief Non-blocking GPS poll.
 *
 * Feeds available UART2 bytes into TinyGPS++.
 * If a new fix is decoded, updates and returns it.
 * If no new fix within the last 5 seconds of calling, returns the
 * last known good fix (or unfixed reading on cold start).
 *
 * @return Most-recent GPSReading; check fixed before use.
 */
GPSReading readGPS();

/**
 * @brief Test whether @p reading is inside the loaded geofence.
 *
 * @param reading A GPSReading with fixed == true.
 * @return true if inside or if no geofence is configured (safe default).
 */
bool isInsideGeofence(const GPSReading& reading);

/**
 * @brief Haversine great-circle distance between two WGS-84 coordinates.
 *
 * @return Distance in metres.
 */
float haversineDistance(float lat1, float lng1, float lat2, float lng2);

/**
 * @brief Encrypt and persist a geofence to /data/geofence.json.
 *
 * @return true on success.
 */
bool saveGeofence(float centerLat, float centerLng, float radiusM);

/**
 * @brief Decrypt and load geofence from /data/geofence.json.
 *
 * @return true on success; loaded geofence is used by isInsideGeofence().
 */
bool loadGeofence();

/**
 * @brief Return false if no GPS fix has been obtained within 5 minutes.
 */
bool gpsHealthCheck();

/**
 * @brief Return the currently loaded Geofence struct.
 */
const Geofence& getGeofence();
