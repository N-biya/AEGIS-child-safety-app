import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guard_message.dart';

/// On-device persistence for the AEGIS Guard chat history.
///
/// Deliberately backed by [SharedPreferences] only — the conversation never
/// leaves the phone and is never synced to Firebase, so a parent can discuss
/// their child freely. Clearing the app data (or "Clear chat") wipes it.
class GuardChatStore {
  static const _key = 'aegis_guard_history';
  static const _maxStored = 200; // keep history bounded

  static Future<List<GuardMessage>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GuardMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<GuardMessage> messages) async {
    final p = await SharedPreferences.getInstance();
    final trimmed = messages.length > _maxStored
        ? messages.sublist(messages.length - _maxStored)
        : messages;
    await p.setString(_key, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
