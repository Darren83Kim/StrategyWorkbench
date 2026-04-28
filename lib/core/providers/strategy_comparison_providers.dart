import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';

class StrategyComparisonRequest {
  final String leftStrategyName;
  final String rightStrategyName;

  const StrategyComparisonRequest({
    required this.leftStrategyName,
    required this.rightStrategyName,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StrategyComparisonRequest &&
            other.leftStrategyName == leftStrategyName &&
            other.rightStrategyName == rightStrategyName;
  }

  @override
  int get hashCode => Object.hash(leftStrategyName, rightStrategyName);
}

class StrategyComparisonMatch {
  final SnapshotStock leftStock;
  final SnapshotStock rightStock;

  const StrategyComparisonMatch({
    required this.leftStock,
    required this.rightStock,
  });

  String get ticker => leftStock.ticker;
  String get name => leftStock.name;
  int get rankGap => leftStock.rank - rightStock.rank;
  int get absoluteRankGap => rankGap.abs();
}

class StrategyComparisonViewModel {
  final SavedFilter leftStrategy;
  final SavedFilter rightStrategy;
  final List<StrategyComparisonMatch> overlap;
  final List<SnapshotStock> onlyLeft;
  final List<SnapshotStock> onlyRight;
  final List<StrategyComparisonMatch> topRankDiffs;

  const StrategyComparisonViewModel({
    required this.leftStrategy,
    required this.rightStrategy,
    required this.overlap,
    required this.onlyLeft,
    required this.onlyRight,
    required this.topRankDiffs,
  });
}

final strategyComparisonProvider = FutureProvider.autoDispose
    .family<StrategyComparisonViewModel?, StrategyComparisonRequest>(
  (ref, request) async {
    if (request.leftStrategyName == request.rightStrategyName) {
      return null;
    }

    final strategies = ref.watch(allStrategiesProvider);
    final leftStrategy = strategies
        .where((strategy) => strategy.name == request.leftStrategyName)
        .firstOrNull;
    final rightStrategy = strategies
        .where((strategy) => strategy.name == request.rightStrategyName)
        .firstOrNull;

    if (leftStrategy == null || rightStrategy == null) {
      return null;
    }

    final leftSnapshot = await ref.watch(
      strategySnapshotProvider(leftStrategy.name).future,
    );
    final rightSnapshot = await ref.watch(
      strategySnapshotProvider(rightStrategy.name).future,
    );

    return buildStrategyComparison(
      leftStrategy: leftStrategy,
      rightStrategy: rightStrategy,
      leftSnapshot: leftSnapshot,
      rightSnapshot: rightSnapshot,
    );
  },
);

StrategyComparisonViewModel buildStrategyComparison({
  required SavedFilter leftStrategy,
  required SavedFilter rightStrategy,
  required StrategySnapshot leftSnapshot,
  required StrategySnapshot rightSnapshot,
}) {
  final leftByTicker = {
    for (final stock in leftSnapshot.current) stock.ticker.toUpperCase(): stock,
  };
  final rightByTicker = {
    for (final stock in rightSnapshot.current)
      stock.ticker.toUpperCase(): stock,
  };

  final overlap = leftSnapshot.current
      .where((stock) => rightByTicker.containsKey(stock.ticker.toUpperCase()))
      .map(
        (stock) => StrategyComparisonMatch(
          leftStock: stock,
          rightStock: rightByTicker[stock.ticker.toUpperCase()]!,
        ),
      )
      .toList()
    ..sort((a, b) => a.leftStock.rank.compareTo(b.leftStock.rank));

  final onlyLeft = leftSnapshot.current
      .where((stock) => !rightByTicker.containsKey(stock.ticker.toUpperCase()))
      .toList();

  final onlyRight = rightSnapshot.current
      .where((stock) => !leftByTicker.containsKey(stock.ticker.toUpperCase()))
      .toList();

  final topRankDiffs = [...overlap]..sort((a, b) {
      final gapCompare = b.absoluteRankGap.compareTo(a.absoluteRankGap);
      if (gapCompare != 0) {
        return gapCompare;
      }
      return a.leftStock.rank.compareTo(b.leftStock.rank);
    });

  return StrategyComparisonViewModel(
    leftStrategy: leftStrategy,
    rightStrategy: rightStrategy,
    overlap: overlap,
    onlyLeft: onlyLeft,
    onlyRight: onlyRight,
    topRankDiffs: topRankDiffs.take(5).toList(),
  );
}
