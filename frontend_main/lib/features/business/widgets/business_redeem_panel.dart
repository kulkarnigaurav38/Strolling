import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../data/sample_business_dashboard.dart';

class BusinessRedeemPanel extends StatelessWidget {
  const BusinessRedeemPanel({
    super.key,
    required this.redemptions,
    required this.onApprove,
    required this.onDecline,
  });

  final List<BusinessRedemption> redemptions;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onDecline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'PENDING REDEMPTIONS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: StrollingColors.mutedAlt,
          ),
        ),
        const SizedBox(height: 12),
        if (redemptions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'All caught up — no pending redemptions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: StrollingColors.mutedAlt,
              ),
            ),
          )
        else
          ...redemptions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RedemptionCard(
                item: item,
                onApprove: () => onApprove(item.id),
                onDecline: () => onDecline(item.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({
    required this.item,
    required this.onApprove,
    required this.onDecline,
  });

  final BusinessRedemption item;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: StrollingColors.nearBlack,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      item.detail,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: StrollingColors.mutedAlt,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: StrollingColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item.code,
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontFamilyFallback: ['Courier', 'monospace'],
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: StrollingColors.nearBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Approve',
                  background: StrollingColors.success,
                  foreground: Colors.white,
                  iconAsset: 'assets/images/business/check_icon.svg',
                  onTap: onApprove,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Decline',
                  background: StrollingColors.surfaceMuted,
                  foreground: StrollingColors.mutedAlt,
                  iconAsset: 'assets/images/business/close_icon.svg',
                  onTap: onDecline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 13,
                height: 13,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
