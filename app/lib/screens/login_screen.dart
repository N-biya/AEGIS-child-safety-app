import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';

// ── Inline SVG helpers ────────────────────────────────────────────────────
// Build SVG strings with dynamic theme colors injected as hex literals.

String _hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

// Email envelope icon (stroke = T.textDim)
String _emailSvg(Color strokeColor) => '''
<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="5" width="20" height="14" rx="2.5"
        stroke="${_hexOf(strokeColor)}" stroke-width="2"/>
  <path d="M3 7l9 6 9-6"
        stroke="${_hexOf(strokeColor)}" stroke-width="2"/>
</svg>''';

// Lock icon (stroke = accent)
String _lockSvg(Color strokeColor) => '''
<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="11" width="16" height="10" rx="2"
        stroke="${_hexOf(strokeColor)}" stroke-width="2"/>
  <path d="M8 11V7a4 4 0 018 0v4"
        stroke="${_hexOf(strokeColor)}" stroke-width="2"/>
</svg>''';

// Shield for logo area — white strokes on gradient bg
const _shieldLogoSvg = '''
<svg width="36" height="42" viewBox="0 0 36 42" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <path d="M18 2L4 7v13c0 9 6 16 14 19 8-3 14-10 14-19V7L18 2z"
        fill="rgba(255,255,255,0.25)" stroke="#FFFFFF"
        stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M12 21l4 4 8-9"
        stroke="#FFFFFF" stroke-width="2.8"
        stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>''';

// 4-path Google G logo from the spec
const _googleSvg = '''
<svg width="18" height="18" viewBox="0 0 24 24"
     xmlns="http://www.w3.org/2000/svg">
  <path fill="#4285F4"
        d="M22 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.6a4.8 4.8 0 01-2 3.2v2.6h3.4c2-1.8 3-4.6 3-7.6z"/>
  <path fill="#34A853"
        d="M12 22c2.7 0 5-.9 6.7-2.4l-3.4-2.6a6 6 0 01-9-3.1H2.7v2.7A10 10 0 0012 22z"/>
  <path fill="#FBBC05"
        d="M6.3 13.9a6 6 0 010-3.8V7.4H2.7a10 10 0 000 9.2l3.6-2.7z"/>
  <path fill="#EA4335"
        d="M12 6a5.4 5.4 0 013.8 1.5l2.9-2.9A10 10 0 002.7 7.4l3.6 2.7A6 6 0 0112 6z"/>
</svg>''';

