// Smoke test for the example app's home menu. The AR demo screens require a
// physical device and are not driven here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ar_flutter_plugin_2_example/main.dart';

void main() {
  testWidgets('home menu lists the demos', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    // App bar and the first (on-screen) demo.
    expect(find.text('AR Flutter Plugin'), findsOneWidget);
    expect(find.text('Objects on planes'), findsOneWidget);

    // The list is lazy, so scroll the last entry into view to confirm it exists.
    await tester.scrollUntilVisible(
      find.text('External model management'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('External model management'), findsOneWidget);
  });
}
