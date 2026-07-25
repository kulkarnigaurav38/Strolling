import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/firebase/auth_service.dart';
import '../../../core/onboarding_args.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';

class WelcomeAuthScreen extends StatefulWidget {
  const WelcomeAuthScreen({super.key, required this.args});

  final OnboardingArgs args;

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  final AuthService _auth = AuthService();
  bool _busy = false;

  Future<void> _continue({required Future<bool> Function() signIn}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await signIn();
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in failed. Try again.')),
        );
        return;
      }
      if (!mounted) return;
      context.push(AppRoutes.city, extra: widget.args);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StrollingColors.background,
      body: Column(
        children: [
          Expanded(
            flex: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.6, -1),
                      end: Alignment(0.8, 1),
                      colors: [
                        StrollingColors.primary,
                        StrollingColors.primaryMid,
                        StrollingColors.primarySoft,
                      ],
                      stops: [0.08, 0.58, 0.92],
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    'assets/images/hero_city.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/images/pin_icon.svg',
                            width: 28,
                            height: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Strolling',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.96,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Walk the city.\nGet rewarded.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: SvgPicture.asset(
                      'assets/images/wave_divider.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 42,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Connect to unlock perks and track your reach',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: StrollingColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AuthButton(
                      background: StrollingColors.facebook,
                      foreground: Colors.white,
                      label: 'Continue with Facebook',
                      leading: Text(
                        'f',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      shadow: BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      onTap: _busy
                          ? null
                          : () => _continue(signIn: _auth.signInWithFacebook),
                    ),
                    const SizedBox(height: 12),
                    _AuthButton(
                      background: Colors.white,
                      foreground: StrollingColors.ink,
                      label: 'Continue with Google',
                      leading: Text(
                        'G',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: StrollingColors.ink,
                        ),
                      ),
                      border: Border.all(color: StrollingColors.border),
                      shadow: BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      onTap: _busy
                          ? null
                          : () => _continue(signIn: _auth.signInWithGoogle),
                    ),
                    const Spacer(),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _continue(signIn: _auth.signInAnonymously),
                      child: Text(
                        'Browse without an account →',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: StrollingColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.background,
    required this.foreground,
    required this.label,
    required this.leading,
    required this.onTap,
    this.border,
    this.shadow,
  });

  final Color background;
  final Color foreground;
  final String label;
  final Widget leading;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: shadow == null ? null : [shadow!],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, child: Center(child: leading)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
