import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fernweh/main.dart';

void main() {
  testWidgets('app boots to the brief screen', (tester) async {
    // Portrait phone target (390×844 logical).
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: FernwehApp()));
    // One frame is enough; avoid pumpAndSettle (live animations never settle).
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.text(
          'Walk in. Talk for 20 minutes. Walk out with a published video.'),
      findsOneWidget,
    );
  });
}
