// Seed data — Stuttgart businesses at their real coordinates. Perk stops carry
// a deliverable; roam-only stops have none.

import 'models.dart';

const kBusinesses = <Business>[
  // The stage-demo stop: the hackathon venue itself. The audience is the shot.
  Business(
    id: 'cursor-hackathon',
    name: 'Cursor Hackathon @ INFOMOTION',
    category: BusinessCategory.culture,
    description: '60 builders, one day, fourth floor at Friedrichstraße 6. '
        'The bar opens when the demos end.',
    walkMinutes: 0,
    rating: 4.9,
    lat: 48.78397,
    lng: 9.17796,
    perkTitle: 'Free drink at the bar',
    perkValue: 6,
    deliverable: '1 photo + 1 story post',
    narration: 'You are already here. Sixty people building at once — '
        'capture the room before the demos start.',
  ),
  Business(
    id: 'brot-roesterei',
    name: 'Brot & Rösterei',
    category: BusinessCategory.cafe,
    description: 'Specialty coffee and sourdough bakery in the Bohnenviertel. '
        'Open from 7am.',
    walkMinutes: 4,
    rating: 4.8,
    lat: 48.7737,
    lng: 9.1862,
    perkTitle: '2 free coffees',
    perkValue: 7,
    deliverable: '1 photo + 1 story post',
    narration: 'A bakery corner in the Bohnenviertel that fills with regulars '
        'before the rest of the city wakes up.',
  ),
  Business(
    id: 'alte-kanzlei',
    name: 'Alte Kanzlei',
    category: BusinessCategory.food,
    description: 'Swabian restaurant on Schillerplatz — Maultaschen, Spätzle, '
        'terrace facing the Old Castle.',
    walkMinutes: 7,
    rating: 4.6,
    lat: 48.7772,
    lng: 9.1794,
    perkTitle: 'Free lunch special',
    perkValue: 18,
    deliverable: '1 reel + tag @altekanzlei',
    narration: 'Schillerplatz has been the city\'s front room for four '
        'centuries. The kitchen here cooks the classics straight.',
  ),
  Business(
    id: 'palmengarten',
    name: 'Palmengarten Kiosk',
    category: BusinessCategory.culture,
    description: 'Greenhouse café at the edge of Rosensteinpark — plants, '
        'records, flat whites.',
    walkMinutes: 9,
    rating: 4.5,
    lat: 48.8009,
    lng: 9.2028,
    perkTitle: 'Free entry + latte',
    perkValue: 6,
    deliverable: '1 photo',
    narration: 'A glasshouse from the Kaiser era, still full of palms. The '
        'café came later.',
  ),
  Business(
    id: 'markthalle',
    name: 'Markthalle Stuttgart',
    category: BusinessCategory.market,
    description: 'Art-nouveau market hall from 1914 — about 40 stalls of '
        'produce, spices and delicatessen.',
    walkMinutes: 6,
    rating: 4.7,
    lat: 48.7756,
    lng: 9.1822,
    perkTitle: 'Tasting basket',
    perkValue: 15,
    deliverable: '1 photo + 1 story post',
    narration: 'The market hall has run daily since 1914. Forty stalls under '
        'one art-nouveau roof.',
  ),
  Business(
    id: 'biergarten-schlossgarten',
    name: 'Biergarten im Schlossgarten',
    category: BusinessCategory.drinks,
    description: 'Beer garden in the palace gardens — 1,200 seats under '
        'chestnut trees, local Pils, pretzels.',
    walkMinutes: 8,
    rating: 4.4,
    lat: 48.7841,
    lng: 9.1856,
    perkTitle: '2 craft beers',
    perkValue: 14,
    deliverable: '1 reel',
    narration: 'End of the route: 1,200 seats in the Schlossgarten shade. '
        'Order at the counter.',
  ),
  // Roam-only stops — no perk, no obligations.
  Business(
    id: 'stadtbibliothek',
    name: 'Stadtbibliothek',
    category: BusinessCategory.culture,
    description: 'The white cube city library by Eun Young Yi. The upper '
        'atrium is one of Germany\'s most photographed rooms.',
    walkMinutes: 11,
    rating: 4.7,
    lat: 48.7908,
    lng: 9.1811,
    narration: 'Nine storeys of white geometry. The atrium light changes by '
        'the hour.',
  ),
  Business(
    id: 'feuersee',
    name: 'Feuersee & Johanneskirche',
    category: BusinessCategory.culture,
    description: 'Neo-gothic church standing in a small lake; the spire was '
        'lost in the war and never rebuilt.',
    walkMinutes: 13,
    rating: 4.6,
    lat: 48.7735,
    lng: 9.1655,
    narration: 'The church kept its broken spire as a war memorial. Best '
        'light in the evening.',
  ),
  Business(
    id: 'weissenburgpark',
    name: 'Weißenburgpark Teehaus',
    category: BusinessCategory.cafe,
    description: 'Marble tea house on the hillside with a wide view over the '
        'city bowl.',
    walkMinutes: 16,
    rating: 4.8,
    lat: 48.7647,
    lng: 9.1868,
    narration: 'The climb pays off at the top — the whole city bowl in one '
        'view.',
  ),
];

Business businessById(String id) =>
    kBusinesses.firstWhere((b) => b.id == id, orElse: () => kBusinesses.first);

/// Mock AI caption for a stop post (a later commit swaps this for Claude).
String draftCaption(Business b) => switch (b.category) {
      BusinessCategory.cafe =>
        'Morning stop at ${b.name}, Stuttgart. #strolling #stuttgart',
      BusinessCategory.food =>
        'Lunch at ${b.name} — Swabian classics done right. #strolling #stuttgart',
      BusinessCategory.drinks =>
        'Golden hour at ${b.name}. #strolling #stuttgart #biergarten',
      BusinessCategory.culture =>
        '${b.name}, Stuttgart. Worth the detour. #strolling #stuttgart',
      BusinessCategory.market =>
        'Tasting through ${b.name}. #strolling #stuttgart #markthalle',
    };
