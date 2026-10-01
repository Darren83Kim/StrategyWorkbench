import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/stock_comparison_providers.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  test('builds a three-stock metric report without comparing prices', () {
    final now = DateTime(2026, 7, 10);
    final universe = [
      Stock(
        ticker: '000001',
        name: '국내 샘플',
        price: 10000,
        per: 5,
        roe: 8,
        dividendYield: 1,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'AAPL',
        name: 'Apple',
        price: 200,
        per: 25,
        roe: 35,
        dividendYield: 0.5,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'MSFT',
        name: 'Microsoft',
        price: 400,
        per: 15,
        roe: 20,
        dividendYield: 2,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'NVDA',
        name: 'NVIDIA',
        price: 150,
        per: 40,
        roe: 50,
        dividendYield: 0,
        lastUpdated: now,
      ),
    ];

    final report = buildStockComparisonReport(
      universe: universe,
      symbols: const ['000001', 'AAPL', 'MSFT', 'NVDA'],
      strategy: SavedFilter(
        name: '퀀트',
        weights: const {'per': 0.34, 'roe': 0.33, 'dividend': 0.33},
      ),
    );

    expect(report, isNotNull);
    expect(report!.items.map((item) => item.stock.ticker), [
      '000001',
      'AAPL',
      'MSFT',
    ]);
    expect(report.hasMixedMarkets, isTrue);
    expect(report.items.first.normalizedScores.keys, [
      'per',
      'roe',
      'dividend',
    ]);
    expect(report.items.first.contributions['per'], greaterThan(0));
    expect(report.headline, contains('축'));
  });

  test('requires at least two known stocks', () {
    final report = buildStockComparisonReport(
      universe: [
        Stock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 200,
          per: 20,
          roe: 30,
          dividendYield: 1,
          lastUpdated: DateTime(2026, 7, 10),
        ),
      ],
      symbols: const ['AAPL', 'UNKNOWN'],
      strategy: SavedFilter(
        name: '가치주',
        weights: const {'per': 0.7, 'roe': 0.3},
      ),
    );

    expect(report, isNull);
  });
}
