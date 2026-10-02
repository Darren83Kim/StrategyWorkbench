import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/features/learning/presentation/metric_dictionary_screen.dart';

void main() {
  testWidgets('metric dictionary explains core indicators', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MetricDictionaryScreen(),
      ),
    );

    expect(find.text('지표 사전'), findsOneWidget);
    expect(find.text('분석 기준을 읽는 작은 사전'), findsOneWidget);
    expect(find.text('PER'), findsOneWidget);
    expect(find.text('ROE'), findsOneWidget);
    expect(find.text('배당수익률'), findsOneWidget);

    await tester.tap(find.text('PER'));
    await tester.pumpAndSettle();

    expect(find.text('의미'), findsOneWidget);
    expect(find.textContaining('주가가 이익 대비'), findsOneWidget);
    expect(find.textContaining('매수/매도 권유가 아닙니다'), findsOneWidget);
  });
}
