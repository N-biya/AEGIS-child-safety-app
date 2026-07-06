import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/child_model.dart';
import '../router/app_router.dart';
import '../screens/about_aegis_screen.dart';
import '../screens/privacy_data_screen.dart';
import '../screens/safe_zone_picker_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
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
  final _firestore = FirestoreService();

  // ── Child profile ──────────────────────────────────────────────────────
  void _showChildProfileSheet(ChildModel child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChildProfileSheet(
        child: child,
        onSave: (name, age) async {
          await _firestore.updateChildProfile(
            child.id,
            name: name,
            age: age,
          );
        },
      ),
    );
  }

  // ── Emergency contacts ─────────────────────────────────────────────────
  void _showContactSheet(ChildModel child, {EmergencyContactModel? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmergencyContactSheet(
        existing: existing,
        nextPriority: child.emergencyContacts.length + 1,
        onSave: (contact) async {
          final updated = [...child.emergencyContacts];
          final idx = updated.indexWhere((c) => c.id == contact.id);
          if (idx >= 0) {
            updated[idx] = contact;
          } else {
            updated.add(contact);
          }
          await _firestore.updateEmergencyContacts(child.id, updated);
        },
        onDelete: existing == null
            ? null
            : () async {
                final updated = [...child.emergencyContacts]
                  ..removeWhere((c) => c.id == existing.id);
                await _firestore.updateEmergencyContacts(child.id, updated);
              },
      ),
    );
  }

  Future<void> _callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  // ── Geofence ────────────────────────────────────────────────────────────
  void _showGeofenceSheet(ChildModel child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GeofenceSheet(
        child: child,
        onSave: (geofence) => _firestore.updateGeofence(child.id, geofence),
      ),
    );
  }

  // ── Restricted (no-go) areas ─────────────────────────────────────────────
  void _showForbiddenZonesSheet(ChildModel child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ForbiddenZonesSheet(
        child: child,
        onSave: (zones) => _firestore.updateForbiddenZones(child.id, zones),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = AegisT.isDark(context);
    final T        = AegisT.text(context);
    final D        = AegisT.textDim(context);
    final themeNot = context.watch<ThemeNotifier>();
    final uid       = context.watch<AuthService>().userId;

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            bottom: false,
            child: StreamBuilder<ChildModel?>(
              stream: uid.isEmpty ? null : _firestore.watchChildForUser(uid),
              builder: (context, snapshot) {
                final child = snapshot.data;
                return ListView(
                  padding: EdgeInsets.fromLTRB(18, 60, 18, kNavBarHeight + 24),
                  children: [
                    Text('Settings',
                        style: AegisText.h2(color: T)
                            .copyWith(fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: GlassCard(
                          child: Text(
                            "Couldn't load your child's profile: ${snapshot.error}",
                            style: AegisText.caption(color: kAlert).copyWith(fontSize: 12),
                          ),
                        ),
                      ),

                    // ── Child profile card ───────────────────────────────
                    GestureDetector(
                      onTap: child == null ? null : () => _showChildProfileSheet(child),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: (child?.photoUrl.isEmpty ?? true)
                                    ? const LinearGradient(
                                        colors: [kAccentLight, kAccent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                boxShadow: const [
                                  BoxShadow(color: Color(0x4D7C3AED), blurRadius: 20, offset: Offset(0, 8)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: (child?.photoUrl.isNotEmpty ?? false)
                                    ? Image.network(child!.photoUrl,
                                        width: 60, height: 60, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                            child: Text(child.initials,
                                                style: AegisText.h2(color: Colors.white)
                                                    .copyWith(fontSize: 24, fontWeight: FontWeight.w800))))
                                    : Center(
                                        child: Text(child?.initials ?? '?',
                                            style: AegisText.h2(color: Colors.white)
                                                .copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(child?.name ?? 'No child linked yet',
                                      style: AegisText.h5(color: T).copyWith(fontSize: 17)),
                                  const SizedBox(height: 2),
                                  Text(
                                    child == null
                                        ? 'Complete onboarding to add your child'
                                        : 'Band · ${child.deviceId.isEmpty ? "Not paired" : child.deviceId} · ${child.age} years old',
                                    style: AegisText.caption(color: D).copyWith(fontSize: 12),
                                  ),
                                  if (child != null) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: child.deviceId.isEmpty ? kOffline : kSafe,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(child.deviceId.isEmpty ? 'NOT PAIRED' : 'CONNECTED',
                                          style: AegisText.label(color: child.deviceId.isEmpty ? kOffline : kSafe)
                                              .copyWith(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.3)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                            if (child != null)
                              Icon(Icons.chevron_right_rounded, size: 16, color: D),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Emergency Contacts ───────────────────────────────
                    _SectionLabel('Emergency Contacts', D),
                    if (child == null)
                      GlassCard(
                        child: Text('Add your child\'s profile first to set up emergency contacts.',
                            style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                      )
                    else if (child.emergencyContacts.isEmpty)
                      GlassCard(
                        padded: false,
                        child: Column(children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Text(
                              'No emergency contacts yet. They\'ll be contacted in priority order if your child needs help.',
                              style: AegisText.caption(color: D).copyWith(fontSize: 12, height: 1.4),
                            ),
                          ),
                          _SettingsRow(
                            isDark: isDark, T: T, D: D,
                            iconBg: isDark ? const Color(0x14FFFFFF) : const Color(0x1A7C3AED),
                            iconWidget: Icon(Icons.add_rounded, color: kAccent, size: 16),
                            title: 'Add contact',
                            titleColor: kAccent,
                            isLast: true,
                            showChevron: false,
                            onTap: () => _showContactSheet(child),
                          ),
                        ]),
                      )
                    else
                      GlassCard(
                        padded: false,
                        child: Column(children: [
                          for (final contact in child.contactsByPriority) ...[
                            _ContactRow(
                              isDark: isDark, T: T, D: D,
                              contact: contact,
                              onTap: () => _showContactSheet(child, existing: contact),
                              onCall: () => _callContact(contact.phone),
                            ),
                            _Divider(isDark: isDark),
                          ],
                          _SettingsRow(
                            isDark: isDark, T: T, D: D,
                            iconBg: isDark ? const Color(0x14FFFFFF) : const Color(0x1A7C3AED),
                            iconWidget: Icon(Icons.add_rounded, color: kAccent, size: 16),
                            title: 'Add contact',
                            titleColor: kAccent,
                            isLast: true,
                            showChevron: false,
                            onTap: () => _showContactSheet(child),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 18),

                    // ── Appearance ────────────────────────────────────────
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

                    // ── Account ───────────────────────────────────────────
                    _SectionLabel('Account', D),
                    GlassCard(
                      padded: false,
                      child: Column(children: [
                        _SettingsRow(
                          isDark: isDark, T: T, D: D, iconBg: kSafe,
                          iconWidget: const Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                          title: 'Safe zone',
                          detail: child?.geofence == null ? 'Not set' : '${child!.geofence!.radiusMeters.round()}m radius',
                          onTap: child == null ? null : () => _showGeofenceSheet(child),
                        ),
                        _Divider(isDark: isDark),
                        _SettingsRow(
                          isDark: isDark, T: T, D: D, iconBg: kAlert,
                          iconWidget: const Icon(Icons.block, color: Colors.white, size: 14),
                          title: 'Restricted areas',
                          detail: (child?.forbiddenZones.isEmpty ?? true)
                              ? 'None set'
                              : '${child!.forbiddenZones.length} no-go zone${child.forbiddenZones.length == 1 ? '' : 's'}',
                          onTap: child == null ? null : () => _showForbiddenZonesSheet(child),
                        ),
                        _Divider(isDark: isDark),
                        _SettingsRow(
                          isDark: isDark, T: T, D: D, iconBg: kOffline,
                          iconWidget: const Icon(Icons.lock_outlined, color: Colors.white, size: 14),
                          title: 'Privacy & data',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PrivacyDataScreen(child: child))),
                        ),
                        _Divider(isDark: isDark),
                        _SettingsRow(
                          isDark: isDark, T: T, D: D, iconBg: const Color(0xFF64748B),
                          iconWidget: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 14),
                          title: 'About AEGIS', detail: 'v1.4.2', isLast: true,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const AboutAegisScreen())),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── Sign Out ──────────────────────────────────────────
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
                );
              },
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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}

// ── Emergency contact row ───────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final bool isDark;
  final Color T, D;
  final EmergencyContactModel contact;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const _ContactRow({
    required this.isDark,
    required this.T,
    required this.D,
    required this.contact,
    required this.onTap,
    required this.onCall,
  });

  Color get _iconBg {
    switch (contact.priority) {
      case 1:  return kAlert;
      case 2:  return kAccent;
      default: return kStress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _iconBg),
              child: Center(
                child: Text('${contact.priority}',
                    style: AegisText.label(color: Colors.white).copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${contact.relation.isEmpty ? "Contact" : contact.relation} · ${contact.name}',
                      style: AegisText.body(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(contact.phone, style: AegisText.caption(color: D).copyWith(fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onCall,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSafe.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.call_rounded, color: kSafe, size: 15),
              ),
            ),
          ],
        ),
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

// ── Shared bottom-sheet shell ───────────────────────────────────────────────
class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T      = AegisT.text(context);
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isDark ? const Color(0x26FFFFFF) : const Color(0x267C3AED),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: AegisText.h5(color: T).copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _sheetLabel(String text, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(text, style: AegisText.caption(color: color).copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
    );

InputDecoration _sheetInputDecoration(BuildContext context, {String? hint}) {
  final isDark = AegisT.isDark(context);
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    hintStyle: TextStyle(color: AegisT.textDim(context).withValues(alpha: 0.7)),
  );
}

Widget _sheetPrimaryButton(BuildContext context, String label, VoidCallback? onTap, {bool loading = false}) {
  return SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: kAccent.withValues(alpha: onTap == null ? 0.4 : 1),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
              : Text(label, style: AegisText.title(color: Colors.white).copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ),
  );
}

// ── Child profile edit sheet ────────────────────────────────────────────────
class _ChildProfileSheet extends StatefulWidget {
  final ChildModel child;
  final Future<void> Function(String name, int age) onSave;
  const _ChildProfileSheet({required this.child, required this.onSave});

  @override
  State<_ChildProfileSheet> createState() => _ChildProfileSheetState();
}

class _ChildProfileSheetState extends State<_ChildProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.child.name);
    _ageCtrl  = TextEditingController(text: widget.child.age > 0 ? '${widget.child.age}' : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final age  = int.tryParse(_ageCtrl.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name.');
      return;
    }
    if (age == null || age < 1 || age > 18) {
      setState(() => _error = 'Enter a valid age between 1 and 18.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave(name, age);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Child profile save failed: $e');
      if (mounted) setState(() { _saving = false; _error = 'Could not save: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return _Sheet(
      title: "Child's profile",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [kAccentLight, kAccent]),
              ),
              child: Center(
                child: Text(widget.child.initials,
                    style: AegisText.h2(color: Colors.white).copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          _sheetLabel('Name', D),
          TextField(controller: _nameCtrl, style: TextStyle(color: T), decoration: _sheetInputDecoration(context, hint: "Child's name")),
          _sheetLabel('Age', D),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: T),
            decoration: _sheetInputDecoration(context, hint: 'Age in years'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: kAlert, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          _sheetPrimaryButton(context, 'Save changes', _submit, loading: _saving),
        ],
      ),
    );
  }
}

// ── Emergency contact edit sheet ────────────────────────────────────────────
class _EmergencyContactSheet extends StatefulWidget {
  final EmergencyContactModel? existing;
  final int nextPriority;
  final Future<void> Function(EmergencyContactModel contact) onSave;
  final Future<void> Function()? onDelete;

  const _EmergencyContactSheet({
    this.existing,
    required this.nextPriority,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_EmergencyContactSheet> createState() => _EmergencyContactSheetState();
}

class _EmergencyContactSheetState extends State<_EmergencyContactSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _relationCtrl;
  late final TextEditingController _phoneCtrl;
  late int _priority;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl     = TextEditingController(text: e?.name ?? '');
    _relationCtrl = TextEditingController(text: e?.relation ?? '');
    _phoneCtrl    = TextEditingController(text: e?.phone ?? '');
    _priority     = e?.priority ?? widget.nextPriority;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name     = _nameCtrl.text.trim();
    final relation = _relationCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Name and phone number are required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final contact = EmergencyContactModel(
        id:       widget.existing?.id ?? const Uuid().v4(),
        name:     name,
        relation: relation,
        phone:    phone,
        priority: _priority,
      );
      await widget.onSave(contact);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save. Please try again.'; });
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await widget.onDelete?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not delete. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    const relations = ['Mother', 'Father', 'Guardian', 'Sibling', 'Other'];

    return _Sheet(
      title: widget.existing == null ? 'Add emergency contact' : 'Edit contact',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetLabel('Name', D),
          TextField(controller: _nameCtrl, style: TextStyle(color: T), decoration: _sheetInputDecoration(context, hint: 'Full name')),
          _sheetLabel('Relation', D),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: relations.map((r) {
              final selected = _relationCtrl.text == r;
              return GestureDetector(
                onTap: () => setState(() => _relationCtrl.text = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: selected ? kAccent : (AegisT.isDark(context) ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED)),
                  ),
                  child: Text(r, style: AegisText.label(color: selected ? Colors.white : D).copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          _sheetLabel('Phone number', D),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: T),
            decoration: _sheetInputDecoration(context, hint: '+1 (555) 000-0000'),
          ),
          _sheetLabel('Priority', D),
          Row(
            children: [
              Text(
                'Contacted ${_ordinal(_priority)} if your child needs help',
                style: AegisText.caption(color: D).copyWith(fontSize: 12),
              ),
              const Spacer(),
              _PriorityStepper(
                value: _priority,
                onChanged: (v) => setState(() => _priority = v),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: kAlert, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          _sheetPrimaryButton(context, widget.existing == null ? 'Add contact' : 'Save changes', _submit, loading: _saving),
          if (widget.onDelete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _delete,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kAlert.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: Text('Remove contact', style: AegisText.body(color: kAlert).copyWith(fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ordinal(int n) {
    switch (n) {
      case 1:  return '1st';
      case 2:  return '2nd';
      case 3:  return '3rd';
      default: return '${n}th';
    }
  }
}

class _PriorityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PriorityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final bg = isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: bg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            color: AegisT.text(context),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Text('$value', style: AegisText.body(color: AegisT.text(context)).copyWith(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            color: AegisT.text(context),
            onPressed: value < 9 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

// ── Geofence edit sheet ─────────────────────────────────────────────────────
class _GeofenceSheet extends StatefulWidget {
  final ChildModel child;
  final Future<void> Function(GeofenceModel geofence) onSave;
  const _GeofenceSheet({required this.child, required this.onSave});

  @override
  State<_GeofenceSheet> createState() => _GeofenceSheetState();
}

class _GeofenceSheetState extends State<_GeofenceSheet> {
  double? _lat;
  double? _lng;
  double _radius = 300;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.child.geofence;
    if (g != null) {
      _lat = g.lat;
      _lng = g.lng;
      _radius = g.radiusMeters;
    }
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const SafeZonePickerScreen()),
    );
    if (picked == null) return;
    setState(() {
      _lat = picked.latitude;
      _lng = picked.longitude;
    });
  }

  Future<void> _submit() async {
    if (_lat == null || _lng == null) return;
    setState(() => _saving = true);
    await widget.onSave(GeofenceModel(lat: _lat!, lng: _lng!, radiusMeters: _radius));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);
    final hasLocation = _lat != null && _lng != null;

    return _Sheet(
      title: 'Geofence settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You'll be alerted if your child leaves this safe zone.",
            style: AegisText.caption(color: D).copyWith(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickLocation,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: kAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasLocation
                          ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                          : 'Choose location on map',
                      style: AegisText.body(color: T).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: D, size: 16),
                ],
              ),
            ),
          ),
          _sheetLabel('Safe zone radius', D),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Radius', style: AegisText.body(color: T).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${_radius.round()} m', style: AegisText.h5(color: kAccent).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: kAccent,
              inactiveTrackColor: isDark ? const Color(0x0FFFFFFF) : const Color(0x147C3AED),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayColor: const Color(0x267C3AED),
              trackHeight: 6,
            ),
            child: Slider(
              value: _radius,
              min: 50,
              max: 2000,
              onChanged: (v) => setState(() => _radius = v),
            ),
          ),
          const SizedBox(height: 10),
          _sheetPrimaryButton(context, 'Save geofence', hasLocation ? _submit : null, loading: _saving),
        ],
      ),
    );
  }
}

// ── Restricted (no-go) areas sheet ──────────────────────────────────────────
class _ForbiddenZonesSheet extends StatefulWidget {
  final ChildModel child;
  final Future<void> Function(List<ForbiddenZoneModel> zones) onSave;
  const _ForbiddenZonesSheet({required this.child, required this.onSave});

  @override
  State<_ForbiddenZonesSheet> createState() => _ForbiddenZonesSheetState();
}

class _ForbiddenZonesSheetState extends State<_ForbiddenZonesSheet> {
  late List<ForbiddenZoneModel> _zones;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _zones = [...widget.child.forbiddenZones];
  }

  Future<void> _add() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const SafeZonePickerScreen()),
    );
    if (picked == null || !mounted) return;
    final details = await showDialog<({String name, double radius})>(
      context: context,
      builder: (_) => const _ForbiddenZoneDetailsDialog(),
    );
    if (details == null) return;
    setState(() {
      _zones.add(ForbiddenZoneModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: details.name.isEmpty ? 'Restricted area' : details.name,
        lat: picked.latitude,
        lng: picked.longitude,
        radiusMeters: details.radius,
      ));
    });
  }

  void _remove(String id) =>
      setState(() => _zones.removeWhere((z) => z.id == id));

  Future<void> _submit() async {
    setState(() => _saving = true);
    await widget.onSave(_zones);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return _Sheet(
      title: 'Restricted areas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You'll be alerted if your child spends time in any of these no-go "
            "zones. Briefly passing by won't trigger an alert.",
            style: AegisText.caption(color: D).copyWith(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_zones.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED),
              ),
              child: Text('No restricted areas yet',
                  style: AegisText.caption(color: D).copyWith(fontSize: 12)),
            )
          else
            ..._zones.map((z) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isDark ? const Color(0x0FFFFFFF) : const Color(0x0A7C3AED),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.block, color: kAlert, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(z.name,
                                  style: AegisText.body(color: T).copyWith(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 1),
                              Text(
                                '${z.radiusMeters.round()}m · ${z.lat.toStringAsFixed(4)}, ${z.lng.toStringAsFixed(4)}',
                                style: AegisText.caption(color: D).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _remove(z.id),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(Icons.close_rounded, color: D, size: 18),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _add,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: kAlert.withValues(alpha: 0.12),
                border: Border.all(color: kAlert.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_location_alt_outlined, color: kAlert, size: 18),
                  const SizedBox(width: 8),
                  Text('Add restricted area',
                      style: AegisText.body(color: kAlert)
                          .copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sheetPrimaryButton(context, 'Save', _submit, loading: _saving),
        ],
      ),
    );
  }
}

// ── Name + radius entry for a new restricted area ───────────────────────────
class _ForbiddenZoneDetailsDialog extends StatefulWidget {
  const _ForbiddenZoneDetailsDialog();

  @override
  State<_ForbiddenZoneDetailsDialog> createState() =>
      _ForbiddenZoneDetailsDialogState();
}

class _ForbiddenZoneDetailsDialogState
    extends State<_ForbiddenZoneDetailsDialog> {
  final _nameCtrl = TextEditingController();
  double _radius = 80;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return Dialog(
      backgroundColor: isDark ? kDarkBg : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name this area',
                style: AegisText.h5(color: T)
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              style: AegisText.body(color: T).copyWith(fontSize: 14),
              decoration: _sheetInputDecoration(context, hint: 'e.g. Old construction site'),
            ),
            _sheetLabel('Trigger radius', D),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Radius', style: AegisText.body(color: T).copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${_radius.round()} m', style: AegisText.h5(color: kAlert).copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: kAlert,
                inactiveTrackColor: isDark ? const Color(0x0FFFFFFF) : const Color(0x14F43F5E),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayColor: const Color(0x26F43F5E),
                trackHeight: 6,
              ),
              child: Slider(
                value: _radius,
                min: 30,
                max: 500,
                onChanged: (v) => setState(() => _radius = v),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: AegisText.label(color: D).copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(
                      (name: _nameCtrl.text.trim(), radius: _radius)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: kAlert,
                    ),
                    child: Text('Add',
                        style: AegisText.label(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
