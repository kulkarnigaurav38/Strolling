import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Strolling design tokens (Figma + CursorStutt).
abstract final class StrollingColors {
  static const background = Color(0xFFF8F6F2);
  static const ink = Color(0xFF1B1928);
  static const muted = Color(0xFF888699);
  static const mutedAlt = Color(0xFF6B6B80);
  static const primary = Color(0xFFFF5C3A);
  static const primaryDeep = Color(0xFFFF4F2B);
  static const primaryMid = Color(0xFFFF8C42);
  static const primarySoft = Color(0xFFFFB347);
  static const facebook = Color(0xFF1877F2);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0x1F1B1928); // ~12% ink
  static const nearBlack = Color(0xFF0A0A0A);
  static const surfaceMuted = Color(0xFFF4F4F7);
  static const success = Color(0xFF00BC7D);
  static const successDeep = Color(0xFF008236);
  static const warningBg = Color(0xFFFEF3C6);
  static const warningText = Color(0xFFBB4D00);
  static const successBg = Color(0xFFDCFCE7);
  static const infoBg = Color(0xFFDBEAFE);
  static const infoText = Color(0xFF1447E6);
}

ThemeData buildStrollingTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: StrollingColors.background,
    colorScheme: const ColorScheme.light(
      primary: StrollingColors.primary,
      onPrimary: StrollingColors.white,
      secondary: StrollingColors.primaryMid,
      onSecondary: StrollingColors.white,
      surface: StrollingColors.background,
      onSurface: StrollingColors.ink,
      outline: StrollingColors.border,
    ),
  );

  final nunito = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
    bodyColor: StrollingColors.ink,
    displayColor: StrollingColors.ink,
  );
  final fraunces = GoogleFonts.frauncesTextTheme(nunito);

  return base.copyWith(
    textTheme: nunito.copyWith(
      displayLarge: fraunces.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        color: StrollingColors.ink,
      ),
      displayMedium: fraunces.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        color: StrollingColors.ink,
      ),
      headlineLarge: fraunces.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: StrollingColors.ink,
      ),
      headlineMedium: fraunces.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: StrollingColors.ink,
      ),
      headlineSmall: fraunces.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: StrollingColors.ink,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: StrollingColors.ink,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: StrollingColors.ink,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: StrollingColors.ink,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: StrollingColors.mutedAlt,
      ),
      labelLarge: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: StrollingColors.ink,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: StrollingColors.primaryDeep,
        foregroundColor: StrollingColors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
  );
}
