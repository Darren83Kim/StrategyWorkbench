import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/strategy_comparison_providers.dart';

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
    );

    expect(comparison.overlap.map((match) => match.ticker), ['AAPL', 'MSFT']);
    expect(comparison.onlyLeft.map((stock) => stock.ticker), ['NVDA']);
    expect(comparison.onlyRight.map((stock) => stock.ticker), ['KO']);
    expect(comparison.topRankDiffs.first.ticker, 'MSFT');
    expect(comparison.topRankDiffs.first.absoluteRankGap, 3);
  });
}
