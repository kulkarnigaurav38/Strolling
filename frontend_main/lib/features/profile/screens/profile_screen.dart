import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../data/sample_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.persona,
    this.onLogout,
  });

  final CreatorPersona persona;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StrollingColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _Header(persona: persona),
            const SizedBox(height: 16),
            _SocialRow(socials: persona.socials),
            const SizedBox(height: 20),
            _StatsRow(stats: persona.stats),
            const SizedBox(height: 24),
            Text(
              'My strolls',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: StrollingColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ...persona.strolls.map(
              (stroll) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StrollCard(stroll: stroll),
              ),
            ),
            if (onLogout != null) ...[
              const SizedBox(height: 12),
              _LogoutButton(onTap: onLogout!),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: StrollingColors.ink.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: StrollingColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Log out',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: StrollingColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.persona});

  final CreatorPersona persona;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                StrollingColors.primary,
                StrollingColors.primaryMid,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: StrollingColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            persona.avatarEmoji,
            style: const TextStyle(fontSize: 30, height: 1.2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                persona.displayName,
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  color: StrollingColors.ink,
                ),
              ),
              Text(
                persona.locationLine,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: StrollingColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.socials});

  final List<ProfileSocial> socials;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          for (final social in socials) ...[
            Expanded(child: _SocialCard(social: social)),
            const SizedBox(width: 8),
          ],
          const _AddSocialButton(),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.social});

  final ProfileSocial social;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StrollingColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Text(
            social.glyph,
            style: TextStyle(
              fontSize: social.glyph == 'f' ? 18 : 17.5,
              fontWeight:
                  social.glyph == 'f' ? FontWeight.w800 : FontWeight.w400,
              color: social.glyphColor != null
                  ? Color(social.glyphColor!)
                  : StrollingColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  social.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: StrollingColors.ink,
                  ),
                ),
                Text(
                  social.followersLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: StrollingColors.muted,
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

class _AddSocialButton extends StatelessWidget {
  const _AddSocialButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 58,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: StrollingColors.ink.withValues(alpha: 0.15),
          radius: 20,
          strokeWidth: 1.3,
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset(
              'assets/images/profile/plus_icon.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _StatCard(stat: stats[i])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StrollingColors.ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset(stat.iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: GoogleFonts.fraunces(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              height: 1.5,
              color: StrollingColors.ink,
            ),
          ),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 9.5,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: StrollingColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrollCard extends StatelessWidget {
  const _StrollCard({required this.stroll});

  final ProfileStroll stroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StrollingColors.ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 56,
              height: 56,
              child: stroll.thumbAsset != null
                  ? Image.asset(
                      stroll.thumbAsset!,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: StrollingColors.surfaceMuted,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stroll.city,
                  style: GoogleFonts.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: StrollingColors.ink,
                  ),
                ),
                Text(
                  stroll.meta,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: StrollingColors.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 16,
            height: 16,
            child: SvgPicture.asset(
              'assets/images/profile/chevron_icon.svg',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
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

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
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
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
