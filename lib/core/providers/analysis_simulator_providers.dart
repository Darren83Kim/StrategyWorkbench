import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/core/scoring/scoring_engine.dart';
import 'package:strategy_workbench/features/market/models/stock.dart'
    as market_stock;
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

class AnalysisSimulationRequest {
  final String strategyName;
  final MarketFilter marketFilter;
  final int perWeight;
  final int roeWeight;
  final int dividendWeight;
  final int sampleCount;

  const AnalysisSimulationRequest({
    required this.strategyName,
    required this.marketFilter,
    required this.perWeight,
    required this.roeWeight,
    required this.dividendWeight,
    required this.sampleCount,
  });

  Map<String, double> get normalizedWeights => normalizeAnalysisWeights({
        'per': perWeight.toDouble(),
        'roe': roeWeight.toDouble(),
        'dividend': dividendWeight.toDouble(),
      });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AnalysisSimulationRequest &&
            other.strategyName == strategyName &&
            other.marketFilter == marketFilter &&
            other.perWeight == perWeight &&
            other.roeWeight == roeWeight &&
            other.dividendWeight == dividendWeight &&
            other.sampleCount == sampleCount;
  }

  @override
  int get hashCode => Object.hash(
        strategyName,
        marketFilter,
        perWeight,
        roeWeight,
        dividendWeight,
        sampleCount,
      );
}

class AnalysisSimulationStock {
  final String ticker;
  final String name;
  final double price;
  final int baselineRank;
  final int simulatedRank;
  final double baselineScore;
  final double simulatedScore;
  final Map<String, double> baselineContributions;
  final Map<String, double> simulatedContributions;

  const AnalysisSimulationStock({
    required this.ticker,
    required this.name,
    required this.price,
    required this.baselineRank,
    required this.simulatedRank,
    required this.baselineScore,
    required this.simulatedScore,
    required this.baselineContributions,
    required this.simulatedContributions,
  });

  int get rankChange => baselineRank - simulatedRank;
  int get absoluteRankChange => rankChange.abs();

  factory AnalysisSimulationStock.fromJson(Map<String, dynamic> json) {
    return AnalysisSimulationStock(
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      baselineRank: json['baselineRank'] as int,
      simulatedRank: json['simulatedRank'] as int,
      baselineScore: (json['baselineScore'] as num).toDouble(),
      simulatedScore: (json['simulatedScore'] as num).toDouble(),
      baselineContributions: Map<String, double>.from(
        json['baselineContributions'] as Map,
      ),
      simulatedContributions: Map<String, double>.from(
        json['simulatedContributions'] as Map,
      ),
    );
  }
}

class AnalysisSimulationResult {
  final String strategyName;
  final Map<String, double> baselineWeights;
  final Map<String, double> simulatedWeights;
  final List<AnalysisSimulationStock> simulatedTop;
  final List<AnalysisSimulationStock> biggestMovers;
  final int overlapCount;
  final int enteredCount;
  final int exitedCount;

  const AnalysisSimulationResult({
    required this.strategyName,
    required this.baselineWeights,
    required this.simulatedWeights,
    required this.simulatedTop,
    required this.biggestMovers,
    required this.overlapCount,
    required this.enteredCount,
    required this.exitedCount,
  });

