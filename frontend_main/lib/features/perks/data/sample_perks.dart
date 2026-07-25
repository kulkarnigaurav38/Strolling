import 'package:flutter/material.dart';

import '../../../core/theme.dart';

enum PerkStatus { redeemed, ready, pending }

class CreatorPerk {
  const CreatorPerk({
    required this.id,
    required this.businessName,
    required this.perkLabel,
    required this.valueLabel,
    required this.accent,
    required this.status,
    required this.giftAsset,
    this.footerLabel,
  });

  final String id;
  final String businessName;
  final String perkLabel;
  final String valueLabel;
  final Color accent;
  final PerkStatus status;
  final String giftAsset;
  final String? footerLabel;
}

const kSamplePerks = [
  CreatorPerk(
    id: '1',
    businessName: 'Brot & Rösterei',
    perkLabel: '2 free coffees',
    valueLabel: '€7',
    accent: Color(0xFFF5A623),
    status: PerkStatus.redeemed,
    giftAsset: 'assets/images/perks/gift_orange.svg',
    footerLabel: 'Redeemed · Today',
  ),
  CreatorPerk(
    id: '2',
    businessName: 'Markthalle',
    perkLabel: '€15 voucher',
    valueLabel: '€15',
    accent: Color(0xFF2DCE89),
    status: PerkStatus.ready,
    giftAsset: 'assets/images/perks/gift_green.svg',
  ),
  CreatorPerk(
    id: '3',
    businessName: 'Brauhaus am Eck',
    perkLabel: '3 craft beers',
    valueLabel: '€14',
    accent: Color(0xFF6C63FF),
    status: PerkStatus.pending,
    giftAsset: 'assets/images/perks/gift_purple.svg',
    footerLabel: 'Verifying your post…',
  ),
  CreatorPerk(
    id: '4',
    businessName: 'Weinstube Fröhlich',
    perkLabel: 'Free lunch',
    valueLabel: '€18',
    accent: StrollingColors.primary,
    status: PerkStatus.redeemed,
    giftAsset: 'assets/images/perks/gift_primary.svg',
    footerLabel: 'Redeemed · 12 Jul',
  ),
];
