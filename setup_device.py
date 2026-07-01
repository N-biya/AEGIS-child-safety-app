"""One-time setup so the ESP32 wristband can stream vitals to Firestore.

Does three things using the Admin SDK (bypasses rules):
  1. Creates (or reuses) a dedicated device auth account (email/password).
  2. Adds that account's UID to the child's `linkedDevices` array + sets deviceId.
  3. Seeds one sample vitals doc so the path exists and the app shows data.

Run once:  python setup_device.py
Prints the exact values to put in the hardware's secrets.h.
"""
import secrets as pysecrets
import datetime
import json
import firebase_admin
from firebase_admin import credentials, auth, firestore

KEY_PATH = r"E:\FypApp\aegis-child-safety-app-firebase-adminsdk-fbsvc-bf931b5676.json"

# --- target child: wajeehaa ---
CHILD_ID    = "ecc086c4-215c-4661-b6c4-693cadb54d16"
DEVICE_EMAIL = "band-wajeehaa@aegis.device"
DEVICE_ID    = "esp32-wajeehaa"

# Placeholder location (Lahore) for the seed doc — real fixes come from the band's GPS.
SEED_LAT, SEED_LNG = 31.5204, 74.3587


def main():
    cred = credentials.Certificate(KEY_PATH)
    app = firebase_admin.initialize_app(cred)
    project_id = cred.project_id
    db = firestore.client()

    # 1. Device auth account ---------------------------------------------------
    password = pysecrets.token_urlsafe(16)
    try:
        user = auth.get_user_by_email(DEVICE_EMAIL)
        auth.update_user(user.uid, password=password)
        print(f"[auth] reused existing device account, reset password")
    except auth.UserNotFoundError:
        user = auth.create_user(email=DEVICE_EMAIL, password=password)
        print(f"[auth] created device account")
    uid = user.uid

    # 2. Link device to child --------------------------------------------------
    child_ref = db.collection("children").document(CHILD_ID)
    child_ref.set(
        {
            "linkedDevices": firestore.ArrayUnion([uid]),
            "deviceId": DEVICE_ID,
        },
        merge=True,
    )
    print(f"[firestore] linked device UID to child {CHILD_ID}")

    # 3. Seed one vitals doc so the path exists + dashboard lights up ----------
    now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    child_ref.collection("vitals").add(
        {
            "hr": 92,
            "spo2": 98,
            "gsr": 5.2,
            "temp": 36.6,
            "movement": 1.1,
            "status": "NORMAL",
            "lat": SEED_LAT,
            "lng": SEED_LNG,
            "timestamp": now_iso,
            "battery": 100.0,
        }
    )
    print(f"[firestore] seeded sample vitals doc")

    # --- hand-off summary -----------------------------------------------------
    print("\n" + "=" * 64)
    print("  secrets.h values for the hardware person")
    print("=" * 64)
    print(f'  FIREBASE_PROJECT_ID    "{project_id}"')
    print(f'  FIREBASE_USER_EMAIL    "{DEVICE_EMAIL}"')
    print(f'  FIREBASE_USER_PASSWORD "{password}"')
    print(f'  CHILD_ID               "{CHILD_ID}"')
    print(f"  (device auth UID: {uid})")
    print("=" * 64)
    print("  Still needed from the Firebase console (Project Settings > General):")
    print("    FIREBASE_API_KEY  -> the Web API Key")
    print("  And the WiFi the band will use: WIFI_SSID / WIFI_PASSWORD")
    print("=" * 64)

    firebase_admin.delete_app(app)


if __name__ == "__main__":
    main()
