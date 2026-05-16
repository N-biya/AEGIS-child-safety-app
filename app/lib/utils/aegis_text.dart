import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// AEGIS text style helpers — Nunito headings, DM Sans body.
// All are getters (not const) so GoogleFonts can be used.
class AegisText {
  AegisText._();

  // ── Headings (Nunito) ───────────────────────────────────────────────────
  static TextStyle h1({Color? color}) =>
      GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: color, letterSpacing: 1);

  static TextStyle h2({Color? color}) =>
      GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: color);

  static TextStyle h3({Color? color}) =>
      GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: color);

  static TextStyle h4({Color? color}) =>
      GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800, color: color);

  static TextStyle h5({Color? color}) =>
      GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: color);

  static TextStyle title({Color? color}) =>
      GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: color);

  static TextStyle numDisplay({Color? color}) =>
      GoogleFonts.nunito(fontSize: 52, fontWeight: FontWeight.w800, height: 1, color: color);

  static TextStyle numLarge({Color? color}) =>
      GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, height: 1, color: color);

  static TextStyle numMedium({Color? color}) =>
      GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, height: 1, color: color);

  // ── Body (DM Sans) ──────────────────────────────────────────────────────
  static TextStyle bodyLg({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: color, height: 1.5);

  static TextStyle body({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.45);

  static TextStyle bodySm({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: color);

  static TextStyle label({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3);

  static TextStyle caption({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle micro({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4);

  static TextStyle micro9({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4);

  static TextStyle unit({Color? color}) =>
      GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: color);

  // ── Context-aware convenience ───────────────────────────────────────────
  static TextStyle h1ctx(BuildContext ctx)    => h1(color: AegisT.text(ctx));
  static TextStyle h2ctx(BuildContext ctx)    => h2(color: AegisT.text(ctx));
  static TextStyle h3ctx(BuildContext ctx)    => h3(color: AegisT.text(ctx));
  static TextStyle h4ctx(BuildContext ctx)    => h4(color: AegisT.text(ctx));
  static TextStyle h5ctx(BuildContext ctx)    => h5(color: AegisT.text(ctx));
  static TextStyle bodyCtx(BuildContext ctx)  => body(color: AegisT.text(ctx));
  static TextStyle dimCtx(BuildContext ctx)   => body(color: AegisT.textDim(ctx));
  static TextStyle labelDimCtx(BuildContext ctx) => label(color: AegisT.textDim(ctx));
  static TextStyle capDimCtx(BuildContext ctx) => caption(color: AegisT.textDim(ctx));
}
