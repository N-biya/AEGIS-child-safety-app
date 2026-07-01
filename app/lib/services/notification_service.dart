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

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
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
