import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/onboarding_args.dart';
import '../../../core/router.dart';
import '../../../core/theme.dart';
import '../data/sample_business_dashboard.dart';
import '../widgets/business_creators_panel.dart';
import '../widgets/business_offers_panel.dart';
import '../widgets/business_posts_panel.dart';
import '../widgets/business_redeem_panel.dart';
import '../widgets/business_stats_grid.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key, required this.args});

  final OnboardingArgs args;

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  BusinessTab _tab = BusinessTab.offers;
  late List<BusinessRedemption> _redemptions;

  @override
  void initState() {
    super.initState();
    _redemptions = List.of(kBusinessRedemptions);
  }

  void _setTab(BusinessTab tab) => setState(() => _tab = tab);

  void _approve(String id) {
    setState(() => _redemptions.removeWhere((r) => r.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redemption approved',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: StrollingColors.success,
      ),
    );
  }

  void _decline(String id) {
    setState(() => _redemptions.removeWhere((r) => r.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redemption declined',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: StrollingColors.mutedAlt,
      ),
    );
  }

  void _onAddOffer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Offer builder coming soon',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BusinessHeader(
              onProfileTap: () => context.go(AppRoutes.role),
            ),
            _BusinessTabs(selected: _tab, onSelect: _setTab),
            const Divider(height: 1, thickness: 1, color: Color(0x1A000000)),
            const BusinessStatsGrid(stats: kBusinessStats),
            Expanded(
              child: switch (_tab) {
                BusinessTab.offers => BusinessOffersPanel(
                    offers: kBusinessOffers,
                    onAddOffer: _onAddOffer,
                  ),
                BusinessTab.creators => const BusinessCreatorsPanel(
                    creators: kBusinessCreators,
                  ),
                BusinessTab.posts => const BusinessPostsPanel(
                    posts: kBusinessPosts,
                  ),
                BusinessTab.redeem => BusinessRedeemPanel(
                    redemptions: _redemptions,
                    onApprove: _approve,
                    onDecline: _decline,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STROLLING FOR BUSINESS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: StrollingColors.primaryDeep,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kBusinessName,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: StrollingColors.nearBlack,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: StrollingColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/business/bell_icon.svg',
              width: 17,
              height: 17,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E51FF), Color(0xFF4F39F6)],
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
          ),
        ],
      ),
    );
  }
}

class _BusinessTabs extends StatelessWidget {
  const _BusinessTabs({
    required this.selected,
    required this.onSelect,
  });

  final BusinessTab selected;
  final ValueChanged<BusinessTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: BusinessTab.values.map((tab) {
          final active = tab == selected;
          final label = switch (tab) {
            BusinessTab.offers => 'Offers',
            BusinessTab.creators => 'Creators',
            BusinessTab.posts => 'Posts',
            BusinessTab.redeem => 'Redeem',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      active ? StrollingColors.primaryDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : StrollingColors.mutedAlt,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
