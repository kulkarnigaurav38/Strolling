import 'package:flutter/cupertino.dart';

import '../models/map_business.dart';
import 'stroll_models.dart';

class ScriptTemplate {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  final String vibe;

  const ScriptTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.vibe,
  });

  List<ScriptStep> generate(List<MapBusiness> stops) => [
        for (var i = 0; i < stops.length; i++) _scene(this, i, stops[i]),
      ];
}

const kTemplates = <ScriptTemplate>[
  ScriptTemplate(
    id: 'wes',
    name: 'The Symmetrist',
    tagline: 'à la Wes Anderson',
    icon: CupertinoIcons.square_split_2x2,
    color: Color(0xFFE98FA6),
    vibe: 'Centered frames, level horizons, deadpan captions.',
  ),
  ScriptTemplate(
    id: 'kubrick',
    name: 'One-Point Stare',
    tagline: 'à la Kubrick',
    icon: CupertinoIcons.circle_fill,
    color: Color(0xFFC03A2B),
    vibe: 'One-point perspective, slow push-ins, long holds.',
  ),
  ScriptTemplate(
    id: 'doku',
    name: 'Der Doku',
    tagline: 'documentary',
    icon: CupertinoIcons.mic_fill,
    color: Color(0xFFB8860B),
    vibe: 'Handheld, real sound, first takes. Details over drama.',
  ),
  ScriptTemplate(
    id: 'viral',
    name: "Whatever's Viral",
    tagline: 'trend format',
    icon: CupertinoIcons.bolt_fill,
    color: Color(0xFF6C63E8),
    vibe: 'Hook first, fast cuts, POV captions, loopable endings.',
  ),
];

ScriptTemplate templateById(String id) =>
    kTemplates.firstWhere((t) => t.id == id, orElse: () => kTemplates[2]);

List<ScriptStep> scriptForStroll(StrollState stroll) {
  if (!stroll.active) return const [];
  final template = templateById(stroll.templateId);
  return template.generate(stroll.stopIds.map(businessById).toList());
}

ScriptStep _scene(ScriptTemplate t, int index, MapBusiness b) {
  final perkCallout = b.hasPerk
      ? 'Deliver ${b.required} → ${b.perk} (${b.perkVal})'
      : null;

  final required = _requiredFromDeliverable(t, b);
  final flavor = _flavor(t)
      .where((a) => !required.any((r) => r.kind == a.kind))
      .toList();

  final location = _location(b);
  final blocks = _blocks(t, b);
  final captures = blocks.where((b) => b.isCapture).toList();
  final actions = [
    ...required,
    ...flavor,
    for (final c in captures)
      if (!required.any((r) => r.kind == c.captureKind) &&
          !flavor.any((f) => f.kind == c.captureKind))
        ScriptAction(c.captureKind!, c.capturePrompt!),
  ];

  return ScriptStep(
    businessId: b.id,
    sceneTitle: 'SCENE ${index + 1} · ${_sceneName(t, b)}',
    direction: _direction(t, b),
    line: _line(t, b),
    perkCallout: perkCallout,
    actions: actions,
    locationTitle: location.title,
    locationBody: location.body,
    blocks: blocks,
  );
}

List<ScriptAction> _requiredFromDeliverable(ScriptTemplate t, MapBusiness b) {
  final d = b.required?.toLowerCase() ?? '';
  return [
    if (d.contains('photo'))
      ScriptAction(CaptureAction.photo, _photoPrompt(t), required: true),
    if (d.contains('reel') || d.contains('story') || d.contains('video'))
      ScriptAction(CaptureAction.video, _videoPrompt(t), required: true),
  ];
}

List<ScriptAction> _flavor(ScriptTemplate t) => switch (t.id) {
      'wes' => [
          ScriptAction(CaptureAction.photo, _photoPrompt(t)),
          const ScriptAction(
              CaptureAction.text, 'One deadpan sentence, no filler.'),
        ],
      'kubrick' => [
          ScriptAction(CaptureAction.video, _videoPrompt(t)),
          ScriptAction(CaptureAction.photo, _photoPrompt(t)),
        ],
      'doku' => [
          const ScriptAction(CaptureAction.voice,
              '30 seconds, first take: what is this place actually like?'),
          ScriptAction(CaptureAction.photo, _photoPrompt(t)),
        ],
      _ => [
          ScriptAction(CaptureAction.video, _videoPrompt(t)),
          const ScriptAction(
              CaptureAction.text, 'POV caption, present tense, one line.'),
        ],
    };

String _key(MapBusiness b) => b.filterKey ?? b.category;

