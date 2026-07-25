class CityOption {
  const CityOption({
    required this.name,
    required this.region,
    required this.emoji,
    this.live = false,
  });

  final String name;
  final String region;
  final String emoji;
  final bool live;
}

const kCities = [
  CityOption(
    name: 'Stuttgart',
    region: 'Baden-Württemberg',
    emoji: '🏰',
    live: true,
  ),
  CityOption(
    name: 'Munich',
    region: 'Bavaria',
    emoji: '🥨',
  ),
  CityOption(
    name: 'Berlin',
    region: 'Berlin',
    emoji: '🐻',
  ),
  CityOption(
    name: 'Hamburg',
    region: 'Hamburg',
    emoji: '⚓',
  ),
  CityOption(
    name: 'Cologne',
    region: 'North Rhine-Westphalia',
    emoji: '⛪',
  ),
  CityOption(
    name: 'Frankfurt',
    region: 'Hesse',
    emoji: '🏦',
  ),
];
