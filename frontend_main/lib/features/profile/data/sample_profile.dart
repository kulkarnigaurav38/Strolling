class ProfileSocial {
  const ProfileSocial({
    required this.id,
    required this.label,
    required this.followersLabel,
    required this.glyph,
    this.glyphColor,
  });

  final String id;
  final String label;
  final String followersLabel;
  final String glyph;
  final int? glyphColor;
}

class ProfileStat {
  const ProfileStat({
    required this.value,
    required this.label,
    required this.iconAsset,
  });

  final String value;
  final String label;
  final String iconAsset;
}

class ProfileStroll {
  const ProfileStroll({
    required this.id,
    required this.city,
    required this.meta,
    this.thumbAsset,
  });

  final String id;
  final String city;
  final String meta;
  final String? thumbAsset;
}

class CreatorPersona {
  const CreatorPersona({
    required this.displayName,
    required this.avatarEmoji,
    required this.city,
    required this.interestLabels,
    required this.socials,
    required this.stats,
    required this.strolls,
  });

  final String displayName;
  final String avatarEmoji;
  final String city;
  final List<String> interestLabels;
  final List<ProfileSocial> socials;
  final List<ProfileStat> stats;
  final List<ProfileStroll> strolls;

  String get locationLine {
    final interests = interestLabels.take(2).join(', ');
    if (interests.isEmpty) return city;
    return '$city · $interests';
  }
}

const kSampleSocials = [
  ProfileSocial(
    id: 'ig',
    label: 'Instagram',
    followersLabel: '4.2k followers',
    glyph: '📸',
  ),
  ProfileSocial(
    id: 'fb',
    label: 'Facebook',
    followersLabel: '1.8k followers',
    glyph: 'f',
    glyphColor: 0xFF1877F2,
  ),
];

const kSampleStats = [
  ProfileStat(
    value: '3',
    label: 'Strolls',
    iconAsset: 'assets/images/profile/strolls_icon.svg',
  ),
  ProfileStat(
    value: '8.2k',
    label: 'Reach',
    iconAsset: 'assets/images/profile/reach_icon.svg',
  ),
  ProfileStat(
    value: '€74',
    label: 'Earned',
    iconAsset: 'assets/images/profile/earned_icon.svg',
  ),
  ProfileStat(
    value: '4.9',
    label: 'Score',
    iconAsset: 'assets/images/profile/score_icon.svg',
  ),
];

const kSampleStrolls = [
  ProfileStroll(
    id: '1',
    city: 'Stuttgart',
    meta: '3 stops · Today',
    thumbAsset: 'assets/images/profile/stroll_thumb_1.jpg',
  ),
  ProfileStroll(
    id: '2',
    city: 'Stuttgart',
    meta: '2 stops · 12 Jul',
    thumbAsset: 'assets/images/profile/stroll_thumb_2.jpg',
  ),
  ProfileStroll(
    id: '3',
    city: 'Heidelberg',
    meta: '4 stops · 28 Jun',
    thumbAsset: 'assets/images/profile/stroll_thumb_3.jpg',
  ),
];

CreatorPersona buildSamplePersona({
  String? city,
  List<String>? interests,
}) {
  final labels = (interests == null || interests.isEmpty)
      ? const ['Food', 'Culture']
      : interests.map(_stripInterestEmoji).where((s) => s.isNotEmpty).toList();

  return CreatorPersona(
    displayName: 'Alex Müller',
    avatarEmoji: '🧍',
    city: city ?? 'Stuttgart',
    interestLabels: labels,
    socials: kSampleSocials,
    stats: kSampleStats,
    strolls: kSampleStrolls,
  );
}

String _stripInterestEmoji(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\w\s&\-]+'), '').trim();
  return cleaned;
}