String _sceneName(ScriptTemplate t, MapBusiness b) {
  final noun = switch (_key(b)) {
    'Café' => 'CAFÉ',
    'Food' => 'RESTAURANT',
    'Drinks' => 'BIERGARTEN',
    'Culture' => 'LANDMARK',
    'Market' => 'MARKET HALL',
    _ => 'STOP',
  };
  return switch (t.id) {
    'wes' => 'THE $noun, CENTERED',
    'kubrick' => 'THE $noun, ONE POINT',
    'doku' => 'THE $noun, AS IT IS',
    _ => 'THE $noun, ON LOOP',
  };
}

String _direction(ScriptTemplate t, MapBusiness b) => switch (t.id) {
      'wes' => switch (_key(b)) {
          'Café' =>
            'Face the counter straight on. Cups in a row, one person centered, '
                'horizon level.',
          'Food' =>
            'Top-down on the set table, cutlery parallel. Then one straight-on '
                'of the entrance.',
          'Drinks' =>
            'Center yourself on the longest bench row. Glass at dead center, '
                'hold still.',
          'Culture' =>
            'Face the facade straight on and center it. Wait for one person '
                'to cross the frame.',
          'Market' => 'One stall, front-on. Produce stacked, vendor centered.',
          _ => 'Center the subject. Horizon level. Hold still.',
        },
      'kubrick' => switch (_key(b)) {
          'Café' =>
            'Find the longest sightline inside. One-point perspective, slow '
                'push-in, no talking.',
          'Food' =>
            'Shoot the arcade columns vanishing to a point. Hold the frame '
                'three seconds longer than feels right.',
          'Drinks' =>
            'Use the tree rows as a corridor. Walk the center line, camera '
                'level, even steps.',
          'Culture' =>
            'Center the doorway and push in slowly until the room fills the '
                'frame.',
          'Market' =>
            'The central aisle at eye level, dead center. Let people pass '
                'through the frame.',
          _ => 'One-point perspective. Slow push-in. Hold longer than feels right.',
        },
      'doku' => switch (_key(b)) {
          'Café' =>
            'Handheld: hands at work, steam, the first sip. Then record '
                'yourself, one take.',
          'Food' =>
            'Film plates leaving the kitchen. Then say on tape what this '
                'food means here.',
          'Drinks' =>
            'One wide of the crowd, one close of a glass. Record the '
                'background noise for ten seconds.',
          'Culture' =>
            'Ten seconds of ambience before you speak. Then one honest '
                'observation.',
          'Market' =>
            'Follow one ingredient from stall to stall. Record the vendors '
                'answering.',
          _ => 'Handheld, real sound. One honest observation.',
        },
      _ => switch (_key(b)) {
          'Café' =>
            'Hook in the first half second: pour or latte art hitting the '
                'table. Whip-pan to your reaction.',
          'Food' => 'Food shot first, context later. Jump cuts, trend audio.',
          'Drinks' =>
            'POV: glass raised into frame at golden hour. Cut on the clink, '
                'loop the ending.',
          'Culture' =>
            'Doorway transition: outside/inside on one step. Save the best '
                'angle for the beat drop.',
          'Market' =>
            'Run the tasting-basket challenge stall to stall, prices as text '
                'overlays.',
          _ => 'Hook first. Fast cuts. Loopable ending.',
        },
    };

String _line(ScriptTemplate t, MapBusiness b) => switch (t.id) {
      'wes' => 'This is ${b.name}. It has not moved in some time.',
      'kubrick' => 'Say nothing. Let the frame hold.',
      'doku' => 'What surprised me about ${b.name} is — finish it honestly.',
      _ => 'Nobody talks about ${b.name}. That ends today.',
    };

String _photoPrompt(ScriptTemplate t) => switch (t.id) {
      'wes' => 'Facade centered, horizon level.',
      'kubrick' => 'One-point perspective still, vanishing point centered.',
      'doku' => 'The detail people walk past — hands, signs, wear.',
      _ => 'The angle that reads at thumbnail size.',
    };

String _videoPrompt(ScriptTemplate t) => switch (t.id) {
      'wes' => '4 seconds, locked off. One thing moves.',
      'kubrick' => 'Slow push-in, 6 seconds, no cuts.',
      'doku' => '10 seconds handheld, real sound, no filter.',
      _ => 'Hook, whip-pan, reveal — under 7 seconds, loopable.',
    };

({String title, String body}) _location(MapBusiness b) => switch (_key(b)) {
      'Café' => (
          title: 'The Bohnenviertel',
          body:
              "Stuttgart's oldest residential quarter — the 'bean quarter', named after "
              'the beans workers grew in their tiny gardens. Walking into it from the '
              'Königstraße feels like the city took a breath. Everything slows down by '
              'about a third.',
        ),
      'Food' => (
          title: 'Around Mitte',
          body:
              'Swabian cooking lives in these side streets — wood panels, long tables, '
              'and wine poured without ceremony. The walk from the station already smells '
              'like broth and roasted onions.',
        ),
      'Drinks' => (
          title: 'Golden hour terrace',
          body:
              'When the light hits the courtyard benches, conversations stretch. Locals '
              'claim tables early; visitors learn to share.',
        ),
      'Culture' => (
          title: 'City stage',
          body:
              'Public squares here are designed for lingering. Facades do the talking — '
              'you just have to give them a clean frame.',
        ),
      'Market' => (
          title: 'The Markthalle',
          body:
              'Art Nouveau arches, produce piled high, and a hum that never quite stops. '
              'Come hungry; leave with a story and a bag.',
        ),
      _ => (
          title: b.category,
          body: b.desc,
        ),
    };

