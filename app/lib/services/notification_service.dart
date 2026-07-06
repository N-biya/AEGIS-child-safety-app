import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'prefs_service.dart';

/// Fires real device notifications for AEGIS alerts using
/// flutter_local_notifications. Works while the app is running or
/// backgrounded; does not require a backend.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Invoked when the user taps a notification. Set by the alarm dispatcher so
  /// tapping the lock-screen emergency notification opens the alarm screen.
  static void Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) =>
          onNotificationTap?.call(resp.payload),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  /// Shows a notification for [alertType] (matches AlertModel.type), unless
  /// the user has muted that category, push alerts entirely, or it's
  /// currently within their quiet hours window.
  Future<void> showAlertIfEnabled({
    required int id,
    required String alertType,
    required String title,
    required String body,
  }) async {
    final prefs = await PrefsService.getNotifPrefs();
    final pushMaster = await PrefsService.getBool(PrefsService.pushMaster);
    if (!pushMaster) return;

    final categoryEnabled = switch (alertType) {
      'GEOFENCE' => prefs['safeZone'] as bool,
      'STRESS'   => prefs['stress'] as bool,
      'ELEVATED' => prefs['heartbeat'] as bool,
      'SPO2'     => prefs['heartbeat'] as bool,
      _          => true,
    };
    if (!categoryEnabled) return;

    if (prefs['quietHours'] as bool && _withinQuietHours(
          prefs['quietStart'] as String,
          prefs['quietEnd'] as String,
        )) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'aegis_alerts_urgent',
      'AEGIS Urgent Alerts',
      channelDescription: "Safety alerts from your child's AEGIS band",
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      vibrationPattern: null,
      ticker: 'AEGIS ALERT',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Fires an UNCONDITIONAL emergency notification for a safety alert.
  ///
  /// Unlike [showAlertIfEnabled], this ignores the push-master switch, muted
  /// categories, and quiet hours — a real emergency must never be silenced by
  /// a preference. It uses a full-screen intent (takes over the lock screen)
  /// and the *insistent* flag so the siren loops until the parent acts.
  Future<void> showEmergencyAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'aegis_emergency_alarm',
      'AEGIS Emergency Alarm',
      channelDescription: 'Unmissable full-screen safety alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'AEGIS EMERGENCY',
      // FLAG_INSISTENT (4) — loops the sound/vibration until dismissed.
      additionalFlags: Int32List.fromList(<int>[4]),
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.critical,
      ),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Clears a previously shown notification (e.g. once the alarm is dismissed).
  Future<void> cancel(int id) => _plugin.cancel(id);

  bool _withinQuietHours(String startStr, String endStr) {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = _toMinutes(startStr);
    final endMin = _toMinutes(endStr);
    if (startMin == endMin) return false;
    if (startMin < endMin) {
      return nowMin >= startMin && nowMin < endMin;
    }
    // Wraps past midnight, e.g. 22:00 → 07:00
    return nowMin >= startMin || nowMin < endMin;
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0;
    final m = int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0;
    return h * 60 + m;
  }
}
