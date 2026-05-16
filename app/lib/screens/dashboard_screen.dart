import 'dart:io';
import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../screens/parent_profile_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';
import '../widgets/hr_sparkline.dart';
import '../widgets/spo2_wave.dart';
import '../widgets/aegis_animations.dart';

// ── Info-modal content model ──────────────────────────────────────────────────
class _CardInfo {
  final String title, body;
  const _CardInfo(this.title, this.body);
}

const _heartbeatInfo = _CardInfo(
  'What is Heartbeat?',
  'This shows how fast your child\'s heart is beating. A normal resting rate '
      'for kids is between 70–110 beats per minute. A higher number can mean '
      'they\'re active, excited, or unwell.',
);
const _breathingInfo = _CardInfo(
  'What is Breathing Quality?',
  'This tells us how well oxygen is moving through your child\'s body. A '
      'reading of 95% or above is perfectly healthy. If it drops below 94%, '
      'the device will alert you.',
);
const _stressInfo = _CardInfo(
  'What is Stress Level?',
  'The wearable picks up subtle physical signs — like tiny changes in sweat '
      'and heart rhythm — to estimate how calm or stressed your child feels. '
      'Low is great, High means they may need comfort.',
);
const _tempInfo = _CardInfo(
  'What is Body Temperature?',
  'This is the temperature on your child\'s skin. Normal is roughly 36–37°C. '
      'If it goes above 37.5°C, it could be an early sign of fever and the '
      'app will notify you.',
);

