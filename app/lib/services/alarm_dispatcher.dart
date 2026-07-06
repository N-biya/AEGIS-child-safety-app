import 'package:flutter/material.dart';

import '../models/alert_model.dart';
import '../models/child_model.dart';
import '../screens/alert_alarm_screen.dart';
import '../utils/app_globals.dart';
import 'alarm_service.dart';
import 'notification_service.dart';

/// Central decision point for an incoming WiFi safety alert.
///
/// Foreground → immediately throw up the full-screen [AlertAlarmScreen]
/// (in-app looping siren). Backgrounded / locked → fire an unmissable
/// full-screen-intent notification whose siren loops until tapped; tapping it
/// resumes the app and opens the same alarm screen.
class AlarmDispatcher {
  AlarmDispatcher._();

  static const int emergencyNotifId = 909090;

  /// A full-screen SOS can't fire more than once per this window. Extra alerts
  /// that arrive inside it are logged and dropped, so a flapping sensor that
  /// crosses the trigger repeatedly can't scream over and over. (This is a UI
  /// safeguard only — it does NOT change the band's detection threshold.)
  static const Duration _cooldown = Duration(minutes: 1);
  static DateTime? _lastAlarmAt;

  static AlertModel? _pendingAlert;
  static ChildModel? _pendingChild;

  /// Registers the notification-tap handler. Call once at startup.
  static void wire() {
    NotificationService.onNotificationTap = (_) => _onNotificationTapped();
  }

  /// Handle a brand-new alert coming from the band over WiFi.
  static void raise(AlertModel alert, ChildModel? child) {
    final now = DateTime.now();
    if (_lastAlarmAt != null && now.difference(_lastAlarmAt!) < _cooldown) {
      final ago = now.difference(_lastAlarmAt!).inSeconds;
      debugPrint('[AlarmDispatcher] cooldown active (${ago}s since last SOS) — '
          'suppressing full-screen alarm for ${alert.type} ${alert.id}');
      return;
    }
    _lastAlarmAt = now;

    _pendingAlert = alert;
    _pendingChild = child;

    final state = WidgetsBinding.instance.lifecycleState;
    final foreground = state == null || state == AppLifecycleState.resumed;

    if (foreground) {
      _openAlarmScreen(alert, child);
    } else {
      NotificationService().showEmergencyAlert(
        id: emergencyNotifId,
        title: _title(alert),
        body: _body(alert, child),
      );
    }
  }

  static void _onNotificationTapped() {
    final alert = _pendingAlert;
    if (alert == null) return;
    // Silence the looping notification; the in-app siren takes over.
    NotificationService().cancel(emergencyNotifId);
    _openAlarmScreen(alert, _pendingChild);
  }

  static void _openAlarmScreen(AlertModel alert, ChildModel? child) {
    // Don't stack a second alarm on top of one that's already ringing.
    if (AlarmService.instance.isRinging) return;
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AlertAlarmScreen(alert: alert, child: child),
    ));
  }

  static String _title(AlertModel alert) {
    switch (alert.type) {
      case 'GEOFENCE':  return '🚨 SAFE ZONE BREACH';
      case 'FORBIDDEN': return '🚫 RESTRICTED AREA';
      default:          return '🚨 ${alert.typeLabel}';
    }
  }

  static String _body(AlertModel alert, ChildModel? child) {
    final name = child?.name ?? 'Your child';
    switch (alert.type) {
      case 'GEOFENCE':
        return '$name has left the safe zone. Tap to respond.';
      case 'FORBIDDEN':
        return '$name entered a place you marked off-limits. Tap to respond.';
      default:
        return "$name's AEGIS band reported an emergency. Tap to respond.";
    }
  }
}
