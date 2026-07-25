import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../data/live_perks.dart';
import '../data/sample_perks.dart';

/// Loads the wallet from GET /api/me/perks once, then renders it. Pass [perks]
/// explicitly to bypass the network (tests / previews). If the API is
/// unreachable we fall back to the sample wallet so the screen is never blank.
class MyPerksScreen extends StatefulWidget {
  const MyPerksScreen({super.key, this.perks});

  final List<CreatorPerk>? perks;

  @override
  State<MyPerksScreen> createState() => _MyPerksScreenState();
}

class _MyPerksScreenState extends State<MyPerksScreen> {
  late Future<List<CreatorPerk>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.perks != null
        ? Future.value(widget.perks!)
        : LivePerks.fetch().then((live) => live ?? kSamplePerks);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CreatorPerk>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const ColoredBox(
            color: StrollingColors.background,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _PerksView(perks: snap.data!);
      },
    );
  }
}

class _PerksView extends StatelessWidget {
  const _PerksView({required this.perks});

  final List<CreatorPerk> perks;

  int get _totalValueEuros {
    var sum = 0;
    for (final p in perks) {
      final digits = p.valueLabel.replaceAll(RegExp(r'[^0-9]'), '');
      sum += int.tryParse(digits) ?? 0;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StrollingColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My perks',
                    style: GoogleFonts.fraunces(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      letterSpacing: -0.58,
                      color: StrollingColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${perks.length} perks · €$_totalValueEuros total value',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: StrollingColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: perks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _PerkCard(perk: perks[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  const _PerkCard({required this.perk});

  final CreatorPerk perk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StrollingColors.ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perk.businessName,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: StrollingColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: SvgPicture.asset(
                            perk.giftAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            perk.perkLabel,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              color: perk.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    perk.valueLabel,
                    style: GoogleFonts.fraunces(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: perk.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: perk.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          switch (perk.status) {
            PerkStatus.redeemed => _FooterPill(
                background: const Color(0xFF2DCE89).withValues(alpha: 0.06),
                iconAsset: 'assets/images/perks/check.svg',
                label: perk.footerLabel ?? 'Redeemed',
                labelColor: const Color(0xFF2DCE89),
              ),
            PerkStatus.pending => _FooterPill(
                background: const Color(0xFFFFF4E6),
                borderColor: const Color(0xFFFDEBD0),
                iconAsset: 'assets/images/perks/clock.svg',
                label: perk.footerLabel ?? 'Pending',
                labelColor: const Color(0xFFE67E22),
              ),
            PerkStatus.ready => const _ReadyQrArea(),
          },
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PerkStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      PerkStatus.redeemed => (
          'Redeemed',
          const Color(0xFF2DCE89),
          const Color(0xFF2DCE89).withValues(alpha: 0.08),
        ),
      PerkStatus.ready => (
          'Ready to use',
          StrollingColors.primary,
          StrollingColors.primary.withValues(alpha: 0.08),
        ),
      PerkStatus.pending => (
          'Pending',
          const Color(0xFFF5A623),
          const Color(0xFFF5A623).withValues(alpha: 0.08),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.5,
          color: fg,
        ),
      ),
    );
  }
}

class _FooterPill extends StatelessWidget {
  const _FooterPill({
    required this.background,
    required this.iconAsset,
    required this.label,
    required this.labelColor,
    this.borderColor,
  });

  final Color background;
  final String iconAsset;
  final String label;
  final Color labelColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: borderColor != null ? 12.65 : 12,
        vertical: borderColor != null ? 8.65 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: SvgPicture.asset(iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyQrArea extends StatelessWidget {
  const _ReadyQrArea();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: const Color(0xFF2DCE89).withValues(alpha: 0.25),
          fillColor: const Color(0xFF2DCE89).withValues(alpha: 0.03),
          radius: 20,
          strokeWidth: 2,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 28,
                color: StrollingColors.ink.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 2),
              Text(
                'Show this at the venue',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: const Color(0xFF2DCE89),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.fillColor,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final Color fillColor;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), stroke);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
