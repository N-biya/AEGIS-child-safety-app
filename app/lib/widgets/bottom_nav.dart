import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';

// ─── 3D gradient SVG icon strings ────────────────────────────────────────
String _shieldSvg(bool active) => '''
<svg viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="sg" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#C4A8E8"/>
<stop offset="55%" stop-color="#7C3AED"/>
<stop offset="100%" stop-color="#3D2460"/>
</linearGradient>
<radialGradient id="sh" cx="0.3" cy="0.25" r="0.5">
<stop offset="0%" stop-color="#ffffff" stop-opacity="0.85"/>
<stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
</defs>
<ellipse cx="22" cy="40" rx="12" ry="2.2" fill="rgba(0,0,0,0.18)"/>
<path d="M22 5L9 9v9c0 7.5 5.5 12.5 13 14.5 7.5-2 13-7 13-14.5V9L22 5z"
  fill="url(#sg)" stroke="${active ? '#A78BFA' : 'none'}" stroke-width="0.8"/>
<path d="M22 5L9 9v9c0 7.5 5.5 12.5 13 14.5 7.5-2 13-7 13-14.5V9L22 5z" fill="url(#sh)"/>
<path d="M16 16.5a2.5 2.5 0 0 1 4.2 -1.7a2.5 2.5 0 0 1 4.2 1.7c0 3-4.2 5.6-4.2 5.6s-4.2-2.6-4.2-5.6z"
  transform="translate(2 2)" fill="white" fill-opacity="0.95"/>
<circle cx="14" cy="11" r="1.3" fill="white" opacity="0.8"/>
</svg>''';

const String _pinSvg = '''
<svg viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="pg" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#E9DDFF"/>
<stop offset="55%" stop-color="#A78BFA"/>
<stop offset="100%" stop-color="#5B2EBC"/>
</linearGradient>
<radialGradient id="ph" cx="0.32" cy="0.28" r="0.42">
<stop offset="0%" stop-color="#ffffff" stop-opacity="0.85"/>
<stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
</defs>
<ellipse cx="22" cy="40" rx="7" ry="1.6" fill="rgba(0,0,0,0.18)"/>
<path d="M22 6c-5 0-9 4-9 9 0 7 9 18 9 18s9-11 9-18c0-5-4-9-9-9z" fill="url(#pg)"/>
<path d="M22 6c-5 0-9 4-9 9 0 7 9 18 9 18s9-11 9-18c0-5-4-9-9-9z" fill="url(#ph)"/>
<circle cx="22" cy="15" r="3.5" fill="white" fill-opacity="0.95"/>
<circle cx="20.5" cy="13.5" r="1" fill="#A78BFA"/>
</svg>''';

const String _bellSvg = '''
<svg viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#FFE4B5"/>
<stop offset="55%" stop-color="#F5A623"/>
<stop offset="100%" stop-color="#9A5A0F"/>
</linearGradient>
<radialGradient id="bh" cx="0.3" cy="0.25" r="0.45">
<stop offset="0%" stop-color="#ffffff" stop-opacity="0.85"/>
<stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
</defs>
<ellipse cx="22" cy="40" rx="9" ry="1.7" fill="rgba(0,0,0,0.18)"/>
<path d="M22 7c-5 0-8 3.5-8 9 0 5-2 7-2 9h20c0-2-2-4-2-9 0-5.5-3-9-8-9z" fill="url(#bg)"/>
<path d="M22 7c-5 0-8 3.5-8 9 0 5-2 7-2 9h20c0-2-2-4-2-9 0-5.5-3-9-8-9z" fill="url(#bh)"/>
<ellipse cx="22" cy="33" rx="3" ry="2" fill="#9A5A0F"/>
<circle cx="22" cy="6" r="1.6" fill="#F5A623"/>
</svg>''';

