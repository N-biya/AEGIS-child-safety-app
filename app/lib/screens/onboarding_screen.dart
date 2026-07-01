import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/child_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';
import '../widgets/aegis_form.dart';

// ── Inline SVG helpers ────────────────────────────────────────────────────
String _hexOf(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

String _personSvg(Color c) => '''
<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="8" r="4" stroke="${_hexOf(c)}" stroke-width="2"/>
  <path d="M4 21a8 8 0 0116 0" stroke="${_hexOf(c)}" stroke-width="2"
        stroke-linecap="round"/>
</svg>''';

String _childSvg(Color c) => '''
<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="7" r="3.5" stroke="${_hexOf(c)}" stroke-width="2"/>
  <path d="M5 20c0-3.866 3.134-7 7-7s7 3.134 7 7"
        stroke="${_hexOf(c)}" stroke-width="2" stroke-linecap="round"/>
</svg>''';

String _ageSvg(Color c) => '''
<svg width="16" height="16" viewBox="0 0 24 24" fill="none"
     xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="${_hexOf(c)}" stroke-width="2"/>
  <path d="M12 7v5l3 3" stroke="${_hexOf(c)}" stroke-width="2"
        stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

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

// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  final _parentNameCtrl = TextEditingController();
  final _childNameCtrl  = TextEditingController();
  final _childAgeCtrl   = TextEditingController();
  String _parentRelation = '';

  final _parentNameFocus = FocusNode();
  final _childNameFocus  = FocusNode();
  final _childAgeFocus   = FocusNode();

  bool    _loading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _parentNameFocus.addListener(() => setState(() {}));
    _childNameFocus.addListener(() => setState(() {}));
    _childAgeFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _parentNameCtrl.dispose();
    _childNameCtrl.dispose();
    _childAgeCtrl.dispose();
    _parentNameFocus.dispose();
    _childNameFocus.dispose();
    _childAgeFocus.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (_parentNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (_parentRelation.isEmpty) {
      setState(() => _error = 'Please select how you\'re related to your child.');
      return;
    }
    setState(() { _error = null; _step = 1; });
    _animCtrl.reset();
    _animCtrl.forward();
  }

  Future<void> _finish() async {
    final childName   = _childNameCtrl.text.trim();
    final childAgeStr = _childAgeCtrl.text.trim();
    if (childName.isEmpty || childAgeStr.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final childAge = int.tryParse(childAgeStr);
    if (childAge == null || childAge < 1 || childAge > 18) {
      setState(() => _error = 'Enter a valid age between 1 and 18.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final uid = context.read<AuthService>().userId;
    final child = ChildModel(
      id:                const Uuid().v4(),
      name:              childName,
      age:               childAge,
      deviceId:          '',
      emergencyContacts: const [],
      calibrated:        false,
      daysCollected:     0,
    );

    try {
      await FirestoreService().createChild(uid, child);
      await PrefsService.completeOnboarding(
        parentNameVal:     _parentNameCtrl.text.trim(),
        parentRelationVal: _parentRelation,
        childNameVal:      childName,
        childAgeVal:       childAge,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() { _loading = false; _error = 'Could not save your profile. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = AegisT.isDark(context);
    final dimColor = AegisT.textDim(context);

    return Scaffold(
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

                  // ── Logo ─────────────────────────────────────────────
                  _OnboardingLogo(isDark: isDark),
                  const SizedBox(height: 28),

                  // ── Step dots ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepDot(active: _step == 0),
                      const SizedBox(width: 8),
                      _StepDot(active: _step == 1),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Animated card ─────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: AegisFormCard(
                        child: _step == 0
                            ? _StepOneBody(
                                dimColor:  dimColor,
                                ctrl:      _parentNameCtrl,
                                focus:     _parentNameFocus,
                                isFocused: _parentNameFocus.hasFocus,
                                relation:  _parentRelation,
                                onRelationChanged: (r) =>
                                    setState(() => _parentRelation = r),
                                error:     _error,
                                onNext:    _goToStep2,
                              )
                            : _StepTwoBody(
                                dimColor:         dimColor,
                                childNameCtrl:    _childNameCtrl,
                                childAgeCtrl:     _childAgeCtrl,
                                childNameFocus:   _childNameFocus,
                                childAgeFocus:    _childAgeFocus,
                                childNameFocused: _childNameFocus.hasFocus,
                                childAgeFocused:  _childAgeFocus.hasFocus,
                                loading:          _loading,
                                error:            _error,
                                onFinish:         _finish,
                              ),
                      ),
                    ),
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

// ── Logo ──────────────────────────────────────────────────────────────────────
class _OnboardingLogo extends StatelessWidget {
  final bool isDark;
  const _OnboardingLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? kDarkText    : kLightText;
    final dimColor  = isDark ? kDarkTextDim : kLightTextDim;

    return Column(
      children: [
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
              BoxShadow(color: Color(0x667C3AED), blurRadius: 32, offset: Offset(0, 12)),
              BoxShadow(color: Color(0x4DFFFFFF), blurRadius: 0, offset: Offset(0, 1)),
            ],
          ),
          child: Center(
            child: SvgPicture.string(_shieldLogoSvg, width: 36, height: 42),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AEGIS',
          style: AegisText.h1(color: textColor)
              .copyWith(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          "Let's set up your guardian profile.",
          style: AegisText.body(color: dimColor).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

// ── Step indicator dot ────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? kAccent
            : AegisT.textDim(context).withValues(alpha: 0.3),
      ),
    );
  }
}

// ── Step 1 — parent name ──────────────────────────────────────────────────────
class _StepOneBody extends StatelessWidget {
  final Color dimColor;
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool isFocused;
  final String relation;
  final ValueChanged<String> onRelationChanged;
  final String? error;
  final VoidCallback onNext;

  static const _relations = ['Mother', 'Father', 'Guardian'];

  const _StepOneBody({
    required this.dimColor,
    required this.ctrl,
    required this.focus,
    required this.isFocused,
    required this.relation,
    required this.onRelationChanged,
    required this.error,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What should we call you?',
          style: AegisText.h4(color: T)
              .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "We'll use this to personalise your experience.",
          style: AegisText.body(color: dimColor).copyWith(fontSize: 13),
        ),
        const SizedBox(height: 22),
        const AegisFieldLabel('YOUR NAME'),
        const SizedBox(height: 6),
        AegisTextField(
          controller:   ctrl,
          focusNode:    focus,
          isFocused:    isFocused,
          iconSvg:      _personSvg(isFocused ? kAccent : dimColor),
          keyboardType: TextInputType.name,
          hintText:     'e.g. Sarah',
        ),
        const SizedBox(height: 14),
        const AegisFieldLabel('YOUR RELATION TO YOUR CHILD'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _relations.map((r) {
            final selected = relation == r;
            return GestureDetector(
              onTap: () => onRelationChanged(r),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: selected
                      ? kAccent
                      : (AegisT.isDark(context)
                          ? const Color(0x0FFFFFFF)
                          : const Color(0x0A7C3AED)),
                ),
                child: Text(r,
                    style: AegisText.label(color: selected ? Colors.white : dimColor)
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: AegisText.caption(color: kAlert), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        AegisPrimaryButton(label: 'Next', onTap: onNext),
      ],
    );
  }
}

// ── Step 2 — child name + age ─────────────────────────────────────────────────
class _StepTwoBody extends StatelessWidget {
  final Color dimColor;
  final TextEditingController childNameCtrl, childAgeCtrl;
  final FocusNode childNameFocus, childAgeFocus;
  final bool childNameFocused, childAgeFocused, loading;
  final String? error;
  final VoidCallback onFinish;

  const _StepTwoBody({
    required this.dimColor,
    required this.childNameCtrl,
    required this.childAgeCtrl,
    required this.childNameFocus,
    required this.childAgeFocus,
    required this.childNameFocused,
    required this.childAgeFocused,
    required this.loading,
    required this.error,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final T = AegisT.text(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Who are you protecting?',
          style: AegisText.h4(color: T)
              .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us about your child so we can keep them safe.',
          style: AegisText.body(color: dimColor).copyWith(fontSize: 13),
        ),
        const SizedBox(height: 22),
        const AegisFieldLabel("CHILD'S NAME"),
        const SizedBox(height: 6),
        AegisTextField(
          controller:   childNameCtrl,
          focusNode:    childNameFocus,
          isFocused:    childNameFocused,
          iconSvg:      _childSvg(childNameFocused ? kAccent : dimColor),
          keyboardType: TextInputType.name,
          hintText:     'e.g. Aisha',
        ),
        const SizedBox(height: 14),
        const AegisFieldLabel("CHILD'S AGE"),
        const SizedBox(height: 6),
        AegisTextField(
          controller:   childAgeCtrl,
          focusNode:    childAgeFocus,
          isFocused:    childAgeFocused,
          iconSvg:      _ageSvg(childAgeFocused ? kAccent : dimColor),
          keyboardType: TextInputType.number,
          hintText:     'e.g. 8',
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: AegisText.caption(color: kAlert), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        AegisPrimaryButton(label: "Let's Go", loading: loading, onTap: onFinish),
      ],
    );
  }
}
