// The script template engine. A template turns the influencer's picks into a
// per-stop shooting script: a themed scene with staging directions, a line to
// say, the perk deliverable woven in, and the exact capture actions to open
// (photo / video / voice / text). Pure Dart — a later commit can swap the
// generator for Claude without touching any screen.

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'seed.dart';
import 'state.dart';

class ScriptTemplate {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  final String vibe; // one-line description on the picker card

  const ScriptTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.vibe,
  });

  List<ScriptStep> generate(List<Business> stops) => [
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

/// The generated script for the active stroll. A backend-written script
/// (fetched when the mock flag is off) wins over the local generator.
final strollScriptProvider = Provider<List<ScriptStep>>((ref) {
  final stroll = ref.watch(strollProvider);
  if (!stroll.active) return const [];
  if (stroll.fetchedSteps != null) return stroll.fetchedSteps!;
  final template = templateById(stroll.templateId);
  return template.generate(stroll.stopIds.map(businessById).toList());
});

// ---------------------------------------------------------------------------
// Scene generation
// ---------------------------------------------------------------------------

ScriptStep _scene(ScriptTemplate t, int index, Business b) {
  final perkCallout = b.hasPerk
      ? 'Deliver ${b.deliverable} → ${b.perkTitle} (€${b.perkValue})'
      : null;

  // Required actions come from the perk deliverable; the template then adds
  // its own flavor actions (never duplicating a kind that's already required).
  final required = _requiredFromDeliverable(t, b);
  final flavor = _flavor(t)
      .where((a) => !required.any((r) => r.kind == a.kind))
      .toList();

  return ScriptStep(
    businessId: b.id,
    sceneTitle: 'SCENE ${index + 1} · ${_sceneName(t, b)}',
    direction: _direction(t, b),
    line: _line(t, b),
    perkCallout: perkCallout,
    actions: [...required, ...flavor],
  );
}

/// Parse "1 photo + 1 story post" / "1 reel + tag us" into required actions,
/// phrased in the template's voice.
List<ScriptAction> _requiredFromDeliverable(ScriptTemplate t, Business b) {
  final d = b.deliverable?.toLowerCase() ?? '';
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
          const ScriptAction(CaptureAction.text, 'One deadpan sentence, no filler.'),
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
          const ScriptAction(CaptureAction.text,
              'POV caption, present tense, one line.'),
        ],
    };

String _sceneName(ScriptTemplate t, Business b) {
  final noun = switch (b.category) {
    BusinessCategory.cafe => 'CAFÉ',
    BusinessCategory.food => 'RESTAURANT',
    BusinessCategory.drinks => 'BIERGARTEN',
    BusinessCategory.culture => 'LANDMARK',
    BusinessCategory.market => 'MARKET HALL',
  };
  return switch (t.id) {
    'wes' => 'THE $noun, CENTERED',
    'kubrick' => 'THE $noun, ONE POINT',
    'doku' => 'THE $noun, AS IT IS',
    _ => 'THE $noun, ON LOOP',
  };
}

String _direction(ScriptTemplate t, Business b) => switch (t.id) {
      'wes' => switch (b.category) {
          BusinessCategory.cafe =>
            'Face the counter straight on. Cups in a row, one person centered, '
                'horizon level.',
          BusinessCategory.food =>
            'Top-down on the set table, cutlery parallel. Then one straight-on '
                'of the entrance.',
          BusinessCategory.drinks =>
            'Center yourself on the longest bench row. Glass at dead center, '
                'hold still.',
          BusinessCategory.culture =>
            'Face the facade straight on and center it. Wait for one person '
                'to cross the frame.',
          BusinessCategory.market =>
            'One stall, front-on. Produce stacked, vendor centered.',
        },
      'kubrick' => switch (b.category) {
          BusinessCategory.cafe =>
            'Find the longest sightline inside. One-point perspective, slow '
                'push-in, no talking.',
          BusinessCategory.food =>
            'Shoot the arcade columns vanishing to a point. Hold the frame '
                'three seconds longer than feels right.',
          BusinessCategory.drinks =>
            'Use the tree rows as a corridor. Walk the center line, camera '
                'level, even steps.',
          BusinessCategory.culture =>
            'Center the doorway and push in slowly until the room fills the '
                'frame.',
          BusinessCategory.market =>
            'The central aisle at eye level, dead center. Let people pass '
                'through the frame.',
        },
      'doku' => switch (b.category) {
          BusinessCategory.cafe =>
            'Handheld: hands at work, steam, the first sip. Then record '
                'yourself, one take.',
          BusinessCategory.food =>
            'Film plates leaving the kitchen. Then say on tape what this '
                'food means here.',
          BusinessCategory.drinks =>
            'One wide of the crowd, one close of a glass. Record the '
                'background noise for ten seconds.',
          BusinessCategory.culture =>
            'Ten seconds of ambience before you speak. Then one honest '
                'observation.',
          BusinessCategory.market =>
            'Follow one ingredient from stall to stall. Record the vendors '
                'answering.',
        },
      _ => switch (b.category) {
          BusinessCategory.cafe =>
            'Hook in the first half second: pour or latte art hitting the '
                'table. Whip-pan to your reaction.',
          BusinessCategory.food =>
            'Food shot first, context later. Jump cuts, trend audio.',
          BusinessCategory.drinks =>
            'POV: glass raised into frame at golden hour. Cut on the clink, '
                'loop the ending.',
          BusinessCategory.culture =>
            'Doorway transition: outside/inside on one step. Save the best '
                'angle for the beat drop.',
          BusinessCategory.market =>
            'Run the tasting-basket challenge stall to stall, prices as text '
                'overlays.',
        },
    };

String _line(ScriptTemplate t, Business b) => switch (t.id) {
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
