import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/onboarding_args.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/onboarding_progress.dart';

const _interests = [
  '☕ Coffee',
  '🍝 Food',
  '🍻 Nightlife',
  '🎨 Culture',
  '🌿 Outdoors',
  '🛍 Shopping',
  '🎵 Music',
  '🏛 History',
  '🧁 Bakeries',
  '🍷 Wine bars',
  '🍺 Breweries',
  '🍦 Sweet treats',
  '📸 Photo spots',
  '🖼 Galleries',
  '🎭 Theatre',
  '📚 Bookshops',
  '🌳 Parks',
  '⛰ Viewpoints',
  '🏞 Nature walks',
  '🛤 Hidden alleys',
  '🕌 Architecture',
  '🎪 Markets',
  '💎 Vintage',
  '🧘 Wellness',
  '🎞 Cinema',
  '🏀 Sports',
  '🐶 Pet-friendly',
  '🌙 Night views',
  '🌅 Sunrise spots',
  '👨‍🍳 Street food',
];

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key, required this.args});

  final OnboardingArgs args;

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selected = {'☕ Coffee', '🍝 Food'};

  bool get _canContinue => _selected.isNotEmpty;

  void _toggle(String interest) {
    setState(() {
      if (_selected.contains(interest)) {
        _selected.remove(interest);
      } else {
        _selected.add(interest);
      }
    });
  }

  void _start() {
    if (!_canContinue) return;
    final next = widget.args.copyWith(interests: _selected.toList());
    context.go(AppRoutes.creatorHome, extra: next);
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
              const OnboardingProgress(step: 2),
              const SizedBox(height: 24),
              Text(
                'What do you love?',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A0A0A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.args.city == null
                    ? 'We use this to show you the best stops on every stroll.'
                    : 'Best stops in ${widget.args.city} for every stroll.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: StrollingColors.mutedAlt,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _interests.map((interest) {
                      final selected = _selected.contains(interest);
                      return GestureDetector(
                        onTap: () => _toggle(interest),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? StrollingColors.primaryDeep
                                : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            interest,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _canContinue ? 1 : 0.45,
                duration: const Duration(milliseconds: 160),
                child: Material(
                  color: StrollingColors.primaryDeep,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    onTap: _canContinue ? _start : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 54,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/sparkle_icon.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start strolling!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
