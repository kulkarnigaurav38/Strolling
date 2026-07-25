import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';

enum MapTab { explore, stroll, perks, profile }

class MapBottomNav extends StatelessWidget {
  const MapBottomNav({
    super.key,
    required this.active,
    required this.onSelect,
    this.showPerksDot = true,
  });

  final MapTab active;
  final ValueChanged<MapTab> onSelect;
  final bool showPerksDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: StrollingColors.ink.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              _NavItem(
                label: 'Explore',
                icon: Icons.map_outlined,
                selected: active == MapTab.explore,
                onTap: () => onSelect(MapTab.explore),
              ),
              _NavItem(
                label: 'My stroll',
                icon: Icons.explore_outlined,
                selected: active == MapTab.stroll,
                onTap: () => onSelect(MapTab.stroll),
              ),
              _NavItem(
                label: 'Perks',
                icon: Icons.card_giftcard_rounded,
                selected: active == MapTab.perks,
                onTap: () => onSelect(MapTab.perks),
                showDot: showPerksDot,
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                selected: active == MapTab.profile,
                onTap: () => onSelect(MapTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? StrollingColors.primary : const Color(0xFF9E9AA8);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (showDot)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: StrollingColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
