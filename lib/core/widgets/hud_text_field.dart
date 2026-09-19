import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HudTextField extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final bool hasScannerButton;
  final VoidCallback? onScanPressed;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const HudTextField({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.hasScannerButton = false,
    this.onScanPressed,
    this.validator,
    this.onChanged,
  });

  @override
  State<HudTextField> createState() => _HudTextFieldState();
}

class _HudTextFieldState extends State<HudTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
          cursorColor: AppColors.primary,
          validator: widget.validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            hintText: widget.placeholder,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.outline.withAlpha(150),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66BEC9C2), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66BEC9C2), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.outline, size: 20)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.hasScannerButton
                    ? Container(
                        margin: const EdgeInsets.all(4),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                          onPressed: widget.onScanPressed,
                        ),
                      )
                    : null,
          ),
        ),
      ],
    );
  }
}
