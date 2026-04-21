import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: aegisText,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: aegisText,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: aegisText,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: aegisText,
    height: 1.5,
  );

  static const TextStyle bodyMid = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: aegisText,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: aegisTextMid,
    letterSpacing: 0.3,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: aegisTextSoft,
  );

  static const TextStyle vitalNumber = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: aegisText,
  );
}
