import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

class ModeSwitchCard extends StatelessWidget {
  const ModeSwitchCard({
    super.key,
    required this.mode,
    required this.onSwitch,
  });

  final MapMode mode;
  final ValueChanged<MapMode> onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StrollingColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ModeOption(
                selected: mode == MapMode.explore,
                selectedColor: StrollingColors.ink,
                icon: Icons.explore_outlined,
                title: 'Roam the city',
                subtitle: 'Every place, no obligations',
                onTap: () => onSwitch(MapMode.explore),
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: StrollingColors.border,
            ),
            Expanded(
              child: _ModeOption(
                selected: mode == MapMode.earn,
                selectedColor: StrollingColors.primary,
                icon: Icons.card_giftcard_rounded,
                title: 'Earn incentives',
                subtitle: 'Perks for posting',
                onTap: () => onSwitch(MapMode.earn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.selected,
    required this.selectedColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final Color selectedColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : const Color(0xFF888699);
    final sub = selected
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFFC0BBCC);

    return Material(
      color: selected ? selectedColor : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : const Color(0xFFB0ACBC)),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: fg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  height: 1.3,
                  color: sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
