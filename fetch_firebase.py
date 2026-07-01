"""Fetch all Firestore data using the Admin SDK and dump to JSON.

Usage: python fetch_firebase.py
Writes: firebase_dump.json  (full recursive tree of every collection)
"""
import json
import datetime
import firebase_admin
from firebase_admin import credentials, firestore

KEY_PATH = r"E:\FypApp\aegis-child-safety-app-firebase-adminsdk-fbsvc-bf931b5676.json"
OUT_PATH = r"E:\FypApp\firebase_dump.json"


def _serialize(v):
    """Make Firestore values JSON-safe."""
    if isinstance(v, datetime.datetime):
        return v.isoformat()
    if hasattr(v, "latitude") and hasattr(v, "longitude"):  # GeoPoint
        return {"lat": v.latitude, "lng": v.longitude}
    if hasattr(v, "path"):  # DocumentReference
        return v.path
    return v


def dump_collection(col_ref):
    """Recursively dump a collection -> {doc_id: {fields..., _subcollections}}."""
    out = {}
    for doc in col_ref.stream():
        data = {k: _serialize(v) for k, v in (doc.to_dict() or {}).items()}
        subs = {}
        for sub in doc.reference.collections():
            subs[sub.id] = dump_collection(sub)
        if subs:
            data["_subcollections"] = subs
        out[doc.id] = data
    return out


def main():
    cred = credentials.Certificate(KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    result = {}
    counts = {}
    for col in db.collections():
        result[col.id] = dump_collection(col)
        counts[col.id] = len(result[col.id])

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

    print("Top-level collections and doc counts:")
    for name, n in counts.items():
        print(f"  {name}: {n} docs")
    print(f"\nFull dump written to: {OUT_PATH}")


if __name__ == "__main__":
    main()
