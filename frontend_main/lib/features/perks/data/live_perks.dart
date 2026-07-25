import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../../../core/models/map_business.dart';
import '../../map/data/sample_businesses.dart';
import 'sample_perks.dart';

/// Live wallet from GET /api/me/perks, mapped into the CreatorPerk model the
/// perks screen already renders.
///
/// Returns null when the API is unreachable so the caller can fall back to the
/// sample wallet — the screen never renders empty because of a network blip.
/// An empty list IS returned when the user genuinely has no perks yet.
class LivePerks {
  static const _accents = <Color>[
    Color(0xFFF5A623),
    Color(0xFF2DCE89),
    Color(0xFF6C63FF),
    Color(0xFFFF4F2B),
  ];

  static const _giftAssets = <String>[
    'assets/images/perks/gift_orange.svg',
    'assets/images/perks/gift_green.svg',
    'assets/images/perks/gift_purple.svg',
    'assets/images/perks/gift_primary.svg',
  ];

  static Future<List<CreatorPerk>?> fetch({
    String userId = 'demo-user',
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (Config.mock) return null;
    try {
      final res = await http
          .get(Uri.parse('${Config.apiBaseUrl}/api/me/perks?userId=$userId'))
          .timeout(timeout);
      if (res.statusCode != 200) return null;
      final rows = (jsonDecode(res.body) as List<dynamic>).cast<Map<String, dynamic>>();
      return [
        for (var i = 0; i < rows.length; i++) _map(rows[i], i),
      ];
    } catch (_) {
      return null;
    }
  }

  static CreatorPerk _map(Map<String, dynamic> claim, int index) {
    final businessId = claim['businessId'] as String? ?? '';
    final business = _businessFor(businessId);
    final status = claim['status'] as String? ?? 'pending';
    return CreatorPerk(
      id: claim['id'] as String? ?? '$index',
      businessName: business?.name ?? _titleize(businessId),
      perkLabel: business?.perk ?? 'Perk',
      valueLabel: business?.perkVal ?? '€0',
      accent: _accents[index % _accents.length],
      status: switch (status) {
        'redeemed' => PerkStatus.redeemed,
        'approved' => PerkStatus.ready,
        _ => PerkStatus.pending,
      },
      giftAsset: _giftAssets[index % _giftAssets.length],
      footerLabel: switch (status) {
        'redeemed' => 'Redeemed',
        'approved' => null, // ready → the screen shows the QR area instead
        'posted' => 'Verifying your post…',
        'arrived' => 'You\'re here — capture and post',
        'en_route' => 'On the way',
        _ => 'Waiting for the business',
      },
    );
  }

  /// API business ids are slugs; the map data carries the matching apiId.
  static MapBusiness? _businessFor(String apiId) {
    for (final b in kSampleBusinesses) {
      if (b.apiId == apiId) return b;
    }
    return null;
  }

  static String _titleize(String slug) => slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
