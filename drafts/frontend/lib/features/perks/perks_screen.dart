import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/seed.dart';
import '../../core/state.dart';
import '../../core/theme.dart';

/// The perk wallet: pending → approved (QR ready) → redeemed.
class PerksScreen extends ConsumerWidget {
  const PerksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perks = ref.watch(perksProvider).reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Perks', style: titleStyle(size: 24)),
      ),
      body: perks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.gift,
                      size: 52, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('No perks yet', style: titleStyle(size: 22)),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Post from a perk stop on your stroll and the reward '
                      'lands here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: perks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _PerkCard(perk: perks[i]),
            ),
    );
  }
}

class _PerkCard extends ConsumerWidget {
  final Perk perk;
  const _PerkCard({required this.perk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = businessById(perk.businessId);
    final approved = perk.status == PerkStatus.approved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: approved
              ? AppColors.green.withValues(alpha: 0.6)
              : AppColors.border,
          width: approved ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: b.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(b.category.icon,
                    size: 22, color: b.category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.perkTitle ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(b.name,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: perk.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  perk.status.label,
                  style: TextStyle(
                    color: perk.status.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          if (approved) ...[
            const SizedBox(height: 14),
            // QR placeholder — show at the counter.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CustomPaint(
                    size: const Size(74, 74),
                    painter: _QrPainter(seed: b.id.hashCode),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Show this at the counter',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => ref
                              .read(perksProvider.notifier)
                              .redeem(perk.businessId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: const Text(
                              'Mark redeemed',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A deterministic fake QR — enough to sell the wallet moment in the demo.
class _QrPainter extends CustomPainter {
  final int seed;
  _QrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink;
    const n = 9;
    final cell = size.width / n;
    var rng = seed;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        rng = (rng * 1103515245 + 12345) & 0x7fffffff;
        final corner = (x < 3 && y < 3) ||
            (x > n - 4 && y < 3) ||
            (x < 3 && y > n - 4);
        if (corner || rng % 5 < 2) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}
