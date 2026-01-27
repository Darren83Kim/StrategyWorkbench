// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:strategy_workbench/main.dart';

void main() {
  testWidgets('DebugScreen loads and shows controls', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that DebugScreen title is shown and buttons exist.
    expect(find.text('Debug & Verification'), findsOneWidget);
    expect(find.text('Test Scoring Engine'), findsOneWidget);
    expect(find.text('Force Run Background Task'), findsOneWidget);
  });
}
