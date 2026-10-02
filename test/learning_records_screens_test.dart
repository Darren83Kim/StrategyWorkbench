import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/features/learning/presentation/analysis_history_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/observation_notes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('observation notes screen shows locally stored note',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      observationNotesStorageKey: jsonEncode({
        'AAPL': {
          'ticker': 'AAPL',
          'name': 'Apple Inc.',
          'text': 'ROE 데이터 갱신 여부 다시 확인',
          'tags': ['ROE', '데이터'],
          'updatedAt': '2026-07-10T12:00:00.000',
        },
      }),
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ObservationNotesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('관찰 메모'), findsOneWidget);
    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.text('ROE 데이터 갱신 여부 다시 확인'), findsOneWidget);
    expect(find.textContaining('이 기기에만 저장'), findsOneWidget);
  });

  testWidgets('analysis history screen shows weights and saved samples',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      analysisHistoryStorageKey: jsonEncode([
        {
          'id': 'history-1',
          'strategyName': '가치주 기준 실험',
          'marketFilter': 'hybrid',
          'weights': {'per': 0.6, 'roe': 0.3, 'dividend': 0.1},
          'topSamples': [
            {'ticker': 'AAPL', 'name': 'Apple Inc.', 'rank': 1},
          ],
          'createdAt': '2026-07-10T12:00:00.000',
        },
      ]),
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AnalysisHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('실험 기록'), findsOneWidget);
    expect(find.text('가치주 기준 실험'), findsOneWidget);

    await tester.tap(find.text('가치주 기준 실험'));
    await tester.pumpAndSettle();

    expect(find.text('PER 60%'), findsOneWidget);
    expect(find.text('Apple Inc.'), findsOneWidget);
    expect(find.textContaining('최근 20개'), findsOneWidget);
  });
}
