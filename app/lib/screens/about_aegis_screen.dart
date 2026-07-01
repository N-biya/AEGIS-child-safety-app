import 'package:flutter/material.dart';
import '../router/app_router.dart' show kNavBarHeight;
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/glass_card.dart';

class AboutAegisScreen extends StatelessWidget {
  const AboutAegisScreen({super.key});

  static const _team = [
    ('Barira Sarfaraz', 'Creator & Developer'),
    ('Nabeeha Zahid', 'Creator & Developer'),
  ];

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
                      Text('About AEGIS', style: AegisText.h5(color: T).copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, kNavBarHeight + 24),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(colors: [kAccentLight, kAccent]),
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
                            ),
                            const SizedBox(height: 12),
                            Text('AEGIS', style: AegisText.h2(color: T).copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
                            Text('Version 1.4.2', style: AegisText.caption(color: D).copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        child: Text(
                          "Every parent knows that quiet, nagging fear — the one that creeps in the moment "
                          "your child is out of sight. AEGIS was built to ease that fear. It's a small band "
                          "on your child's wrist that carries a piece of your love with it everywhere they go, "
                          "so even when you can't hold their hand, you can still feel close to them — knowing "
                          "they're safe, they're well, and they're never truly alone.",
                          style: AegisText.caption(color: D).copyWith(fontSize: 12, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionLabel('Development team', D),
                      GlassCard(
                        padded: false,
                        child: Column(
                          children: [
                            for (var i = 0; i < _team.length; i++) ...[
                              _TeamRow(name: _team[i].$1, role: _team[i].$2, T: T, D: D),
                              if (i != _team.length - 1) _Divider(isDark: isDark),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionLabel('Contact', D),
                      GlassCard(
                        padded: false,
                        child: Column(children: [
                          _InfoRow(D: D, T: T, icon: Icons.email_outlined, title: 'Support', detail: 'aegisbn40@gmail.com', isLast: true),
                        ]),
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

class _TeamRow extends StatelessWidget {
  final String name, role;
  final Color T, D;
  const _TeamRow({required this.name, required this.role, required this.T, required this.D});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: kAccentLight),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AegisText.body(color: T).copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(role, style: AegisText.caption(color: D).copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
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
                Text(detail, style: AegisText.caption(color: D).copyWith(fontSize: 11)),
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
