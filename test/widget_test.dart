import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:strategy_workbench/main.dart';

void main() {
  testWidgets('DebugScreen loads and shows controls', (WidgetTester tester) async {
    // Build DebugScreen directly (MyApp now routes to /dashboard, not /debug)
    await tester.pumpWidget(
      const MaterialApp(
        home: DebugScreen(),
      ),
    );

    // Verify that DebugScreen title is shown and buttons exist.
    expect(find.text('Debug & Verification'), findsOneWidget);
    expect(find.text('Test Scoring Engine'), findsOneWidget);
    expect(find.text('Force Run Background Task'), findsOneWidget);
  });
}
