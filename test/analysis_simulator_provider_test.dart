import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/analysis_simulator_providers.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  final now = DateTime(2026, 7, 10);
  final stocks = [
    Stock(
      ticker: 'AAA',
      name: 'Low PER',
      price: 100,
      per: 5,
      roe: 5,
      dividendYield: 1,
      lastUpdated: now,
    ),
    Stock(
      ticker: 'BBB',
      name: 'High ROE',
      price: 200,
      per: 20,
      roe: 30,
      dividendYield: 1,
      lastUpdated: now,
    ),
    Stock(
      ticker: 'CCC',
      name: 'Balanced',
      price: 150,
      per: 10,
      roe: 10,
      dividendYield: 5,
      lastUpdated: now,
    ),
  ];

  test('normalizes positive analysis weights', () {
    final weights = normalizeAnalysisWeights({
      'per': 20,
      'roe': 30,
      'dividend': 50,
      'ignored': 0,
    });

    expect(weights['per'], closeTo(0.2, 0.0001));
    expect(weights['roe'], closeTo(0.3, 0.0001));
    expect(weights['dividend'], closeTo(0.5, 0.0001));
    expect(weights.containsKey('ignored'), isFalse);
  });

  test('compares baseline and simulated ranks without saving a strategy', () {
    final result = buildAnalysisSimulation(
      stocks: stocks,
      strategy: SavedFilter(
        name: 'PER 기준',
        weights: const {'per': 1},
        topN: 2,
      ),
      simulatedWeights: const {'roe': 1},
      sampleCount: 2,
    );

    expect(result.overlapCount, 1);
    expect(result.enteredCount, 1);
    expect(result.exitedCount, 1);
    expect(result.simulatedTop.first.ticker, 'BBB');
    expect(result.simulatedTop.first.baselineRank, 3);
    expect(result.simulatedTop.first.simulatedRank, 1);
    expect(result.simulatedTop.first.rankChange, 2);
    expect(result.biggestMovers.first.ticker, 'BBB');
    expect(result.simulatedWeights, {'roe': 1.0});
  });
}
