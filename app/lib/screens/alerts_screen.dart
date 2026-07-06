import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _filterIndex = 0;
  static const _filters = ['All', 'Stress', 'Geofence', 'Vitals'];

  int _timeRangeIndex = 0; // 0=All time, 1=Today, 2=This week, 3=This month
  static const _timeRanges = ['All time', 'Today', 'This week', 'This month'];

  int _statusIndex = 0; // 0=All, 1=Unresolved, 2=Resolved
  static const _statuses = ['All', 'Unresolved', 'Resolved'];

  final _firestore = FirestoreService();
  StreamSubscription<List<AlertModel>>? _alertSub;
  List<AlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final uid = context.read<AuthService>().userId;
    if (uid.isEmpty) return;
    _firestore.watchChildForUser(uid).first.then((child) {
      if (child == null || !mounted) return;
      _alertSub = _firestore.watchAlerts(child.id).listen((alerts) {
        if (mounted) setState(() => _alerts = alerts);
      });
    });
  }

  String _typeBucket(String type) {
    switch (type) {
      case 'STRESS':
      case 'ELEVATED':
        return 'Stress';
      case 'GEOFENCE':
      case 'FORBIDDEN':
        return 'Geofence';
      default:
        return 'Vitals';
    }
  }

  bool get _hasActiveFilters => _timeRangeIndex != 0 || _statusIndex != 0;

  List<AlertModel> get _filtered {
    final now = DateTime.now();
    return _alerts.where((a) {
      if (_filterIndex != 0 && _typeBucket(a.type) != _filters[_filterIndex]) return false;
      switch (_timeRangeIndex) {
        case 1:
          if (!_isSameDay(a.timestamp, now)) return false;
          break;
        case 2:
          if (now.difference(a.timestamp) > const Duration(days: 7)) return false;
          break;
        case 3:
          if (now.difference(a.timestamp) > const Duration(days: 30)) return false;
          break;
      }
      if (_statusIndex == 1 && a.resolved) return false;
      if (_statusIndex == 2 && !a.resolved) return false;
      return true;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<({int timeRange, int status})>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AlertFilterSheet(
        timeRangeIndex: _timeRangeIndex,
        statusIndex: _statusIndex,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _timeRangeIndex = result.timeRange;
        _statusIndex = result.status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);
    final alerts = _filtered;

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 60, 18, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Alerts',
                              style: AegisText.h2(color: T)
                                  .copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.05)),
                          Text(
                            '${alerts.length} events · ${_timeRanges[_timeRangeIndex].toLowerCase()}',
                            style: AegisText.caption(color: D).copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _openFilterSheet,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _hasActiveFilters
                                    ? kAccent.withValues(alpha: 0.18)
                                    : (isDark ? const Color(0x0FFFFFFF) : const Color(0xB3FFFFFF)),
                                border: Border.all(
                                  color: _hasActiveFilters ? kAccent : AegisT.glassBorder(context),
                                ),
                              ),
                              child: Icon(Icons.tune_rounded, size: 18,
                                  color: _hasActiveFilters ? kAccent : T),
                            ),
                            if (_hasActiveFilters)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kAccent,
                                    border: Border.all(color: AegisT.bg(context), width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filter chips ───────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final active = i == _filterIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? kAccent
                                : (isDark ? const Color(0x0DFFFFFF) : const Color(0xB3FFFFFF)),
                            border: active
                                ? null
                                : Border.all(color: AegisT.glassBorder(context)),
                            boxShadow: active
                                ? const [BoxShadow(color: Color(0x4D7C3AED), blurRadius: 12, offset: Offset(0, 4))]
                                : null,
                          ),
                          child: Text(
                            _filters[i],
                            style: AegisText.label(
                              color: active ? Colors.white : T,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Alert list ─────────────────────────────────────────
                Expanded(
                  child: alerts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No alerts match these filters.',
                              textAlign: TextAlign.center,
                              style: AegisText.caption(color: D).copyWith(fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(18, 0, 18, kNavBarHeight + 16),
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _AlertTile(alert: alerts[i], isDark: isDark, T: T, D: D),
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

// ── Filter sheet (tune button) ──────────────────────────────────────────────
class _AlertFilterSheet extends StatefulWidget {
  final int timeRangeIndex;
  final int statusIndex;
  const _AlertFilterSheet({required this.timeRangeIndex, required this.statusIndex});

  @override
  State<_AlertFilterSheet> createState() => _AlertFilterSheetState();
}

class _AlertFilterSheetState extends State<_AlertFilterSheet> {
  late int _timeRange;
  late int _status;

  @override
  void initState() {
    super.initState();
    _timeRange = widget.timeRangeIndex;
    _status = widget.statusIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    Widget chipGroup(List<String> options, int selected, void Function(int) onSelect) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(options.length, (i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active ? kAccent : (isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED)),
              ),
              child: Text(options[i],
                  style: AegisText.label(color: active ? Colors.white : D)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          );
        }),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: isDark ? kDarkBg : Colors.white,
        border: Border.all(color: isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark ? const Color(0x26FFFFFF) : const Color(0x267C3AED),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter alerts',
                style: AegisText.h2(color: T).copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Text('Time range', style: AegisText.caption(color: D).copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            chipGroup(_AlertsScreenState._timeRanges, _timeRange, (i) => setState(() => _timeRange = i)),
            const SizedBox(height: 18),
            Text('Status', style: AegisText.caption(color: D).copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            chipGroup(_AlertsScreenState._statuses, _status, (i) => setState(() => _status = i)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _timeRange = 0; _status = 0; }),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AegisT.glassBorder(context)),
                    ),
                    child: Text('Reset', style: AegisText.body(color: D).copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop((timeRange: _timeRange, status: _status)),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: kAccent,
                    ),
                    child: Text('Apply', style: AegisText.body(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Single alert tile ─────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final AlertModel alert;
  final bool isDark;
  final Color T, D;

  const _AlertTile({required this.alert, required this.isDark, required this.T, required this.D});

  Color get _color {
    switch (alert.type) {
      case 'STRESS':
      case 'ELEVATED':
        return kStress;
      case 'SPO2':
        return const Color(0xFF5EEAD4);
      default:
        return kAlert;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case 'STRESS':    return Icons.bolt_rounded;
      case 'ELEVATED':  return Icons.favorite_rounded;
      case 'SPO2':      return Icons.air_rounded;
      case 'FORBIDDEN': return Icons.block_rounded;
      default:          return Icons.location_on_outlined;
    }
  }

  String get _desc {
    switch (alert.type) {
      case 'STRESS':   return 'Elevated stress · HR ${alert.heartRate} bpm';
      case 'ELEVATED': return 'Elevated heart rate · ${alert.heartRate} bpm';
      case 'SPO2':      return 'Low oxygen · SpO₂ ${alert.spo2}%';
      case 'GEOFENCE':  return 'Left the designated safe zone';
      case 'FORBIDDEN': return 'Entered a restricted (no-go) area';
      default:          return alert.typeLabel;
    }
  }

  String get _time {
    final now = DateTime.now();
    final t = alert.timestamp;
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final clock = '$h:$m $period';
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return 'Today · $clock';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (t.year == yesterday.year && t.month == yesterday.month && t.day == yesterday.day) {
      return 'Yesterday · $clock';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[t.month - 1]} ${t.day} · $clock';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: c,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: c.withValues(alpha: 0.13),
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: c,
                          ),
                          child: Icon(_icon, color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(alert.typeLabel,
                                  style: AegisText.h5(color: T)
                                      .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                            if (alert.resolved)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: kSafe),
                              ),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            _desc,
                            style: AegisText.caption(color: D).copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(_time,
                              style: AegisText.micro(color: D)
                                  .copyWith(fontSize: 10, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: D),
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
