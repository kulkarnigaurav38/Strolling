import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/copy.dart';
import '../../../core/models.dart';
import '../../../core/state.dart';
import '../../../core/theme.dart';

/// Full-width two-mode card (v5): "Roam the city" vs "Earn incentives" with a
/// sliding highlight. The dark ink panel marks the active side.
class ModeSwitchCard extends ConsumerWidget {
  const ModeSwitchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: mode == StrollMode.roam ? 0 : half,
                top: 0,
                bottom: 0,
                width: half,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
              ),
              Row(
                children: [
                  _half(ref, StrollMode.roam, Icons.explore_outlined,
                      Copy.roamTitle, Copy.roamSub, mode),
                  _half(ref, StrollMode.earn, Icons.card_giftcard,
                      Copy.earnTitle, Copy.earnSub, mode),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _half(WidgetRef ref, StrollMode value, IconData icon, String title,
      String sub, StrollMode current) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(modeProvider.notifier).state = value,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20, color: active ? Colors.white : AppColors.muted),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.text,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  color: active
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
