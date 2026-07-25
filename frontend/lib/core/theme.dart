import 'package:flutter/material.dart';

/// The one place colour, type and shape are defined. Warm cream light theme,
/// coral CTAs, sunset hero gradient, ink-navy accents. Typeface: SF Pro.
class AppColors {
  // Surfaces
  static const bg = Color(0xFFF8F5F0); // warm cream page
  static const card = Colors.white;
  static const ink = Color(0xFF241E38); // dark navy — mode card, headings
  static const text = Color(0xFF2C2640);
  static const muted = Color(0xFF8D8798);
  static const border = Color(0xFFEDE8E0);

  // Brand
  static const coral = Color(0xFFF1512D); // primary CTA
  static const coralDark = Color(0xFFD8431F);
  static const amber = Color(0xFFF6A50B); // perk value badges
  static const green = Color(0xFF23B26D); // captured / approved
  static const indigo = Color(0xFF6C63E8);
  static const leaf = Color(0xFFE8940A);

  // Sunset hero gradient (onboarding header).
  static const sunset = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9A13B), Color(0xFFF05423), Color(0xFFE23A2E)],
  );

  static const instagram = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
  );

  static const facebook = Color(0xFF1877F2);
}

class AppRadius {
  static const card = 22.0;
  static const button = 18.0;
  static const pill = 999.0;
}

const kFontFamily = 'SF Pro';

/// Headings — SF Pro, heavy. (Business names, screen titles, the wordmark.)
TextStyle titleStyle({
  double size = 32,
  Color color = AppColors.text,
  FontWeight weight = FontWeight.w700,
}) =>
    TextStyle(
      fontFamily: kFontFamily,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: -0.4,
    );

ThemeData buildStrollingTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.coral,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.coral,
    onPrimary: Colors.white,
    secondary: AppColors.amber,
    onSecondary: Colors.white,
    surface: AppColors.card,
    onSurface: AppColors.text,
    error: const Color(0xFFDC2626),
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
      ),
    ),
  );
}
