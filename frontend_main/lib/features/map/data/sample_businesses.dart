import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

const kMapFilters = ['All', 'Café', 'Food', 'Drinks', 'Culture', 'Market'];

/// Real Stuttgart spots around Mitte / Bohnenviertel.
const kSampleBusinesses = [
  MapBusiness(
    id: 1,
    name: 'Brot & Rösterei',
    category: 'Café',
    filterKey: 'Café',
    desc:
        'Third-wave coffee and stone-baked sourdough in the Bohnenviertel. Open from 7am.',
    perk: '2 free coffees',
    perkVal: '€7',
    perkColor: Color(0xFFF5A623),
    required: '1 photo + 1 story post',
    distance: '4 min walk',
    walkMin: 4,
    latLng: LatLng(48.7758, 9.1852),
    imageUrl:
        'https://images.unsplash.com/photo-1495474472930-0de66167e1c9?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 2,
    name: 'Weinstube Fröhlich',
    category: 'Restaurant',
    filterKey: 'Food',
    desc:
        'Family-run since 1952. Swabian classics and local Trollinger wine, poured generously.',
    perk: 'Free Maultaschen lunch',
    perkVal: '€18',
    perkColor: StrollingColors.primary,
    required: '1 video + 1 feed post',
    distance: '8 min walk',
    walkMin: 8,
    latLng: LatLng(48.7769, 9.1774),
    imageUrl:
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 3,
    name: 'Schlossplatz',
    category: 'Landmark',
    filterKey: 'Culture',
    desc:
        'The heart of Stuttgart. The Neues Schloss dates from 1746 — worth stopping for the light at noon.',
    distance: '2 min walk',
    walkMin: 2,
    latLng: LatLng(48.7785, 9.1800),
    imageUrl:
        'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=500&h=320&fit=crop',
    hasPerk: false,
  ),
  MapBusiness(
    id: 4,
    name: 'Markthalle Stuttgart',
    category: 'Market',
    filterKey: 'Market',
    desc:
        'Art Nouveau market hall from 1914. Fresh produce, deli goods, and the best pretzels in town.',
    perk: '€15 voucher',
    perkVal: '€15',
    perkColor: Color(0xFF2DCE89),
    required: '1 reel + tag @markthalle',
    distance: '6 min walk',
    walkMin: 6,
    latLng: LatLng(48.7755, 9.1789),
    imageUrl:
        'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 5,
    name: 'Galerie am Schloss',
    category: 'Culture',
    filterKey: 'Culture',
    desc:
        'Contemporary local artists in a 19th-century townhouse. Free entry on Thursdays.',
    distance: '5 min walk',
    walkMin: 5,
    latLng: LatLng(48.7796, 9.1828),
    imageUrl:
        'https://images.unsplash.com/photo-1540575467537-14c55c93a8e8?w=500&h=320&fit=crop',
    hasPerk: false,
  ),
  MapBusiness(
    id: 6,
    name: 'Brauhaus am Eck',
    category: 'Bar',
    filterKey: 'Drinks',
    desc:
        'Local craft brewery with a rooftop terrace. 12 taps, all brewed on site since 2011.',
    perk: '3 free craft beers',
    perkVal: '€14',
    perkColor: Color(0xFF6C63FF),
    required: '1 video tour + story post',
    distance: '11 min walk',
    walkMin: 11,
    latLng: LatLng(48.7732, 9.1868),
    imageUrl:
        'https://images.unsplash.com/photo-1436076863939-06870fe779c2?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 7,
    name: 'Stadtgarten Kiosk',
    category: 'Outdoors',
    filterKey: 'Café',
    desc:
        'The kiosk at the edge of the Stadtgarten. Best bench in Stuttgart behind it.',
    perk: 'Free pretzel + drink',
    perkVal: '€6',
    perkColor: Color(0xFFF5A623),
    required: '1 photo from the bench',
    distance: '9 min walk',
    walkMin: 9,
    latLng: LatLng(48.7818, 9.1746),
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db2b175?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 8,
    name: 'The Record Loft',
    category: 'Culture',
    filterKey: 'Culture',
    desc:
        "Vinyl heaven up a narrow staircase — the sign says only 'Loft'. Max has been here 22 years.",
    perk: 'Free entry + 1 drink',
    perkVal: '€12',
    perkColor: Color(0xFFF5A623),
    required: '1 reel + 1 story',
    distance: '0.6 km · 8 min',
    walkMin: 8,
    latLng: LatLng(48.7772, 9.1835),
    imageUrl: 'asset:assets/images/business_record_loft.jpg',
    hasPerk: true,
  ),
];
