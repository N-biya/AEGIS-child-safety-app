/// A single turn in the AEGIS Guard conversation.
///
/// Stored only on the device (see [GuardChatStore]) — these messages are never
/// written to Firestore so the family's discussions stay private.
class GuardMessage {
  final String text;
  final bool fromUser; // true = parent, false = AEGIS Guard
  final DateTime timestamp;

  const GuardMessage({
    required this.text,
    required this.fromUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'fromUser': fromUser,
        'ts': timestamp.toIso8601String(),
      };

  factory GuardMessage.fromJson(Map<String, dynamic> j) => GuardMessage(
        text: j['text'] as String,
        fromUser: j['fromUser'] as bool,
        timestamp: DateTime.parse(j['ts'] as String),
      );
}
