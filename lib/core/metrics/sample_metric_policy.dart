import 'package:flutter/foundation.dart';

import '../config/store_policy.dart';
import '../../features/strategy/domain/entities/stock.dart';

const sampleMetricSource = '샘플 데이터';
const missingMetricLabel = '지표 없음';

class SampleMetricPolicy {
  static const bool rejectSampleMetrics =
      kReleaseMode || StorePolicy.isPersonalMode;

  static bool isSampleMetric(Stock stock, String metric) =>
      stock.metricSources[metric] == sampleMetricSource;

  static Stock withoutSampleMetrics(Stock stock) {
    if (!stock.usesSampleMetrics) {
      return stock;
    }

    final sources = Map<String, String>.from(stock.metricSources)
      ..removeWhere((_, source) => source == sampleMetricSource);
    return stock.copyWith(
      per: isSampleMetric(stock, 'per') ? 0 : stock.per,
      roe: isSampleMetric(stock, 'roe') ? 0 : stock.roe,
      dividendYield:
          isSampleMetric(stock, 'dividend') ? 0 : stock.dividendYield,
      metricSources: sources,
    );
  }

  static Stock forDisplay(Stock stock) =>
      rejectSampleMetrics ? withoutSampleMetrics(stock) : stock;

  static List<Stock> rankableStocks(
    List<Stock> stocks,
    Map<String, double> weights, {
    bool? rejectSampleMetrics,
  }) {
    final reject = rejectSampleMetrics ?? SampleMetricPolicy.rejectSampleMetrics;
    if (!reject) {
      return stocks;
    }

    final weightedKeys = weights.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
    if (weightedKeys.isEmpty) {
      return const [];
    }

    return [
      for (final stock in stocks)
        if (_hasRealWeightedMetric(withoutSampleMetrics(stock), weightedKeys))
          withoutSampleMetrics(stock),
    ];
  }

  static bool _hasRealWeightedMetric(Stock stock, List<String> keys) {
    for (final key in keys) {
      final real = switch (key) {
        'per' => stock.per > 0,
        'roe' => stock.roe > 0,
        'dividend' => stock.dividendYield > 0,
        _ => false,
      };
      if (real) {
        return true;
      }
    }
    return false;
  }

  /// Rank only on real weighted metrics. When none exist, keep priced stocks
  /// visible so the strategy list is not blank.
  static ({List<Stock> ranked, List<Stock> unranked}) partitionForDisplay(
    List<Stock> stocks,
    Map<String, double> weights, {
    bool? rejectSampleMetrics,
  }) {
    final reject = rejectSampleMetrics ?? SampleMetricPolicy.rejectSampleMetrics;
    if (!reject) {
      return (ranked: stocks, unranked: const <Stock>[]);
    }

    final ranked = rankableStocks(
      stocks,
      weights,
      rejectSampleMetrics: true,
    );
    if (ranked.isNotEmpty) {
      return (ranked: ranked, unranked: const <Stock>[]);
    }

    return (
      ranked: const <Stock>[],
      unranked: [
        for (final stock in stocks)
          if (stock.price > 0) withoutSampleMetrics(stock),
      ],
    );
  }

  static String fundamentalText({
    required Stock stock,
    required String metric,
    required String formatted,
    bool? rejectSampleMetrics,
  }) {
    final reject = rejectSampleMetrics ?? SampleMetricPolicy.rejectSampleMetrics;
    final value = switch (metric) {
      'per' => stock.per,
      'roe' => stock.roe,
      'dividend' => stock.dividendYield,
      _ => 0.0,
    };
    if (isSampleMetric(stock, metric) || value <= 0) {
      return reject ? missingMetricLabel : '없음';
    }
    return formatted;
  }
}
