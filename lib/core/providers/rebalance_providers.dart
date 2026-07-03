import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';

enum RebalanceSuggestionType {
  review,
  add,
  trim,
}

class WeightedPortfolioItem {
  final PortfolioItem item;
  final double portfolioWeight;

  const WeightedPortfolioItem({
    required this.item,
    required this.portfolioWeight,
  });
}

class RebalanceSuggestion {
  final RebalanceSuggestionType type;
  final String ticker;
  final String headline;
  final String reason;
  final String supportingLabel;

  const RebalanceSuggestion({
    required this.type,
    required this.ticker,
    required this.headline,
    required this.reason,
    required this.supportingLabel,
  });
}

class RebalanceCoach {
  final SavedFilter strategy;
  final List<PortfolioItem> holdingsOutsideStrategy;
  final List<SnapshotStock> missingTopPicks;
  final List<WeightedPortfolioItem> overweightHoldings;
  final List<RebalanceSuggestion> suggestions;

  const RebalanceCoach({
    required this.strategy,
    required this.holdingsOutsideStrategy,
    required this.missingTopPicks,
    required this.overweightHoldings,
    required this.suggestions,
  });

  bool get isAligned => suggestions.isEmpty;
}

final rebalanceCoachProvider = FutureProvider<RebalanceCoach?>((ref) async {
  final strategy = ref.watch(activeStrategyProvider);
  final portfolio = ref.watch(portfolioProvider);

  if (strategy == null) {
    return null;
  }

  final snapshot =
      await ref.watch(strategySnapshotProvider(strategy.name).future);

  return buildRebalanceCoach(
    strategy: strategy,
    snapshot: snapshot,
    portfolio: portfolio,
  );
});

RebalanceCoach buildRebalanceCoach({
  required SavedFilter strategy,
  required StrategySnapshot snapshot,
  required List<PortfolioItem> portfolio,
}) {
  final currentTickers = {
    for (final stock in snapshot.current) stock.ticker.toUpperCase(): stock,
  };
  final portfolioByTicker = {
    for (final item in portfolio) item.ticker.toUpperCase(): item,
  };
  final totalValue =
      portfolio.fold<double>(0, (sum, item) => sum + item.currentValue);

  final holdingsOutsideStrategy = portfolio
      .where((item) => !currentTickers.containsKey(item.ticker.toUpperCase()))
      .toList();

  final missingTopPicks = snapshot.current
      .where(
          (stock) => !portfolioByTicker.containsKey(stock.ticker.toUpperCase()))
      .take(3)
      .toList();

  final overweightThreshold = _calculateOverweightThreshold(portfolio.length);
  final overweightHoldings = totalValue <= 0
      ? <WeightedPortfolioItem>[]
      : portfolio
          .map(
            (item) => WeightedPortfolioItem(
              item: item,
              portfolioWeight: item.currentValue / totalValue,
            ),
          )
          .where((weighted) => weighted.portfolioWeight >= overweightThreshold)
          .toList()
    ..sort(
      (a, b) => b.portfolioWeight.compareTo(a.portfolioWeight),
    );

  final suggestions = <RebalanceSuggestion>[
    ...holdingsOutsideStrategy.take(2).map(
          (item) => RebalanceSuggestion(
            type: RebalanceSuggestionType.review,
            ticker: item.ticker,
            headline: '${resolveInstrumentName(item.ticker, item.name)} 점검',
            reason: '현재 활성 전략 Top ${strategy.topN} 밖에 있어 보유 이유를 다시 확인할 시점입니다.',
            supportingLabel:
                '보유 ${item.quantity.toStringAsFixed(0)}주 · \$${item.currentValue.toStringAsFixed(2)}',
          ),
        ),
    ...overweightHoldings.take(2).map(
          (weighted) => RebalanceSuggestion(
            type: RebalanceSuggestionType.trim,
            ticker: weighted.item.ticker,
            headline:
                '${resolveInstrumentName(weighted.item.ticker, weighted.item.name)} 비중 점검',
            reason:
                '포트폴리오 비중 ${(weighted.portfolioWeight * 100).toStringAsFixed(0)}%로 집중도가 높습니다.',
            supportingLabel:
                '현재가 \$${weighted.item.currentPrice.toStringAsFixed(2)}',
          ),
        ),
    ...missingTopPicks.take(2).map(
          (stock) => RebalanceSuggestion(
            type: RebalanceSuggestionType.add,
            ticker: stock.ticker,
            headline:
                '${resolveInstrumentName(stock.ticker, stock.name)} 편입 후보',
            reason: '활성 전략에서 #${stock.rank}에 올라 있지만 아직 보유하고 있지 않습니다.',
            supportingLabel: '전략 점수 ${stock.score.toStringAsFixed(1)}',
          ),
        ),
  ];

  return RebalanceCoach(
    strategy: strategy,
    holdingsOutsideStrategy: holdingsOutsideStrategy,
    missingTopPicks: missingTopPicks,
    overweightHoldings: overweightHoldings,
    suggestions: suggestions,
  );
}

double _calculateOverweightThreshold(int holdingsCount) {
  if (holdingsCount <= 1) {
    return double.infinity;
  }

  final equalWeight = 1 / holdingsCount;
  return (equalWeight * 1.8).clamp(0.35, 0.55);
}
