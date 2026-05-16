import 'package:shared_preferences/shared_preferences.dart';

/// All shared-preference keys are public constants so other files (e.g.
/// notification_settings_screen) can reference them for targeted saves.
class PrefsService {
  // ── Onboarding ────────────────────────────────────────────────────────────
  static const String onboardingDone = 'onboarding_done';
  static const String parentName     = 'parent_name';
  static const String childName      = 'child_name';
  static const String childAge       = 'child_age';

  // ── Extended profile ──────────────────────────────────────────────────────
  static const String profileEmail   = 'profile_email';
  static const String profilePhone   = 'profile_phone';
  static const String profileAddress = 'profile_address';
  static const String profileCity    = 'profile_city';
  static const String emergencyName  = 'emergency_name';
  static const String emergencyPhone = 'emergency_phone';
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

  // ── Onboarding ────────────────────────────────────────────────────────────
  static Future<bool> isOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(onboardingDone) ?? false;
  }

  static Future<void> completeOnboarding({
    required String parentNameVal,
    required String childNameVal,
    required int childAgeVal,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(parentName, parentNameVal);
    await p.setString(childName, childNameVal);
    await p.setInt(childAge, childAgeVal);
    await p.setBool(onboardingDone, true);
  }

  // ── Individual getters ────────────────────────────────────────────────────
  static Future<String> getParentName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(parentName) ?? 'Parent';
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
      'name':          p.getString(parentName)     ?? '',
      'email':         p.getString(profileEmail)   ?? '',
      'phone':         p.getString(profilePhone)   ?? '',
      'address':       p.getString(profileAddress) ?? '',
      'city':          p.getString(profileCity)    ?? '',
      'emergencyName': p.getString(emergencyName)  ?? '',
      'emergencyPhone':p.getString(emergencyPhone) ?? '',
      'photo':         p.getString(profilePhoto)   ?? '',
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(parentName,      name);
    await p.setString(profileEmail,    email);
    await p.setString(profilePhone,    phone);
    await p.setString(profileAddress,  address);
    await p.setString(profileCity,     city);
    await p.setString(emergencyName,   emergencyContactName);
    await p.setString(emergencyPhone,  emergencyContactPhone);
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
}
