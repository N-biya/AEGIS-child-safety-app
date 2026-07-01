# AEGIS Testing Tracker

Companion to Chapter 7 (Testing) of the thesis document. The thesis chapter is the
narrative/methodology write-up; **this file is the working tracker** — update the
Status column as cases are actually executed, rather than editing the docx each time.

Project stage: **MVP**. Firmware exists as a design (no `firmware/` code committed yet).
Flutter app + Firebase backend are implemented and runnable. No packaged wearable yet —
hardware test cases run on a dev-kit/breadboard prototype. The app currently renders
vitals/location from `dummy_data_service.dart` for screens not yet wired to live hardware.

Status values to use: `Not Run` / `Pass` / `Fail` / `Blocked`.

## How to actually run each layer

| Layer | Command / Setup |
|---|---|
| Firmware unit tests | `pio test -e native` (PlatformIO native env, Unity framework) — write firmware logic as pure functions in a lib/ folder so they compile off-target |
| Flutter unit/widget tests | `cd app && flutter test` |
| Firebase emulator | `firebase emulators:start --only auth,firestore,functions` then point the app's Firebase config at the emulator ports for test runs |
| Hardware bench | Manual — see Section 7.4.3 / 7.6 test plan below, log results in this file |

## Test Case Tracker

| ID | Title | Layer | Type | Status | Notes |
|---|---|---|---|---|---|
| TC-FW-001 | Baseline Z-Score Normalization | Firmware | Unit | Not Run | |
| TC-FW-002 | Stress Classification on Known Feature Vector | Firmware | Unit | Not Run | |
| TC-FW-003 | 7-Day Calibration Window Completion | Firmware | Integration | Not Run | |
| TC-HW-001 | MAX30102 Heart Rate Accuracy vs Reference Oximeter | Hardware | Bench | Not Run | Needs reference pulse oximeter |
| TC-HW-002 | GSM SMS Fallback Delivery | Hardware/Network | Manual | Not Run | Needs funded SIM in SIM800L |
| TC-APP-001 | Parent Account Registration | Mobile App | Unit | Pass | Automated via `auth_service_test.dart` (firebase_auth_mocks) |
| TC-APP-002 | Define and Persist a Safe Zone | Mobile App | Unit | Pass | Automated via `safe_zone_test.dart` (model round-trip + prefs + fake Firestore) |
| TC-APP-003 | Invalid Login Credential Rejection | Mobile App | Unit | Pass | Automated via `auth_service_test.dart` — rejects wrong creds, no session |
| TC-INT-001 | End-to-End Geofence Breach Notification | Integration | Black Box | Pass | Automated via `geofence_breach_test.dart` — breach math + GEOFENCE alert write |
| TC-INT-002 | Alert Flag Triggers FCM Push | Integration | Black Box | Pass | Automated via `alert_push_test.dart` — verifies push-ready alert doc contract |

Full test case definitions (description, procedure, pre/post-conditions, input/expected
output) are in Chapter 7, Section 7.8 of the thesis document — this file intentionally
only tracks status so it doesn't drift out of sync with the prose copy.

## Hardware Sensor Accuracy Test Plan (Section 7.4.3 / 7.6)

| Sensor | Test Condition | Reference Instrument | Tolerance | Status |
|---|---|---|---|---|
| MAX30102 (HR/SpO2) | Resting subject, paired 5-min sampling | Clinical pulse oximeter | ±5 bpm, ±2% SpO2 | Pending hardware session |
| MLX90614 (Temperature) | Known-temperature reference object | Calibrated digital thermometer | ±0.5°C | Pending hardware session |
| GSR electrodes | Stimulus-response relative change | None (relative-change only) | Detectable rise during stimulus | Pending hardware session |
| Accelerometer | Static vs known motion | Visual/manual motion log | Correct high-motion flag | Pending hardware session |
| NEO-6M GPS | Outdoor, open-sky fix | Smartphone GPS | Within ~5 m | Pending hardware session |
| SIM800L GSM | SMS send/receive | Parent test phone | Delivery within fallback window | Pending hardware session |

## Defect Log

Log defects found during execution here, referencing the test case ID that found them.

| Defect ID | Found In (TC ID) | Description | Severity | Status | Fix Notes |
|---|---|---|---|---|---|
| | | | | | |

## Firmware Unit Test Coverage (Section 7.4.2)

| Module / Function | Test Type | Covered Off-Device | Notes |
|---|---|---|---|
| Z-score normalization | Unit | Yes | Pure function |
| Sliding-window filter | Unit | Yes | Pure function |
| Random Forest classifier wrapper | Unit | Yes | Tested against labelled feature vectors |
| Geofence breach check | Unit | Yes | Pure distance-vs-radius comparison |
| Sensor I2C drivers (MAX30102, MLX90614) | Hardware | Partial | Needs physical board |
| GSM AT command sequencing | Hardware | Partial | Timing-dependent |
| Power manager / duty-cycle logic | Integration | Planned | Needs extended-run hardware testing |
