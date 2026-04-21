import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AegisTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool obscure;
  final TextInputType keyboardType;

  const AegisTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AegisTextField> createState() => _AegisTextFieldState();
}

class _AegisTextFieldState extends State<AegisTextField> {
  bool _focused = false;
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: aegisPinkLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused ? aegisPinkDark : aegisPink,
                width: _focused ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscure && !_visible,
              keyboardType: widget.keyboardType,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.caption,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: aegisTextMid, size: 18)
                    : null,
                suffixIcon: widget.obscure
                    ? GestureDetector(
                        onTap: () => setState(() => _visible = !_visible),
                        child: Icon(
                          _visible ? Icons.visibility_off : Icons.visibility,
                          color: aegisTextSoft,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
