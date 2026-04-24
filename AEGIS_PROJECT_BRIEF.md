# AEGIS — Project Brief for Claude Code

---

## What is AEGIS?

AEGIS is a child safety wearable band system built as a startup product. It monitors a child's physiological signals in real time, detects stress or danger, tracks location, and alerts parents via SMS — all without depending on internet connectivity. The system is designed for children aged 4–12.

The name stands for: Adaptive Edge-Intelligence Guardian and Safety System.

The core philosophy is edge computing — all critical decisions happen on the wearable device itself, not in the cloud. The mobile app is only for visualization and configuration. The backend is only for storage and sync.

---

## System Components

AEGIS has four components that work together:

**Component 1 — The Wearable Band (ESP32)**
This is the brain of the system. It reads sensors, runs the ML model, performs baseline calibration, makes decisions, and sends alerts. Everything critical happens here.

**Component 2 — ML Model (trained offline, deployed to ESP32)**
A Random Forest model trained on the WESAD physiological stress dataset. Converted to a C header file and flashed into the ESP32. It runs entirely on-device with no internet needed.

**Component 3 — Flutter Mobile App**
Parents use this to view their child's vitals, location, alert history, and configure settings like geofence zones. The app does not make any decisions. It only displays data and sends configuration to the device.

**Component 4 — Backend (Firebase — free tier only)**
Stores vitals history, alerts, child profiles, and geofence settings. Used for sync between device and app. Not involved in real-time decision making. Only free Firebase services are used: Firestore, Authentication, and Cloud Messaging.

---

## Hardware Components on the Band

The ESP32 microcontroller connects to these sensors and modules:

- MAX30102 — Heart rate and SpO2 sensor (I2C)
- MPU6050 — Accelerometer and gyroscope (I2C)
- GSR sensor — Galvanic Skin Response / Electrodermal Activity (analog pin)
- DS18B20 — Wrist skin temperature sensor (OneWire)
- NEO-6M GPS module — Location tracking (UART)
- SIM800L GSM module — SMS alerts without internet (UART)
- Vibration motor — Haptic feedback for alerts
- LiPo battery with TP4056 charging module

---

## ML Model Details

The model is already trained. Here is what was done:

- Dataset: WESAD (Wearable Stress and Affect Detection) — 15 subjects, wrist sensor data
- Algorithm: Random Forest Classifier, 15 trees, max depth 8
- Training accuracy: 97.96%
- Cross-validation: 96.03% ± 1.24%
- Output files already generated: `aegis_model.pkl`, `aegis_scaler.pkl`, `aegis_model.h`

Important WESAD feature ranges (these are real measured values, not assumptions):
- hr_mean: 74.5 ± 7.3 bpm
- hrv: 184.4 ± 42.8 ms
- rmssd: 250.7 ± 61.4 ms
- eda_mean: 2.12 ± 2.76 µS (stress mean: 3.10)
- temp_mean: 33.1 ± 1.45°C (wrist skin temperature, not core)
- acc_mean: 63.7 ± 0.93 (raw ADC units)

The 14 input features in order are:
`hr_mean, hrv, rmssd, eda_mean, eda_std, eda_max, eda_slope, spike_count, temp_mean, temp_std, temp_slope, acc_mean, acc_std, acc_max`

Model output: 0 = NORMAL, 1 = STRESS

---

## ESP32 Software Architecture

The ESP32 firmware has three phases:

**Phase 1 — Baseline Calibration (Days 1 to 7)**

When a child first wears the band, it enters calibration mode. Every 10 seconds it reads all sensors and stores the values. After 7 days it calculates mean and standard deviation per sensor for this specific child. This personal profile is saved to ESP32 flash memory (SPIFFS) as a JSON file.

The calibration profile structure:
```
child_profile.json
{
  "hr_mean": 82.4,
  "hr_std": 6.8,
  "gsr_mean": 2.3,
  "gsr_std": 0.4,
  "temp_mean": 33.1,
  "temp_std": 0.9,
  "acc_mean": 63.7,
  "acc_std": 1.2,
  "calibrated": true,
  "days_collected": 7
}
```

**Phase 2 — Monitoring (after Day 7)**

Every 10 seconds:
1. Read all sensors
2. Validate sensor readings (check for disconnection or malfunction)
3. Convert raw values to Z-scores using child's personal baseline:
   `z_score = (current_value - child_mean) / child_std`
4. Feed Z-scores into the WESAD ML model
5. Apply sliding window: collect 6 readings, alert only if 4 out of 6 say STRESS
6. Apply activity filter: if high ACC + low GSR spikes → it is physical activity, not stress
7. Check GPS against stored geofence boundary using Haversine formula
8. If alert condition met → vibrate band + send SMS via GSM

