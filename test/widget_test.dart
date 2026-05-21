// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen/main.dart';

void main() {
  testWidgets('Onboarding and Discover navigation smoke test', (WidgetTester tester) async {
    // Set a realistic viewport size to prevent RenderFlex overflow issues in the test
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const HypenApp());

    // Verify that onboarding screen shows the logo and slides.
    expect(find.text('HYPEN.'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);

    // Tap the 'Discover' button to go to HomePage.
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    // Verify that we are on the HomePage (e.g. verify home bottom bar items exist or home content is visible).
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Hot Items'), findsOneWidget);
  });
}
