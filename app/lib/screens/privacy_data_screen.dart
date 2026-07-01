import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../router/app_router.dart' show kNavBarHeight;
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class PrivacyDataScreen extends StatefulWidget {
  final ChildModel? child;
  const PrivacyDataScreen({super.key, this.child});

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final isDark = AegisT.isDark(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? kDarkCard : Colors.white,
        title: Text('Delete all data?', style: TextStyle(color: AegisT.text(ctx), fontWeight: FontWeight.w700)),
        content: Text(
          "This permanently deletes ${widget.child?.name ?? 'your child'}'s profile, vitals history, "
          'and alerts from AEGIS. This cannot be undone.',
          style: TextStyle(color: AegisT.textDim(ctx)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: kAlert, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.child == null) return;
    setState(() => _deleting = true);
    try {
      await FirestoreService().deleteChild(widget.child!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final T = AegisT.text(context);
    final D = AegisT.textDim(context);

    return Scaffold(
      backgroundColor: AegisT.bg(context),
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            color: isDark ? const Color(0x0FFFFFFF) : const Color(0xB3FFFFFF),
                            border: Border.all(color: AegisT.glassBorder(context)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: T),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('Privacy & Data', style: AegisText.h5(color: T).copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, kNavBarHeight + 24),
                    children: [
                      _SectionLabel('What we collect', D),
                      GlassCard(
                        padded: false,
                        child: Column(children: [
                          _InfoRow(D: D, T: T, icon: Icons.favorite_outline, title: 'Vitals',
                              detail: "Heart rate, SpO2, GSR and temperature readings from your child's band."),
                          _Divider(isDark: isDark),
                          _InfoRow(D: D, T: T, icon: Icons.location_on_outlined, title: 'Location',
                              detail: 'GPS coordinates used only for geofence safe-zone alerts.'),
                          _Divider(isDark: isDark),
                          _InfoRow(D: D, T: T, icon: Icons.contact_phone_outlined, title: 'Emergency contacts',
                              detail: 'Names, relations and phone numbers you add for emergencies.', isLast: true),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      _SectionLabel('How it’s stored', D),
                      GlassCard(
                        child: Text(
                          'All data is stored securely in Firebase and is only visible to parent accounts linked '
                          "to your child's profile. Vitals and alerts are retained so you can review trends over "
                          'time; you can permanently delete everything at any time below.',
                          style: AegisText.caption(color: D).copyWith(fontSize: 12, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: (_deleting || widget.child == null) ? null : _confirmDelete,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kAlert.withValues(alpha: 0.4)),
                            color: kAlert.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: _deleting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kAlert, strokeWidth: 2.4))
                                : Text('Delete my data', style: AegisText.title(color: kAlert)),
                          ),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(text, style: AegisText.micro(color: color).copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color T, D;
  final IconData icon;
  final String title, detail;
  final bool isLast;
  const _InfoRow({required this.T, required this.D, required this.icon, required this.title, required this.detail, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kAccent),
            child: Center(child: Icon(icon, color: Colors.white, size: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AegisText.body(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail, style: AegisText.caption(color: D).copyWith(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
