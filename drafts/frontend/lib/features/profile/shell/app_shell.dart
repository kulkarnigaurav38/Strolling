import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state.dart';
import '../../core/theme.dart';

/// Bottom nav: Map | My Stroll | Perks | Profile — with the notification dot
/// on Perks when a reward is ready to redeem.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perkReady = ref.watch(perkReadyProvider);

    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _item(context, 0, Icons.map_outlined, Icons.map, 'Map'),
                _item(context, 1, Icons.explore_outlined, Icons.explore,
                    'My stroll'),
                _item(context, 2, Icons.card_giftcard_outlined,
                    Icons.card_giftcard, 'Perks',
                    dot: perkReady),
                _item(context, 3, Icons.person_outline, Icons.person,
                    'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon,
      IconData activeIcon, String label,
      {bool dot = false}) {
    final active = shell.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => shell.goBranch(index,
            initialLocation: index == shell.currentIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? AppColors.coral : AppColors.muted,
                  size: 24,
                ),
                if (dot)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppColors.coral : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
