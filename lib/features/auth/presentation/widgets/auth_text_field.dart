import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sweatera/core/theme/app_theme.dart';

/// Reusable styled text field for auth screens.
/// Applies the SweatEra dark glassmorphism design system.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: obscureText ? 1 : maxLines,
      style: GoogleFonts.inter(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: AppTheme.primaryStart,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppTheme.textMuted, size: 20)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
