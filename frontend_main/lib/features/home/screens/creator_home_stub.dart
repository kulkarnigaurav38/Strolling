import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/onboarding_args.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/user_role.dart';

class CreatorHomeStub extends StatelessWidget {
  const CreatorHomeStub({super.key, required this.args});

  final OnboardingArgs args;

  @override
  Widget build(BuildContext context) {
    final browsing = args.role == UserRole.browse;
    final city = args.city;
    return Scaffold(
      backgroundColor: StrollingColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                browsing ? 'Browsing' : 'Creator',
                style: GoogleFonts.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: StrollingColors.ink,
                ),
              ),
              if (city != null) ...[
                const SizedBox(height: 8),
                Text(
                  city,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: StrollingColors.primaryDeep,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                browsing
                    ? 'You\'re exploring as a guest. Map coming soon.'
                    : 'Your map and stroll are coming soon.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  height: 1.45,
                  color: StrollingColors.mutedAlt,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.role),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: StrollingColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: StrollingColors.ink,
                ),
                child: Text(
                  'Change role',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
