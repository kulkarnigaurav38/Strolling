import 'models.dart';

// Business + shot list, ported verbatim from the brief's lib/seed.ts.

class Business {
  final String slug;
  final String name;
  final String venue;
  final String incentive;
  final String vibe;
  final String style;

  const Business({
    required this.slug,
    required this.name,
    required this.venue,
    required this.incentive,
    required this.vibe,
    required this.style,
  });

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'venue': venue,
        'incentive': incentive,
        'vibe': vibe,
        'style': style,
      };
}

const kBusiness = Business(
  slug: 'cursor-stuttgart',
  name: 'Cursor Hackathon Stuttgart',
  venue: 'Infomotion · Friedrichstr. 6, 70174 Stuttgart · 4th floor',
  incentive: '🍹 Free drink at the bar — show your finished video',
  vibe:
      'AI hackathon, 60 builders, laptops everywhere, sponsor stickers, city view',
  style: 'energetic mini-doc, warm colors, quick cuts, authentic not polished',
);

const kFallbackTasks = <Task>[
  Task(
    id: 't1',
    order: 1,
    type: TaskType.photo,
    title: '📸 The entrance',
    instruction: 'Sign or door at Friedrichstr. 6, low angle, logo sharp.',
    suggestedLine: 'So this is where 60 people are building for one day…',
  ),
  Task(
    id: 't2',
    order: 2,
    type: TaskType.clip,
    title: '🎬 The floor (2–3s)',
    instruction: 'Slow pan across the hacking floor — laptops, teams, energy.',
    suggestedLine: 'The energy in here is honestly unreal.',
  ),
  Task(
    id: 't3',
    order: 3,
    type: TaskType.photo,
    title: '📸 Mid-build moment',
    instruction: "Over someone's shoulder: Cursor open, code flowing.",
    suggestedLine: 'Everyone here is shipping something today.',
  ),
  Task(
    id: 't4',
    order: 4,
    type: TaskType.clip,
    title: '🎬 The incentive (2–3s)',
    instruction: 'The drinks / coffee moment — the reward in frame.',
    suggestedLine: 'And yes — this video literally pays for my drink.',
  ),
  Task(
    id: 't5',
    order: 5,
    type: TaskType.photo,
    title: '📸 The closer',
    instruction: '4th-floor window view or a team selfie mid-pitch.',
    suggestedLine: "If you're wondering whether to come next time — come.",
  ),
];
