import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../models/child_model.dart';
import '../models/guard_message.dart';
import '../models/vital_model.dart';
import '../services/aegis_guard_brain.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/guard_chat_store.dart';
import '../utils/aegis_text.dart';
import '../utils/app_colors.dart';
import '../utils/vitals_snapshot.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

/// AEGIS Guard — a private, on-device chat where a parent can ask about their
/// child's data and talk through everyday concerns. Conversation history is
/// stored only on the device (never in Firebase). Fully theme-aware.
class AegisGuardScreen extends StatefulWidget {
  const AegisGuardScreen({super.key});

  @override
  State<AegisGuardScreen> createState() => _AegisGuardScreenState();
}

class _AegisGuardScreenState extends State<AegisGuardScreen> {
  final _firestore = FirestoreService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  AegisGuardBrain? _brain;
  List<GuardMessage> _messages = [];
  bool _loading = true;
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Read the uid synchronously before any await (no context across gaps).
    final uid = context.read<AuthService>().userId;

    // Stored chat is instant; child data comes from Firestore in parallel.
    final stored = await GuardChatStore.load();

    ChildModel? child;
    List<VitalModel> history = [];
    List<AlertModel> alerts = [];
    try {
      if (uid.isNotEmpty) {
        child = await _firestore.watchChildForUser(uid).first;
        if (child != null) {
          history = await _firestore.getHistory(child.id);
          alerts = await _firestore.getAlerts(child.id);
        }
      }
    } catch (_) {
      // Offline / no child yet — the brain still answers general questions.
    }

    final brain = AegisGuardBrain(
      VitalsSnapshot(child: child, history: history, alerts: alerts),
    );

    if (!mounted) return;
    setState(() {
      _brain = brain;
      _messages = stored;
      _loading = false;
    });

    if (_messages.isEmpty) {
      // Open with a grounded greeting and persist it as the first turn.
      _addMessage(GuardMessage(
        text: brain.greeting(),
        fromUser: false,
        timestamp: DateTime.now(),
      ));
    } else {
      _scrollToEnd();
    }
  }

  void _addMessage(GuardMessage m) {
    setState(() => _messages = [..._messages, m]);
    GuardChatStore.save(_messages);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _thinking) return;
    _input.clear();
    _addMessage(GuardMessage(
      text: trimmed,
      fromUser: true,
      timestamp: DateTime.now(),
    ));

    setState(() => _thinking = true);
    // A short, natural pause so the reply doesn't appear instantly.
    await Future.delayed(const Duration(milliseconds: 550));
    final answer = _brain?.reply(trimmed) ??
        "I'm just getting set up — give me a moment and try again.";
    if (!mounted) return;
    setState(() => _thinking = false);
    _addMessage(GuardMessage(
      text: answer,
      fromUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _clearChat() async {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassCard(
          borderRadius: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clear conversation?',
                  style: AegisText.h5(color: T).copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('This permanently deletes your chat history from this device. '
                  'It was never stored anywhere else.',
                  style: AegisText.body(color: D).copyWith(fontSize: 13, height: 1.5)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Cancel',
                          style: AegisText.label(color: D).copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: kAlert.withValues(alpha: isDark ? 0.9 : 1),
                      ),
                      child: Text('Clear',
                          style: AegisText.label(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;
    await GuardChatStore.clear();
    final greeting = _brain?.greeting();
    setState(() => _messages = []);
    if (greeting != null) {
      _addMessage(GuardMessage(text: greeting, fromUser: false, timestamp: DateTime.now()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            child: Column(
              children: [
                _header(T, D),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: kAccent))
                      : _messageList(),
                ),
                if (!_loading && _messages.length <= 1) _suggestionChips(D),
                _composer(T, D),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(Color T, Color D) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: T),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [kAccentLight, kAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [BoxShadow(color: Color(0x667C3AED), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AEGIS Guard',
                    style: AegisText.h5(color: T).copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 11, color: kSafe),
                    const SizedBox(width: 3),
                    Text('Private · on-device only',
                        style: AegisText.caption(color: D).copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearChat,
            tooltip: 'Clear chat',
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: D),
          ),
        ],
      ),
    );
  }

  // ── Message list ────────────────────────────────────────────────────────
  Widget _messageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: _messages.length + (_thinking ? 1 : 0),
      itemBuilder: (_, i) {
        if (_thinking && i == _messages.length) return const _TypingBubble();
        return _Bubble(message: _messages[i]);
      },
    );
  }

  // ── Suggestion chips ──────────────────────────────────────────────────────
  Widget _suggestionChips(Color D) {
    final chips = _brain?.suggestions() ?? const [];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(chips[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: kAccent.withValues(alpha: 0.12),
              border: Border.all(color: kAccent.withValues(alpha: 0.35)),
            ),
            child: Text(chips[i],
                style: AegisText.label(color: kAccent).copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  // ── Composer ──────────────────────────────────────────────────────────────
  Widget _composer(Color T, Color D) {
    final isDark = AegisT.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark ? const Color(0x1AFFFFFF) : Colors.white,
                border: Border.all(
                    color: isDark ? const Color(0x33FFFFFF) : const Color(0x1A7C3AED)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                style: AegisText.body(color: T).copyWith(fontSize: 14),
                cursorColor: kAccent,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Ask about ${_brain?.s.childName ?? 'your child'}…',
                  hintStyle: AegisText.body(color: D).copyWith(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_input.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kAccentLight, kAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: Color(0x667C3AED), blurRadius: 14, offset: Offset(0, 5))],
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble ─────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final GuardMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final fromUser = message.fromUser;
    final T = AegisT.text(context);

    final bg = fromUser
        ? kAccent
        : (isDark ? const Color(0x1FFFFFFF) : Colors.white);
    final textColor = fromUser ? Colors.white : T;
    final border = fromUser
        ? null
        : Border.all(color: isDark ? const Color(0x1AFFFFFF) : const Color(0x147C3AED));

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromUser ? 18 : 5),
            bottomRight: Radius.circular(fromUser ? 5 : 18),
          ),
          border: border,
          boxShadow: fromUser
              ? const [BoxShadow(color: Color(0x4D7C3AED), blurRadius: 14, offset: Offset(0, 5))]
              : null,
        ),
        child: Text(
          message.text,
          style: AegisText.body(color: textColor).copyWith(fontSize: 14, height: 1.45),
        ),
      ),
    );
  }
}

// ── Typing indicator ────────────────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final D = AegisT.textDim(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x1FFFFFFF) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: isDark ? const Color(0x1AFFFFFF) : const Color(0x147C3AED)),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_c.value - i * 0.2) % 1.0;
                final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: D),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
