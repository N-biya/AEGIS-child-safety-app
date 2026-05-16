import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';

/// Card container that exactly matches the Login / Signup card style:
/// dark bg = kDarkBg, light bg = white, with accent border + glow shadows.
class AegisFormCard extends StatelessWidget {
  final Widget child;
  const AegisFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark      = AegisT.isDark(context);
    final cardBg      = isDark ? kDarkBg : Colors.white;
    final cardBorder  = isDark ? const Color(0x4D7C3AED) : const Color(0x267C3AED);
    final shadowGlow  = isDark ? const Color(0x667C3AED) : const Color(0x337C3AED);
    final shadowDrop  = isDark ? const Color(0x4D000000) : const Color(0x1A7C3AED);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cardBg,
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(color: shadowGlow, blurRadius: 60),
          BoxShadow(color: shadowDrop, blurRadius: 32, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

/// Uppercase field label — identical to the private _FieldLabel in login/signup.
class AegisFieldLabel extends StatelessWidget {
  final String text;
  const AegisFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AegisText.micro(color: AegisT.textDim(context))
          .copyWith(fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5),
    );
  }
}

/// Styled text field with an SVG icon prefix — matches login/signup field style exactly.
class AegisTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String iconSvg;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? hintText;

  const AegisTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.iconSvg,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark    = AegisT.isDark(context);
    final textColor = AegisT.text(context);
    final dimColor  = AegisT.textDim(context);

    final Color fillColor;
    final Color borderColor;
    final List<BoxShadow> shadows;

    if (isFocused) {
      fillColor   = isDark ? const Color(0x2E7C3AED) : const Color(0x147C3AED);
      borderColor = kAccent;
      shadows     = [
        BoxShadow(
          color: isDark ? const Color(0x2E7C3AED) : const Color(0x1A7C3AED),
          blurRadius: 0,
          spreadRadius: 4,
        ),
      ];
    } else {
      fillColor   = isDark ? const Color(0x0FFFFFFF) : const Color(0x0F7C3AED);
      borderColor = isDark ? const Color(0x14FFFFFF)  : const Color(0x1A7C3AED);
      shadows     = const [];
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: fillColor,
        border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          SvgPicture.string(iconSvg, width: 16, height: 16),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: AegisText.body(color: textColor).copyWith(fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hintText,
                hintStyle: AegisText.body(color: dimColor).copyWith(fontSize: 15),
              ),
              cursorColor: kAccent,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            suffix!,
            const SizedBox(width: 14),
          ] else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// Primary accent-filled button — same style as Sign In / Create Account buttons.
class AegisPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const AegisPrimaryButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: kAccent,
          boxShadow: const [
            BoxShadow(color: Color(0x667C3AED), blurRadius: 22, offset: Offset(0, 8)),
            BoxShadow(color: Color(0x40FFFFFF), blurRadius: 0, spreadRadius: 0, offset: Offset(0, 1)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: AegisText.title(color: Colors.white)
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
