import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/core/scoring/scoring_engine.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/features/market/models/stock.dart'
    as market_stock;
import 'dart:developer' as developer;

// ── 스냅샷 종목 ──
class SnapshotStock {
  final String ticker;
  final String name;
  final double price;
  final double score;
  final int rank;

  const SnapshotStock({
    required this.ticker,
    required this.name,
    required this.price,
    required this.score,
    required this.rank,
  });

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'price': price,
        'score': score,
        'rank': rank,
      };

  factory SnapshotStock.fromJson(Map<String, dynamic> json) => SnapshotStock(
        ticker: json['ticker'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        score: (json['score'] as num).toDouble(),
        rank: json['rank'] as int,
      );
}

// ── 전략 스냅샷 (현재 + 이전) ──
class StrategySnapshot {
  final String date;
  final List<SnapshotStock> current;
  final List<SnapshotStock> previous;

  const StrategySnapshot({
    required this.date,
    required this.current,
    this.previous = const [],
  });

  /// 순위 변동: 양수 = 상승, 음수 = 하락, null = 신규
  int? rankChange(String ticker) {
    final prevRank =
        previous.where((s) => s.ticker == ticker).firstOrNull?.rank;
    final curRank = current.where((s) => s.ticker == ticker).firstOrNull?.rank;
    if (prevRank == null || curRank == null) return null;
    return prevRank - curRank;
  }

  /// 이탈 종목: 관심 등록됐으나 현재 top-N에서 빠진 종목
  List<SnapshotStock> exitedStocks(Set<String> watchedTickers) {
    final currentTickers = current.map((s) => s.ticker).toSet();
    return previous
        .where((s) =>
            watchedTickers.contains(s.ticker) &&
            !currentTickers.contains(s.ticker))
        .toList();
  }
}

// ── 스냅샷 캐시 키 ──
String _snapKey(String strategyName) =>
    'snap_v1_${strategyName.replaceAll(' ', '_')}';

Map<String, dynamic> _serializeStrategyStock(Stock stock) => {
      'ticker': stock.ticker,
      'name': stock.name,
      'price': stock.price,
      'per': stock.per,
      'roe': stock.roe,
      'dividendYield': stock.dividendYield,
    };

Map<String, dynamic> _serializeSnapshotRequest({
  required List<Stock> stocks,
  required Map<String, double> weights,
  required int topN,
}) {
  return {
    'stocks': stocks.map(_serializeStrategyStock).toList(),
    'weights': weights,
    'topN': topN,
  };
}

