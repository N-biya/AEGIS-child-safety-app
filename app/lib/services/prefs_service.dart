import 'package:shared_preferences/shared_preferences.dart';

/// All shared-preference keys are public constants so other files (e.g.
/// notification_settings_screen) can reference them for targeted saves.
class PrefsService {
  // ── Onboarding ────────────────────────────────────────────────────────────
  static const String onboardingDone  = 'onboarding_done';
  static const String parentName      = 'parent_name';
  static const String parentRelation  = 'parent_relation';
  static const String childName       = 'child_name';
  static const String childAge        = 'child_age';

  // ── Extended profile ──────────────────────────────────────────────────────
  static const String profilePhoto   = 'profile_photo';

  // ── Notification prefs ────────────────────────────────────────────────────
  static const String notifSafeZone  = 'notif_safe_zone';
  static const String notifArrived   = 'notif_arrived';
  static const String notifHeartbeat = 'notif_heartbeat';
  static const String notifStress    = 'notif_stress';
  static const String notifBattery   = 'notif_battery';
  static const String notifSummary   = 'notif_summary';
  static const String quietHours     = 'notif_quiet_hours';
  static const String quietStart     = 'notif_quiet_start';
  static const String quietEnd       = 'notif_quiet_end';
  static const String pushMaster     = 'notif_push_master';
  static const String smsMaster      = 'notif_sms_master';
  static const String stressSensitivity = 'stress_sensitivity';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static Future<bool> isOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(onboardingDone) ?? false;
  }

  static Future<void> completeOnboarding({
    required String parentNameVal,
    required String parentRelationVal,
    required String childNameVal,
    required int childAgeVal,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(parentName, parentNameVal);
    await p.setString(parentRelation, parentRelationVal);
    await p.setString(childName, childNameVal);
    await p.setInt(childAge, childAgeVal);
    await p.setBool(onboardingDone, true);
  }

  // ── Individual getters ────────────────────────────────────────────────────
  static Future<String> getParentName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(parentName) ?? 'Parent';
  }

  static Future<String> getParentRelation() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(parentRelation) ?? '';
  }

  static Future<String> getChildName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(childName) ?? 'Your child';
  }

  static Future<int> getChildAge() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(childAge) ?? 0;
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  static Future<Map<String, String>> getProfile() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name':     p.getString(parentName)     ?? '',
      'relation': p.getString(parentRelation) ?? '',
      'photo':    p.getString(profilePhoto)   ?? '',
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String relation,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(parentName,     name);
    await p.setString(parentRelation, relation);
  }

  /// Persists just the parent's name (used at sign-up and as a one-time
  /// backfill from the Firebase display name) without touching other fields.
  static Future<void> setParentName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(parentName, name);
  }

  static Future<void> saveProfilePhoto(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(profilePhoto, path);
  }

  // ── Notification prefs ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getNotifPrefs() async {
    final p = await SharedPreferences.getInstance();
    return {
      'safeZone':   p.getBool(notifSafeZone)   ?? true,
      'arrived':    p.getBool(notifArrived)     ?? true,
      'heartbeat':  p.getBool(notifHeartbeat)   ?? true,
      'stress':     p.getBool(notifStress)      ?? true,
      'battery':    p.getBool(notifBattery)     ?? true,
      'summary':    p.getBool(notifSummary)     ?? false,
      'quietHours': p.getBool(quietHours)       ?? false,
      'quietStart': p.getString(quietStart)     ?? '22:00',
      'quietEnd':   p.getString(quietEnd)       ?? '07:00',
    };
  }

  static Future<void> setNotifBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  static Future<void> setNotifString(String key, String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, value);
  }

  // ── Quick-toggle prefs (Settings screen) ──────────────────────────────────
  static Future<bool> getBool(String key, {bool fallback = true}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(key) ?? fallback;
  }

  static Future<void> setBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  static Future<double> getDouble(String key, {double fallback = 0.5}) async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(key) ?? fallback;
  }

  static Future<void> setDouble(String key, double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(key, value);
  }
}
