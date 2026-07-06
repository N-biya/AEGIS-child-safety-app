import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/alert_model.dart';
import '../models/child_model.dart';
import '../services/alarm_service.dart';
import '../utils/aegis_text.dart';

/// Full-screen, unmissable emergency takeover shown when the band raises an
/// alert over WiFi. Blares a looping siren + vibration (via [AlarmService]) and
/// fills the whole screen with a pulsing red UI. The parent can Call the
/// emergency contact or Dismiss (which silences the alarm).
///
/// This deliberately ignores Quiet Hours / muted categories — a real safety
/// alert should never be silenced by a preference toggle.
class AlertAlarmScreen extends StatefulWidget {
  final AlertModel alert;
  final ChildModel? child;

  const AlertAlarmScreen({super.key, required this.alert, this.child});

  @override
  State<AlertAlarmScreen> createState() => _AlertAlarmScreenState();
}

class _AlertAlarmScreenState extends State<AlertAlarmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    // Start the physical alarm as soon as the screen is up.
    AlarmService.instance.start();
  }

  @override
  void dispose() {
    _pulse.dispose();
    // Safety net: never leave the siren running if this screen goes away.
    AlarmService.instance.stop();
    super.dispose();
  }

  EmergencyContactModel? get _contact {
    final contacts = widget.child?.contactsByPriority ?? const [];
    return contacts.isEmpty ? null : contacts.first;
  }

  Future<void> _dismiss() async {
    await AlarmService.instance.stop();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _call() async {
    final contact = _contact;
    if (contact == null || contact.phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add an emergency contact in Settings first.'),
      ));
      return;
    }
    final uri = Uri(scheme: 'tel', path: contact.phone.trim());
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open the dialer. Call ${contact.name}.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final childName = widget.child?.name ?? 'Your child';
    final contact = _contact;
    final isForbidden = alert.type == 'FORBIDDEN';
    // Location-based alerts (leaving the safe zone or entering a no-go zone)
    // carry no meaningful HR/SpO₂, so those stat tiles are hidden for them.
    final isLocationAlert = alert.type == 'GEOFENCE' || isForbidden;

    final IconData headerIcon = isForbidden
        ? Icons.block_rounded
        : (alert.type == 'GEOFENCE'
            ? Icons.location_off_rounded
            : Icons.warning_amber_rounded);

    final String subtitle = isForbidden
        ? '$childName entered a restricted area'
        : (alert.type == 'GEOFENCE'
            ? '$childName has left the safe zone'
            : "$childName's AEGIS band reported an emergency");

    // Block the hardware back button — the alarm must be explicitly dismissed.
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF7A0A1E),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB91C3C), Color(0xFF7A0A1E)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text('EMERGENCY ALERT',
                        style: AegisText.h4(color: Colors.white).copyWith(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w900,
                        )),
                    const Spacer(),
                    // Pulsing siren icon
                    ScaleTransition(
                      scale: Tween(begin: 0.88, end: 1.12).animate(
                        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          headerIcon,
                          color: Colors.white,
                          size: 76,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(alert.typeLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AegisText.h2(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AegisText.bodyLg(
                          color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 22),
                    _statsRow(alert, isLocationAlert),
                    const Spacer(),
                    _callButton(contact),
                    const SizedBox(height: 12),
                    _dismissButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsRow(AlertModel alert, bool isLocationAlert) {
    final items = <Widget>[];
    if (!isLocationAlert) {
      items.add(_stat('${alert.heartRate}', 'bpm', Icons.favorite_rounded));
      if (alert.spo2 > 0) {
        items.add(_stat('${alert.spo2}%', 'SpO₂', Icons.air_rounded));
      }
    }
    if (alert.latitude != 0 || alert.longitude != 0) {
      items.add(_stat(
        '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
        'location',
        Icons.place_rounded,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: items,
    );
  }

  Widget _stat(String value, String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: AegisText.title(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w800)),
            Text(label,
                style: AegisText.micro(
                    color: Colors.white.withValues(alpha: 0.75))),
          ],
        ),
      );

  Widget _callButton(EmergencyContactModel? contact) => SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: _call,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFB91C3C),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          icon: const Icon(Icons.call_rounded, size: 24),
          label: Text(
            contact != null ? 'Call ${contact.name}' : 'Call emergency contact',
            style: AegisText.title(color: const Color(0xFFB91C3C))
                .copyWith(fontWeight: FontWeight.w900, fontSize: 17),
          ),
        ),
      );

  Widget _dismissButton() => SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: _dismiss,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: Text('Dismiss & silence',
              style: AegisText.title(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w800)),
        ),
      );
}
