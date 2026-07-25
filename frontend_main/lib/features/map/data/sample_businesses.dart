import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

const kMapFilters = ['All', 'Café', 'Food', 'Drinks', 'Culture', 'Market'];

/// Real Stuttgart spots around Mitte / Bohnenviertel.
const kSampleBusinesses = [
  MapBusiness(
    id: 1,
    apiId: 'brot-roesterei',
    name: 'Brot & Rösterei',
    category: 'Café',
    filterKey: 'Café',
    desc:
        'Specialty coffee and sourdough bakery in the Bohnenviertel. Open from 7am.',
    perk: '2 free coffees',
    perkVal: '€7',
    perkColor: Color(0xFFF5A623),
    required: '1 photo + 1 story post',
    distance: '4 min walk',
    walkMin: 4,
    latLng: LatLng(48.7737, 9.1862),
    imageUrl:
        'https://images.unsplash.com/photo-1495474472930-0de66167e1c9?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 2,
    apiId: 'alte-kanzlei',
    name: 'Alte Kanzlei',
    category: 'Restaurant',
    filterKey: 'Food',
    desc:
        'Swabian restaurant on Schillerplatz — Maultaschen, Spätzle, terrace facing the Old Castle.',
    perk: 'Free lunch special',
    perkVal: '€18',
    perkColor: StrollingColors.primary,
    required: '1 reel + tag @altekanzlei',
    distance: '7 min walk',
    walkMin: 7,
    latLng: LatLng(48.7772, 9.1794),
    imageUrl:
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 3,
    apiId: 'stadtbibliothek',
    name: 'Stadtbibliothek',
    category: 'Landmark',
    filterKey: 'Culture',
    desc:
        "The white cube city library. The upper atrium is one of Germany's most photographed rooms.",
    distance: '11 min walk',
    walkMin: 11,
    latLng: LatLng(48.7908, 9.1811),
    imageUrl:
        'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=500&h=320&fit=crop',
    hasPerk: false,
  ),
  MapBusiness(
    id: 4,
    apiId: 'markthalle',
    name: 'Markthalle Stuttgart',
    category: 'Market',
    filterKey: 'Market',
    desc:
        'Art-nouveau market hall from 1914 — about 40 stalls of produce, spices and delicatessen.',
    perk: 'Tasting basket',
    perkVal: '€15',
    perkColor: Color(0xFF2DCE89),
    required: '1 photo + 1 story post',
    distance: '6 min walk',
    walkMin: 6,
    latLng: LatLng(48.7756, 9.1822),
    imageUrl:
        'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 5,
    apiId: 'palmengarten',
    name: 'Palmengarten Kiosk',
    category: 'Culture',
    filterKey: 'Culture',
    desc:
        'Greenhouse café at the edge of Rosensteinpark — plants, records, flat whites.',
    distance: '9 min walk',
    walkMin: 9,
    latLng: LatLng(48.8009, 9.2028),
    imageUrl:
        'https://images.unsplash.com/photo-1540575467537-14c55c93a8e8?w=500&h=320&fit=crop',
    required: '1 photo',
    hasPerk: true,
  ),
  MapBusiness(
    id: 6,
    apiId: 'biergarten-schlossgarten',
    name: 'Biergarten im Schlossgarten',
    category: 'Bar',
    filterKey: 'Drinks',
    desc:
        'Beer garden in the palace gardens — 1,200 seats under chestnut trees, local Pils, pretzels.',
    perk: '2 craft beers',
    perkVal: '€14',
    perkColor: Color(0xFF6C63FF),
    required: '1 reel',
    distance: '8 min walk',
    walkMin: 8,
    latLng: LatLng(48.7841, 9.1856),
    imageUrl:
        'https://images.unsplash.com/photo-1436076863939-06870fe779c2?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
  MapBusiness(
    id: 7,
    apiId: 'weissenburgpark',
    name: 'Weißenburgpark Teehaus',
    category: 'Outdoors',
    filterKey: 'Café',
    desc:
        'Marble tea house on the hillside with a wide view over the city bowl.',
    perkColor: Color(0xFFF5A623),
    distance: '16 min walk',
    walkMin: 16,
    latLng: LatLng(48.7647, 9.1868),
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db2b175?w=500&h=320&fit=crop',
    hasPerk: false,
  ),
  MapBusiness(
    id: 8,
    apiId: 'feuersee',
    name: 'Feuersee & Johanneskirche',
    category: 'Culture',
    filterKey: 'Culture',
    desc:
        "Vinyl heaven up a narrow staircase — the sign says only 'Loft'. Max has been here 22 years.",
    perkColor: Color(0xFFF5A623),
    distance: '13 min walk',
    walkMin: 13,
    latLng: LatLng(48.7735, 9.1655),
    imageUrl: 'asset:assets/images/business_record_loft.jpg',
    hasPerk: false,
  ),
  MapBusiness(
    id: 9,
    apiId: 'cursor-hackathon',
    name: 'Cursor Hackathon @ INFOMOTION',
    category: 'Culture',
    filterKey: 'Culture',
    desc:
        '60 builders, one day, fourth floor at Friedrichstraße 6. The bar opens when the demos end.',
    perk: 'Free drink at the bar',
    perkVal: '€6',
    perkColor: StrollingColors.primary,
    required: '1 photo + 1 story post',
    distance: 'You are here',
    walkMin: 0,
    latLng: LatLng(48.78397, 9.17796),
    imageUrl:
        'https://images.unsplash.com/photo-1497366216548-37526070297c?w=500&h=320&fit=crop',
    hasPerk: true,
  ),
];
