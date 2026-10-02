import 'dart:developer' as developer;

import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/core/tags/smart_tag.dart';
import 'package:strategy_workbench/core/visualization/normalizer.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

class StockDetailViewModel {
  final Stock stock;
  final Map<String, double> normalizedMetrics;
  final List<String> metrics;
  final List<String> tags;
  final int peerCount;

  const StockDetailViewModel({
    required this.stock,
    required this.normalizedMetrics,
    required this.metrics,
    required this.tags,
    required this.peerCount,
  });
}

class StockInsightDriver {
  final String metricKey;
  final String label;
  final double weight;
  final double normalizedValue;
  final String rawValueLabel;
  final String summary;

  const StockInsightDriver({
    required this.metricKey,
    required this.label,
    required this.weight,
    required this.normalizedValue,
    required this.rawValueLabel,
    required this.summary,
  });
}

class StockInsightViewModel {
  final String strategyName;
  final String headline;
  final String summary;
  final String comparisonNote;
  final String watchPoint;
  final List<StockInsightDriver> drivers;
  final int? rank;
  final int? rankChange;

  const StockInsightViewModel({
    required this.strategyName,
    required this.headline,
    required this.summary,
    this.comparisonNote = '',
    this.watchPoint = '',
    required this.drivers,
    this.rank,
    this.rankChange,
  });

  String get compactSummary {
    final segments = <String>[];

    if (rank != null) {
      segments.add('#$rank');
    }

    if (rankChange != null && rankChange != 0) {
      segments.add('${rankChange! > 0 ? '↑' : '↓'}${rankChange!.abs()}');
    }

    if (drivers.isNotEmpty) {
      segments.add(drivers.first.summary);
    } else {
      segments.add(headline);
    }

    return segments.join(' · ');
  }
}

class StockInsightRequest {
  final String strategyName;
  final String symbol;

  const StockInsightRequest({
    required this.strategyName,
    required this.symbol,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StockInsightRequest &&
            other.strategyName == strategyName &&
            other.symbol == symbol;
  }

  @override
  int get hashCode => Object.hash(strategyName, symbol);
}

Stock? findStockBySymbol(List<Stock> stocks, String symbol) {
  final normalized = normalizeTickerInput(symbol);
  for (final stock in stocks) {
    if (normalizeTickerInput(stock.ticker) == normalized) {
      return stock;
    }
  }
  return null;
}

List<model.Transaction> filterTransactionsByTicker(
  List<model.Transaction> transactions,
  String ticker,
) {
  final normalized = normalizeTickerInput(ticker);
  final filtered = transactions
      .where((tx) => normalizeTickerInput(tx.ticker) == normalized)
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return filtered;
}

Stock? _stockFromPortfolioHolding(
  List<PortfolioItem> portfolio,
  String symbol,
) {
  final normalized = normalizeTickerInput(symbol);
  final item = portfolio
      .where((holding) => normalizeTickerInput(holding.ticker) == normalized)
      .firstOrNull;
  if (item == null) {
    return null;
  }

  return Stock(
    ticker: item.ticker,
    name: resolveInstrumentName(item.ticker, item.name),
    price: item.currentPrice > 0 ? item.currentPrice : item.avgPrice,
    per: 0,
    roe: 0,
    dividendYield: 0,
    lastUpdated: DateTime.now(),
  );
}

final stockDetailProvider =
    FutureProvider.autoDispose.family<StockDetailViewModel?, String>(
  (ref, symbol) async {
    final normalizedSymbol = normalizeTickerInput(symbol);
    const metrics = ['per', 'roe', 'dividendYield'];
    final repository = ref.read(hybridRepositoryProvider);
    final portfolioFallback = StorePolicy.showPortfolioFeatures
        ? _stockFromPortfolioHolding(
            ref.watch(portfolioProvider), normalizedSymbol)
        : null;

    List<Stock> allStocks = const [];
    try {
      allStocks = await ref.watch(allStocksForSnapshotProvider.future);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load stock universe for detail: $error',
        name: 'stockDetailProvider',
        error: error,
        stackTrace: stackTrace,
      );
    }

    Stock? stock = await repository.getStock(normalizedSymbol);
    stock ??= findStockBySymbol(allStocks, normalizedSymbol);
    stock ??= portfolioFallback;

    if (stock == null) {
      developer.log(
        'Stock not found: $normalizedSymbol',
        name: 'stockDetailProvider',
      );
      return null;
    }

    final peers = allStocks
        .where((candidate) =>
            candidate.ticker.toUpperCase() != stock!.ticker.toUpperCase())
        .toList();
    final normalized = Normalizer().normalize([stock, ...peers], metrics);

    return StockDetailViewModel(
      stock: stock,
      normalizedMetrics: normalized[stock.ticker] ??
          {for (final metric in metrics) metric: 0.5},
      metrics: metrics,
      tags: SmartTagger().generateTags(stock),
      peerCount: peers.length,
    );
  },
);

