import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/hybrid_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/core/scoring/scoring_engine.dart';
import 'package:strategy_workbench/core/extensions/stock_extension.dart';
import 'dart:developer' as developer;

// ── Repository Provider ──
final hybridRepositoryProvider = Provider<HybridStockRepository>((ref) {
  return HybridStockRepository();
});

// ── 필터 타입 (US / Korea / Hybrid) ──
enum MarketFilter { us, korea, hybrid }

class MarketFilterNotifier extends Notifier<MarketFilter> {
  @override
  MarketFilter build() => MarketFilter.hybrid;

  void set(MarketFilter filter) => state = filter;
}

final marketFilterProvider =
    NotifierProvider<MarketFilterNotifier, MarketFilter>(
  MarketFilterNotifier.new,
);

// ── 가중치 (PER, ROE, Dividend) ──
class WeightsNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => {'per': 0.5, 'roe': 0.5};

  void set(Map<String, double> weights) => state = weights;
}

final weightsProvider =
    NotifierProvider<WeightsNotifier, Map<String, double>>(
  WeightsNotifier.new,
);

// ── 원본 Strategy Stock 리스트 (Hive 캐시 → API 폴백) ──
final stockListProvider =
    FutureProvider.autoDispose<List<Stock>>((ref) async {
  final repo = ref.watch(hybridRepositoryProvider);
  final filter = ref.watch(marketFilterProvider);

  // 1. Hive 캐시 확인 (오늘 날짜의 데이터가 있으면 캐시 사용)
  try {
    final settings = Hive.box('settings');
    final lastUpdate = settings.get('last_update_date');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastUpdate == today) {
      final stockCache = Hive.box('stock_cache');
      if (stockCache.isNotEmpty) {
        final cachedStocks = <Stock>[];
        for (final key in stockCache.keys) {
          final s = stockCache.get(key);
          if (s is Stock) cachedStocks.add(s);
        }
        if (cachedStocks.isNotEmpty) {
          developer.log(
              'Using Hive cache: ${cachedStocks.length} stocks (updated $lastUpdate)',
              name: 'stockListProvider');

          // 필터 적용
          return _filterStocks(cachedStocks, filter);
        }
      }
    }
  } catch (e) {
    developer.log('Hive cache read failed: $e', name: 'stockListProvider');
  }

  // 2. 캐시 미스 → API에서 가져오기
  developer.log('Cache miss, fetching from API (filter: $filter)',
      name: 'stockListProvider');
  switch (filter) {
    case MarketFilter.us:
      return await repo.getUsStocks();
    case MarketFilter.korea:
      return await repo.getKoreanStocks();
    case MarketFilter.hybrid:
      return await repo.getAllStocks();
  }
});

/// 캐시된 전체 주식에서 필터 기준으로 분류
List<Stock> _filterStocks(List<Stock> stocks, MarketFilter filter) {
  switch (filter) {
    case MarketFilter.us:
      return stocks
          .where((s) => !RegExp(r'^\d+$').hasMatch(s.ticker))
          .toList();
    case MarketFilter.korea:
      return stocks
          .where((s) => RegExp(r'^\d+$').hasMatch(s.ticker))
          .toList();
    case MarketFilter.hybrid:
      return stocks;
  }
}

// ── 스코어링된 Market Stock 리스트 ──
final scoredStockListProvider =
    FutureProvider.autoDispose<List<ScoredStock>>((ref) async {
  final stocks = await ref.watch(stockListProvider.future);
  final weights = ref.watch(weightsProvider);
  final engine = ScoringEngine();

  final marketStocks = stocks.map((s) => s.toMarketStock()).toList();
  return engine.calculateScores(stocks: marketStocks, weights: weights);
});

// ── 데이터 소스 상태 ──
final dataSourceStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final repo = ref.watch(hybridRepositoryProvider);
  return repo.getStatus();
});
