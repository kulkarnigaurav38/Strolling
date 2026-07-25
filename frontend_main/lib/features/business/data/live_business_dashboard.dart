import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import 'sample_business_dashboard.dart';

/// Live business-portal data from GET /api/business/:id/{stats,offers,creators,posts}
/// mapped into the same models the panels already render.
///
/// Fetch-all-or-nothing: if any request fails we return null and the screen keeps
/// the sample data, so the dashboard never renders half-empty on stage.
class LiveBusinessDashboard {
  const LiveBusinessDashboard({
    required this.stats,
    required this.offers,
    required this.creators,
    required this.posts,
    required this.redemptions,
  });

  final List<BusinessStat> stats;
  final List<BusinessOffer> offers;
  final List<BusinessCreator> creators;
  final List<BusinessPost> posts;
  final List<BusinessRedemption> redemptions;

  /// [businessId] is a business slug, or 'demo' for the seeded showcase which
  /// also surfaces activity from the hackathon venue stop.
  static Future<LiveBusinessDashboard?> fetch({
    String businessId = 'demo',
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (Config.mock) return null;
    final base = '${Config.apiBaseUrl}/api/business/$businessId';
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$base/stats')).timeout(timeout),
        http.get(Uri.parse('$base/offers')).timeout(timeout),
        http.get(Uri.parse('$base/creators')).timeout(timeout),
        http.get(Uri.parse('$base/posts')).timeout(timeout),
      ]);
      if (responses.any((r) => r.statusCode != 200)) return null;

      final stats = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final offers = (jsonDecode(responses[1].body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final creators = (jsonDecode(responses[2].body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final posts = (jsonDecode(responses[3].body) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      return LiveBusinessDashboard(
        stats: _mapStats(stats, offers.length),
        offers: offers.map(_mapOffer).toList(),
        creators: creators.map(_mapCreator).toList(),
        posts: posts.map(_mapPost).toList(),
        redemptions: creators
            .where((c) => c['status'] == 'posted')
            .map(_mapRedemption)
            .toList(),
      );
    } catch (_) {
      return null; // offline / API down → caller keeps sample data
    }
  }

  static List<BusinessStat> _mapStats(Map<String, dynamic> s, int offerCount) {
    final posts = (s['posts'] as num?)?.toInt() ?? 0;
    final reach = (s['totalReach'] as num?)?.toInt() ?? 0;
    final cost = (s['costEur'] as num?)?.toDouble() ?? 0;
    final perPost = posts > 0 ? cost / posts : 0;
    return [
      BusinessStat(
        value: '${(s['creatorsHosted'] as num?)?.toInt() ?? 0}',
        label: 'Creators hosted',
        trend: '$offerCount live offers',
        color: const ColorData(0xFF2B7FFF),
        background: const ColorData(0xFFEFF6FF),
      ),
      BusinessStat(
        value: '$posts',
        label: 'Posts live',
        trend: 'from this month',
        color: const ColorData(0xFF00BC7D),
        background: const ColorData(0xFFECFDF5),
      ),
      BusinessStat(
        value: _compact(reach),
        label: 'Total reach',
        trend: 'across all posts',
        color: const ColorData(0xFF8E51FF),
        background: const ColorData(0xFFF5F3FF),
      ),
      BusinessStat(
        value: '€${perPost.toStringAsFixed(2)}',
        label: 'Cost per post',
        trend: '€${cost.toStringAsFixed(0)} spent',
        color: const ColorData(0xFFFF4F2B),
        background: const ColorData(0x0DFF4F2B),
      ),
    ];
  }

  static BusinessOffer _mapOffer(Map<String, dynamic> o) {
    final total = (o['slotsTotal'] as num?)?.toInt() ?? 0;
    final left = (o['slotsRemaining'] as num?)?.toInt() ?? 0;
    return BusinessOffer(
      title: o['perkTitle'] as String? ?? 'Offer',
      kind: o['offerType'] == 'cash' ? OfferKind.cash : OfferKind.inKind,
      claimed: (total - left).clamp(0, total),
      left: left,
      // ⚠️ MOCK: eligibility counts need real audience data; derive a stand-in.
      eligible: (o['minFollowers'] as num?)?.toInt() == 0 ? 152 : 28,
      requires: o['deliverable'] as String? ?? '1 post',
    );
  }

  static BusinessCreator _mapCreator(Map<String, dynamic> c) {
    final status = c['status'] as String? ?? 'en_route';
    final eta = (c['etaMin'] as num?)?.toInt() ?? 0;
    return BusinessCreator(
      name: c['name'] as String? ?? 'Creator',
      handle: c['handle'] as String? ?? '@creator',
      followers: _compact((c['followers'] as num?)?.toInt() ?? 0),
      status: switch (status) {
        'posted' => CreatorStatus.posted,
        'arrived' => CreatorStatus.arrived,
        _ => CreatorStatus.eta,
      },
      statusLabel: switch (status) {
        'posted' => 'Posted',
        'arrived' => 'Arrived',
        'approved' => 'Approved',
        'redeemed' => 'Redeemed',
        _ => eta > 0 ? '$eta min away' : 'On the way',
      },
      avatarStart: const ColorData(0xFFFF8A4C),
      avatarEnd: const ColorData(0xFFFF4F2B),
    );
  }

  static BusinessPost _mapPost(Map<String, dynamic> p) {
    return BusinessPost(
      handle: p['creatorHandle'] as String? ?? '@creator',
      platform: switch (p['platform']) {
        'tiktok' => 'TikTok',
        'facebook' => 'Facebook',
        _ => 'Instagram',
      },
      views: _compact((p['reach'] as num?)?.toInt() ?? 0),
      likes: _compact((p['likes'] as num?)?.toInt() ?? 0),
      comments: '${(p['comments'] as num?)?.toInt() ?? 0}',
      thumbnailAsset: kBusinessPosts.isNotEmpty
          ? kBusinessPosts.first.thumbnailAsset
          : '',
    );
  }

  static BusinessRedemption _mapRedemption(Map<String, dynamic> c) {
    final handle = c['handle'] as String? ?? '@creator';
    return BusinessRedemption(
      id: handle,
      name: c['name'] as String? ?? 'Creator',
      detail: 'Posted · ${_compact((c['followers'] as num?)?.toInt() ?? 0)} followers',
      code: handle.replaceAll('@', '').toUpperCase().padRight(6, 'X').substring(0, 6),
    );
  }

  /// 17784 → '17.8K', 1200000 → '1.2M'
  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
