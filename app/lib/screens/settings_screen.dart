import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/aegis_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _stressAlerts = true;
  bool _geofenceAlerts = true;
  bool _lowSpo2Alerts = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final child = DummyDataService.dummyChild;

    return Scaffold(
      backgroundColor: aegisCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text('Settings', style: AppTextStyles.h2),
            const SizedBox(height: 24),

            // Child profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: aegisCard,
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
                    decoration: BoxDecoration(
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
                  const Icon(LucideIcons.pencil, size: 16, color: aegisTextSoft),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SettingsGroup(
              title: 'Geofence',
              children: [
                _SettingsRow(
                  icon: LucideIcons.mapPin,
                  label: 'Safe zone center',
                  value: '31.5204, 74.3587',
                ),
                _SettingsRow(
                  icon: LucideIcons.circleDashed,
                  label: 'Radius',
                  value: '300 m',
                ),
              ],
            ),
            const SizedBox(height: 16),

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

            _SettingsGroup(
              title: 'Notifications',
              children: [
                _ToggleRow(
                  icon: LucideIcons.bell,
                  label: 'Push notifications',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
            color: aegisCard,
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
                    const Divider(height: 1, thickness: 0.8,
                        color: aegisWarm, indent: 52),
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
  const _SettingsRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: aegisTextMid),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(value, style: AppTextStyles.caption),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronRight, size: 14, color: aegisTextSoft),
        ],
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
          Icon(icon, size: 16, color: aegisTextMid),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
