import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum MapMode { explore, earn }

class MapBusiness {
  const MapBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.desc,
    required this.distance,
    required this.walkMin,
    required this.latLng,
    required this.imageUrl,
    required this.hasPerk,
    this.apiId,
    this.perk,
    this.perkVal,
    this.perkColor = const Color(0xFF888699),
    this.required,
    this.filterKey,
  });

  final int id;
  /// Backend seed slug (`src/lib/seed.ts`). Defaults to `id` as string.
  final String? apiId;
  final String name;
  final String category;
  final String desc;
  final String distance;
  final int walkMin;
  final LatLng latLng;
  final String imageUrl;
  final bool hasPerk;
  final String? perk;
  final String? perkVal;
  final Color perkColor;
  final String? required;
  final String? filterKey;

  /// Id sent to POST /api/scripts and /api/render.
  String get backendId => apiId ?? id.toString();

  String get emoji => switch (category) {
        'Café' => '☕',
        'Restaurant' => '🍽',
        'Bar' => '🍺',
        'Market' => '🧺',
        'Outdoors' => '🌿',
        'Culture' => '🎨',
        'Landmark' => '🏛',
        _ => '●',
      };

  String get shortLabel {
    final first = name.split(' ').first;
    return first.length > 10 ? '${first.substring(0, 8)}…' : first;
  }

}

/// User "you are here" — Stuttgart Hauptbahnhof.
const kUserLocation = LatLng(48.7835, 9.1817);
const kStuttgartCenter = LatLng(48.7780, 9.1805);
