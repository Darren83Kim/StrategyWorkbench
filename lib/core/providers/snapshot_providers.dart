import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/core/scoring/scoring_engine.dart';
import 'package:strategy_workbench/core/extensions/stock_extension.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
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
    final curRank =
        current.where((s) => s.ticker == ticker).firstOrNull?.rank;
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

// ── 전체 주식 (Hive 캐시 → API 폴백, 마켓 필터 무관) ──
final allStocksForSnapshotProvider = FutureProvider<List<Stock>>((ref) async {
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
            'Snapshot using ${cached.length} cached stocks',
            name: 'allStocksForSnapshot');
        return cached;
      }
    }
  } catch (e) {
    developer.log('Hive read error: $e', name: 'allStocksForSnapshot');
  }
  final repo = ref.read(hybridRepositoryProvider);
  return await repo.getAllStocks();
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
        developer.log(
            'Cache hit: $strategyName ($today)', name: 'strategySnapshot');
        return StrategySnapshot(
            date: today, current: current, previous: previous);
      }

      // 날짜 바뀜 → 현재를 이전으로 이동 후 재계산
      final prevStocks = (json['current'] as List)
          .map((e) => SnapshotStock.fromJson(e as Map<String, dynamic>))
          .toList();
      return await _compute(ref, strategyName, today, prevStocks, prefs, cacheKey);
    } catch (e) {
      developer.log(
          'Cache parse error for $strategyName: $e', name: 'strategySnapshot');
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
    orElse: () => SavedFilter(
        name: strategyName, weights: {'per': 0.5, 'roe': 0.5}),
  );

  try {
    final stocks = await ref.read(allStocksForSnapshotProvider.future);
    final engine = ScoringEngine();
    final marketStocks = stocks.map((s) => s.toMarketStock()).toList();
    final scored =
        engine.calculateScores(stocks: marketStocks, weights: strategy.weights);

    final current = scored
        .take(strategy.topN)
        .toList()
        .asMap()
        .entries
        .map((e) => SnapshotStock(
              ticker: e.value.stock.symbol,
              name: e.value.stock.name,
              price: e.value.stock.price,
              score: e.value.score,
              rank: e.key + 1,
            ))
        .toList();

    final snapshot =
        StrategySnapshot(date: date, current: current, previous: previous);

    await prefs.setString(
        cacheKey,
        jsonEncode({
          'date': date,
          'current': current.map((s) => s.toJson()).toList(),
          'previous': previous.map((s) => s.toJson()).toList(),
        }));

    developer.log(
        'Computed $strategyName: ${current.length} stocks',
        name: 'strategySnapshot');
    return snapshot;
  } catch (e) {
    developer.log(
        'Compute error for $strategyName: $e', name: 'strategySnapshot');
    return StrategySnapshot(date: date, current: [], previous: previous);
  }
}

/// 스냅샷 강제 새로고침 (캐시 삭제 후 재계산)
Future<void> refreshStrategySnapshot(
    WidgetRef ref, String strategyName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_snapKey(strategyName));
  ref.invalidate(strategySnapshotProvider(strategyName));
}
