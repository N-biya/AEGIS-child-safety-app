import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Frosted glass card matching the AEGIS GlassCard spec.
/// Uses BackdropFilter to blur what's rendered behind it.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool padded;
  final double borderRadius;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.padded = true,
    this.borderRadius = 20,
    this.constraints,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AegisT.isDark(context);
    final bg = AegisT.glassBg(context);
    final border = AegisT.glassBorder(context);
    final shadow = isDark
        ? [
            BoxShadow(
              color: const Color(0x0FFFFFFF),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
            const BoxShadow(
              color: Color(0x40000000),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xE6FFFFFF),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
            const BoxShadow(
              color: Color(0x147C3AED),
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ];

    final effective = padding ?? (padded ? const EdgeInsets.all(16) : EdgeInsets.zero);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          alignment: alignment,
          constraints: constraints,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
            boxShadow: shadow,
          ),
          padding: effective,
          child: child,
        ),
      ),
    );
  }
}
