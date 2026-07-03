import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/rebalance_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';

void main() {
  test(
      'buildRebalanceCoach identifies outside holdings, missing picks and trim candidates',
      () {
    final coach = buildRebalanceCoach(
      strategy: SavedFilter(
        name: '가치주',
        weights: const {'per': 0.7, 'roe': 0.3},
        topN: 10,
      ),
      snapshot: const StrategySnapshot(
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
            score: 87,
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
      portfolio: const [
        PortfolioItem(
          ticker: 'AAPL',
          name: 'Apple',
          quantity: 2,
          avgPrice: 150,
          currentPrice: 190,
        ),
        PortfolioItem(
          ticker: 'IBM',
          name: 'IBM',
          quantity: 1,
          avgPrice: 120,
          currentPrice: 125,
        ),
      ],
    );

    expect(coach.holdingsOutsideStrategy.map((item) => item.ticker), ['IBM']);
    expect(
        coach.missingTopPicks.map((stock) => stock.ticker), ['MSFT', 'NVDA']);
    expect(coach.overweightHoldings.map((weighted) => weighted.item.ticker),
        ['AAPL']);
    expect(
      coach.suggestions.map((suggestion) => suggestion.type),
      [
        RebalanceSuggestionType.review,
        RebalanceSuggestionType.trim,
        RebalanceSuggestionType.add,
        RebalanceSuggestionType.add,
      ],
    );
    expect(coach.suggestions.first.headline, 'IBM 점검');
    expect(coach.suggestions[1].reason, contains('비중'));
    expect(coach.suggestions[2].headline, 'Microsoft 편입 후보');
  });
}
