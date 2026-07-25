import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../data/sample_business_dashboard.dart';

class BusinessCreatorsPanel extends StatelessWidget {
  const BusinessCreatorsPanel({super.key, required this.creators});

  final List<BusinessCreator> creators;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'CREATOR ACTIVITY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: StrollingColors.mutedAlt,
          ),
        ),
        const SizedBox(height: 12),
        ...creators.map(
          (creator) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CreatorCard(creator: creator),
          ),
        ),
      ],
    );
  }
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.creator});

  final BusinessCreator creator;

  (Color bg, Color text) get _badgeColors => switch (creator.status) {
        CreatorStatus.eta => (
            StrollingColors.warningBg,
            StrollingColors.warningText,
          ),
        CreatorStatus.arrived => (
            StrollingColors.infoBg,
            StrollingColors.infoText,
          ),
        CreatorStatus.posted => (
            StrollingColors.successBg,
            StrollingColors.successDeep,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeText) = _badgeColors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(creator.avatarStart.value),
                  Color(creator.avatarEnd.value),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
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
                        creator.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: StrollingColors.nearBlack,
                          height: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' · ${creator.followers}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: StrollingColors.mutedAlt,
                      ),
                    ),
                  ],
                ),
                Text(
                  creator.handle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: StrollingColors.mutedAlt,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              creator.statusLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
