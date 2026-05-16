import 'package:flutter/material.dart';

/// Ambient radial-gradient glow blobs rendered behind screen content.
/// Uses RadialGradient which achieves the same soft-feathered look as
/// CSS radial-gradient + filter:blur on the original design.
class AuroraBg extends StatelessWidget {
  const AuroraBg({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: SizedBox.expand(
        child: isDark ? const _DarkBlobs() : const _LightBlobs(),
      ),
    );
  }
}

class _DarkBlobs extends StatelessWidget {
  const _DarkBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blob 1 — top-left, large purple
        Positioned(
          top: -120,
          left: -80,
          child: _Blob(
            size: 420,
            color: const Color(0x737C3AED), // rgba(124,58,237,0.45)
          ),
        ),
        // Blob 2 — top-right, lighter purple
        Positioned(
          top: 200,
          right: -120,
          child: _Blob(
            size: 380,
            color: const Color(0x47A78BFA), // rgba(167,139,250,0.28)
          ),
        ),
        // Blob 3 — bottom-left, faint rose
        Positioned(
          bottom: -80,
          left: 40,
          child: _Blob(
            size: 300,
            color: const Color(0x1AF43F5E), // rgba(244,63,94,0.10)
          ),
        ),
      ],
    );
  }
}

class _LightBlobs extends StatelessWidget {
  const _LightBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blob 1 — top-right, lavender
        Positioned(
          top: -80,
          right: -80,
          child: _Blob(
            size: 320,
            color: const Color(0x4DA78BFA), // rgba(167,139,250,0.30)
          ),
        ),
        // Blob 2 — bottom-left, purple
        Positioned(
          bottom: 100,
          left: -60,
          child: _Blob(
            size: 280,
            color: const Color(0x2E7C3AED), // rgba(124,58,237,0.18)
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