Future<List<SnapshotStock>> _buildSnapshotStocksInBackground({
  required List<Stock> stocks,
  required Map<String, double> weights,
  required int topN,
}) async {
  final payload = _serializeSnapshotRequest(
    stocks: stocks,
    weights: weights,
    topN: topN,
  );
  final results = await compute(_scoreSnapshotStocks, payload);

  return results
      .map((item) => SnapshotStock.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<Map<String, dynamic>> _scoreSnapshotStocks(Map<String, dynamic> payload) {
  final rawStocks = (payload['stocks'] as List<dynamic>)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  final weights = Map<String, double>.from(payload['weights'] as Map);
  final topN = payload['topN'] as int? ?? 10;

  final marketStocks = rawStocks
      .map(
        (item) => market_stock.Stock(
          symbol: item['ticker'] as String,
          name: item['name'] as String,
          price: (item['price'] as num).toDouble(),
          change: 0,
          per: (item['per'] as num?)?.toDouble(),
          roe: (item['roe'] as num?)?.toDouble(),
          dividendYield: (item['dividendYield'] as num?)?.toDouble(),
        ),
      )
      .toList();

  final scored =
      ScoringEngine().calculateScores(stocks: marketStocks, weights: weights);

  return scored
      .take(topN)
      .toList()
      .asMap()
      .entries
      .map(
        (entry) => {
          'ticker': entry.value.stock.symbol,
          'name': entry.value.stock.name,
          'price': entry.value.stock.price,
          'score': entry.value.score,
          'rank': entry.key + 1,
        },
      )
      .toList();
}

// ── 전체 주식 (Hive 캐시 → API 폴백, 당일 캐시만 사용) ──
final allStocksForSnapshotProvider = FutureProvider<List<Stock>>((ref) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  try {
    final settings = Hive.box('settings');
    final lastUpdate = settings.get('last_update_date') as String?;
    if (lastUpdate == today) {
      final stockCache = Hive.box('stock_cache');
      if (stockCache.isNotEmpty) {
        final cached = <Stock>[];
        for (final key in stockCache.keys) {
          final s = stockCache.get(key);
          if (s is Stock) cached.add(s);
        }
        if (cached.isNotEmpty) {
          developer.log(
              'Snapshot using ${cached.length} cached stocks ($today)',
              name: 'allStocksForSnapshot');
          return cached;
        }
      }
    } else {
      developer.log(
          'Hive cache stale (was: $lastUpdate, today: $today), fetching fresh',
          name: 'allStocksForSnapshot');
    }
  } catch (e) {
    developer.log('Hive read error: $e', name: 'allStocksForSnapshot');
  }
  final repo = ref.read(hybridRepositoryProvider);
  final freshStocks = await repo.getAllStocks();
  if (freshStocks.isNotEmpty) {
    return freshStocks;
  }

  try {
    final stockCache = Hive.box('stock_cache');
    if (stockCache.isNotEmpty) {
      final cached = <Stock>[];
      for (final key in stockCache.keys) {
        final s = stockCache.get(key);
        if (s is Stock) cached.add(s);
      }
      if (cached.isNotEmpty) {
        developer.log(
            'Fresh fetch returned 0 stocks. Reusing stale Hive cache with ${cached.length} entries.',
            name: 'allStocksForSnapshot');
        return cached;
      }
    }
  } catch (e) {
    developer.log('Stale Hive fallback read error: $e',
        name: 'allStocksForSnapshot');
  }

  return freshStocks;
});

// ── 전략별 스냅샷 Provider (family, non-autoDispose) ──
final strategySnapshotProvider =
    FutureProvider.family<StrategySnapshot, String>((ref, strategyName) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final prefs = await SharedPreferences.getInstance();
  final cacheKey = _snapKey(strategyName);

  // 캐시 확인
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      final Map<String, dynamic> json = jsonDecode(cached);
      final storedDate = json['date'] as String?;

      if (storedDate == today) {
        final current = (json['current'] as List)
            .map((e) => SnapshotStock.fromJson(e as Map<String, dynamic>))
            .toList();
        final previous = (json['previous'] as List? ?? [])
            .map((e) => SnapshotStock.fromJson(e as Map<String, dynamic>))
            .toList();
        if (current.isEmpty) {
          developer.log(
              'Same-day cache for $strategyName is empty. Recomputing snapshot.',
              name: 'strategySnapshot');
          return await _compute(
            ref,
            strategyName,
            today,
            previous,
            prefs,
            cacheKey,
          );
        }
        developer.log('Cache hit: $strategyName ($today)',
            name: 'strategySnapshot');
        return StrategySnapshot(
            date: today, current: current, previous: previous);
      }

      // 날짜 바뀜 → 현재를 이전으로 이동 후 재계산
      final prevStocks = (json['current'] as List)
          .map((e) => SnapshotStock.fromJson(e as Map<String, dynamic>))
          .toList();
      return await _compute(
          ref, strategyName, today, prevStocks, prefs, cacheKey);
    } catch (e) {
      developer.log('Cache parse error for $strategyName: $e',
          name: 'strategySnapshot');
    }
  }

  return await _compute(ref, strategyName, today, [], prefs, cacheKey);
});

Future<StrategySnapshot> _compute(
  Ref ref,
  String strategyName,
  String date,
  List<SnapshotStock> previous,
  SharedPreferences prefs,
  String cacheKey,
) async {
  final allStrategies = ref.read(allStrategiesProvider);
  final strategy = allStrategies.firstWhere(
    (s) => s.name == strategyName,
    orElse: () =>
        SavedFilter(name: strategyName, weights: {'per': 0.5, 'roe': 0.5}),
  );

  try {
    final stocks = await ref.read(allStocksForSnapshotProvider.future);
    final current = await _buildSnapshotStocksInBackground(
      stocks: stocks,
      weights: strategy.weights,
      topN: strategy.topN,
    );

    final snapshot =
        StrategySnapshot(date: date, current: current, previous: previous);

    await prefs.setString(
        cacheKey,
        jsonEncode({
          'date': date,
          'current': current.map((s) => s.toJson()).toList(),
          'previous': previous.map((s) => s.toJson()).toList(),
        }));

    developer.log('Computed $strategyName: ${current.length} stocks',
        name: 'strategySnapshot');
    return snapshot;
  } catch (e) {
    developer.log('Compute error for $strategyName: $e',
        name: 'strategySnapshot');
    return StrategySnapshot(date: date, current: [], previous: previous);
  }
}

/// 스냅샷 강제 새로고침 (캐시 삭제 후 재계산)
Future<void> refreshStrategySnapshot(WidgetRef ref, String strategyName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_snapKey(strategyName));
  ref.invalidate(strategySnapshotProvider(strategyName));
}
