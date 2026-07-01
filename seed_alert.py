"""Seed one sample alert + verify both vitals and alerts read back in the
exact shape the app's VitalModel / AlertModel expect."""
import datetime
import firebase_admin
from firebase_admin import credentials, firestore

KEY_PATH = r"E:\FypApp\aegis-child-safety-app-firebase-adminsdk-fbsvc-bf931b5676.json"
CHILD_ID = "ecc086c4-215c-4661-b6c4-693cadb54d16"
SEED_LAT, SEED_LNG = 31.5204, 74.3587

REQUIRED_VITALS = {"hr", "spo2", "gsr", "temp", "movement", "status", "lat", "lng", "timestamp"}
REQUIRED_ALERT  = {"type", "timestamp", "vitals", "location", "resolved"}


def main():
    app = firebase_admin.initialize_app(credentials.Certificate(KEY_PATH))
    db = firestore.client()
    child = db.collection("children").document(CHILD_ID)

    now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Seed a sample alert shaped exactly like AlertModel.fromMap expects.
    child.collection("alerts").add({
        "type": "STRESS",
        "timestamp": now_iso,
        "vitals": {"hr": 118, "spo2": 96},
        "location": {"lat": SEED_LAT, "lng": SEED_LNG},
        "resolved": False,
    })
    print("[firestore] seeded sample alert")

    # --- verify both collections read back with all required fields ---
    v = list(child.collection("vitals").order_by(
        "timestamp", direction=firestore.Query.DESCENDING).limit(1).stream())
    a = list(child.collection("alerts").order_by(
        "timestamp", direction=firestore.Query.DESCENDING).limit(1).stream())

    print(f"\nvitals docs: {len(list(child.collection('vitals').stream()))}")
    if v:
        d = v[0].to_dict()
        missing = REQUIRED_VITALS - d.keys()
        print("  latest vitals OK" if not missing else f"  MISSING vitals fields: {missing}")
    print(f"alerts docs: {len(list(child.collection('alerts').stream()))}")
    if a:
        d = a[0].to_dict()
        missing = REQUIRED_ALERT - d.keys()
        nested_ok = (isinstance(d.get('vitals'), dict) and {'hr','spo2'} <= d['vitals'].keys()
                     and isinstance(d.get('location'), dict) and {'lat','lng'} <= d['location'].keys())
        print("  latest alert OK" if not missing and nested_ok else
              f"  PROBLEM: missing={missing} nested_ok={nested_ok}")

    firebase_admin.delete_app(app)


if __name__ == "__main__":
    main()
