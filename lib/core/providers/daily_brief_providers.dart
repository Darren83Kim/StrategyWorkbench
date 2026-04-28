import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';

class DailyBriefRiskHolding {
  final PortfolioItem item;
  final int? previousRank;

  const DailyBriefRiskHolding({
    required this.item,
    this.previousRank,
  });

  bool get recentlyExited => previousRank != null;
}

class DailyBriefMover {
  final SnapshotStock stock;
  final int change;

  const DailyBriefMover({
    required this.stock,
    required this.change,
  });

  bool get isUp => change > 0;
  int get absoluteChange => change.abs();
}

class DailyBrief {
  final SavedFilter strategy;
  final StrategySnapshot snapshot;
  final List<SnapshotStock> entered;
  final List<SnapshotStock> exited;
  final List<DailyBriefRiskHolding> riskHoldings;
  final List<SnapshotStock> topPicks;
  final List<DailyBriefMover> movers;

  const DailyBrief({
    required this.strategy,
    required this.snapshot,
    required this.entered,
    required this.exited,
    required this.riskHoldings,
    required this.topPicks,
    required this.movers,
  });

  bool get hasSignals =>
      entered.isNotEmpty ||
      exited.isNotEmpty ||
      riskHoldings.isNotEmpty ||
      movers.isNotEmpty;
}

final dailyBriefProvider = FutureProvider<DailyBrief?>((ref) async {
  final strategy = ref.watch(activeStrategyProvider);
  final portfolio = ref.watch(portfolioProvider);

  if (strategy == null) {
    return null;
  }

  final snapshot =
      await ref.watch(strategySnapshotProvider(strategy.name).future);

  return buildDailyBrief(
    strategy: strategy,
    snapshot: snapshot,
    portfolio: portfolio,
  );
});

DailyBrief buildDailyBrief({
  required SavedFilter strategy,
  required StrategySnapshot snapshot,
  required List<PortfolioItem> portfolio,
}) {
  final currentByTicker = {
    for (final stock in snapshot.current) stock.ticker.toUpperCase(): stock,
  };
  final previousByTicker = {
    for (final stock in snapshot.previous) stock.ticker.toUpperCase(): stock,
  };

  final entered = snapshot.current
      .where(
          (stock) => !previousByTicker.containsKey(stock.ticker.toUpperCase()))
      .toList();

  final exited = snapshot.previous
      .where(
          (stock) => !currentByTicker.containsKey(stock.ticker.toUpperCase()))
      .toList();

  final riskHoldings = portfolio
      .where((item) => !currentByTicker.containsKey(item.ticker.toUpperCase()))
      .map(
        (item) => DailyBriefRiskHolding(
          item: item,
          previousRank: previousByTicker[item.ticker.toUpperCase()]?.rank,
        ),
      )
      .toList()
    ..sort((a, b) {
      if (a.recentlyExited != b.recentlyExited) {
        return a.recentlyExited ? -1 : 1;
      }
      return a.item.ticker.compareTo(b.item.ticker);
    });

  final movers = snapshot.current
      .map((stock) {
        final change = snapshot.rankChange(stock.ticker);
        if (change == null || change == 0) {
          return null;
        }
        return DailyBriefMover(stock: stock, change: change);
      })
      .nonNulls
      .toList()
    ..sort((a, b) {
      final changeCompare = b.absoluteChange.compareTo(a.absoluteChange);
      if (changeCompare != 0) {
        return changeCompare;
      }
      return a.stock.rank.compareTo(b.stock.rank);
    });

  return DailyBrief(
    strategy: strategy,
    snapshot: snapshot,
    entered: entered,
    exited: exited,
    riskHoldings: riskHoldings,
    topPicks: snapshot.current.take(3).toList(),
    movers: movers.take(3).toList(),
  );
}
