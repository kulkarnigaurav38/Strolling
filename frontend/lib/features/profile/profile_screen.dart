import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider) ?? 'guest';
    final perks = ref.watch(perksProvider);
    final stroll = ref.watch(strollProvider);

    final earned = perks
        .where((p) => p.status != PerkStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: titleStyle(size: 24))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connected account
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: AppColors.sunset,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stuttgart Stroller',
                          style: titleStyle(size: 19)),
                      Text(
                        auth == 'guest'
                            ? 'Browsing without an account'
                            : 'Connected with ${auth[0].toUpperCase()}${auth.substring(1)}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).signOut(),
                  child: const Text('Sign out',
                      style: TextStyle(color: AppColors.coral)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Stat grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: [
              _stat(Icons.directions_walk_rounded,
                  stroll.active ? '1' : '0', 'active strolls'),
              _stat(CupertinoIcons.film, stroll.completedCount.toString(),
                  'scenes posted'),
              _stat(CupertinoIcons.gift, '$earned', 'perks earned'),
              _stat(CupertinoIcons.star_fill,
                  (4.2 + earned * 0.1).toStringAsFixed(1), 'stroller score'),
            ],
          ),
          const SizedBox(height: 18),
          Text('History', style: titleStyle(size: 19)),
          const SizedBox(height: 8),
          if (!stroll.active && perks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Finished strolls will appear here.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.film,
                      size: 22, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stroll.active
                          ? 'Stuttgart Mitte — in progress '
                              '(${stroll.completedCount}/${stroll.stopIds.length} scenes)'
                          : 'Stuttgart Mitte — done',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.coral),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}
