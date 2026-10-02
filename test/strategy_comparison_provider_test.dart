import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/strategy_comparison_providers.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  test('buildStrategyComparison summarizes overlap and unique stocks', () {
    final comparison = buildStrategyComparison(
      leftStrategy: SavedFilter(
        name: '가치주',
        weights: const {'per': 0.7, 'roe': 0.3},
        topN: 10,
      ),
      rightStrategy: SavedFilter(
        name: '배당주',
        weights: const {'per': 0.2, 'roe': 0.2, 'dividend': 0.6},
        topN: 10,
      ),
      leftSnapshot: const StrategySnapshot(
        date: '2026-04-21',
        current: [
          SnapshotStock(
            ticker: 'AAPL',
            name: 'Apple',
            price: 190,
            score: 92,
            rank: 1,
          ),
          SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 410,
            score: 88,
            rank: 2,
          ),
          SnapshotStock(
            ticker: 'NVDA',
            name: 'NVIDIA',
            price: 920,
            score: 85,
            rank: 3,
          ),
        ],
      ),
      rightSnapshot: const StrategySnapshot(
        date: '2026-04-21',
        current: [
          SnapshotStock(
            ticker: 'AAPL',
            name: 'Apple',
            price: 190,
            score: 76,
            rank: 3,
          ),
          SnapshotStock(
            ticker: 'KO',
            name: 'Coca-Cola',
            price: 61,
            score: 81,
            rank: 1,
          ),
          SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 410,
            score: 75,
            rank: 5,
          ),
        ],
      ),
      universe: [
        Stock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 190,
          per: 25,
          roe: 35,
          dividendYield: 0.5,
          lastUpdated: DateTime(2026, 4, 21),
        ),
        Stock(
          ticker: 'MSFT',
          name: 'Microsoft',
          price: 410,
          per: 30,
          roe: 30,
          dividendYield: 1,
          lastUpdated: DateTime(2026, 4, 21),
        ),
        Stock(
          ticker: 'NVDA',
          name: 'NVIDIA',
          price: 920,
          per: 40,
          roe: 45,
          dividendYield: 0,
          lastUpdated: DateTime(2026, 4, 21),
        ),
        Stock(
          ticker: 'KO',
          name: 'Coca-Cola',
          price: 61,
          per: 20,
          roe: 20,
          dividendYield: 3,
          lastUpdated: DateTime(2026, 4, 21),
        ),
      ],
    );

    expect(comparison.overlap.map((match) => match.ticker), ['AAPL', 'MSFT']);
    expect(comparison.onlyLeft.map((stock) => stock.ticker), ['NVDA']);
    expect(comparison.onlyRight.map((stock) => stock.ticker), ['KO']);
    expect(comparison.topRankDiffs.first.ticker, 'MSFT');
    expect(comparison.topRankDiffs.first.absoluteRankGap, 3);
    expect(comparison.headline, contains('공통'));
    expect(comparison.summary, contains('가치주'));
    expect(comparison.leftFocusLabel, 'PER');
    expect(comparison.rightFocusLabel, '배당');
    expect(comparison.weightDeltas.first.label, '배당');
    expect(comparison.overlap.first.leftContributions, isNotEmpty);
    expect(comparison.overlap.first.rightContributions, isNotEmpty);
    expect(comparison.observations.map((item) => item.title), [
      '공통 샘플',
      '기준별 차이',
      '순위 민감도',
    ]);
  });
}
