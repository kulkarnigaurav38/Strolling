import 'package:flutter_test/flutter_test.dart';

import 'package:strolling/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Role select screen shows brand and role options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StrollingApp());
    await tester.pumpAndSettle();

    expect(find.text('Strolling'), findsOneWidget);
    expect(find.text('Creator'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
  });
}
