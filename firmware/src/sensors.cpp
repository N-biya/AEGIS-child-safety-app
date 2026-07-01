// firmware/src/sensors.cpp
#include "sensors.h"
#include "secrets.h"

#include <Wire.h>
#include <SparkFun_MAX3010x_Sensor_Algorithm.h>
#include <SparkFun_MAX3010x.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// ── Hardware objects ──────────────────────────────────────────────────────────

static MAX30105        s_max30102;
static Adafruit_MPU6050 s_mpu;
static OneWire         s_oneWire(ONE_WIRE_BUS);
static DallasTemperature s_ds18b20(&s_oneWire);

// ── MAX30102 IR/Red sample buffers (algorithm needs 100-sample windows) ───────
static uint32_t s_irBuf[100];
static uint32_t s_redBuf[100];

// ── Circular buffer ───────────────────────────────────────────────────────────

static SensorReading s_buf[SENSOR_BUFFER_SIZE] = {};
static int           s_bufHead  = 0;   // next write index
static int           s_bufCount = 0;   // number of valid entries

// ── Sensor health ─────────────────────────────────────────────────────────────

static uint8_t s_healthMask = 0xFF;    // all bad until initSensors() succeeds

// ── GSR ADC helpers ───────────────────────────────────────────────────────────

static float readGSR()
{
    // 12-bit ADC, 3.3 V reference.  Simple linear map 0–4095 → 0.1–20 µS.
    int raw = analogRead(GSR_PIN);
    return GSR_MIN + (static_cast<float>(raw) / 4095.0f) * (GSR_MAX - GSR_MIN);
}

// ── Public API ────────────────────────────────────────────────────────────────

uint8_t initSensors()
{
    s_healthMask = 0x00;

    // MAX30102 ─────────────────────────────────────────────────────────────────
    if (!s_max30102.begin(Wire, I2C_SPEED_FAST)) {
#if DEBUG_MODE
        Serial.println("[SENSOR] MAX30102 init FAIL");
#endif
        s_healthMask |= SENSOR_ERR_HR | SENSOR_ERR_SPO2;
    } else {
        s_max30102.setup();
        s_max30102.setPulseAmplitudeRed(0x0A);
        s_max30102.setPulseAmplitudeIR(0x0A);
    }

    // MPU6050 ──────────────────────────────────────────────────────────────────
    if (!s_mpu.begin()) {
#if DEBUG_MODE
        Serial.println("[SENSOR] MPU6050 init FAIL");
#endif
        s_healthMask |= SENSOR_ERR_ACCEL;
    } else {
        s_mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
        s_mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    }

    // DS18B20 ──────────────────────────────────────────────────────────────────
    s_ds18b20.begin();
    if (s_ds18b20.getDeviceCount() == 0) {
#if DEBUG_MODE
        Serial.println("[SENSOR] DS18B20 not found");
#endif
        s_healthMask |= SENSOR_ERR_TEMP;
    }

    // GSR: ADC configuration ──────────────────────────────────────────────────
    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);   // 0–3.3 V range

    return s_healthMask;
}