**Phase 3 — Data Sync**

When WiFi is available, the ESP32 sends data to Firebase Firestore. When no internet, it stores readings locally and syncs later when connection is restored. SMS alerts always work regardless of internet.

---

## Alert Logic

Alerts are triggered by any of these conditions:

| Condition | Trigger | Action |
|---|---|---|
| Stress detected | 4 out of 6 sliding window readings = STRESS | Vibrate + SMS + Firebase alert |
| Geofence breach | GPS outside saved boundary | Vibrate + SMS + Firebase alert |
| Low SpO2 | SpO2 below 90% for 3 consecutive readings | SMS + Firebase alert |
| Sensor failure | Any sensor reading outside valid range | Firebase error alert |
| Low battery | Battery below 15% | Firebase warning |

SMS format:
```
AEGIS ALERT
Child: [name]
Status: [STRESS / LOCATION BREACH / LOW SPO2]
Location: [lat, lng]
Time: [timestamp]
```

---

## Flutter App Architecture

**Tech stack — all free:**
- Flutter (latest stable)
- Firebase Firestore — database (free tier)
- Firebase Authentication — login (free tier)
- Firebase Cloud Messaging — push notifications (free tier)
- flutter_map with OpenStreetMap tiles — maps (completely free, no API key needed)
- MQTT or direct Firestore listener — real-time data updates
- fl_chart — graphs and vitals charts (free package)

**App screens:**

1. Splash / Login screen — email and password login via Firebase Auth, support for multiple children per parent account

2. Dashboard screen — current status badge (SAFE / ELEVATED / ALERT), live vitals (HR, SpO2, GSR, Skin Temp), last updated timestamp, quick link to map

3. Map screen — child's current GPS location using flutter_map + OpenStreetMap, drawn geofence circle, location history trail for last 24 hours, button to set or update geofence

4. Alerts screen — list of all historical alerts, each showing type, time, vitals at time of alert, and location

5. Analytics screen — line graphs of HR, GSR, SpO2 over past 7 days, stress frequency chart, calibration progress (Day X of 7)

6. Settings screen — child profile (name, age, photo), geofence (set center and radius on map), alert thresholds (optional manual overrides), emergency contacts (phone numbers for SMS), device pairing (connect band via WiFi or BLE)

7. Calibration screen — shown during first 7 days, progress bar showing Day X of 7, current baseline readings building up, message explaining alerts will activate after calibration completes

**App data flow:**
```
ESP32 collects data
      ↓
Sends to Firebase Firestore (when WiFi available)
      ↓
Flutter app listens to Firestore in real time
      ↓
UI updates automatically
      ↓
Firebase Cloud Messaging sends push notification for alerts
```

---

## Firebase Database Structure

```
Firestore Collections:

/users/{userId}
  - email
  - name
  - createdAt

/users/{userId}/children/{childId}
  - name
  - age
  - deviceId
  - geofence: { lat, lng, radiusMeters }
  - emergencyContacts: [phone1, phone2]
  - calibrated: bool
  - daysCollected: int

/users/{userId}/children/{childId}/vitals/{timestamp}
  - hr
  - spo2
  - gsr
  - temp
  - movement
  - status: NORMAL / ELEVATED / STRESS
  - lat
  - lng

/users/{userId}/children/{childId}/alerts/{alertId}
  - type: STRESS / GEOFENCE / SPO2 / SENSOR_ERROR
  - timestamp
  - vitals: { hr, spo2, gsr, temp }
  - location: { lat, lng }
  - resolved: bool

/devices/{deviceId}
  - childId
  - lastSeen
  - batteryLevel
  - firmwareVersion
  - calibrationProfile: { hr_mean, hr_std, ... }
```

---

## Communication Architecture

```
Band (ESP32)
    |
    |── WiFi ──→ Firebase Firestore ──→ Flutter App (real-time listener)
    |                                         ↑
    |── WiFi ──→ Firebase FCM ─────────→ Push Notification
    |
    |── GSM ───→ SMS to parent phone (no internet needed, always works)
    |
    └── BLE ────→ Flutter App (for initial device setup and pairing)
```

---

## Zero Paid Services Policy

This is a startup with zero budget for external APIs. Every tool and service used must be free.

| Need | Solution | Cost |
|---|---|---|
| Database | Firebase Firestore free tier | Free |
| Authentication | Firebase Auth free tier | Free |
| Push notifications | Firebase Cloud Messaging | Free |
| Maps in app | flutter_map + OpenStreetMap | Free |
| SMS alerts | SIM800L GSM hardware module | Hardware only |
| Charts | fl_chart Flutter package | Free |
| Git hosting | GitHub (free) | Free |
| CI checks | GitHub Actions (free tier) | Free |

