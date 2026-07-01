# AEGIS — Quick Brief

## What is AEGIS?
AEGIS (Adaptive Edge-Intelligence Guardian and Safety System) is a **child safety wristband** for kids aged 4–12.

It does three things:
1. Reads the child's body signals (heart rate, sweat, temperature, movement).
2. Decides — **on the band itself** — if the child is stressed or in danger.
3. Tracks location and alerts the parent by **SMS**, even with no internet.

**Key idea:** all the "thinking" happens on the band. The phone app only *shows* data. The internet (Firebase) is only for *storage*. If WiFi is down, the band still works and still sends SMS.

---

## How it works (the flow)
```
Sensors  →  ESP32 reads them  →  ML model decides (Normal / Stress)
                                          ↓
                         If stress or danger → Vibrate band + Send SMS to parent
                                          ↓
                  When WiFi is available → upload data to Firebase → Parent app shows it
```

---

## The band hardware (ESP32 + these parts)
| Part | Job | Connection |
|---|---|---|
| ESP32 | Main brain | — |
| MAX30102 | Heart rate + SpO2 | I2C |
| MPU6050 | Movement (accel/gyro) | I2C |
| GSR sensor | Skin sweat (stress signal) | Analog pin |
| DS18B20 | Skin temperature | OneWire |
| NEO-6M GPS | Location | UART |
| SIM800L GSM | SMS alerts (no internet needed) | UART |
| Vibration motor | Buzz the child on alert | GPIO |
| LiPo battery + TP4056 | Power + charging | — |

---

## What the band does, step by step

**Phase 1 — Calibration (first 7 days)**
Every child is different. For the first 7 days the band just records the child's normal readings and builds a personal baseline (saved in the band's flash memory). No alerts during this time.

**Phase 2 — Monitoring (after day 7)**
Every 10 seconds the band:
1. Reads all sensors.
2. Checks the readings are valid (no loose/broken sensor).
3. Compares them to the child's own baseline.
4. Runs the ML model → Normal or Stress.
5. Confirms with a sliding window — alert only if **4 of the last 6** readings say Stress (avoids false alarms).
6. Activity filter — lots of movement + low sweat = just running/playing, not stress.
7. Checks GPS against the parent's safe-zone boundary.
8. If a real alert → vibrate + send SMS.

**Phase 3 — Sync**
When WiFi is available, upload readings and alerts to Firebase. No WiFi = store locally and sync later. **SMS always works regardless of internet.**

---

## When does it alert?
| Condition | Trigger |
|---|---|
| Stress | 4 of 6 readings = Stress |
| Left safe zone | GPS outside the boundary |
| Low oxygen | SpO2 below 90% for 3 readings |
| Sensor fault | A sensor reads outside valid range |
| Low battery | Below 15% |

**SMS looks like:**
```
AEGIS ALERT
Child: [name]
Status: STRESS / LOCATION BREACH / LOW SPO2
Location: [lat, lng]
Time: [timestamp]
```

---

## The ML model (already done — don't worry about training)
- Trained Random Forest, converted to a C header file (`aegis_model.h`).
- Runs fully on the ESP32, no internet.
- Input = 14 features built from the sensor readings.
- Output = 0 (Normal) or 1 (Stress).
- You just drop the header into the firmware and call it — the math is handled.

---

## What's needed on the hardware side
1. Wire up the sensors to the ESP32 (pins per the table above; I2C pins are SDA=8, SCL=9 in current code).
2. Get clean, stable readings from each sensor (this is the real work — sensor noise and contact issues).
3. Confirm GPS gets a location fix and GSM can send a real SMS with a working SIM.
4. Make sure the band runs on battery and charges properly.
5. Keep power use low so the battery lasts (band must run all day).

Current firmware (`Wrist_Band_v1.5/`) already has separate modules for each sensor (temperature, MPU6050, GSR, MAX30102), Bluetooth, communication, and the stress AI, each running as its own task. The base structure is there — the focus is making the physical sensors read reliably.

---

## The two ground rules
1. **Everything critical runs on the band.** The app and cloud never decide anything — they only display and store.
2. **It must work offline.** WiFi/Firebase are a bonus. The SMS alert path is the safety net and must always work.
