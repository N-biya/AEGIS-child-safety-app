#ifndef SECRETS_H
#define SECRETS_H

/**************************************************************
 * AEGIS device secrets — TEMPLATE
 *
 * Copy this file to "secrets.h" and fill in real values.
 * secrets.h is gitignored — never commit real credentials.
 **************************************************************/

// ── WiFi ──
#define WIFI_SSID           "your_wifi_name"
#define WIFI_PASSWORD       "your_wifi_password"

// ── Firebase project (from app/lib/firebase_options.dart) ──
#define FIREBASE_API_KEY    "your_web_api_key"
#define FIREBASE_PROJECT_ID "aegis-child-safety-app"

// ── Device account (created in Firebase Auth; its UID must be in the
//    child's linkedDevices array so the security rules allow writes) ──
#define DEVICE_EMAIL        "band01@aegis.device"
#define DEVICE_PASSWORD     "change_me"

// ── Child document id in the 'children' collection to write vitals under ──
#define CHILD_ID            "child_001"

// ── How often to upload a vitals sample (milliseconds) ──
#define UPLOAD_INTERVAL_MS  15000

#endif // SECRETS_H
