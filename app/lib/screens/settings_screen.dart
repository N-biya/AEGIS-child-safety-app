import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../utils/theme_provider.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onViewMap;
  const SettingsScreen({super.key, this.onViewMap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushAlerts = true;
  bool _smsAlerts  = true;
  double _sensitivity = 0.5;

  @override
  Widget build(BuildContext context) {
    final isDark   = AegisT.isDark(context);
    final T        = AegisT.text(context);
    final D        = AegisT.textDim(context);
    final themeNot = context.watch<ThemeNotifier>();

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(18, 60, 18, kNavBarHeight + 24),
              children: [
                Text('Settings',
                    style: AegisText.h2(color: T)
                        .copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),

                // ── Child profile card ───────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [kAccentLight, kAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x4D7C3AED), blurRadius: 20, offset: Offset(0, 8)),
                          ],
                        ),
                        child: Center(
                          child: Text('A',
                              style: AegisText.h2(color: Colors.white)
                                  .copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aisha Khan', style: AegisText.h5(color: T).copyWith(fontSize: 17)),
                            const SizedBox(height: 2),
                            Text('Band · AEG-K8L · 8 years old',
                                style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kSafe,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text('CONNECTED',
                                  style: AegisText.label(color: kSafe)
                                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.3)),
                            ]),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: D),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Emergency Contacts ───────────────────────────────────
                _SectionLabel('Emergency Contacts', D),
                GlassCard(
                  padded: false,
                  child: Column(children: [
                    _SettingsRow(isDark: isDark, T: T, D: D, iconBg: kAlert,  iconWidget: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 14), title: 'Mom · Sarah Khan', detail: '+1 (555) 0148'),
                    _Divider(isDark: isDark),
                    _SettingsRow(isDark: isDark, T: T, D: D, iconBg: kAccent, iconWidget: const Icon(Icons.person_outlined, color: Colors.white, size: 14), title: 'Dad · Omar Khan', detail: '+1 (555) 0173'),
                    _Divider(isDark: isDark),
                    _SettingsRow(isDark: isDark, T: T, D: D, iconBg: kStress, iconWidget: const Icon(Icons.elderly_outlined, color: Colors.white, size: 14), title: 'Grandma · Naila', detail: '+1 (555) 0291'),
                    _Divider(isDark: isDark),
                    _SettingsRow(
                      isDark: isDark, T: T, D: D,
                      iconBg: isDark ? const Color(0x14FFFFFF) : const Color(0x1A7C3AED),
                      iconWidget: Icon(Icons.add_rounded, color: kAccent, size: 16),
                      title: 'Add contact',
                      titleColor: kAccent,
                      isLast: true,
                      showChevron: false,
                    ),
                  ]),
                ),
                const SizedBox(height: 18),

                // ── Notifications ────────────────────────────────────────
                _SectionLabel('Notifications', D),
                GlassCard(
                  padded: false,
                  child: Column(children: [
                    _ToggleRow(isDark: isDark, T: T, iconBg: kAccent, icon: Icons.notifications_outlined, label: 'Push alerts', value: _pushAlerts, onChanged: (v) => setState(() => _pushAlerts = v)),
                    _Divider(isDark: isDark),
                    _ToggleRow(isDark: isDark, T: T, iconBg: kAccentLight, icon: Icons.sms_outlined, label: 'SMS via band GSM', value: _smsAlerts, onChanged: (v) => setState(() => _smsAlerts = v)),
                    _Divider(isDark: isDark),
                    _SensitivityRow(isDark: isDark, T: T, D: D, value: _sensitivity, onChanged: (v) => setState(() => _sensitivity = v)),
                  ]),
                ),
                const SizedBox(height: 18),

                // ── Appearance ───────────────────────────────────────────
                _SectionLabel('Appearance', D),
                GlassCard(
                  padded: false,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme',
                            style: AegisText.body(color: T)
                                .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _ThemeChip(
                            label: 'Velvet Night',
                            bg: kDarkBg,
                            cardBg: kDarkCard,
                            textColor: kDarkText,
                            selected: isDark,
                            onTap: () => themeNot.setDark(true),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _ThemeChip(
                            label: 'Warm Blossom',
                            bg: kLightBg,
                            cardBg: kLightNav,
                            textColor: kLightText,
                            selected: !isDark,
                            onTap: () => themeNot.setDark(false),
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Account ──────────────────────────────────────────────
                _SectionLabel('Account', D),
                GlassCard(
                  padded: false,
                  child: Column(children: [
                    _SettingsRow(isDark: isDark, T: T, D: D, iconBg: kSafe,    iconWidget: const Icon(Icons.location_on_outlined, color: Colors.white, size: 14), title: 'Geofence settings'),
                    _Divider(isDark: isDark),
                    _SettingsRow(isDark: isDark, T: T, D: D, iconBg: kOffline, iconWidget: const Icon(Icons.lock_outlined, color: Colors.white, size: 14), title: 'Privacy & data'),
                    _Divider(isDark: isDark),
                    _SettingsRow(isDark: isDark, T: T, D: D, iconBg: const Color(0xFF64748B), iconWidget: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 14), title: 'About AEGIS', detail: 'v1.4.2', isLast: true),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Sign Out ─────────────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    await context.read<AuthService>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kAlert.withValues(alpha: 0.4)),
                      color: kAlert.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text('Sign Out',
                          style: AegisText.title(color: kAlert)),
                    ),
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

// ── Section label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        text,
        style: AegisText.micro(color: color)
            .copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Generic settings row ───────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final bool isDark;
  final Color T, D;
  final Color iconBg;
  final Widget iconWidget;
  final String title;
  final String detail;
  final Color? titleColor;
  final bool isLast;
  final bool showChevron;

  const _SettingsRow({
    required this.isDark,
    required this.T,
    required this.D,
    required this.iconBg,
    required this.iconWidget,
    required this.title,
    this.detail = '',
    this.titleColor,
    this.isLast = false,
    this.showChevron = true,
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: iconBg),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AegisText.body(color: titleColor ?? T).copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(detail, style: AegisText.caption(color: D).copyWith(fontSize: 11)),
                ],
              ],
            ),
          ),
          if (showChevron)
            Icon(Icons.chevron_right_rounded, size: 16, color: D),
        ],
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final bool isDark;
  final Color T;
  final Color iconBg;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.isDark, required this.T, required this.iconBg, required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: iconBg),
            child: Center(child: Icon(icon, color: Colors.white, size: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AegisText.body(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w600))),
          _AegisToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Sensitivity slider row ─────────────────────────────────────────────────
