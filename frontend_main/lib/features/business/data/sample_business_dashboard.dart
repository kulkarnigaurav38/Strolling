enum BusinessTab { offers, creators, posts, redeem }

enum OfferKind { inKind, cash }

enum CreatorStatus { eta, arrived, posted }

class BusinessStat {
  const BusinessStat({
    required this.value,
    required this.label,
    required this.trend,
    required this.color,
    required this.background,
  });

  final String value;
  final String label;
  final String trend;
  final ColorData color;
  final ColorData background;
}

/// Tiny color holder so sample data stays free of Flutter imports.
class ColorData {
  const ColorData(this.value);
  final int value;
}

class BusinessOffer {
  const BusinessOffer({
    required this.title,
    required this.kind,
    required this.claimed,
    required this.left,
    required this.eligible,
    required this.requires,
  });

  final String title;
  final OfferKind kind;
  final int claimed;
  final int left;
  final int eligible;
  final String requires;

  double get progress {
    final total = claimed + left;
    if (total <= 0) return 0;
    return claimed / total;
  }
}

class BusinessCreator {
  const BusinessCreator({
    required this.name,
    required this.handle,
    required this.followers,
    required this.status,
    required this.statusLabel,
    required this.avatarStart,
    required this.avatarEnd,
  });

  final String name;
  final String handle;
  final String followers;
  final CreatorStatus status;
  final String statusLabel;
  final ColorData avatarStart;
  final ColorData avatarEnd;
}

class BusinessPost {
  const BusinessPost({
    required this.handle,
    required this.platform,
    required this.views,
    required this.likes,
    required this.comments,
    required this.thumbnailAsset,
  });

  final String handle;
  final String platform;
  final String views;
  final String likes;
  final String comments;
  final String thumbnailAsset;
}

class BusinessRedemption {
  const BusinessRedemption({
    required this.id,
    required this.name,
    required this.detail,
    required this.code,
  });

  final String id;
  final String name;
  final String detail;
  final String code;
}

const kBusinessName = 'Bar Soleil';

const kBusinessStats = [
  BusinessStat(
    value: '24',
    label: 'Creators this month',
    trend: '+6 this week',
    color: ColorData(0xFF2B7FFF),
    background: ColorData(0xFFEFF6FF),
  ),
  BusinessStat(
    value: '18',
    label: 'Posts live',
    trend: '+3 this week',
    color: ColorData(0xFF00BC7D),
    background: ColorData(0xFFECFDF5),
  ),
  BusinessStat(
    value: '142K',
    label: 'Total reach',
    trend: '+28K this week',
    color: ColorData(0xFF8E51FF),
    background: ColorData(0xFFF5F3FF),
  ),
  BusinessStat(
    value: '€8.30',
    label: 'Cost per post',
    trend: '−€1.2 this week',
    color: ColorData(0xFFFF4F2B),
    background: ColorData(0x0DFF4F2B),
  ),
];

const kBusinessOffers = [
  BusinessOffer(
    title: '3 free craft beers',
    kind: OfferKind.inKind,
    claimed: 12,
    left: 8,
    eligible: 152,
    requires: 'Requires: 1 story + tag',
  ),
  BusinessOffer(
    title: '€25 cash payment',
    kind: OfferKind.cash,
    claimed: 2,
    left: 3,
    eligible: 28,
    requires: 'Requires: 1 post + 1 reel · 10K min',
  ),
];

const kBusinessCreators = [
  BusinessCreator(
    name: 'Sophie M.',
    handle: '@sophie.explores',
    followers: '8.5K',
    status: CreatorStatus.eta,
    statusLabel: '12 min',
    avatarStart: ColorData(0xFFFF8904),
    avatarEnd: ColorData(0xFFF6339A),
  ),
  BusinessCreator(
    name: 'Lukas K.',
    handle: '@lukasinthewild',
    followers: '22K',
    status: CreatorStatus.arrived,
    statusLabel: 'arrived',
    avatarStart: ColorData(0xFF00D5BE),
    avatarEnd: ColorData(0xFF00B8DB),
  ),
  BusinessCreator(
    name: 'Anna B.',
    handle: '@byannab',
    followers: '41K',
    status: CreatorStatus.posted,
    statusLabel: 'posted',
    avatarStart: ColorData(0xFFA684FF),
    avatarEnd: ColorData(0xFFAD46FF),
  ),
];

const kBusinessPosts = [
  BusinessPost(
    handle: '@anna.explores',
    platform: 'Instagram',
    views: '38.2K',
    likes: '1,240',
    comments: '87',
    thumbnailAsset: 'assets/images/business/post_thumb_1.jpg',
  ),
  BusinessPost(
    handle: '@cityguidemax',
    platform: 'TikTok',
    views: '61K',
    likes: '3,850',
    comments: '214',
    thumbnailAsset: 'assets/images/business/post_thumb_2.jpg',
  ),
];

const kBusinessRedemptions = [
  BusinessRedemption(
    id: 'r1',
    name: 'Sophie M.',
    detail: '3 free craft beers · just now',
    code: 'STR-A4BX',
  ),
  BusinessRedemption(
    id: 'r2',
    name: 'Lukas K.',
    detail: '3 free craft beers · 8 min ago',
    code: 'STR-7YMQ',
  ),
];
