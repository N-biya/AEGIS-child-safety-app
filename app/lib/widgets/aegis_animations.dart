import 'package:flutter/material.dart';

/// Breathing pulse wrapper — animates a glowing box shadow ring.
/// Equivalent to .aegis-pulse (aegisBreath, 2.4s ease-in-out infinite).
class AegisPulse extends StatefulWidget {
  final Widget child;
  final Color glowColor;

  const AegisPulse({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF34D399),
  });

  @override
  State<AegisPulse> createState() => _AegisPulseState();
}

class _AegisPulseState extends State<AegisPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final spread = _anim.value * 10;
        final opacity = 0.35 * (1 - _anim.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: opacity),
                blurRadius: spread * 2,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Expanding ping ring — equivalent to .aegis-ping (aegisPing, 2.2s).
/// Renders a pulsing ring behind [child].
class AegisPing extends StatefulWidget {
  final Widget child;
  final Color ringColor;

  const AegisPing({
    super.key,
    required this.child,
    this.ringColor = const Color(0xFF7C3AED),
  });

  @override
  State<AegisPing> createState() => _AegisPingState();
}

class _AegisPingState extends State<AegisPing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              // scale: 0.6 → 2.2, opacity: 0.85 → 0
              final scale = 0.6 + _ctrl.value * 1.6;
              final opacity = 0.85 * (1 - _ctrl.value);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.ringColor.withValues(alpha: opacity * 0.5),
                        widget.ringColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Pulsing dot — equivalent to .aegis-pulse-dot (aegisDot, 1.6s).
class AegisPulseDot extends StatefulWidget {
  final double size;
  final Color color;

  const AegisPulseDot({
    super.key,
    this.size = 6,
    required this.color,
  });

  @override
  State<AegisPulseDot> createState() => _AegisPulseDotState();
}

class _AegisPulseDotState extends State<AegisPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale   = Tween(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween(begin: 1.0, end: 0.4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