final transactionsByTickerProvider =
    Provider.family<AsyncValue<List<model.Transaction>>, String>(
  (ref, ticker) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);
    return transactionsAsync.whenData(
      (transactions) => filterTransactionsByTicker(transactions, ticker),
    );
  },
);

final activeStockInsightProvider =
    FutureProvider.autoDispose.family<StockInsightViewModel?, String>(
  (ref, symbol) async {
    final strategy = ref.watch(activeStrategyProvider);
    if (strategy == null) {
      return null;
    }

    return ref.watch(
      stockInsightProvider(
        StockInsightRequest(strategyName: strategy.name, symbol: symbol),
      ).future,
    );
  },
);

final stockInsightProvider = FutureProvider.autoDispose
    .family<StockInsightViewModel?, StockInsightRequest>(
  (ref, request) async {
    final strategy = ref
        .watch(allStrategiesProvider)
        .where((item) => item.name == request.strategyName)
        .firstOrNull;
    if (strategy == null) {
      return null;
    }

    final detail = await ref.watch(stockDetailProvider(request.symbol).future);
    if (detail == null) {
      return null;
    }

    final snapshot =
        await ref.watch(strategySnapshotProvider(strategy.name).future);

    return buildStockInsight(
      strategy: strategy,
      detail: detail,
      snapshot: snapshot,
    );
  },
);

final strategyStockInsightsProvider = FutureProvider.autoDispose
    .family<Map<String, StockInsightViewModel>, String>(
  (ref, strategyName) async {
    final strategy = ref
        .watch(allStrategiesProvider)
        .where((item) => item.name == strategyName)
        .firstOrNull;
    if (strategy == null) {
      return const {};
    }

    final snapshot =
        await ref.watch(strategySnapshotProvider(strategy.name).future);
    if (snapshot.current.isEmpty) {
      return const {};
    }

    List<Stock> allStocks;
    try {
      allStocks = await ref.watch(allStocksForSnapshotProvider.future);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load stock universe for strategy insights: $error',
        name: 'strategyStockInsightsProvider',
        error: error,
        stackTrace: stackTrace,
      );
      return const {};
    }

    if (allStocks.isEmpty) {
      return const {};
    }

    const metrics = ['per', 'roe', 'dividendYield'];
    final normalized = Normalizer().normalize(allStocks, metrics);
    final stocksByTicker = {
      for (final stock in allStocks) stock.ticker.toUpperCase(): stock,
    };
    final tagger = SmartTagger();
    final fallbackMetrics = {for (final metric in metrics) metric: 0.5};
    final insights = <String, StockInsightViewModel>{};

    for (final snapshotStock in snapshot.current) {
      final stock = stocksByTicker[snapshotStock.ticker.toUpperCase()];
      if (stock == null) {
        continue;
      }

      final detail = StockDetailViewModel(
        stock: stock,
        normalizedMetrics: normalized[stock.ticker] ?? fallbackMetrics,
        metrics: metrics,
        tags: tagger.generateTags(stock),
        peerCount: allStocks.length > 1 ? allStocks.length - 1 : 0,
      );

      insights[stock.ticker.toUpperCase()] = buildStockInsight(
        strategy: strategy,
        detail: detail,
        snapshot: snapshot,
      );
    }

    return insights;
  },
);

