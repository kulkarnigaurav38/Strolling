import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../data/sample_business_dashboard.dart';

class BusinessOffersPanel extends StatelessWidget {
  const BusinessOffersPanel({
    super.key,
    required this.offers,
    required this.onAddOffer,
  });

  final List<BusinessOffer> offers;
  final VoidCallback onAddOffer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'ACTIVE OFFERS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.55,
            color: StrollingColors.mutedAlt,
          ),
        ),
        const SizedBox(height: 12),
        ...offers.map(
          (offer) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OfferCard(offer: offer),
          ),
        ),
        _AddOfferButton(onTap: onAddOffer),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final BusinessOffer offer;

  @override
  Widget build(BuildContext context) {
    final isCash = offer.kind == OfferKind.cash;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  offer.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: StrollingColors.nearBlack,
                    height: 1.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCash
                      ? StrollingColors.successBg
                      : StrollingColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCash ? 'cash' : 'in-kind',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isCash
                        ? StrollingColors.successDeep
                        : StrollingColors.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: offer.progress,
              minHeight: 6,
              backgroundColor: StrollingColors.surfaceMuted,
              color: StrollingColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${offer.claimed} claimed · ${offer.left} left',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: StrollingColors.mutedAlt,
                ),
              ),
              Text(
                '${offer.eligible} eligible',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: StrollingColors.mutedAlt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            offer.requires,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: StrollingColors.mutedAlt,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOfferButton extends StatelessWidget {
  const _AddOfferButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: const Color(0x1A000000),
            radius: 16,
            strokeWidth: 2,
          ),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/business/plus_icon.svg',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add new offer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: StrollingColors.mutedAlt,
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

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
