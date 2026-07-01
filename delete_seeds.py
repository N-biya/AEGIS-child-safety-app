"""Delete the placeholder seed docs from wajeehaa's vitals + alerts so only
real band data remains. Safe to run now (only seeds exist)."""
import firebase_admin
from firebase_admin import credentials, firestore

KEY_PATH = r"E:\FypApp\aegis-child-safety-app-firebase-adminsdk-fbsvc-bf931b5676.json"
CHILD_ID = "ecc086c4-215c-4661-b6c4-693cadb54d16"


def clear(col):
    n = 0
    for doc in col.stream():
        doc.reference.delete()
        n += 1
    return n


def main():
    app = firebase_admin.initialize_app(credentials.Certificate(KEY_PATH))
    db = firestore.client()
    child = db.collection("children").document(CHILD_ID)

    v = clear(child.collection("vitals"))
    a = clear(child.collection("alerts"))
    print(f"deleted {v} vitals doc(s), {a} alert doc(s)")

    firebase_admin.delete_app(app)


if __name__ == "__main__":
    main()