final strategyStockInsightsByMarketProvider = FutureProvider.autoDispose
    .family<Map<String, StockInsightViewModel>, StrategySnapshotMarketRequest>(
  (ref, request) async {
    final strategy = ref
        .watch(allStrategiesProvider)
        .where((item) => item.name == request.strategyName)
        .firstOrNull;
    if (strategy == null) {
      return const {};
    }

    final snapshot =
        await ref.watch(strategySnapshotByMarketProvider(request).future);
    if (snapshot.current.isEmpty) {
      return const {};
    }

    List<Stock> allStocks;
    try {
      allStocks = await ref.watch(allStocksForSnapshotProvider.future);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load stock universe for market strategy insights: $error',
        name: 'strategyStockInsightsByMarketProvider',
        error: error,
        stackTrace: stackTrace,
      );
      return const {};
    }

    final marketStocks = filterStocksByMarket(allStocks, request.marketFilter);
    if (marketStocks.isEmpty) {
      return const {};
    }

    const metrics = ['per', 'roe', 'dividendYield'];
    final normalized = Normalizer().normalize(marketStocks, metrics);
    final stocksByTicker = {
      for (final stock in marketStocks)
        normalizeTickerInput(stock.ticker): stock,
    };
    final tagger = SmartTagger();
    final fallbackMetrics = {for (final metric in metrics) metric: 0.5};
    final insights = <String, StockInsightViewModel>{};

    for (final snapshotStock in snapshot.current) {
      final stock = stocksByTicker[normalizeTickerInput(snapshotStock.ticker)];
      if (stock == null) {
        continue;
      }

      final detail = StockDetailViewModel(
        stock: stock,
        normalizedMetrics: normalized[stock.ticker] ?? fallbackMetrics,
        metrics: metrics,
        tags: tagger.generateTags(stock),
        peerCount: marketStocks.length > 1 ? marketStocks.length - 1 : 0,
      );

      insights[normalizeTickerInput(stock.ticker)] = buildStockInsight(
        strategy: strategy,
        detail: detail,
        snapshot: snapshot,
      );
    }

    return insights;
  },
);