  factory AnalysisSimulationResult.fromJson(Map<String, dynamic> json) {
    return AnalysisSimulationResult(
      strategyName: json['strategyName'] as String,
      baselineWeights: Map<String, double>.from(
        json['baselineWeights'] as Map,
      ),
      simulatedWeights: Map<String, double>.from(
        json['simulatedWeights'] as Map,
      ),
      simulatedTop: (json['simulatedTop'] as List)
          .map(
            (item) => AnalysisSimulationStock.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      biggestMovers: (json['biggestMovers'] as List)
          .map(
            (item) => AnalysisSimulationStock.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      overlapCount: json['overlapCount'] as int,
      enteredCount: json['enteredCount'] as int,
      exitedCount: json['exitedCount'] as int,
    );
  }
}

final analysisSimulationProvider = FutureProvider.autoDispose
    .family<AnalysisSimulationResult?, AnalysisSimulationRequest>(
  (ref, request) async {
    final strategy = ref
        .watch(allStrategiesProvider)
        .where((item) => item.name == request.strategyName)
        .firstOrNull;
    if (strategy == null || request.normalizedWeights.isEmpty) {
      return null;
    }

    final stocks = await ref.watch(allStocksForSnapshotProvider.future);
    final marketStocks = filterStocksByMarket(stocks, request.marketFilter);
    if (marketStocks.isEmpty) {
      return null;
    }

    final payload = _serializeSimulationRequest(
      stocks: marketStocks,
      strategy: strategy,
      simulatedWeights: request.normalizedWeights,
      sampleCount: request.sampleCount,
    );
    final raw = await compute(runAnalysisSimulation, payload);
    return AnalysisSimulationResult.fromJson(raw);
  },
);

Map<String, double> normalizeAnalysisWeights(Map<String, double> weights) {
  final positive = <String, double>{
    for (final entry in weights.entries)
      if (entry.value > 0) entry.key: entry.value,
  };
  final total = positive.values.fold<double>(0, (sum, value) => sum + value);
  if (total <= 0) {
    return const {};
  }
  return {
    for (final entry in positive.entries) entry.key: entry.value / total,
  };
}

AnalysisSimulationResult buildAnalysisSimulation({
  required List<Stock> stocks,
  required SavedFilter strategy,
  required Map<String, double> simulatedWeights,
  int sampleCount = 10,
}) {
  final raw = runAnalysisSimulation(
    _serializeSimulationRequest(
      stocks: stocks,
      strategy: strategy,
      simulatedWeights: normalizeAnalysisWeights(simulatedWeights),
      sampleCount: sampleCount,
    ),
  );
  return AnalysisSimulationResult.fromJson(raw);
}

Map<String, dynamic> _serializeSimulationRequest({
  required List<Stock> stocks,
  required SavedFilter strategy,
  required Map<String, double> simulatedWeights,
  required int sampleCount,
}) {
  return {
    'strategyName': strategy.name,
    'baselineWeights': normalizeAnalysisWeights(strategy.weights),
    'simulatedWeights': simulatedWeights,
    'sampleCount': sampleCount,
    'stocks': stocks
        .map(
          (stock) => {
            'ticker': stock.ticker,
            'name': stock.name,
            'price': stock.price,
            'per': stock.per,
            'roe': stock.roe,
            'dividendYield': stock.dividendYield,
          },
        )
        .toList(),
  };
}

@visibleForTesting
Map<String, dynamic> runAnalysisSimulation(Map<String, dynamic> payload) {
  final stocks = (payload['stocks'] as List).map(
    (item) {
      final map = Map<String, dynamic>.from(item as Map);
      return market_stock.Stock(
        symbol: map['ticker'] as String,
        name: map['name'] as String,
        price: (map['price'] as num).toDouble(),
        change: 0,
        per: (map['per'] as num?)?.toDouble(),
        roe: (map['roe'] as num?)?.toDouble(),
        dividendYield: (map['dividendYield'] as num?)?.toDouble(),
      );
    },
  ).toList();
  final baselineWeights = Map<String, double>.from(
    payload['baselineWeights'] as Map,
  );
  final simulatedWeights = Map<String, double>.from(
    payload['simulatedWeights'] as Map,
  );
  final sampleCount = payload['sampleCount'] as int? ?? 10;
  final engine = ScoringEngine();
  final baseline = engine.calculateScores(
    stocks: stocks,
    weights: baselineWeights,
  );
  final simulated = engine.calculateScores(
    stocks: stocks,
    weights: simulatedWeights,
  );

  final baselineByTicker = {
    for (final entry in baseline.asMap().entries)
      entry.value.stock.symbol.toUpperCase(): (
        rank: entry.key + 1,
        item: entry.value,
      ),
  };
  final simulatedByTicker = {
    for (final entry in simulated.asMap().entries)
      entry.value.stock.symbol.toUpperCase(): (
        rank: entry.key + 1,
        item: entry.value,
      ),
  };
  final baselineTopTickers = baseline
      .take(sampleCount)
      .map((item) => item.stock.symbol.toUpperCase())
      .toSet();
  final simulatedTopTickers = simulated
      .take(sampleCount)
      .map((item) => item.stock.symbol.toUpperCase())
      .toSet();

  Map<String, dynamic> serializeStock(String ticker) {
    final baselineEntry = baselineByTicker[ticker]!;
    final simulatedEntry = simulatedByTicker[ticker]!;
    final stock = simulatedEntry.item.stock;
    return {
      'ticker': stock.symbol,
      'name': stock.name,
      'price': stock.price,
      'baselineRank': baselineEntry.rank,
      'simulatedRank': simulatedEntry.rank,
      'baselineScore': baselineEntry.item.score,
      'simulatedScore': simulatedEntry.item.score,
      'baselineContributions': _metricContributions(
        baselineEntry.item.normalizedScores,
        baselineWeights,
      ),
      'simulatedContributions': _metricContributions(
        simulatedEntry.item.normalizedScores,
        simulatedWeights,
      ),
    };
  }

  final simulatedTop = simulated
      .take(sampleCount)
      .map((item) => serializeStock(item.stock.symbol.toUpperCase()))
      .toList();
  final moverTickers = {...baselineTopTickers, ...simulatedTopTickers}.toList()
    ..sort((a, b) {
      final aGap =
          (baselineByTicker[a]!.rank - simulatedByTicker[a]!.rank).abs();
      final bGap =
          (baselineByTicker[b]!.rank - simulatedByTicker[b]!.rank).abs();
      if (aGap != bGap) {
        return bGap.compareTo(aGap);
      }
      return simulatedByTicker[a]!.rank.compareTo(simulatedByTicker[b]!.rank);
    });

  return {
    'strategyName': payload['strategyName'] as String,
    'baselineWeights': baselineWeights,
    'simulatedWeights': simulatedWeights,
    'simulatedTop': simulatedTop,
    'biggestMovers': moverTickers.take(5).map(serializeStock).toList(),
    'overlapCount': baselineTopTickers.intersection(simulatedTopTickers).length,
    'enteredCount': simulatedTopTickers.difference(baselineTopTickers).length,
    'exitedCount': baselineTopTickers.difference(simulatedTopTickers).length,
  };
}

Map<String, double> _metricContributions(
  Map<String, double> normalizedScores,
  Map<String, double> weights,
) {
  return {
    for (final metric in const ['per', 'roe', 'dividend'])
      metric: (normalizedScores[metric] ?? 0) * (weights[metric] ?? 0),
  };
}