Never suggest, use, or integrate: Google Maps API (paid), Twilio (paid), AWS (paid), Azure (paid), MapBox (paid), any paid SMS gateway, or any service that requires a credit card.

---

## Git and GitHub Setup

### Repository Structure

The project lives in a single GitHub repository with three clearly separated folders. This is a monorepo approach — one repo, three sub-projects.

```
aegis/                         ← root of GitHub repository
├── .github/
│   └── workflows/
│       └── flutter_checks.yml ← GitHub Actions CI (free)
├── firmware/                  ← ESP32 PlatformIO project
├── ml/                        ← Python ML scripts (already done)
├── app/                       ← Flutter mobile app
├── .gitignore
├── README.md
└── AEGIS_PROJECT_BRIEF.md
```

### Branching Strategy

```
main
  └── dev
        ├── feature/app-dashboard
        ├── feature/app-map
        ├── feature/app-alerts
        ├── feature/firmware-calibration
        ├── feature/firmware-alerts
        └── feature/firmware-sensors
```

Rules:
- `main` — production-ready code only. Never push directly to main.
- `dev` — active development branch. All features merge here first.
- `feature/*` — one branch per feature. Branch from dev, merge back to dev via pull request.
- When dev is stable and tested → merge dev into main.

### .gitignore File

When development begins, create this `.gitignore` in the project root:

```gitignore
# ── Python / ML ──────────────────────────────
__pycache__/
*.pyc
*.pyo
.env
*.pkl
*.h5
ml/wesad_data/
ml/WESAD/
venv/
.venv/

# ── Flutter / Dart ───────────────────────────
app/.dart_tool/
app/.flutter-plugins
app/.flutter-plugins-dependencies
app/.packages
app/build/
app/.fvm/
app/android/.gradle/
app/android/local.properties
app/android/key.properties
app/ios/.symlinks/
app/ios/Pods/
app/ios/Flutter/Flutter.framework
app/ios/Flutter/Flutter.podspec
*.iml

# ── Firebase (CRITICAL — never commit these) ──
google-services.json
GoogleService-Info.plist
app/lib/firebase_options.dart
**/firebase_options.dart
.firebaserc
firebase.json
serviceAccountKey.json
*.jks
*.keystore

# ── ESP32 / PlatformIO ───────────────────────
firmware/.pio/
firmware/.vscode/
firmware/include/secrets.h

# ── Secrets and credentials ──────────────────
.env
.env.local
secrets.h
secrets.json
*.pem
*.key
*.cert
config/secrets/

# ── OS files ─────────────────────────────────
.DS_Store
Thumbs.db
desktop.ini

# ── IDE files ────────────────────────────────
.idea/
.vscode/settings.json
*.swp
*.swo
```

### Secrets Management

These files must NEVER be committed to GitHub. They contain API keys and credentials:

| File | What it contains | How to handle |
|---|---|---|
| `google-services.json` | Firebase Android config | Each team member downloads from Firebase Console |
| `GoogleService-Info.plist` | Firebase iOS config | Each team member downloads from Firebase Console |
| `firebase_options.dart` | Firebase Dart config | Generated locally via `flutterfire configure` |
| `firmware/include/secrets.h` | WiFi password, Firebase credentials for ESP32 | Created manually from `secrets.example.h` template |

Create a `secrets.example.h` file in `firmware/include/` with empty values as a template:
```cpp
// secrets.example.h
// Copy this file to secrets.h and fill in your values
// secrets.h is gitignored — never commit it

#define WIFI_SSID     "your_wifi_name"
#define WIFI_PASSWORD "your_wifi_password"
#define FIREBASE_HOST "your-project.firebaseio.com"
#define FIREBASE_KEY  "your_firebase_api_key"
#define PARENT_PHONE  "+923001234567"
```

### README.md Content

When development begins, the README should contain:

```
# AEGIS — Adaptive Edge-Intelligence Guardian and Safety System

Child safety wearable band with on-device stress detection,
GPS geofencing, and SMS alerts.

## Project Structure
- /firmware  → ESP32 wearable band code (PlatformIO)
- /ml        → ML model training scripts (Python)
- /app       → Flutter parent mobile app

## Setup Instructions

### Flutter App
1. Clone the repo
2. Download google-services.json from Firebase Console
3. Place it in app/android/app/
4. Run: cd app && flutter pub get && flutter run

### ESP32 Firmware
1. Install PlatformIO in VS Code
2. Copy firmware/include/secrets.example.h to firmware/include/secrets.h
3. Fill in your WiFi and Firebase credentials in secrets.h
4. Copy aegis_model.h into firmware/include/
5. Open firmware/ folder in PlatformIO and upload

### ML Model (already trained)
Model files are in /ml folder.
To retrain: python ml/train_aegis_model.py
To test: python ml/test_aegis_model.py

## Tech Stack
- Wearable: ESP32 + MAX30102 + MPU6050 + GSR + GPS + GSM
- ML: Random Forest trained on WESAD dataset (97.96% accuracy)
- App: Flutter + Firebase (free tier)
- Maps: OpenStreetMap (free, no API key)
- Alerts: SIM800L GSM module (no internet required)

## Branch Strategy
- main → production
- dev → active development
- feature/* → individual features
```

