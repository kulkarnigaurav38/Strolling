import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

class CartPill extends StatelessWidget {
  const CartPill({
    super.key,
    required this.cart,
    required this.businesses,
    required this.onCreateStroll,
  });

  final List<int> cart;
  final List<MapBusiness> businesses;
  final VoidCallback onCreateStroll;

  @override
  Widget build(BuildContext context) {
    final ready = cart.length >= 2;
    final byId = {for (final b in businesses) b.id: b};

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [StrollingColors.primary, StrollingColors.primaryMid],
              ),
            ),
            alignment: Alignment.center,
            child: const Text('🧍', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: cart.isEmpty
                ? Text(
                    'Tap a pin to add a stop.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: StrollingColors.muted,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.length} stop${cart.length == 1 ? '' : 's'} added',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: StrollingColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                        children: cart.map((id) {
                          final b = byId[id];
                          if (b == null) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: b.perkColor.withValues(alpha: 0.15),
                              border: Border.all(color: b.perkColor, width: 2),
                            ),
                            child: Text(b.emoji,
                                style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          // Flexible so a narrow viewport shrinks the CTA instead of
          // overflowing the pill (was a 91px overflow at ~90px width).
          Flexible(
            child: Material(
            color: ready ? StrollingColors.primary : const Color(0xFFF2EFE8),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: ready ? onCreateStroll : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        ready ? 'Create stroll' : 'Add 2+ stops',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: ready ? Colors.white : StrollingColors.muted,
                        ),
                      ),
                    ),
                    if (ready) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 15, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
