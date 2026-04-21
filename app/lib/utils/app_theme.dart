import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData get aegisTheme => ThemeData(
      scaffoldBackgroundColor: aegisCream,
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.light(
        primary: aegisPink,
        secondary: aegisLavender,
        surface: aegisCard,
        error: aegisRose,
      ),
      cardTheme: CardThemeData(
        color: aegisCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.h3,
        iconTheme: IconThemeData(color: aegisText),
      ),
      dividerTheme: const DividerThemeData(
        color: aegisWarm,
        thickness: 0.8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: aegisPinkLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: aegisPink, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: aegisPink, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: aegisPinkDark, width: 1.5),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.caption,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return aegisPinkDark;
          return aegisTextSoft;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return aegisPink;
          return aegisWarm;
        }),
      ),
    );
