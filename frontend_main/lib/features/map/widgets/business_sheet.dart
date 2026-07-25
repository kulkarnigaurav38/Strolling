import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

class BusinessSheet extends StatelessWidget {
  const BusinessSheet({
    super.key,
    required this.business,
    required this.inCart,
    required this.onAdd,
    required this.onRemove,
    required this.onClose,
  });

  final MapBusiness business;
  final bool inCart;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onClose;

  ImageProvider _image() {
    if (business.imageUrl.startsWith('asset:')) {
      return AssetImage(business.imageUrl.substring(6));
    }
    return NetworkImage(business.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: StrollingColors.ink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          image: _image(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFE9E3D6),
                            alignment: Alignment.center,
                            child: Text(business.emoji,
                                style: const TextStyle(fontSize: 40)),
                          ),
                        ),
                        if (business.hasPerk && business.perk != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: business.perkColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.card_giftcard,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    business.perk!,
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                              Text(
                                business.name,
                                style: GoogleFonts.fraunces(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: StrollingColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2EFE8),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      business.category,
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: StrollingColors.mutedAlt,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    business.distance,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: StrollingColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (business.hasPerk && business.perk != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: business.perkColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.perk!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${business.perkVal} value',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      business.desc,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        height: 1.5,
                        color: StrollingColors.ink.withValues(alpha: 0.72),
                      ),
                    ),
                    if (business.hasPerk && business.required != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.bolt,
                              size: 14, color: business.perkColor),
                          const SizedBox(width: 6),
                          Text(
                            'Requires: ${business.required}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: StrollingColors.mutedAlt,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: inCart ? onRemove : onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: inCart
                              ? const Color(0xFFF2EFE8)
                              : StrollingColors.primary,
                          foregroundColor:
                              inCart ? StrollingColors.muted : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          inCart ? '✓ Added to stroll' : '+ Add to stroll',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