StockInsightViewModel buildStockInsight({
  required SavedFilter strategy,
  required StockDetailViewModel detail,
  required StrategySnapshot snapshot,
}) {
  final stock = detail.stock;
  final drivers = <StockInsightDriver>[
    if ((strategy.weights['per'] ?? 0) > 0 && stock.per > 0)
      StockInsightDriver(
        metricKey: 'per',
        label: 'PER',
        weight: strategy.weights['per'] ?? 0,
        normalizedValue: detail.normalizedMetrics['per'] ?? 0.0,
        rawValueLabel: stock.per.toStringAsFixed(1),
        summary: _buildMetricSummary(
          metricKey: 'per',
          stock: stock,
          normalizedValue: detail.normalizedMetrics['per'] ?? 0.0,
        ),
      ),
    if ((strategy.weights['roe'] ?? 0) > 0 && stock.roe > 0)
      StockInsightDriver(
        metricKey: 'roe',
        label: 'ROE',
        weight: strategy.weights['roe'] ?? 0,
        normalizedValue: detail.normalizedMetrics['roe'] ?? 0.0,
        rawValueLabel: '${stock.roe.toStringAsFixed(1)}%',
        summary: _buildMetricSummary(
          metricKey: 'roe',
          stock: stock,
          normalizedValue: detail.normalizedMetrics['roe'] ?? 0.0,
        ),
      ),
    if ((strategy.weights['dividend'] ?? 0) > 0 && stock.dividendYield > 0)
      StockInsightDriver(
        metricKey: 'dividend',
        label: '배당',
        weight: strategy.weights['dividend'] ?? 0,
        normalizedValue: detail.normalizedMetrics['dividendYield'] ?? 0.0,
        rawValueLabel: '${stock.dividendYield.toStringAsFixed(1)}%',
        summary: _buildMetricSummary(
          metricKey: 'dividend',
          stock: stock,
          normalizedValue: detail.normalizedMetrics['dividendYield'] ?? 0.0,
        ),
      ),
  ]..sort((a, b) {
      final contributionA = a.weight * a.normalizedValue;
      final contributionB = b.weight * b.normalizedValue;
      final contributionCompare = contributionB.compareTo(contributionA);
      if (contributionCompare != 0) {
        return contributionCompare;
      }
      return b.weight.compareTo(a.weight);
    });

  final rank = snapshot.current
      .where((candidate) =>
          candidate.ticker.toUpperCase() == stock.ticker.toUpperCase())
      .firstOrNull
      ?.rank;
  final rankChange = snapshot.rankChange(stock.ticker);
  final primaryDriver = drivers.isNotEmpty ? drivers.first : null;

  final headline = _buildInsightHeadline(
    strategyName: strategy.name,
    rank: rank,
    rankChange: rankChange,
    primaryDriver: primaryDriver,
  );

  final summary = _buildInsightSummary(
    strategyName: strategy.name,
    topN: strategy.topN,
    rank: rank,
    rankChange: rankChange,
    primaryDriver: primaryDriver,
  );

  return StockInsightViewModel(
    strategyName: strategy.name,
    headline: headline,
    summary: summary,
    comparisonNote: _buildComparisonNote(
      strategyName: strategy.name,
      drivers: drivers,
    ),
    watchPoint: _buildWatchPoint(
      strategy: strategy,
      stock: stock,
      drivers: drivers,
    ),
    drivers: drivers.take(3).toList(),
    rank: rank,
    rankChange: rankChange,
  );
}

String _buildInsightHeadline({
  required String strategyName,
  required int? rank,
  required int? rankChange,
  required StockInsightDriver? primaryDriver,
}) {
  if (rank != null && rank <= 3) {
    return '$strategyName 기준 상위 지표 샘플입니다.';
  }
  if (rankChange != null && rankChange > 0) {
    return '지표 순위가 상승한 샘플입니다.';
  }
  if (primaryDriver != null) {
    return '${primaryDriver.label} 비중 기준에서 설명력이 큰 종목입니다.';
  }
  return '선택한 지표 기준으로 다시 살펴볼 샘플입니다.';
}

String _buildInsightSummary({
  required String strategyName,
  required int topN,
  required int? rank,
  required int? rankChange,
  required StockInsightDriver? primaryDriver,
}) {
  final parts = <String>[];

  if (rank != null) {
    parts.add('현재 $strategyName Top $topN 안에서 #$rank 입니다.');
  }

  if (rankChange != null && rankChange != 0) {
    final direction = rankChange > 0 ? '상승' : '하락';
    parts.add('전일 대비 ${rankChange.abs()}계단 $direction 했습니다.');
  }

  if (primaryDriver != null) {
    parts.add(primaryDriver.summary);
  }

  if (parts.isEmpty) {
    return '선택한 지표 가중치 기준으로 주요 지표를 다시 해석하는 중입니다.';
  }

  return parts.join(' ');
}