class _SensitivityRow extends StatelessWidget {
  final bool isDark;
  final Color T, D;
  final double value;
  final ValueChanged<double> onChanged;

  const _SensitivityRow({required this.isDark, required this.T, required this.D, required this.value, required this.onChanged});

  String get _label {
    if (value < 0.33) return 'Low';
    if (value < 0.66) return 'Medium';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stress sensitivity',
                  style: AegisText.body(color: T).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(_label,
                  style: AegisText.h5(color: kAccent).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: kAccent,
              inactiveTrackColor: isDark ? const Color(0x0FFFFFFF) : const Color(0x147C3AED),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: const Color(0x267C3AED),
              trackHeight: 6,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

// ── Theme chip ────────────────────────────────────────────────────────────
class _ThemeChip extends StatelessWidget {
  final String label;
  final Color bg, cardBg, textColor;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({required this.label, required this.bg, required this.cardBg, required this.textColor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bg,
          border: Border.all(
            color: selected ? kAccent : const Color(0x14FFFFFF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cardBg,
                  ),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: AegisText.label(color: textColor)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kAccent),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Custom toggle switch ──────────────────────────────────────────────────
class _AegisToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AegisToggle({required this.value, required this.onChanged});

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
              ? const [BoxShadow(color: Color(0x4D7C3AED), blurRadius: 8, offset: Offset(0, 2))]
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
                  boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 60),
      color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0A2D1A4A),
    );
  }
}
