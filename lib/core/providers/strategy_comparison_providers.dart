import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/scoring/scoring_engine.dart';
import 'package:strategy_workbench/features/market/models/stock.dart'
    as market_stock;
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

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
  final Map<String, double> leftContributions;
  final Map<String, double> rightContributions;

  const StrategyComparisonMatch({
    required this.leftStock,
    required this.rightStock,
    this.leftContributions = const {},
    this.rightContributions = const {},
  });

  String get ticker => leftStock.ticker;
  String get name => leftStock.name;
  int get rankGap => leftStock.rank - rightStock.rank;
  int get absoluteRankGap => rankGap.abs();

  String get largestContributionGapMetric {
    const keys = ['per', 'roe', 'dividend'];
    return keys.reduce((left, right) {
      final leftGap =
          ((leftContributions[left] ?? 0) - (rightContributions[left] ?? 0))
              .abs();
      final rightGap =
          ((leftContributions[right] ?? 0) - (rightContributions[right] ?? 0))
              .abs();
      return rightGap > leftGap ? right : left;
    });
  }
}

class StrategyWeightDelta {
  final String metricKey;
  final String label;
  final double leftWeight;
  final double rightWeight;

  const StrategyWeightDelta({
    required this.metricKey,
    required this.label,
    required this.leftWeight,
    required this.rightWeight,
  });

  double get absoluteGap => (leftWeight - rightWeight).abs();
}

class StrategyComparisonObservation {
  final String title;
  final String body;

  const StrategyComparisonObservation({
    required this.title,
    required this.body,
  });
}

class StrategyComparisonViewModel {
  final SavedFilter leftStrategy;
  final SavedFilter rightStrategy;
  final String headline;
  final String summary;
  final String leftFocusLabel;
  final String rightFocusLabel;
  final List<StrategyComparisonMatch> overlap;
  final List<SnapshotStock> onlyLeft;
  final List<SnapshotStock> onlyRight;
  final List<StrategyComparisonMatch> topRankDiffs;
  final List<StrategyComparisonObservation> observations;
  final List<StrategyWeightDelta> weightDeltas;

