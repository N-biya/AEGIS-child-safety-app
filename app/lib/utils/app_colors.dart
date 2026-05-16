import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AEGIS DESIGN SYSTEM — Velvet Night (dark) & Warm Blossom (light)
// ═══════════════════════════════════════════════════════════════════════════

// ── Dark theme — Velvet Night ────────────────────────────────────────────
const Color kDarkBg      = Color(0xFF1A0F2E);
const Color kDarkCard    = Color(0xFF2D1A4A);
const Color kDarkNav     = Color(0xFF3D2460);
const Color kDarkText    = Color(0xFFF5E6FF);
const Color kDarkTextDim = Color(0xFFC4A8E8);

// ── Light theme — Warm Blossom ───────────────────────────────────────────
const Color kLightBg      = Color(0xFFFBF7FF);
const Color kLightCard    = Color(0xFFFFFFFF);
const Color kLightNav     = Color(0xFFEDE0FF);
const Color kLightText    = Color(0xFF2D1A4A);
const Color kLightTextDim = Color(0xFF7C5BA8);

// ── Accent (same in both themes) ─────────────────────────────────────────
const Color kAccent      = Color(0xFF7C3AED);
const Color kAccentLight = Color(0xFFA78BFA);
const Color kAccentPale  = Color(0xFFC4A8E8);

// ── Status colors (universal) ────────────────────────────────────────────
const Color kSafe    = Color(0xFF34D399);
const Color kStress  = Color(0xFFF5A623);
const Color kAlert   = Color(0xFFF43F5E);
const Color kCal     = Color(0xFFA78BFA);
const Color kOffline = Color(0xFF64748B);

// ── Glass bg & borders (pre-computed hex with alpha) ─────────────────────
// Dark glass: rgba(124,58,237,0.10) = #1A7C3AED
const Color kDarkGlassBg     = Color(0x1A7C3AED);
// Light glass: rgba(255,255,255,0.65) = #A6FFFFFF
const Color kLightGlassBg    = Color(0xA6FFFFFF);
// Dark glass border: rgba(255,255,255,0.10) = #1AFFFFFF
const Color kDarkGlassBorder  = Color(0x1AFFFFFF);
// Light glass border: rgba(45,26,74,0.08) = #142D1A4A
const Color kLightGlassBorder = Color(0x142D1A4A);
// Dark nav bg: rgba(61,36,96,0.65) = #A63D2460
const Color kDarkNavBg        = Color(0xA63D2460);
// Light nav bg: rgba(255,255,255,0.85) = #D9FFFFFF
const Color kLightNavBg       = Color(0xD9FFFFFF);
// Dark nav border: rgba(245,230,255,0.10) = #1AF5E6FF
const Color kDarkNavBorder    = Color(0x1AF5E6FF);
// Light nav border: rgba(124,58,237,0.10) = #1A7C3AED
const Color kLightNavBorder   = Color(0x1A7C3AED);

// ── Context-aware AEGIS color helpers ───────────────────────────────────
class AegisT {
  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx)      => isDark(ctx) ? kDarkBg      : kLightBg;
  static Color card(BuildContext ctx)    => isDark(ctx) ? kDarkCard    : kLightCard;
  static Color nav(BuildContext ctx)     => isDark(ctx) ? kDarkNav     : kLightNav;
  static Color text(BuildContext ctx)    => isDark(ctx) ? kDarkText    : kLightText;
  static Color textDim(BuildContext ctx) => isDark(ctx) ? kDarkTextDim : kLightTextDim;

  static Color glassBg(BuildContext ctx)     => isDark(ctx) ? kDarkGlassBg    : kLightGlassBg;
  static Color glassBorder(BuildContext ctx) => isDark(ctx) ? kDarkGlassBorder : kLightGlassBorder;
  static Color navBg(BuildContext ctx)       => isDark(ctx) ? kDarkNavBg      : kLightNavBg;
  static Color navBorder(BuildContext ctx)   => isDark(ctx) ? kDarkNavBorder  : kLightNavBorder;
}

// ═══════════════════════════════════════════════════════════════════════════
// LEGACY PALETTE — kept so existing widgets (aegis_button, alert_tile,
// etc.) that are not yet rewritten continue to compile.
// ═══════════════════════════════════════════════════════════════════════════

const Color aegisPink          = Color(0xFFE8A0BF);
const Color aegisPinkLight     = Color(0xFFF5C6D8);
const Color aegisPinkDark      = Color(0xFFD4709A);
const Color aegisPinkPale      = Color(0xFFFCEEF3);

const Color aegisMint          = Color(0xFFB8E0D2);
const Color aegisMintLight     = Color(0xFFD8F0E8);
const Color aegisLavender      = Color(0xFFD4B8E0);
const Color aegisLavenderLight = Color(0xFFECDFF5);
const Color aegisPeach         = Color(0xFFF5C9A0);
const Color aegisPeachLight    = Color(0xFFFAE8D0);
const Color aegisRose          = Color(0xFFE88C8C);
const Color aegisRoseLight     = Color(0xFFF5D0D0);

const Color aegisCream         = Color(0xFFFAF5F7);
const Color aegisWarm          = Color(0xFFF0E8EC);
const Color aegisText          = Color(0xFF3D2535);
const Color aegisTextMid       = Color(0xFF7A5068);
const Color aegisTextSoft      = Color(0xFFAD8E9E);
const Color aegisCard          = Color(0xFFFDF0F5);

const Color darkBg             = Color(0xFF1A1018);
const Color darkCard           = Color(0xFF251A21);
const Color darkWarm           = Color(0xFF3A2830);
const Color darkText           = Color(0xFFF0E0EA);
const Color darkTextMid        = Color(0xFFCCA0B8);
const Color darkTextSoft       = Color(0xFF9A7088);
const Color darkPinkPale       = Color(0xFF2A1822);
const Color darkPinkLight      = Color(0xFF3D2535);

const Color statusSafe         = Color(0xFF7DCEA0);
const Color statusElevated     = Color(0xFFF0B07A);
const Color statusAlert        = Color(0xFFE07070);
const Color statusCalibrating  = Color(0xFF85C1E9);

// Legacy context-aware helpers (still used by old non-rewritten widgets)
class AegisColors {
  static bool _dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx) =>
      _dark(ctx) ? kDarkBg : kLightBg;

  static Color card(BuildContext ctx) =>
      _dark(ctx) ? kDarkCard : kLightCard;

  static Color warm(BuildContext ctx) =>
      _dark(ctx) ? darkWarm : aegisWarm;

  static Color pinkPale(BuildContext ctx) =>
      _dark(ctx) ? darkPinkPale : aegisPinkPale;

  static Color pinkLight(BuildContext ctx) =>
      _dark(ctx) ? darkPinkLight : aegisPinkLight;

  static Color text(BuildContext ctx) =>
      _dark(ctx) ? kDarkText : kLightText;

  static Color textMid(BuildContext ctx) =>
      _dark(ctx) ? darkTextMid : aegisTextMid;

  static Color textSoft(BuildContext ctx) =>
      _dark(ctx) ? darkTextSoft : aegisTextSoft;
}
