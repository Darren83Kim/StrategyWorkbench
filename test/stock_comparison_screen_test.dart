import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/features/learning/presentation/stock_comparison_screen.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows a mixed-market stock comparison report', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 7, 10);
    final stocks = [
      Stock(
        ticker: '000660',
        name: 'SK하이닉스',
        price: 250000,
        per: 12,
        roe: 30,
        dividendYield: 1,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'AAPL',
        name: 'Apple Inc.',
        price: 220,
        per: 28,
        roe: 45,
        dividendYield: 0.5,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'MSFT',
        name: 'Microsoft',
        price: 420,
        per: 35,
        roe: 38,
        dividendYield: 0.8,
        lastUpdated: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => stocks),
        ],
        child: const MaterialApp(
          home: StockComparisonScreen(
            initialSymbols: ['000660', 'AAPL'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('종목 지표 비교'), findsOneWidget);
    expect(find.text('선택 2/3'), findsOneWidget);
    expect(find.text('비교 리포트'), findsOneWidget);
    expect(find.text('정규화 지표 차트'), findsOneWidget);
    expect(find.textContaining('가격 우열은 계산하지 않습니다.'), findsOneWidget);
    expect(find.textContaining('매수·매도를 권유하지 않습니다.'), findsOneWidget);
    expect(find.text('SK하이닉스'), findsWidgets);
    expect(find.text('Apple Inc.'), findsWidgets);
  });
}