List<SceneBlock> _blocks(ScriptTemplate t, MapBusiness b) {
  // Brot & Rösterei matches the Figma CursorStutt scene beat-for-beat.
  if (b.id == 1) {
    return const [
      SceneBlock.narrative(
        'Leave the Hauptbahnhof and head south along Königstraße. At the fountain, '
        'turn right through the stone arch — you\'re now in the Bohnenviertel. The walls '
        'go from glass towers to sandstone in about thirty seconds.',
      ),
      SceneBlock.capture(
        captureTitle: 'CAPTURE — WALK-IN SHOT',
        capturePrompt:
            'Film the transition as you turn into the alley — one continuous walk '
            'from the busy street into the quiet quarter',
        captureKind: CaptureAction.video,
      ),
      SceneBlock.narrative(
        'Brot & Rösterei is through the second archway on your left. The roaster sits '
        'behind a glass panel — you\'ll smell it before you see it. Order the filter '
        'coffee. The counter by the window is the best seat in the building.',
      ),
      SceneBlock.capture(
        captureTitle: 'CAPTURE — THE COFFEE',
        capturePrompt:
            'Close-up of your coffee on the counter, or the espresso machine at work — '
            'natural light only',
        captureKind: CaptureAction.photo,
      ),
      SceneBlock.narrative(
        'The stone-baked sourdough usually runs out by 10am. If there\'s still a loaf '
        'on the shelf behind the counter, that\'s worth a mention — it means you got '
        'here early enough.',
      ),
      SceneBlock.capture(
        captureTitle: 'CAPTURE — YOUR TAKE',
        capturePrompt:
            'Tell the camera what the place feels like — the smell, the quiet, why '
            'you\'d come back here',
        captureKind: CaptureAction.voice,
      ),
    ];
  }

  final walkIn = switch (_key(b)) {
    'Café' => (
        'Approach ${b.name} from the street. Pause at the doorway before you go in — '
            'let the exterior settle in frame for a beat.',
        'Film the walk-up to the door — continuous, no cuts.',
      ),
    'Food' => (
        'Find ${b.name} from the main approach. Notice the signage and the first table '
            'you see through the window.',
        'Film your approach along the facade until the entrance fills the frame.',
      ),
    'Market' => (
        'Enter through the main doors and let the hall open in front of you. Stall '
            'colors hit first; then the smell.',
        'One continuous walk from the entrance into the central aisle.',
      ),
    _ => (
        'Make your way to ${b.name}. Take the scenic approach — streets before the stop.',
        'Film the last thirty seconds of your walk-in.',
      ),
  };

  final detail = switch (_key(b)) {
    'Café' => (
        'Order something local. Sit where the light is honest.',
        'Close-up of your cup or the barista at work — natural light only.',
      ),
    'Food' => (
        'When the plate lands, give it a second before you dig in.',
        'Still of the dish as served — no filters, plate centered.',
      ),
    'Drinks' => (
        'Raise a glass once the pour settles. Catch the ambient noise.',
        'Close-up of the pour or the glass against the courtyard light.',
      ),
    'Market' => (
        'Pick one stall and stay with it. Ask one question.',
        'Detail shot of produce or hands wrapping something for you.',
      ),
    _ => (
        'Look for the detail people walk past.',
        _photoPrompt(t),
      ),
  };

  return [
    SceneBlock.narrative(walkIn.$1),
    SceneBlock.capture(
      captureTitle: 'CAPTURE — WALK-IN SHOT',
      capturePrompt: walkIn.$2,
      captureKind: CaptureAction.video,
    ),
    SceneBlock.narrative('${b.name}. ${b.desc}'),
    SceneBlock.capture(
      captureTitle: 'CAPTURE — THE DETAIL',
      capturePrompt: detail.$2,
      captureKind: CaptureAction.photo,
    ),
    SceneBlock.narrative(
      'Before you leave, take one beat for yourself — what would you tell a friend '
      'waiting around the corner?',
    ),
    SceneBlock.capture(
      captureTitle: 'CAPTURE — YOUR TAKE',
      capturePrompt:
          'Tell the camera what ${b.name} feels like — one honest take, first try.',
      captureKind: CaptureAction.voice,
    ),
  ];
}
