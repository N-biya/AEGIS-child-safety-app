// firmware/include/secrets.example.h
//
// INSTRUCTIONS: Copy this file to secrets.h and fill in your values.
//               secrets.h MUST be listed in .gitignore — NEVER commit it.
//
// Privacy note: CHILD_NAME holds first name only — no surname, no DOB.
// Phone numbers must be in E.164 format: +<country><number>, e.g. +447700900123

#pragma once

// ── Wi-Fi ────────────────────────────────────────────────────────────────────
#define WIFI_SSID        "YourSSID"
#define WIFI_PASSWORD    "YourWiFiPassword"

// ── Firebase ─────────────────────────────────────────────────────────────────
// Firebase project ID (found in Project Settings → General)
#define FIREBASE_PROJECT_ID  "your-firebase-project-id"
// Web API key (found in Project Settings → General)
#define FIREBASE_API_KEY     "AIzaSy_YOUR_API_KEY_HERE"
// Firestore base host (leave as-is unless using emulator)
#define FIREBASE_HOST        "firestore.googleapis.com"
// Service account or user credentials used for Firestore auth
#define FIREBASE_USER_EMAIL    "device@your-project.iam.gserviceaccount.com"
#define FIREBASE_USER_PASSWORD "your-firebase-auth-password"

// ── User / Child identifiers ──────────────────────────────────────────────────
// These must NOT appear in Serial logs in release builds.
#define USER_ID   "uid_xxxxxxxxxxxxxxxx"
#define CHILD_ID  "cid_xxxxxxxxxxxxxxxx"

// ── Child profile (first name only — no surname) ──────────────────────────────
#define CHILD_NAME  "Alex"

// ── Emergency contacts (E.164 format, up to 3) ────────────────────────────────
#define PARENT_PHONE_1  "+447700900001"
#define PARENT_PHONE_2  "+447700900002"
#define PARENT_PHONE_3  ""   // leave empty string if fewer than 3 contacts

// ── Hardware pin assignments ──────────────────────────────────────────────────
// I2C (MAX30102 + MPU6050) uses default ESP32 SDA=21, SCL=22

// UART2 → NEO-6M GPS
#define GPS_RX_PIN   16
#define GPS_TX_PIN   17

// UART1 → SIM800L GSM
// NOTE: spec lists D4 (GPIO4) for both OneWire AND GSM RX.
//       GPIO4 is assigned to GSM RX here; OneWire uses GPIO13.
#define GSM_RX_PIN   4
#define GSM_TX_PIN   2

// OneWire → DS18B20 temperature
#define ONE_WIRE_BUS  13   // hardware conflict resolution: spec D4 reassigned

// Analogue inputs
#define GSR_PIN      36    // GPIO36 / A0  — GSR sensor
#define BATTERY_PIN  34    // GPIO34 / ADC1_CH6 — LiPo voltage divider

// Digital outputs / inputs
#define VIBRATION_PIN    25   // PWM vibration motor
#define PAIR_BUTTON_PIN   0   // Long-press triggers BLE pairing (BOOT button or dedicated)
#define CHRG_PIN         35   // TP4056 CHRG pin (LOW = charging)

// ── Calibration constants ─────────────────────────────────────────────────────
#define CALIBRATION_DAYS          7
#define SAMPLES_PER_DAY        8640   // one sample per 10 s × 86 400 s/day
#define CALIBRATION_TOTAL_SAMPLES (CALIBRATION_DAYS * SAMPLES_PER_DAY)  // 60 480
