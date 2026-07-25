import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The one place colour, type and shape are defined. Ported from the brief's
/// globals.css — a fixed warm-dark theme (never system-driven) so the demo looks
/// identical on every phone we hand over at the venue.
class AppColors {
  static const bg = Color(0xFF0F0D0B);
  static const bg2 = Color(0xFF171310);
  static const panel = Color(0xFF1E1813);
  static const panel2 = Color(0xFF26201A);
  static const border = Color(0xFF3A2F26);
  static const text = Color(0xFFF6EFE7);
  static const muted = Color(0xFFB9A996);
  static const amber = Color(0xFFF59E0B);
  static const orange = Color(0xFFF97316);
  static const accentInk = Color(0xFF1A1206);

  static const amberGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [amber, orange],
  );

  // Warm glow from the top, like room light (mirrors the CSS body radial).
  static const roomGlow = RadialGradient(
    center: Alignment(0, -1.1),
    radius: 1.1,
    colors: [Color(0xFF2A1C0F), bg],
    stops: [0.0, 0.6],
  );
}

class AppRadius {
  static const card = 20.0;
  static const button = 16.0;
  static const pill = 999.0;
}

ThemeData buildFernwehTheme() {
  // fromSeed + copyWith keeps this resilient across Flutter 3.x ColorScheme
  // field changes while pinning the brand colours we actually use.
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.amber,
    onPrimary: AppColors.accentInk,
    secondary: AppColors.orange,
    onSecondary: AppColors.accentInk,
    surface: AppColors.panel,
    onSurface: AppColors.text,
    error: const Color(0xFFF87171),
    onError: AppColors.accentInk,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    // Kill visible Material chrome — no ripples, no default fills.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.amber,
      selectionColor: Color(0x33F59E0B),
      selectionHandleColor: AppColors.amber,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.25),
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
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
    ),
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
  );
}
