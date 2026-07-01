# firmware/

PlatformIO project (WiFi setup, NEO-6M/SIM800L/sensor drivers, BLE pairing)
hasn't been scaffolded yet. `src/alert_logic.{h,cpp}` and
`src/geofence_logic.{h,cpp}` are the hardware-independent pieces of that
future project. Neither has an Arduino/ESP32 dependency, so they can be
written, reviewed, and tested now and dropped into the real PlatformIO
`src/` folder unchanged once hardware work starts.

- **`alert_logic`** — shared by every alert source (geofence breach today;
  stress/SpO2 detection once that pipeline exists). Formats the SMS body and
  the Firestore alert document, and sends both through one `raiseAlert()`
  call so they can't drift out of sync. The JSON shape it produces is
  pinned to match `AlertModel.fromMap` in `app/lib/models/alert_model.dart`
  exactly: `{ type, timestamp, vitals: {hr, spo2, gsr, temp}, location:
  {lat, lng}, resolved }` — the Alerts tab in the app reads this doc
  directly, so any field drift here breaks the UI.
- **`geofence_logic`** — cloud geofence sync (`IGeofenceFetcher`) and the
  Haversine breach check (`GeofenceMonitor`), which raises alerts through
  `alert_logic::raiseAlert()`.

## How it plugs into the real device

- `IGpsProvider::read()` — implement against the NEO-6M UART parser.
- `IVitalsProvider::read()` — implement against the live sensor pipeline
  (MAX30102 etc.), so a geofence-breach alert carries the child's real HR/SpO2
  at that moment instead of zeros.
- `ISmsSender::send()` — implement against the SIM800L AT-command driver.
- `IGeofenceFetcher::fetchGeofenceJson()` — implement against the Firestore
  REST call / Firebase-ESP32 client, returning the flat
  `{"lat":...,"lng":...,"radiusMeters":...}` shape for the child's
  `geofence` field.
- `IAlertPublisher::publish()` — implement against the same client, writing
  to `children/{childId}/alerts/{alertId}`.

`GeofenceMonitor` wires the geofence-specific pieces together: call
`refreshGeofence()` whenever WiFi is up, and `checkAndAlertIfBreached()` on
every monitoring tick (every 10s per the brief). It edge-triggers — one
alert per breach, not one per tick while still outside. When a future
stress/SpO2 detector is added, it should call `alert_logic::raiseAlert()`
directly with `type = "STRESS"` / `"SPO2"` — same function, same guaranteed
document shape, no new code needed on the app side.

## Running the test/simulation

No PlatformIO or hardware needed:

```
cd firmware/test
g++ -std=c++17 -I../src test_geofence_logic.cpp ../src/geofence_logic.cpp ../src/alert_logic.cpp -o test_geofence
./test_geofence
```

It exercises the full flow with mocked GPS/vitals/SMS/Firestore — including
the "enters geofence breach, stays out, comes back" sequence — verifies the
Firestore payload matches `AlertModel.fromMap`'s required fields exactly,
and prints a sample SMS body and Firestore alert payload.
