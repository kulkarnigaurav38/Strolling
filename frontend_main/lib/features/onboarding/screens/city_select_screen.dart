import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/cities.dart';
import '../../../core/onboarding_args.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/user_role.dart';
import '../../../core/widgets/onboarding_progress.dart';

class CitySelectScreen extends StatefulWidget {
  const CitySelectScreen({super.key, required this.args});

  final OnboardingArgs args;

  @override
  State<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends State<CitySelectScreen> {
  String? _selected = 'Stuttgart';

  bool get _canContinue => _selected != null;

  void _continue() {
    if (!_canContinue) return;
    final next = widget.args.copyWith(city: _selected);

    if (widget.args.role == UserRole.business) {
      context.go(AppRoutes.businessHome, extra: next);
      return;
    }

    context.push(AppRoutes.interests, extra: next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OnboardingProgress(step: 1),
              const SizedBox(height: 24),
              Text(
                'Where are you walking?',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A0A0A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a city to see nearby stops and strolls.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: StrollingColors.mutedAlt,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: kCities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final city = kCities[index];
                    final selected = _selected == city.name;
                    return _CityTile(
                      city: city,
                      selected: selected,
                      onTap: () => setState(() => _selected = city.name),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _canContinue ? 1 : 0.45,
                duration: const Duration(milliseconds: 160),
                child: Material(
                  color: StrollingColors.primaryDeep,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _canContinue ? _continue : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: StrollingColors.primaryDeep
                                .withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.args.role == UserRole.business
                            ? 'Continue'
                            : 'Next',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.role);
                  }
                },
                child: Text(
                  '← Back',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: StrollingColors.mutedAlt,
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

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final CityOption city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? StrollingColors.primaryDeep.withValues(alpha: 0.08)
          : StrollingColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? StrollingColors.primaryDeep
                  : Colors.black.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StrollingColors.border),
                ),
                child: Text(city.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            city.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: StrollingColors.ink,
                            ),
                          ),
                        ),
                        if (city.live) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: StrollingColors.primaryDeep,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Live',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      city.region,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: StrollingColors.mutedAlt,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? StrollingColors.primaryDeep
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? StrollingColors.primaryDeep
                        : Colors.black.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
