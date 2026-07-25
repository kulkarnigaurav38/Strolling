import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/copy.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

/// Gradient hero + wordmark + social logins, per the design's onboarding.
/// Logins are mocked — they just record which provider was "connected".
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void signIn(String provider) => ref.read(authProvider.notifier).signIn(provider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(gradient: AppColors.sunset),
                child: Stack(
                  children: [
                    // City-silhouette hint behind the wordmark.
                    Positioned.fill(
                      child: CustomPaint(painter: _SkylinePainter()),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(Icons.place_outlined,
                                color: Colors.white, size: 42),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            Copy.wordmark,
                            style: titleStyle(
                              size: 52,
                              color: Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            Copy.tagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  Copy.connectHint,
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Continue with Instagram',
                  icon: CupertinoIcons.camera_fill,
                  gradient: AppColors.instagram,
                  onTap: () => signIn('instagram'),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continue with Facebook',
                  icon: Icons.facebook,
                  color: AppColors.facebook,
                  onTap: () => signIn('facebook'),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continue with Google',
                  letter: 'G',
                  color: Colors.white,
                  textColor: AppColors.text,
                  onTap: () => signIn('google'),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => signIn('guest'),
                  child: const Text(
                    Copy.browseWithout,
                    style: TextStyle(color: AppColors.muted, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? letter;
  final Gradient? gradient;
  final Color? color;
  final Color textColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.letter,
    this.gradient,
    this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: color == Colors.white
              ? Border.all(color: AppColors.border, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: textColor)
            else
              Text(letter ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  )),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft wave along the hero's bottom edge, like the design.
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
          size.width * 0.25, size.height, size.width * 0.5, size.height - 18)
      ..quadraticBezierTo(
          size.width * 0.8, size.height - 40, size.width, size.height - 10)
      ..lineTo(size.width, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final base = size.height;
    // A loose row of tower blocks.
    const widths = [0.10, 0.07, 0.12, 0.08, 0.11, 0.09, 0.12, 0.08, 0.13];
    const heights = [0.30, 0.48, 0.38, 0.62, 0.34, 0.52, 0.42, 0.58, 0.36];
    var x = 0.0;
    for (var i = 0; i < widths.length; i++) {
      final w = size.width * widths[i];
      final h = size.height * heights[i];
      canvas.drawRect(Rect.fromLTWH(x, base - h, w - 6, h), paint);
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