// ─────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'sarah@parent.app');
  final _passCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _enterCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeIn);
    _enterCtrl.forward();

    // Rebuild on focus change to update field border styling
    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    final error = await context.read<AuthService>().signIn(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() { _loading = false; _error = error; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);

    return Scaffold(
      // Prevents keyboard from resizing the layout — we scroll instead
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? kDarkBg : kLightBg,
      body: Stack(
        children: [
          const AuroraBg(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── Logo section ─────────────────────────────────────
                  _LogoSection(isDark: isDark),
                  const SizedBox(height: 28),

                  // ── Login card ────────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _LoginCard(
                        isDark: isDark,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        emailFocus: _emailFocus,
                        passFocus: _passFocus,
                        emailFocused: _emailFocus.hasFocus,
                        passFocused: _passFocus.hasFocus,
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        loading: _loading,
                        error: _error,
                        onSignIn: _signIn,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Footer ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to AEGIS? ',
                        style: AegisText.body(
                            color: isDark ? kDarkTextDim : kLightTextDim)
                            .copyWith(fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed('/signup'),
                        child: Text(
                          'Create account',
                          style: AegisText.body(color: kAccent)
                              .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo section ───────────────────────────────────────────────────────────
class _LogoSection extends StatelessWidget {
  final bool isDark;
  const _LogoSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? kDarkText    : kLightText;
    final dimColor  = isDark ? kDarkTextDim : kLightTextDim;

    return Column(
      children: [
        // Gradient container with inline shield SVG
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [kAccent, kAccentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x667C3AED), // rgba(124,58,237,0.40)
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Color(0x4DFFFFFF), // inset 0 1px 0 rgba(255,255,255,0.30)
                blurRadius: 0,
                spreadRadius: 0,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.string(
              _shieldLogoSvg,
              width: 36,
              height: 42,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // "AEGIS" — Nunito 800
        Text(
          'AEGIS',
          style: AegisText.h1(color: textColor).copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          'Keeping your child safe, always.',
          style: AegisText.body(color: dimColor)
              .copyWith(fontSize: 13, letterSpacing: 0.2),
        ),
      ],
    );
  }
}

// ── Login card ─────────────────────────────────────────────────────────────
// Not a GlassCard — it's a solid dark card per the design spec.
class _LoginCard extends StatelessWidget {
  final bool isDark;
  final TextEditingController emailCtrl, passCtrl;
  final FocusNode emailFocus, passFocus;
  final bool emailFocused, passFocused, obscure, loading;
  final String? error;
  final VoidCallback onToggleObscure, onSignIn;

  const _LoginCard({
    required this.isDark,
    required this.emailCtrl,
    required this.passCtrl,
    required this.emailFocus,
    required this.passFocus,
    required this.emailFocused,
    required this.passFocused,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.error,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? kDarkText    : kLightText;
    final dimColor  = isDark ? kDarkTextDim : kLightTextDim;

    // Card bg: spec override uses kDarkBg (#1A0F2E) for dark, white for light
    final cardBg    = isDark ? kDarkBg : Colors.white;
    final cardBorder = isDark
        ? const Color(0x4D7C3AED)  // rgba(124,58,237,0.30)
        : const Color(0x267C3AED); // rgba(124,58,237,0.15)
    final shadowGlow = isDark
        ? const Color(0x667C3AED)  // rgba(124,58,237,0.40)
        : const Color(0x337C3AED); // rgba(124,58,237,0.20)
    final shadowDrop = isDark
        ? const Color(0x4D000000)  // rgba(0,0,0,0.30)
        : const Color(0x1A7C3AED); // rgba(124,58,237,0.10)

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Welcome back"
          Text(
            'Welcome back',
            style: AegisText.h4(color: textColor)
                .copyWith(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to continue protecting Aisha',
            style: AegisText.body(color: dimColor).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 22),

          // ── Email field ────────────────────────────────────────────
          _FieldLabel(text: 'EMAIL', color: dimColor),
          const SizedBox(height: 6),
          _StyledField(
            controller: emailCtrl,
            focusNode: emailFocus,
            isFocused: emailFocused,
            isDark: isDark,
            textColor: textColor,
            dimColor: dimColor,
            iconSvg: _emailSvg(dimColor),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          // ── Password field ─────────────────────────────────────────
          _FieldLabel(text: 'PASSWORD', color: dimColor),
          const SizedBox(height: 6),
          _StyledField(
            controller: passCtrl,
            focusNode: passFocus,
            // Password field always shows the "focused" visual per spec
            isFocused: true,
            isDark: isDark,
            textColor: textColor,
            dimColor: dimColor,
            iconSvg: _lockSvg(kAccent),
            obscureText: obscure,
            suffix: GestureDetector(
              onTap: onToggleObscure,
              child: Text(
                obscure ? 'Show' : 'Hide',
                style: AegisText.label(color: kAccent)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Forgot password ────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Forgot password?',
              style: AegisText.label(color: kAccent)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: AegisText.caption(color: kAlert),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 18),

          // ── Sign In button ─────────────────────────────────────────
          GestureDetector(
            onTap: loading ? null : onSignIn,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: kAccent,
                boxShadow: const [
                  // 0 8px 22px rgba(124,58,237,0.4)
                  BoxShadow(color: Color(0x667C3AED), blurRadius: 22, offset: Offset(0, 8)),
                  // inset 0 1px 0 rgba(255,255,255,0.25)
                  BoxShadow(color: Color(0x40FFFFFF), blurRadius: 0, spreadRadius: 0, offset: Offset(0, 1)),
                ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Sign In',
                        style: AegisText.title(color: Colors.white)
                            .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── OR divider ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: isDark
                      ? const Color(0x14FFFFFF) // rgba(255,255,255,0.08)
                      : const Color(0x142D1A4A), // rgba(45,26,74,0.08)
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR',
                  style: AegisText.micro(color: dimColor)
                      .copyWith(letterSpacing: 0.5, fontSize: 11),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: isDark
                      ? const Color(0x14FFFFFF)
                      : const Color(0x142D1A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Google button ──────────────────────────────────────────
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                width: 1.5,
                color: isDark
                    ? const Color(0x24FFFFFF) // rgba(255,255,255,0.14)
                    : const Color(0x1A2D1A4A), // rgba(45,26,74,0.10)
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(_googleSvg, width: 18, height: 18),
                const SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: AegisText.body(color: textColor)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field uppercase label ─────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AegisText.micro(color: color)
          .copyWith(fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5),
    );
  }
}

// ── Custom styled input field ─────────────────────────────────────────────
// Wraps TextField in a custom container that replicates the design spec
// styling — no InputDecoration border, container handles all visual chrome.
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isDark;
  final Color textColor, dimColor;
  final String iconSvg;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;

  const _StyledField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isDark,
    required this.textColor,
    required this.dimColor,
    required this.iconSvg,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    // Colors per focus state, matching spec exactly
    final Color fillColor;
    final Color borderColor;
    final List<BoxShadow> shadows;

    if (isFocused) {
      fillColor   = isDark
          ? const Color(0x2E7C3AED) // rgba(124,58,237,0.18)
          : const Color(0x147C3AED); // rgba(124,58,237,0.08)
      borderColor = kAccent;
      shadows = [
        BoxShadow(
          color: isDark
              ? const Color(0x2E7C3AED) // rgba(124,58,237,0.18)
              : const Color(0x1A7C3AED), // rgba(124,58,237,0.10)
          blurRadius: 0,
          spreadRadius: 4,
        ),
      ];
    } else {
      fillColor   = isDark
          ? const Color(0x0FFFFFFF) // rgba(255,255,255,0.06)
          : const Color(0x0F7C3AED); // rgba(124,58,237,0.06)
      borderColor = isDark
          ? const Color(0x14FFFFFF) // rgba(255,255,255,0.08)
          : const Color(0x1A7C3AED); // rgba(124,58,237,0.10)
      shadows = const [];
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: fillColor,
        border: Border.all(
          color: borderColor,
          width: isFocused ? 1.5 : 1,
        ),
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
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
