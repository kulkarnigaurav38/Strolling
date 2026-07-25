import 'package:flutter/material.dart';

import '../theme.dart';

/// The phone frame. Paints the warm room-glow background and constrains content
/// to a phone width so the app also looks right in `flutter build web` on desktop.
/// Mirrors the brief's `.phone` container + body gradient.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.roomGlow),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