SensorReading readAllSensors()
{
    SensorReading r = {};
    r.timestamp  = millis();
    r.error_mask = 0x00;

    // ── MAX30102: HR + SpO2 ──────────────────────────────────────────────────
    // Collect 100 samples, then run the SparkFun algorithm.
    // Shift buffer left by 25, append 25 fresh samples.
    {
        const int bufLen  = 100;
        const int newSamp = 25;
        for (int i = 0; i < bufLen - newSamp; i++) {
            s_irBuf[i]  = s_irBuf[i + newSamp];
            s_redBuf[i] = s_redBuf[i + newSamp];
        }
        for (int i = bufLen - newSamp; i < bufLen; i++) {
            while (!s_max30102.available()) s_max30102.check();
            s_redBuf[i] = s_max30102.getRed();
            s_irBuf[i]  = s_max30102.getIR();
            s_max30102.nextSample();
        }
        int32_t spo2 = 0, hr = 0;
        int8_t  spo2Valid = 0, hrValid = 0;
        maxim_heart_rate_and_oxygen_saturation(
            s_irBuf, bufLen, s_redBuf, &spo2, &spo2Valid, &hr, &hrValid);

        if (hrValid && hr >= HR_MIN && hr <= HR_MAX) {
            r.hr = static_cast<float>(hr);
        } else {
            r.hr = 0.0f;
            r.error_mask |= SENSOR_ERR_HR;
        }
        if (spo2Valid && spo2 >= SPO2_MIN && spo2 <= SPO2_MAX) {
            r.spo2 = static_cast<float>(spo2);
        } else {
            r.spo2 = 0.0f;
            r.error_mask |= SENSOR_ERR_SPO2;
        }
    }

    // ── MPU6050: acceleration magnitude ─────────────────────────────────────
    {
        sensors_event_t accel, gyro, temp;
        if (s_mpu.getEvent(&accel, &gyro, &temp)) {
            float ax = accel.acceleration.x;
            float ay = accel.acceleration.y;
            float az = accel.acceleration.z;
            float mag = sqrtf(ax * ax + ay * ay + az * az);
            if (mag >= ACC_MIN && mag <= ACC_MAX) {
                r.acc_mag = mag;
            } else {
                r.acc_mag = 0.0f;
                r.error_mask |= SENSOR_ERR_ACCEL;
            }
        } else {
            r.acc_mag = 0.0f;
            r.error_mask |= SENSOR_ERR_ACCEL;
        }
    }

    // ── DS18B20: skin temperature ─────────────────────────────────────────────
    {
        s_ds18b20.requestTemperatures();
        float t = s_ds18b20.getTempCByIndex(0);
        if (t != DEVICE_DISCONNECTED_C && t >= TEMP_MIN && t <= TEMP_MAX) {
            r.temp = t;
        } else {
            r.temp = 0.0f;
            r.error_mask |= SENSOR_ERR_TEMP;
        }
    }

    // ── GSR ADC ───────────────────────────────────────────────────────────────
    {
        float gsr = readGSR();
        if (gsr >= GSR_MIN && gsr <= GSR_MAX) {
            r.gsr = gsr;
        } else {
            r.gsr = 0.0f;
            r.error_mask |= SENSOR_ERR_GSR;
        }
    }

    r.valid = (r.error_mask == 0x00);

    // ── Push to circular buffer ───────────────────────────────────────────────
    s_buf[s_bufHead] = r;
    s_bufHead = (s_bufHead + 1) % SENSOR_BUFFER_SIZE;
    if (s_bufCount < SENSOR_BUFFER_SIZE) s_bufCount++;

    return r;
}

const SensorReading* getSensorBuffer(int& count)
{
    // Re-order so index 0 = oldest.  Copy into a second static scratch buffer.
    static SensorReading s_ordered[SENSOR_BUFFER_SIZE];
    count = s_bufCount;
    // oldest entry sits at s_bufHead when buffer is full, else at 0.
    for (int i = 0; i < s_bufCount; i++) {
        int src = (s_bufHead - s_bufCount + i + SENSOR_BUFFER_SIZE) % SENSOR_BUFFER_SIZE;
        s_ordered[i] = s_buf[src];
    }
    return s_ordered;
}

String getSensorHealthReport()
{
    String report = "SensorHealth: ";
    report += (s_healthMask & SENSOR_ERR_HR)    ? "HR=FAIL "    : "HR=OK ";
    report += (s_healthMask & SENSOR_ERR_SPO2)  ? "SPO2=FAIL "  : "SPO2=OK ";
    report += (s_healthMask & SENSOR_ERR_GSR)   ? "GSR=FAIL "   : "GSR=OK ";
    report += (s_healthMask & SENSOR_ERR_TEMP)  ? "TEMP=FAIL "  : "TEMP=OK ";
    report += (s_healthMask & SENSOR_ERR_ACCEL) ? "ACCEL=FAIL"  : "ACCEL=OK";
    return report;
}
