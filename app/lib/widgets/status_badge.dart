import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  _BadgeStyle get _style {
    switch (status) {
      case 'STRESS':
      case 'ALERT':
        return _BadgeStyle(statusAlert, Colors.white, 'Alert');
      case 'ELEVATED':
        return _BadgeStyle(statusElevated, Colors.white, 'Elevated');
      case 'CALIBRATING':
        return _BadgeStyle(statusCalibrating, Colors.white, 'Calibrating');
      default:
        return _BadgeStyle(statusSafe, Colors.white, 'Safe');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _style.bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _style.label.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          color: _style.fg,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;
  final String label;
  const _BadgeStyle(this.bg, this.fg, this.label);
}
