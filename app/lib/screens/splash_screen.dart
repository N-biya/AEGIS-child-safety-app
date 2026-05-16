import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/prefs_service.dart';
import '../utils/app_colors.dart';
import '../utils/aegis_text.dart';
import '../widgets/aurora_bg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        final done = await PrefsService.isOnboardingDone();
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(done ? '/home' : '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: Stack(
        children: [
          const AuroraBg(),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo container
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          colors: [kAccent, kAccentLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x667C3AED),
                            blurRadius: 32,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: _ShieldIcon(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'AEGIS',
                      style: AegisText.h1(color: kDarkText)
                          .copyWith(letterSpacing: 8, fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keeping your child safe, always.',
                      style: AegisText.body(color: kDarkTextDim),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 52),
      painter: _ShieldPainter(),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x3DFFFFFF)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    // Scale from reference 36x42
    final sx = size.width / 36;
    final sy = size.height / 42;

    final path = Path()
      ..moveTo(18 * sx, 2 * sy)
      ..lineTo(4 * sx, 7 * sy)
      ..lineTo(4 * sx, 20 * sy)
      ..cubicTo(4 * sx, 29 * sy, 10 * sx, 36 * sy, 18 * sx, 39 * sy)
      ..cubicTo(26 * sx, 36 * sy, 32 * sx, 29 * sy, 32 * sx, 20 * sy)
      ..lineTo(32 * sx, 7 * sy)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(12 * sx, 21 * sy)
      ..lineTo(16 * sx, 25 * sy)
      ..lineTo(24 * sx, 16 * sy);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
