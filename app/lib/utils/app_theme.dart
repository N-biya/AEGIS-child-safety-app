import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData get aegisDarkTheme => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kDarkBg,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kAccentLight,
        surface: kDarkCard,
        onSurface: kDarkText,
        error: kAlert,
      ),
      cardTheme: CardThemeData(
        color: kDarkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: kDarkText),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D2460),
        thickness: 0.8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kAccent;
          return kDarkTextDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kAccentLight;
          return kDarkCard;
        }),
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge:  GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: kDarkText),
        displayMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: kDarkText),
        displaySmall:  GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700, color: kDarkText),
        headlineMedium: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: kDarkText),
        headlineSmall:  GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800, color: kDarkText),
        titleLarge:    GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: kDarkText),
        bodyLarge:     GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: kDarkText),
        bodyMedium:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: kDarkText),
        bodySmall:     GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: kDarkTextDim),
        labelLarge:    GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: kDarkTextDim),
        labelSmall:    GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: kDarkTextDim),
      ),
    );

ThemeData get aegisLightTheme => ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: kLightBg,
      colorScheme: const ColorScheme.light(
        primary: kAccent,
        secondary: kAccentLight,
        surface: kLightCard,
        onSurface: kLightText,
        error: kAlert,
      ),
      cardTheme: CardThemeData(
        color: kLightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: kLightText),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE0FF),
        thickness: 0.8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kAccent;
          return kLightTextDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kAccentLight;
          return kLightNav;
        }),
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge:  GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: kLightText),
        displayMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w800, color: kLightText),
        displaySmall:  GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700, color: kLightText),
        headlineMedium: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: kLightText),
        headlineSmall:  GoogleFonts.nunito(fontSize: 19, fontWeight: FontWeight.w800, color: kLightText),
        titleLarge:    GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: kLightText),
        bodyLarge:     GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: kLightText),
        bodyMedium:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: kLightText),
        bodySmall:     GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: kLightTextDim),
        labelLarge:    GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: kLightTextDim),
        labelSmall:    GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: kLightTextDim),
      ),
    );

// Legacy aliases kept for widgets not yet rewritten
ThemeData get aegisTheme     => aegisLightTheme;
