import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/theme_provider.dart';
import '../widgets/aegis_button.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onViewMap;

  const SettingsScreen({super.key, this.onViewMap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _stressAlerts    = true;
  bool _geofenceAlerts  = true;
  bool _lowSpo2Alerts   = true;
  bool _pushNotifs      = true;

  void _showEditProfileDialog() {
    final child = DummyDataService.dummyChild;
    final nameCtrl = TextEditingController(text: child.name);
    final ageCtrl  = TextEditingController(text: '${child.age}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AegisColors.card(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile', style: AppTextStyles.h3),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Child Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 20),
              AegisButton(
                label: 'Save Changes',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child    = DummyDataService.dummyChild;
    final themeNot = context.watch<ThemeNotifier>();

    return Scaffold(
      backgroundColor: AegisColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text('Settings', style: AppTextStyles.h2),
            const SizedBox(height: 24),

            // ── Child profile card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AegisColors.card(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: aegisPink.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: aegisPink,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        child.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.name, style: AppTextStyles.h3),
                        Text('Age ${child.age}  •  Device ${child.deviceId}',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: const Icon(LucideIcons.pencil,
                        size: 16, color: aegisPinkDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Appearance ───────────────────────────────────────────────
            _SettingsGroup(
              title: 'Appearance',
              children: [
                _ToggleRow(
                  icon: LucideIcons.moon,
                  label: 'Dark mode',
                  value: themeNot.isDarkMode,
                  onChanged: (_) => themeNot.toggle(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Geofence ─────────────────────────────────────────────────
            _SettingsGroup(
              title: 'Geofence',
              children: [
                _SettingsRow(
                  icon: LucideIcons.mapPin,
                  label: 'Safe zone center',
                  value: '31.5204, 74.3587',
                  onTap: widget.onViewMap,
                ),
                _SettingsRow(
                  icon: LucideIcons.circleDashed,
                  label: 'Radius',
                  value: '300 m',
                  onTap: widget.onViewMap,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Alert Types ──────────────────────────────────────────────
            _SettingsGroup(
              title: 'Alert Types',
              children: [
                _ToggleRow(
                  icon: LucideIcons.brain,
                  label: 'Stress detection',
                  value: _stressAlerts,
                  onChanged: (v) => setState(() => _stressAlerts = v),
                ),
                _ToggleRow(
                  icon: LucideIcons.mapPin,
                  label: 'Geofence breach',
                  value: _geofenceAlerts,
                  onChanged: (v) => setState(() => _geofenceAlerts = v),
                ),
                _ToggleRow(
                  icon: LucideIcons.wind,
                  label: 'Low SpO2',
                  value: _lowSpo2Alerts,
                  onChanged: (v) => setState(() => _lowSpo2Alerts = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Notifications ────────────────────────────────────────────
            _SettingsGroup(
              title: 'Notifications',
              children: [
                _ToggleRow(
                  icon: LucideIcons.bell,
                  label: 'Push notifications',
                  value: _pushNotifs,
                  onChanged: (v) => setState(() => _pushNotifs = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Emergency Contacts ───────────────────────────────────────
            _SettingsGroup(
              title: 'Emergency Contacts',
              children: child.emergencyContacts.asMap().entries.map((e) {
                return _SettingsRow(
                  icon: LucideIcons.phone,
                  label: 'Contact ${e.key + 1}',
                  value: e.value,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Device ───────────────────────────────────────────────────
            _SettingsGroup(
              title: 'Device',
              children: [
                _SettingsRow(
                  icon: LucideIcons.cpu,
                  label: 'Device ID',
                  value: child.deviceId,
                ),
                _SettingsRow(
                  icon: LucideIcons.radio,
                  label: 'Connection',
                  value: 'WiFi',
                ),
                _SettingsRow(
                  icon: LucideIcons.gitBranch,
                  label: 'Firmware',
                  value: 'v1.0.0',
                ),
              ],
            ),
            const SizedBox(height: 24),

            AegisButton(
              label: 'Sign Out',
              isOutlined: true,
              onPressed: () async {
                await context.read<AuthService>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.label),
        ),
        Container(
          decoration: BoxDecoration(
            color: AegisColors.card(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: aegisPink.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AegisColors.warm(context),
                      indent: 52,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _SettingsRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 16, color: aegisTextSoft),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            Text(value, style: AppTextStyles.caption),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: onTap != null ? aegisPinkDark : aegisTextSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: aegisTextSoft),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
