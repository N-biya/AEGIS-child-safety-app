import 'package:flutter/material.dart';

// Primary brand colors
const Color aegisPink          = Color(0xFFE8A0BF);
const Color aegisPinkLight     = Color(0xFFF5C6D8);
const Color aegisPinkDark      = Color(0xFFD4709A);
const Color aegisPinkPale      = Color(0xFFFCEEF3);

// Supporting pastels
const Color aegisMint          = Color(0xFFB8E0D2);
const Color aegisMintLight     = Color(0xFFD8F0E8);
const Color aegisLavender      = Color(0xFFD4B8E0);
const Color aegisLavenderLight = Color(0xFFECDFF5);
const Color aegisPeach         = Color(0xFFF5C9A0);
const Color aegisPeachLight    = Color(0xFFFAE8D0);
const Color aegisRose          = Color(0xFFE88C8C);
const Color aegisRoseLight     = Color(0xFFF5D0D0);

// Neutral tones — light mode
const Color aegisCream         = Color(0xFFFAF5F7);
const Color aegisWarm          = Color(0xFFF0E8EC);
const Color aegisText          = Color(0xFF3D2535);
const Color aegisTextMid       = Color(0xFF7A5068);
const Color aegisTextSoft      = Color(0xFFAD8E9E);
const Color aegisCard          = Color(0xFFFDF0F5);

// Neutral tones — dark mode
const Color darkBg             = Color(0xFF1A1018);
const Color darkCard           = Color(0xFF251A21);
const Color darkWarm           = Color(0xFF3A2830);
const Color darkText           = Color(0xFFF0E0EA);
const Color darkTextMid        = Color(0xFFCCA0B8);
const Color darkTextSoft       = Color(0xFF9A7088);
const Color darkPinkPale       = Color(0xFF2A1822);
const Color darkPinkLight      = Color(0xFF3D2535);

// Status colors (same for both modes)
const Color statusSafe         = Color(0xFF7DCEA0);
const Color statusElevated     = Color(0xFFF0B07A);
const Color statusAlert        = Color(0xFFE07070);
const Color statusCalibrating  = Color(0xFF85C1E9);

/// Context-aware color helpers — use these in build() methods.
class AegisColors {
  static bool _dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx) =>
      _dark(ctx) ? darkBg : aegisCream;

  static Color card(BuildContext ctx) =>
      _dark(ctx) ? darkCard : aegisCard;

  static Color warm(BuildContext ctx) =>
      _dark(ctx) ? darkWarm : aegisWarm;

  static Color pinkPale(BuildContext ctx) =>
      _dark(ctx) ? darkPinkPale : aegisPinkPale;

  static Color pinkLight(BuildContext ctx) =>
      _dark(ctx) ? darkPinkLight : aegisPinkLight;

  static Color text(BuildContext ctx) =>
      _dark(ctx) ? darkText : aegisText;

  static Color textMid(BuildContext ctx) =>
      _dark(ctx) ? darkTextMid : aegisTextMid;

  static Color textSoft(BuildContext ctx) =>
      _dark(ctx) ? darkTextSoft : aegisTextSoft;
}