// ── Dashboard screen ──────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewMap;
  final void Function(int)? onSwitchTab;

  const DashboardScreen({super.key, this.onViewMap, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String  _parentName = 'Parent';
  String  _childName  = 'Your child';
  int     _childAge   = 0;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pName   = await PrefsService.getParentName();
    final cName   = await PrefsService.getChildName();
    final cAge    = await PrefsService.getChildAge();
    final profile = await PrefsService.getProfile();
    final photo   = profile['photo'] ?? '';
    if (mounted) {
      setState(() {
        _parentName = pName;
        _childName  = cName;
        _childAge   = cAge;
        _photoPath  = photo.isEmpty ? null : photo;
      });
    }
  }

  void _openParentProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => const ParentProfileScreen()))
        .then((_) => _loadData()); // refresh name after editing
  }

  void _openNotifSettings() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const NotificationSettingsScreen()));
  }

  void _showChildSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChildBottomSheet(
        childName:  _childName,
        onSettings: () {
          Navigator.of(context).pop();
          widget.onSwitchTab?.call(4); // Settings tab
        },
      ),
    );
  }

  void _showInfoModal(_CardInfo info) {
    showDialog(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (_) => _InfoModal(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
    final D      = AegisT.textDim(context);

    // Display child label: "Aisha, 8" → "[childName], [age]"
    final childLabel = _childAge > 0
        ? '$_childName, $_childAge'
        : _childName;

    // Parent initial for avatar
    final parentInitial =
        _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(18, 0, 18, kNavBarHeight + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // ── Header ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tappable avatar + greeting → Parent Profile
                      GestureDetector(
                        onTap: _openParentProfile,
                        child: Row(
                          children: [
                            _Avatar(
                              initials: parentInitial,
                              gradient: const [
                                Color(0xFFF5A623),
                                Color(0xFFF43F5E)
                              ],
                              photoPath: _photoPath,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Good morning,',
                                    style: AegisText.body(color: D)
                                        .copyWith(fontSize: 12)),
                                Text(_parentName,
                                    style: AegisText.h5(color: T)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tappable bell → Notification Settings
                      GestureDetector(
                        onTap: _openNotifSettings,
                        child: _NotifButton(isDark: isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Hero status card (tappable → child bottom sheet) ────
                  GestureDetector(
                    onTap: _showChildSheet,
                    child: _HeroCard(
                      isDark:     isDark,
                      T:          T,
                      D:          D,
                      childLabel: childLabel,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── "Latest Health Snapshot" section heading ────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Health Snapshot',
                        style: AegisText.h5(color: T).copyWith(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Based on most recent device reading',
                        style: AegisText.label(color: D)
                            .copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── 2×2 vitals grid ─────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: _VitalCard(
                        title: 'Heartbeat',
                        value: '86',
                        unit:  'bpm',
                        trend: '+2',
                        info:  _heartbeatInfo,
                        onInfo: () => _showInfoModal(_heartbeatInfo),
                        child: HrSparkline(color: kAlert),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalCard(
                        title: 'Breathing Quality',
                        value: '98',
                        unit:  '%',
                        trend: '→',
                        info:  _breathingInfo,
                        onInfo: () => _showInfoModal(_breathingInfo),
                        child: Spo2Wave(
                            color: const Color(0xFF5EEAD4)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _VitalCard(
                        title: 'Stress Level',
                        value: 'Low',
                        unit:  '',
                        trend: '',
                        info:  _stressInfo,
                        onInfo: () => _showInfoModal(_stressInfo),
                        child: _StressBar(level: 0.22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VitalCard(
                        title: 'Body Temperature',
                        value: '36.4',
                        unit:  '°C',
                        trend: '',
                        info:  _tempInfo,
                        onInfo: () => _showInfoModal(_tempInfo),
                        child: _TempReadout(isDark: isDark),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // ── Recent Alerts ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Alerts',
                          style: AegisText.h5(color: T)
                              .copyWith(fontSize: 16)),
                      // "See all →" navigates to Alerts tab (index 2)
                      GestureDetector(
                        onTap: () => widget.onSwitchTab?.call(2),
                        child: Text(
                          'See all →',
                          style: AegisText.label(color: kAccent).copyWith(
                              fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AlertChip(
                            isDark: isDark,
                            type:   'stress',
                            title:  'Stress spike',
                            time:   '3:14 PM'),
                        const SizedBox(width: 10),
                        _AlertChip(
                            isDark: isDark,
                            type:   'safe',
                            title:  'Entered school',
                            time:   '8:02 AM'),
                        const SizedBox(width: 10),
                        _AlertChip(
                            isDark: isDark,
                            type:   'alert',
                            title:  'Geofence',
                            time:   'Yesterday'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero status card ───────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final bool isDark;
  final Color T, D;
  final String childLabel;

  const _HeroCard({
    required this.isDark,
    required this.T,
    required this.D,
    required this.childLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child row
          Row(
            children: [
              _Avatar(
                initials: 'A',
                gradient: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(childLabel, style: AegisText.h5(color: T)),
                    Text(
                      'Updated 12 sec ago · At School',
                      style: AegisText.caption(color: D)
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              _BatteryPill(isDark: isDark, pct: 74),
            ],
          ),
          const SizedBox(height: 16),

          // SAFE badge
          AegisPulse(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0x2E34D399), Color(0x0F34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0x4034D399)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: kSafe,
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x8034D399), blurRadius: 24)
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SAFE',
                          style: AegisText.h2(color: T).copyWith(
                              fontSize: 22,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w800),
                        ),
                        Text('Calm · all vitals normal',
                            style: AegisText.caption(color: D)
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0x1E34D399),
                    ),
                    child: Text(
                      '● LIVE',
                      style: AegisText.label(color: kSafe).copyWith(
                          fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Child card bottom sheet ───────────────────────────────────────────────────
class _ChildBottomSheet extends StatelessWidget {
  final String childName;
  final VoidCallback onSettings;

  const _ChildBottomSheet(
      {required this.childName, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final isDark     = AegisT.isDark(context);
    final T          = AegisT.text(context);
    final D          = AegisT.textDim(context);
    final cardBg     = isDark ? kDarkBg : Colors.white;
    final cardBorder =
        isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED);

    return Container(
      decoration: BoxDecoration(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        color: cardBg,
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isDark
                  ? const Color(0x26FFFFFF)
                  : const Color(0x267C3AED),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          const Text('🛡️', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 14),

          Text(
            "Want to update $childName's profile?",
            style: AegisText.h5(color: T)
                .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "You can change your child's name, age, photo, and device "
            'info in the Settings section.',
            style:
                AegisText.body(color: D).copyWith(fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Go to Settings button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onSettings,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: kAccent,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x667C3AED),
                        blurRadius: 22,
                        offset: Offset(0, 8)),
                    BoxShadow(
                        color: Color(0x40FFFFFF),
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: Offset(0, 1)),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Go to Settings',
                    style: AegisText.title(color: Colors.white)
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: Center(
                child: Text(
                  'Maybe later',
                  style: AegisText.body(color: D)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info modal ────────────────────────────────────────────────────────────────
class _InfoModal extends StatelessWidget {
  final _CardInfo info;
  const _InfoModal({required this.info});

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: GlassCard(
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    info.title,
                    style: AegisText.h5(color: T).copyWith(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close_rounded, size: 20, color: D),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              info.body,
              style: AegisText.body(color: D)
                  .copyWith(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vital card ─────────────────────────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  final String title, value, unit, trend;
  final _CardInfo info;
  final VoidCallback onInfo;
  final Widget child;

  const _VitalCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.info,
    required this.onInfo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AegisText.label(color: D).copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trend.isNotEmpty) ...[
                    Text(trend,
                        style: AegisText.micro(color: D)
                            .copyWith(fontSize: 10)),
                    const SizedBox(width: 4),
                  ],
                  // ⓘ info button
                  GestureDetector(
                    onTap: onInfo,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(Icons.info_outline_rounded,
                          size: 15, color: D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AegisText.numMedium(color: T)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit,
                    style: AegisText.unit(color: D)
                        .copyWith(fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Stress bar ─────────────────────────────────────────────────────────────────
class _StressBar extends StatelessWidget {
  final double level;
  const _StressBar({required this.level});

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    return Column(
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x0FFFFFFF)
                      : const Color(0x147C3AED),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: level,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                        colors: [kSafe, kStress]),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LOW',  style: AegisText.micro9(color: AegisT.textDim(context))),
            Text('MED',  style: AegisText.micro9(color: AegisT.textDim(context))),
            Text('HIGH', style: AegisText.micro9(color: AegisT.textDim(context))),
          ],
        ),
      ],
    );
  }
}

// ── Temp readout ───────────────────────────────────────────────────────────────
class _TempReadout extends StatelessWidget {
  final bool isDark;
  const _TempReadout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        SizedBox(
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), kSafe, kAlert],
                  ),
                ),
              ),
              Positioned(
                left: null,
                child: FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border:
                            Border.all(color: kAccent, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Normal range',
            style: AegisText.micro(color: AegisT.textDim(context))
                .copyWith(fontSize: 10)),
      ],
    );
  }
}

// ── Alert chip ─────────────────────────────────────────────────────────────────
class _AlertChip extends StatelessWidget {
  final bool isDark;
  final String type, title, time;
  const _AlertChip(
      {required this.isDark,
      required this.type,
      required this.title,
      required this.time});

  Color get _color {
    switch (type) {
      case 'safe':   return kSafe;
      case 'stress': return kStress;
      default:       return kAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    final c = _color;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isDark
            ? const Color(0x0DFFFFFF)
            : const Color(0xB3FFFFFF),
        border: Border.all(color: AegisT.glassBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.13),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c,
                  boxShadow: [
                    BoxShadow(
                        color: c.withValues(alpha: 0.6),
                        blurRadius: 8)
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AegisText.label(color: T).copyWith(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              Text(time,
                  style: AegisText.micro(color: D)
                      .copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Battery pill ───────────────────────────────────────────────────────────────
class _BatteryPill extends StatelessWidget {
  final bool isDark;
  final int  pct;
  const _BatteryPill({required this.isDark, required this.pct});

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isDark
            ? const Color(0x14FFFFFF)
            : const Color(0x147C3AED),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_5_bar_rounded, size: 14, color: kSafe),
          const SizedBox(width: 4),
          Text('$pct%',
              style: AegisText.label(color: T)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Notification button ────────────────────────────────────────────────────────
class _NotifButton extends StatelessWidget {
  final bool isDark;
  const _NotifButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? const Color(0x0FFFFFFF)
            : const Color(0xB3FFFFFF),
        border: Border.all(color: AegisT.glassBorder(context)),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.notifications_none_rounded,
                size: 20, color: AegisT.text(context)),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAlert,
                border: Border.all(
                    color: AegisT.bg(context), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable avatar ────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final List<Color> gradient;
  final double size;
  final String? photoPath;

  const _Avatar({
    required this.initials,
    required this.gradient,
    this.size = 44,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    final radius   = BorderRadius.circular(size * 0.32);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: hasPhoto
            ? null
            : LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: hasPhoto
          ? ClipRRect(
              borderRadius: radius,
              child: Image.file(
                File(photoPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: AegisText.h5(color: Colors.white).copyWith(
                        fontSize: size * 0.36,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: AegisText.h5(color: Colors.white).copyWith(
                    fontSize: size * 0.36, fontWeight: FontWeight.w800),
              ),
            ),
    );
  }
}