const String _chartSvg = '''
<svg viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="c1" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#A7F3D0"/>
<stop offset="100%" stop-color="#10B981"/>
</linearGradient>
<linearGradient id="c2" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#FCE7F3"/>
<stop offset="100%" stop-color="#EC4899"/>
</linearGradient>
<linearGradient id="c3" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#DDD6FE"/>
<stop offset="100%" stop-color="#7C3AED"/>
</linearGradient>
</defs>
<ellipse cx="22" cy="39" rx="13" ry="1.8" fill="rgba(0,0,0,0.18)"/>
<rect x="9" y="22" width="6.5" height="14" rx="2.5" fill="url(#c1)"/>
<rect x="9.5" y="22.5" width="2" height="9" rx="1" fill="white" opacity="0.5"/>
<rect x="18.5" y="14" width="6.5" height="22" rx="2.5" fill="url(#c3)"/>
<rect x="19" y="14.5" width="2" height="14" rx="1" fill="white" opacity="0.55"/>
<rect x="28" y="18" width="6.5" height="18" rx="2.5" fill="url(#c2)"/>
<rect x="28.5" y="18.5" width="2" height="11" rx="1" fill="white" opacity="0.55"/>
</svg>''';

const String _gearSvg = '''
<svg viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="gg" x1="0" y1="0" x2="0" y2="1">
<stop offset="0%" stop-color="#E0E7FF"/>
<stop offset="55%" stop-color="#94A3B8"/>
<stop offset="100%" stop-color="#475569"/>
</linearGradient>
<radialGradient id="gh" cx="0.3" cy="0.25" r="0.45">
<stop offset="0%" stop-color="#ffffff" stop-opacity="0.85"/>
<stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
</defs>
<ellipse cx="22" cy="39" rx="11" ry="1.7" fill="rgba(0,0,0,0.18)"/>
<path d="M22 6l2 2.4 3-1 1 3 3 1-1 3 2.4 2-2.4 2 1 3-3 1-1 3-3-1L22 36l-2-2.4-3 1-1-3-3-1 1-3-2.4-2 2.4-2-1-3 3-1 1-3 3 1L22 6z"
  fill="url(#gg)"/>
<path d="M22 6l2 2.4 3-1 1 3 3 1-1 3 2.4 2-2.4 2 1 3-3 1-1 3-3-1L22 36l-2-2.4-3 1-1-3-3-1 1-3-2.4-2 2.4-2-1-3 3-1 1-3 3 1L22 6z"
  fill="url(#gh)"/>
<circle cx="22" cy="21" r="4.5" fill="#1F2A40"/>
<circle cx="20.6" cy="19.6" r="1.4" fill="#94A3B8"/>
</svg>''';

// ─── Nav item descriptor ──────────────────────────────────────────────────
class _NavDef {
  final int index;
  final String label;
  const _NavDef(this.index, this.label);
}

const _navDefs = [
  _NavDef(0, 'Home'),
  _NavDef(1, 'Map'),
  _NavDef(2, 'Alerts'),
  _NavDef(3, 'Trends'),
  _NavDef(4, 'Settings'),
];

// ─── Main widget ─────────────────────────────────────────────────────────
class AegisBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AegisBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _icon(int index, bool active) {
    const s = 40.0;
    switch (index) {
      case 0: return SvgPicture.string(_shieldSvg(active), width: s, height: s);
      case 1: return SvgPicture.string(_pinSvg, width: s, height: s);
      case 2: return SvgPicture.string(_bellSvg, width: s, height: s);
      case 3: return SvgPicture.string(_chartSvg, width: s, height: s);
      default: return SvgPicture.string(_gearSvg, width: s, height: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AegisT.navBg(context),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AegisT.navBorder(context)),
            boxShadow: [
              BoxShadow(
                color: AegisT.isDark(context)
                    ? const Color(0x4D000000)
                    : const Color(0x1A7C3AED),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _navDefs.map((def) {
              final active = def.index == currentIndex;
              return GestureDetector(
                onTap: () => onTap(def.index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: const Cubic(0.34, 1.56, 0.64, 1),
                  transform: active
                      ? Matrix4.translationValues(0.0, -2.0, 0.0)
                      : Matrix4.identity(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drop-shadow on active icon container
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: active
                              ? [
                                  const BoxShadow(
                                    color: Color(0x737C3AED),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Opacity(
                          opacity: active ? 1.0 : 0.78,
                          child: _icon(def.index, active),
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(height: 2),
                        Text(
                          def.label,
                          style: AegisText.micro(color: const Color(0xFF7C3AED)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
