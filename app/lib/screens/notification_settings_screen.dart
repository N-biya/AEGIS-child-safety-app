import 'package:flutter/material.dart';
import '../router/app_router.dart' show kNavBarHeight;
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // ── Toggle states ─────────────────────────────────────────────────────────
  bool _safeZone  = true;
  bool _arrived   = true;
  bool _heartbeat = true;
  bool _stress    = true;
  bool _battery   = true;
  bool _summary   = false;
  bool _quiet     = false;

  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd   = const TimeOfDay(hour: 7,  minute: 0);

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await PrefsService.getNotifPrefs();
    final qs    = (prefs['quietStart'] as String).split(':');
    final qe    = (prefs['quietEnd']   as String).split(':');
    if (!mounted) return;
    setState(() {
      _safeZone  = prefs['safeZone']   as bool;
      _arrived   = prefs['arrived']    as bool;
      _heartbeat = prefs['heartbeat']  as bool;
      _stress    = prefs['stress']     as bool;
      _battery   = prefs['battery']    as bool;
      _summary   = prefs['summary']    as bool;
      _quiet     = prefs['quietHours'] as bool;
      _quietStart = TimeOfDay(
          hour:   int.tryParse(qs.elementAtOrNull(0) ?? '22') ?? 22,
          minute: int.tryParse(qs.elementAtOrNull(1) ?? '0')  ?? 0);
      _quietEnd = TimeOfDay(
          hour:   int.tryParse(qe.elementAtOrNull(0) ?? '7') ?? 7,
          minute: int.tryParse(qe.elementAtOrNull(1) ?? '0') ?? 0);
      _loading = false;
    });
  }

  // ── Persist a single bool toggle ─────────────────────────────────────────
  void _toggle(String key, bool value) =>
      PrefsService.setNotifBool(key, value);

  // ── Time picker ───────────────────────────────────────────────────────────
  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: kAccent),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final str =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (isStart) {
      setState(() => _quietStart = picked);
      await PrefsService.setNotifString(PrefsService.quietStart, str);
    } else {
      setState(() => _quietEnd = picked);
      await PrefsService.setNotifString(PrefsService.quietEnd, str);
    }
  }

  String _fmtTime(TimeOfDay t) {
    final h      = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m      = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? const Color(0x0FFFFFFF)
                                : const Color(0xB3FFFFFF),
                            border: Border.all(
                                color: AegisT.glassBorder(context)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: T),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Notifications',
                        style: AegisText.h5(color: T).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── List body ─────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: kAccent))
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                              18, 0, 18, kNavBarHeight + 24),
                          children: [
                            // Alert toggles
                            GlassCard(
                              padded: false,
                              child: Column(
                                children: [
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.location_off_outlined,
                                    label: 'Child left safe zone',
                                    value: _safeZone,
                                    onChanged: (v) {
                                      setState(() => _safeZone = v);
                                      _toggle(PrefsService.notifSafeZone, v);
                                    },
                                  ),
                                  _Div(isDark: isDark),
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.school_outlined,
                                    label: 'Child arrived at school',
                                    value: _arrived,
                                    onChanged: (v) {
                                      setState(() => _arrived = v);
                                      _toggle(PrefsService.notifArrived, v);
                                    },
                                  ),
                                  _Div(isDark: isDark),
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.favorite_outline,
                                    label: 'Unusual heartbeat detected',
                                    value: _heartbeat,
                                    onChanged: (v) {
                                      setState(() => _heartbeat = v);
                                      _toggle(PrefsService.notifHeartbeat, v);
                                    },
                                  ),
                                  _Div(isDark: isDark),
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.sentiment_dissatisfied_outlined,
                                    label: 'High stress detected',
                                    value: _stress,
                                    onChanged: (v) {
                                      setState(() => _stress = v);
                                      _toggle(PrefsService.notifStress, v);
                                    },
                                  ),
                                  _Div(isDark: isDark),
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.battery_alert_outlined,
                                    label: 'Low device battery',
                                    value: _battery,
                                    onChanged: (v) {
                                      setState(() => _battery = v);
                                      _toggle(PrefsService.notifBattery, v);
                                    },
                                  ),
                                  _Div(isDark: isDark),
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.summarize_outlined,
                                    label: 'Daily health summary',
                                    value: _summary,
                                    onChanged: (v) {
                                      setState(() => _summary = v);
                                      _toggle(PrefsService.notifSummary, v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Quiet hours section
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                              child: Text(
                                'QUIET HOURS',
                                style: AegisText.micro(color: D).copyWith(
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            GlassCard(
                              padded: false,
                              child: Column(
                                children: [
                                  _NRow(
                                    isDark: isDark, T: T,
                                    icon: Icons.bedtime_outlined,
                                    label: 'Enable quiet hours',
                                    value: _quiet,
                                    onChanged: (v) {
                                      setState(() => _quiet = v);
                                      _toggle(PrefsService.quietHours, v);
                                    },
                                  ),
                                  if (_quiet) ...[
                                    _Div(isDark: isDark),
                                    _TimeRow(
                                      isDark: isDark, T: T, D: D,
                                      icon: Icons.nightlight_outlined,
                                      label: 'Start time',
                                      time:  _fmtTime(_quietStart),
                                      onTap: () => _pickTime(true),
                                    ),
                                    _Div(isDark: isDark),
                                    _TimeRow(
                                      isDark: isDark, T: T, D: D,
                                      icon: Icons.wb_sunny_outlined,
                                      label: 'End time',
                                      time:  _fmtTime(_quietEnd),
                                      onTap: () => _pickTime(false),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────
class _NRow extends StatelessWidget {
  final bool isDark;
  final Color T;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NRow({
    required this.isDark,
    required this.T,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: kAccent,
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AegisText.body(color: T)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          _Toggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Tappable time row ─────────────────────────────────────────────────────────
class _TimeRow extends StatelessWidget {
  final bool isDark;
  final Color T, D;
  final IconData icon;
  final String label, time;
  final VoidCallback onTap;

  const _TimeRow({
    required this.isDark,
    required this.T,
    required this.D,
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: kAccentLight,
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AegisText.body(color: T)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Text(time,
                style: AegisText.label(color: kAccent)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: D),
          ],
        ),
      ),
    );
  }
}

// ── Custom toggle switch (replicates the one in settings_screen) ───────────────
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? kAccent : const Color(0x26FFFFFF),
          boxShadow: value
              ? const [
                  BoxShadow(
                      color: Color(0x4D7C3AED),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 19 : 3,
              top: 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section divider (same as settings_screen._Divider) ───────────────────────
class _Div extends StatelessWidget {
  final bool isDark;
  const _Div({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 60),
      color: isDark
          ? const Color(0x0DFFFFFF)
          : const Color(0x0A2D1A4A),
    );
  }
}
