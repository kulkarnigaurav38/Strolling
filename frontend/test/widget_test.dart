import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:strolling/main.dart';
import 'package:strolling/core/script_templates.dart';
import 'package:strolling/core/seed.dart';

void main() {
  testWidgets('app boots to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Portrait phone target (390×844 logical).
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: StrollingApp()));
    // One frame is enough; avoid pumpAndSettle (live animations never settle).
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Strolling'), findsOneWidget);
    expect(find.textContaining('Continue with Google'), findsOneWidget);
  });

  test('script templates weave perk deliverables into required actions', () {
    final stops = [businessById('brot-roesterei'), businessById('alte-kanzlei')];
    for (final template in kTemplates) {
      final script = template.generate(stops);
      expect(script, hasLength(2));
      // "1 photo + 1 story post" → photo AND video required.
      final coffee = script[0];
      expect(coffee.requiredActions.map((a) => a.kind.name).toSet(),
          {'photo', 'video'});
      expect(coffee.perkCallout, contains('2 free coffees'));
      // "1 reel + tag us" → video required.
      final lunch = script[1];
      expect(lunch.requiredActions.map((a) => a.kind.name).toSet(), {'video'});
      // Every scene ends in at least one capture action.
      for (final step in script) {
        expect(step.actions, isNotEmpty);
      }
    }
  });
}