String _buildMetricSummary({
  required String metricKey,
  required Stock stock,
  required double normalizedValue,
}) {
  switch (metricKey) {
    case 'per':
      if (stock.per <= 10) {
        return 'PER ${stock.per.toStringAsFixed(1)}로 저평가 구간에 가깝습니다.';
      }
      if (stock.per <= 20) {
        return 'PER ${stock.per.toStringAsFixed(1)}로 밸류 부담이 낮은 편입니다.';
      }
      return normalizedValue >= 0.6
          ? 'PER ${stock.per.toStringAsFixed(1)}이지만 비교군 대비 상대 점수는 유지하고 있습니다.'
          : 'PER ${stock.per.toStringAsFixed(1)}로 밸류 매력은 보조 요소에 가깝습니다.';
    case 'roe':
      if (stock.roe >= 20) {
        return 'ROE ${stock.roe.toStringAsFixed(1)}%로 수익성이 강합니다.';
      }
      if (stock.roe >= 10) {
        return 'ROE ${stock.roe.toStringAsFixed(1)}%로 수익성이 안정적입니다.';
      }
      return normalizedValue >= 0.6
          ? 'ROE ${stock.roe.toStringAsFixed(1)}%가 비교군 안에서는 방어적으로 버텨주고 있습니다.'
          : 'ROE ${stock.roe.toStringAsFixed(1)}%는 아직 보완이 필요한 편입니다.';
    case 'dividend':
      if (stock.dividendYield >= 4) {
        return '배당 ${stock.dividendYield.toStringAsFixed(1)}%로 현금흐름 매력이 큽니다.';
      }
      if (stock.dividendYield >= 2) {
        return '배당 ${stock.dividendYield.toStringAsFixed(1)}%가 보조 매력으로 작동합니다.';
      }
      return normalizedValue >= 0.6
          ? '배당 수익률은 낮지만 비교군 대비 점수는 유지하고 있습니다.'
          : '배당 수익률은 낮아 이 전략에서는 보조 요소입니다.';
    default:
      return '전략 가중치 기준으로 의미 있는 지표입니다.';
  }
}

String _buildComparisonNote({
  required String strategyName,
  required List<StockInsightDriver> drivers,
}) {
  if (drivers.isEmpty) {
    return '현재 확보된 지표가 부족해 $strategyName 기준의 상대 위치를 제한적으로만 해석할 수 있습니다.';
  }

  final primary = drivers.first;
  final secondary = drivers.length > 1 ? drivers[1] : null;
  final primaryScore = (primary.normalizedValue * 100).clamp(0, 100).round();

  if (secondary == null) {
    return '$strategyName 기준에서는 ${primary.label} 축의 상대 위치가 주로 설명력을 만듭니다. 비교군 백분위는 약 $primaryScore점입니다.';
  }

  final secondaryScore =
      (secondary.normalizedValue * 100).clamp(0, 100).round();
  return '$strategyName 기준에서는 ${primary.label} 축이 가장 크게 작동하고, ${secondary.label} 축은 약 $secondaryScore점 수준으로 보조 설명력을 더합니다.';
}

String _buildWatchPoint({
  required SavedFilter strategy,
  required Stock stock,
  required List<StockInsightDriver> drivers,
}) {
  final missingMetrics = <String>[
    if ((strategy.weights['per'] ?? 0) > 0 && stock.per <= 0) 'PER',
    if ((strategy.weights['roe'] ?? 0) > 0 && stock.roe <= 0) 'ROE',
    if ((strategy.weights['dividend'] ?? 0) > 0 && stock.dividendYield <= 0)
      '배당',
  ];

  if (missingMetrics.isNotEmpty) {
    return '${missingMetrics.join(', ')} 데이터가 비어 있어 해당 축의 비교는 보수적으로 봐야 합니다.';
  }

  if (drivers.isEmpty) {
    return '지표 데이터가 더 쌓이면 기준별 강점과 약점을 더 선명하게 비교할 수 있습니다.';
  }

  final weakest = [...drivers]..sort((a, b) {
      final contributionA = a.weight * a.normalizedValue;
      final contributionB = b.weight * b.normalizedValue;
      return contributionA.compareTo(contributionB);
    });
  final candidate = weakest.first;
  final score = (candidate.normalizedValue * 100).clamp(0, 100).round();

  if (candidate.normalizedValue < 0.35) {
    return '${candidate.label} 축은 비교군 대비 약 $score점으로 낮게 나타나 추가 확인이 필요합니다.';
  }

  return '큰 약점이 두드러지기보다는 ${drivers.first.label} 축의 설명력이 더 큰 샘플입니다.';
}