### GitHub Actions CI (Free)

When development begins, create `.github/workflows/flutter_checks.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ dev, main ]
    paths:
      - 'app/**'
  pull_request:
    branches: [ dev, main ]
    paths:
      - 'app/**'

jobs:
  flutter-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'

      - name: Install dependencies
        run: cd app && flutter pub get

      - name: Analyze code
        run: cd app && flutter analyze

      - name: Run tests
        run: cd app && flutter test
```

This runs automatically on every push to dev or main and checks for code errors. It uses GitHub's free CI minutes.

### Git Workflow — Day to Day

```bash
# Start a new feature
git checkout dev
git pull origin dev
git checkout -b feature/app-dashboard

# Work on code, then commit
git add .
git commit -m "feat(app): add dashboard screen with vitals cards"

# Push feature branch to GitHub
git push origin feature/app-dashboard

# When feature is done → open Pull Request on GitHub
# dev team reviews → merge into dev

# When dev is stable → merge dev into main
git checkout main
git merge dev
git push origin main
```

### Commit Message Convention

Use this format for all commits so the history stays readable:

```
feat(app): add geofence map screen
fix(firmware): correct GSR reading normalization
feat(firmware): implement sliding window alert logic
test(ml): add edge case tests for sleep scenario
docs: update README with setup instructions
chore: update .gitignore for Flutter build files
refactor(app): split dashboard into separate widgets
```

Format: `type(scope): short description`
Types: `feat` / `fix` / `test` / `docs` / `chore` / `refactor`
Scopes: `app` / `firmware` / `ml` / `firebase`

---

## Project Folder Structure

```
aegis/
├── .github/
│   └── workflows/
│       └── flutter_checks.yml
├── firmware/                  ← ESP32 C++ code (PlatformIO)
│   ├── src/
│   │   └── main.cpp
│   ├── include/
│   │   ├── aegis_model.h
│   │   ├── secrets.h          ← gitignored
│   │   └── secrets.example.h  ← committed as template
│   └── platformio.ini
├── ml/                        ← Python ML scripts (already done)
│   ├── train_aegis_model.py
│   ├── test_aegis_model.py
│   ├── convert_to_header.py
│   ├── check_ranges.py
│   ├── aegis_model.pkl        ← gitignored (large binary)
│   ├── aegis_scaler.pkl       ← gitignored (large binary)
│   └── aegis_model.h
├── app/                       ← Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── models/
│   │   ├── services/
│   │   └── utils/
│   ├── pubspec.yaml
│   └── firebase_options.dart  ← gitignored
├── .gitignore
├── README.md
└── AEGIS_PROJECT_BRIEF.md
```

---

## Development Order (for future reference)

When development begins, the order will be:

1. Initialize Git repo, set up branching, push initial structure to GitHub
2. Flutter app — screens and UI with dummy data first
3. Firebase setup — Firestore collections, Auth, FCM
4. ESP32 firmware — sensor reading, calibration, model integration
5. Connect ESP32 to Firebase — data sync
6. Connect Flutter app to Firebase — real-time display
7. GSM SMS alert system on ESP32
8. Geofencing on ESP32 and display on app map
9. BLE device pairing flow
10. Full integration testing
11. Power optimization on ESP32

---

## Important Notes for Development

- Hardware is not yet ready. Do not write firmware code that depends on physical hardware being connected. Simulate sensor data where needed during early development.
- The ML model is already trained and tested. The file `aegis_model.h` is ready to be dropped into the ESP32 project when firmware development begins.
- All stress detection logic runs on the ESP32. The Flutter app never makes stress decisions.
- The app must work even when the band is offline. Show last known data with a last updated timestamp.
- Children's physiological data is sensitive. Firebase security rules must restrict each parent to only their own children's data.
- The 7-day calibration period must be clearly communicated to parents in the app. No alerts are sent during calibration.
- Never commit secrets, API keys, or Firebase config files to GitHub. Use the secrets.example.h pattern for firmware credentials.
- All team members must download their own Firebase config files locally. These are never shared through Git.
