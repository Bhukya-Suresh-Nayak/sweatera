import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SweatEra Design System
/// Central theme configuration for the entire app.
/// Uses dark glassmorphism aesthetic with gradient accents.
class AppTheme {
  AppTheme._();

  // ─── Core Colors ────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundMid = Color(0xFF12121A);
  static const Color surfaceCard = Color(0xFF1A1A25);
  static const Color surfaceElevated = Color(0xFF22223A);
  static const Color border = Color(0xFF2A2A40);

  // ─── Brand Gradient (electric violet → cyan) ────────────────────────────────
  static const Color primaryStart = Color(0xFF7C3AED); // violet
  static const Color primaryMid = Color(0xFF9333EA);   // purple
  static const Color primaryEnd = Color(0xFF06B6D4);   // cyan

  static const Color accentGreen = Color(0xFF10B981);  // emerald
  static const Color accentOrange = Color(0xFFF59E0B); // amber
  static const Color accentRed = Color(0xFFEF4444);    // red

  // ─── Text Colors ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB4B4C8);
  static const Color textMuted = Color(0xFF6B6B80);
  static const Color textHint = Color(0xFF4A4A5A);

  // ─── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryStart, primaryMid, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF0F0F1E), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E30), Color(0xFF16162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Glassmorphism ──────────────────────────────────────────────────────────
  static BoxDecoration glassCard({double opacity = 0.08, double radius = 20}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white.withOpacity(opacity),
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryStart.withOpacity(0.15),
          blurRadius: 30,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration gradientCard({double radius = 20}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: cardGradient,
      border: Border.all(
        color: border,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ─── Text Styles ────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  // ─── Material Theme ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryStart,
        secondary: primaryEnd,
        surface: surfaceCard,
        background: backgroundDark,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: accentRed,
        onError: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        titleLarge: titleLarge,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: titleLarge,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primaryStart,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: GoogleFonts.inter(
          color: textHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryStart, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryStart,
          foregroundColor: textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: labelLarge,
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryStart,
          textStyle: labelLarge,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
