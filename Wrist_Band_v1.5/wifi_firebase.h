#ifndef WIFI_FIREBASE_H
#define WIFI_FIREBASE_H

/**************************************************************
 * WiFi + Firebase (Firestore) uploader
 *
 * Connects to WiFi, syncs time over NTP, signs in to Firebase
 * as the device account, and uploads a vitals document to
 * children/{CHILD_ID}/vitals every UPLOAD_INTERVAL_MS.
 **************************************************************/

void WiFiFirebase_Init(void);
void WiFiFirebase_Task(void *pvParameters);

#endif // WIFI_FIREBASE_H
