import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AegisButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AegisButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: isOutlined
              ? null
              : const LinearGradient(
                  colors: [aegisPink, aegisPinkDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          border: isOutlined
              ? Border.all(color: aegisRose, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: aegisPink.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.bodyMid.copyWith(
                    color: isOutlined ? aegisRose : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
