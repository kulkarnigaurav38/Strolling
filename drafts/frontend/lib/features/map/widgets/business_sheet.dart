import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models.dart';
import '../../../core/state.dart';
import '../../../core/theme.dart';

/// Slide-up sheet on pin tap: cover art, perk badge, meta, deliverable,
/// "Add to stroll" / "Added". Cover art is a gradient + category icon.
Future<void> showBusinessSheet(BuildContext context, Business b) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BusinessSheet(business: b),
  );
}

class BusinessSheet extends ConsumerWidget {
  final Business business;
  const BusinessSheet({super.key, required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = business;
    final inCart = ref.watch(cartProvider).contains(b.id);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        b.category.color.withValues(alpha: 0.85),
                        b.category.color.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: Center(
                    child:
                        Icon(b.category.icon, size: 64, color: Colors.white),
                  ),
                ),
              ),
              if (b.hasPerk)
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.card_giftcard,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          b.perkTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                top: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: titleStyle(size: 26)),
                          const SizedBox(height: 4),
                          Text(
                            '${b.category.label}  ·  ${b.walkMinutes} min walk'
                            '  ·  ★ ${b.rating}',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (b.hasPerk)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '€${b.perkValue}',
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text('perk value',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(b.description,
                    style: const TextStyle(fontSize: 15, height: 1.45)),
                if (b.deliverable != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt,
                            color: AppColors.amber, size: 18),
                        const SizedBox(width: 8),
                        const Text('Deliver:  ',
                            style: TextStyle(color: AppColors.muted)),
                        Expanded(
                          child: Text(
                            b.deliverable!,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).toggle(b.id);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 56,
                          decoration: BoxDecoration(
                            color:
                                inCart ? AppColors.green : AppColors.coral,
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                            boxShadow: [
                              BoxShadow(
                                color: (inCart
                                        ? AppColors.green
                                        : AppColors.coral)
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(inCart ? Icons.check : Icons.add,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                inCart ? 'Added' : 'Add to stroll',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Center(
                        child: Text('More',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
