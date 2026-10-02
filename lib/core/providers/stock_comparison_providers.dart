import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/scoring/scoring_engine.dart';
import 'package:strategy_workbench/features/market/models/stock.dart'
    as market_stock;
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

const comparisonMetricKeys = ['per', 'roe', 'dividend'];

String comparisonMetricLabel(String key) {
  switch (key) {
    case 'per':
      return 'PER';
    case 'roe':
      return 'ROE';
    case 'dividend':
      return '배당';
    default:
      return key.toUpperCase();
  }
}

class StockComparisonRequest {
  final List<String> symbols;
  final String strategyName;

  StockComparisonRequest({
    required Iterable<String> symbols,
    required this.strategyName,
  }) : symbols = List.unmodifiable(
          symbols
              .map(normalizeTickerInput)
              .where((symbol) => symbol.isNotEmpty)
              .take(3),
        );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StockComparisonRequest &&
            other.strategyName == strategyName &&
            other.symbols.join('|') == symbols.join('|');
  }

  @override
  int get hashCode => Object.hash(strategyName, symbols.join('|'));
}

class StockComparisonItem {
  final Stock stock;
  final double score;
  final Map<String, double> normalizedScores;
  final Map<String, double> contributions;

  const StockComparisonItem({
    required this.stock,
    required this.score,
    required this.normalizedScores,
    required this.contributions,
  });

  double rawMetric(String key) {
    switch (key) {
      case 'per':
        return stock.per;
      case 'roe':
        return stock.roe;
      case 'dividend':
        return stock.dividendYield;
      default:
        return 0;
    }
  }
}

class StockComparisonReport {
  final SavedFilter strategy;
  final List<StockComparisonItem> items;
  final String widestMetricKey;
  final double widestMetricGap;
  final bool hasMixedMarkets;
  final int missingMetricCount;

  const StockComparisonReport({
    required this.strategy,
    required this.items,
    required this.widestMetricKey,
    required this.widestMetricGap,
    required this.hasMixedMarkets,
    required this.missingMetricCount,
  });

  String get headline =>
      '${comparisonMetricLabel(widestMetricKey)} 축에서 가장 큰 차이가 나타납니다.';

  String get summary {
    final gap = widestMetricGap.round();
    return '선택한 샘플의 ${comparisonMetricLabel(widestMetricKey)} 정규화 값은 최대 $gap점 차이입니다. '
        '점수는 ${strategy.name}의 가중치로 계산한 상대 비교값입니다.';
  }
}

final stockComparisonProvider = FutureProvider.autoDispose
    .family<StockComparisonReport?, StockComparisonRequest>(
  (ref, request) async {
    if (request.symbols.length < 2) {
      return null;
    }

    final strategies = ref.watch(allStrategiesProvider);
    final strategy = strategies
            .where((item) => item.name == request.strategyName)
            .firstOrNull ??
        strategies.firstOrNull;
    if (strategy == null) {
      return null;
    }

    final universe = await ref.watch(allStocksForSnapshotProvider.future);
    return buildStockComparisonReport(
      universe: universe,
      symbols: request.symbols,
      strategy: strategy,
    );
  },
);

StockComparisonReport? buildStockComparisonReport({
  required List<Stock> universe,
  required Iterable<String> symbols,
  required SavedFilter strategy,
}) {
  if (universe.isEmpty) {
    return null;
  }

  final requested = symbols
      .map(normalizeTickerInput)
      .where((symbol) => symbol.isNotEmpty)
      .take(3)
      .toList();
  final byTicker = {
    for (final stock in universe) normalizeTickerInput(stock.ticker): stock,
  };
  final selected =
      requested.map((symbol) => byTicker[symbol]).whereType<Stock>().toList();
  if (selected.length < 2) {
    return null;
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
  final scoredByTicker = {
    for (final item in scored) normalizeTickerInput(item.stock.symbol): item,
  };

  final items = selected.map((stock) {
    final scoredStock = scoredByTicker[normalizeTickerInput(stock.ticker)];
    final normalized = {
      for (final key in comparisonMetricKeys)
        key: scoredStock?.normalizedScores[key] ?? 0,
    };
    final contributions = {
      for (final key in comparisonMetricKeys)
        key: (normalized[key] ?? 0) * (strategy.weights[key] ?? 0),
    };
    return StockComparisonItem(
      stock: stock,
      score: scoredStock?.score ?? 0,
      normalizedScores: normalized,
      contributions: contributions,
    );
  }).toList();

  var widestMetricKey = comparisonMetricKeys.first;
  var widestMetricGap = -1.0;
  for (final key in comparisonMetricKeys) {
    final values = items.map((item) => item.normalizedScores[key] ?? 0).toList()
      ..sort();
    final gap = values.last - values.first;
    if (gap > widestMetricGap) {
      widestMetricGap = gap;
      widestMetricKey = key;
    }
  }

  final markets = selected.map((stock) => classifyTicker(stock.ticker)).toSet()
    ..remove(MarketRegion.unknown);
  final missingMetricCount = selected.fold<int>(
    0,
    (total, stock) => total + stock.missingMetrics.length,
  );

  return StockComparisonReport(
    strategy: strategy,
    items: items,
    widestMetricKey: widestMetricKey,
    widestMetricGap: widestMetricGap < 0 ? 0 : widestMetricGap,
    hasMixedMarkets: markets.length > 1,
    missingMetricCount: missingMetricCount,
  );
}