  const StrategyComparisonViewModel({
    required this.leftStrategy,
    required this.rightStrategy,
    this.headline = '',
    this.summary = '',
    this.leftFocusLabel = '',
    this.rightFocusLabel = '',
    required this.overlap,
    required this.onlyLeft,
    required this.onlyRight,
    required this.topRankDiffs,
    this.observations = const [],
    this.weightDeltas = const [],
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
    List<Stock> universe = const [];
    try {
      universe = await ref.watch(allStocksForSnapshotProvider.future);
    } catch (_) {
      // Snapshot-only comparison still works when the full universe is absent.
    }

    return buildStrategyComparison(
      leftStrategy: leftStrategy,
      rightStrategy: rightStrategy,
      leftSnapshot: leftSnapshot,
      rightSnapshot: rightSnapshot,
      universe: universe,
    );
  },
);

StrategyComparisonViewModel buildStrategyComparison({
  required SavedFilter leftStrategy,
  required SavedFilter rightStrategy,
  required StrategySnapshot leftSnapshot,
  required StrategySnapshot rightSnapshot,
  List<Stock> universe = const [],
}) {
  final leftByTicker = {
    for (final stock in leftSnapshot.current) stock.ticker.toUpperCase(): stock,
  };
  final rightByTicker = {
    for (final stock in rightSnapshot.current)
      stock.ticker.toUpperCase(): stock,
  };

  final leftContributions = _buildContributionMap(
    universe: universe,
    strategy: leftStrategy,
  );
  final rightContributions = _buildContributionMap(
    universe: universe,
    strategy: rightStrategy,
  );

  final overlap = leftSnapshot.current
      .where((stock) => rightByTicker.containsKey(stock.ticker.toUpperCase()))
      .map(
        (stock) => StrategyComparisonMatch(
          leftStock: stock,
          rightStock: rightByTicker[stock.ticker.toUpperCase()]!,
          leftContributions:
              leftContributions[stock.ticker.toUpperCase()] ?? const {},
          rightContributions:
              rightContributions[stock.ticker.toUpperCase()] ?? const {},
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

  final leftFocusLabel = _dominantMetricLabel(leftStrategy);
  final rightFocusLabel = _dominantMetricLabel(rightStrategy);
  final strongestGap = topRankDiffs.firstOrNull;

  return StrategyComparisonViewModel(
    leftStrategy: leftStrategy,
    rightStrategy: rightStrategy,
    headline: _buildComparisonHeadline(
      overlapCount: overlap.length,
      leftTopN: leftStrategy.topN,
      rightTopN: rightStrategy.topN,
    ),
    summary: _buildComparisonSummary(
      leftStrategy: leftStrategy,
      rightStrategy: rightStrategy,
      leftFocusLabel: leftFocusLabel,
      rightFocusLabel: rightFocusLabel,
      overlapCount: overlap.length,
    ),
    leftFocusLabel: leftFocusLabel,
    rightFocusLabel: rightFocusLabel,
    overlap: overlap,
    onlyLeft: onlyLeft,
    onlyRight: onlyRight,
    topRankDiffs: topRankDiffs.take(5).toList(),
    weightDeltas: _buildWeightDeltas(leftStrategy, rightStrategy),
    observations: _buildComparisonObservations(
      leftStrategy: leftStrategy,
      rightStrategy: rightStrategy,
      overlapCount: overlap.length,
      onlyLeft: onlyLeft,
      onlyRight: onlyRight,
      strongestGap: strongestGap,
    ),
  );
}

List<StrategyWeightDelta> _buildWeightDeltas(
  SavedFilter leftStrategy,
  SavedFilter rightStrategy,
) {
  const labels = {'per': 'PER', 'roe': 'ROE', 'dividend': '배당'};
  final deltas = labels.entries
      .map(
        (entry) => StrategyWeightDelta(
          metricKey: entry.key,
          label: entry.value,
          leftWeight: leftStrategy.weights[entry.key] ?? 0,
          rightWeight: rightStrategy.weights[entry.key] ?? 0,
        ),
      )
      .toList()
    ..sort((a, b) => b.absoluteGap.compareTo(a.absoluteGap));
  return deltas;
}

Map<String, Map<String, double>> _buildContributionMap({
  required List<Stock> universe,
  required SavedFilter strategy,
}) {
  if (universe.isEmpty) {
    return const {};
  }

  final marketStocks = universe
      .map(
        (stock) => market_stock.Stock(
          symbol: stock.ticker,
          name: stock.name,
          price: stock.price,
          change: 0,
          per: stock.per,
          roe: stock.roe,
          dividendYield: stock.dividendYield,
        ),
      )
      .toList();
  final scored = ScoringEngine().calculateScores(
    stocks: marketStocks,
    weights: strategy.weights,
  );

  return {
    for (final item in scored)
      item.stock.symbol.toUpperCase(): {
        for (final key in ['per', 'roe', 'dividend'])
          key: (item.normalizedScores[key] ?? 0) * (strategy.weights[key] ?? 0),
      },
  };
}

String _buildComparisonHeadline({
  required int overlapCount,
  required int leftTopN,
  required int rightTopN,
}) {
  if (overlapCount == 0) {
    return '두 기준이 서로 다른 샘플군을 보여줍니다.';
  }

  final denominator = leftTopN < rightTopN ? leftTopN : rightTopN;
  final ratio = denominator == 0 ? 0 : overlapCount / denominator;
  if (ratio >= 0.6) {
    return '두 기준이 비슷한 상위 샘플을 가리킵니다.';
  }
  if (ratio >= 0.3) {
    return '일부 샘플은 겹치지만 기준별 차이가 보입니다.';
  }
  return '공통 샘플이 적어 기준 차이가 뚜렷합니다.';
}

String _buildComparisonSummary({
  required SavedFilter leftStrategy,
  required SavedFilter rightStrategy,
  required String leftFocusLabel,
  required String rightFocusLabel,
  required int overlapCount,
}) {
  if (leftFocusLabel == rightFocusLabel) {
    return '${leftStrategy.name}와 ${rightStrategy.name} 모두 $leftFocusLabel 축을 중심으로 보지만, 가중치 조합에 따라 상위 샘플이 다르게 정렬됩니다.';
  }

  return '${leftStrategy.name}는 $leftFocusLabel, ${rightStrategy.name}는 $rightFocusLabel 축을 더 크게 보므로 공통 $overlapCount개 외의 차이를 비교해 볼 수 있습니다.';
}

List<StrategyComparisonObservation> _buildComparisonObservations({
  required SavedFilter leftStrategy,
  required SavedFilter rightStrategy,
  required int overlapCount,
  required List<SnapshotStock> onlyLeft,
  required List<SnapshotStock> onlyRight,
  required StrategyComparisonMatch? strongestGap,
}) {
  final observations = <StrategyComparisonObservation>[
    StrategyComparisonObservation(
      title: '공통 샘플',
      body: overlapCount == 0
          ? '상위 구간에서 겹치는 종목이 없어 두 기준을 독립적으로 살펴볼 수 있습니다.'
          : '두 기준 모두에서 상위권에 남은 샘플이 $overlapCount개 있습니다.',
    ),
    StrategyComparisonObservation(
      title: '기준별 차이',
      body:
          '${leftStrategy.name} 전용 ${onlyLeft.length}개, ${rightStrategy.name} 전용 ${onlyRight.length}개가 있어 가중치가 결과에 주는 영향을 볼 수 있습니다.',
    ),
  ];

  if (strongestGap != null) {
    observations.add(
      StrategyComparisonObservation(
        title: '순위 민감도',
        body:
            '${strongestGap.name}은 두 기준 사이에서 ${strongestGap.absoluteRankGap}계단 차이가 납니다.',
      ),
    );
  } else {
    observations.add(
      const StrategyComparisonObservation(
        title: '순위 민감도',
        body: '공통 샘플이 생기면 기준별 순위 차이를 여기서 확인할 수 있습니다.',
      ),
    );
  }

  return observations;
}

String _dominantMetricLabel(SavedFilter strategy) {
  if (strategy.weights.isEmpty) {
    return '복합 지표';
  }

  final dominant = strategy.weights.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  switch (dominant.first.key) {
    case 'per':
      return 'PER';
    case 'roe':
      return 'ROE';
    case 'dividend':
      return '배당';
    default:
      return dominant.first.key.toUpperCase();
  }
}
