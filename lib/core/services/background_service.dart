import 'dart:convert';

import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../scoring/scoring_engine.dart';
import 'notification_service.dart';
import '../../features/market/models/stock.dart' as market;
import '../../features/strategy/domain/entities/stock.dart' as strategy;
import 'dart:developer' as developer;

const backgroundTask = "backgroundStrategyCheck";

/// WorkManager 콜백 (별도 Isolate에서 실행)
/// Hive stock_cache, SharedPreferences saved_filters 에서 실 데이터를 읽어
/// 스코어링 후 순위 이탈 종목에 알림을 보냄.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundTask) {
      developer.log("--- Running Background Strategy Check ---",
          name: 'BackgroundService');
      try {
        // --- 0. Isolate에서 Hive 재초기화 ---
        final appDocDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocDir.path);
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(strategy.StockAdapter());
        }

        final stockCache = await Hive.openBox('stock_cache');
        final settings = await Hive.openBox('settings');

        // --- 1. Hive에서 주식 데이터 로드 ---
        final allMarketStocks = <market.Stock>[];
        for (final key in stockCache.keys) {
          final s = stockCache.get(key);
          if (s is strategy.Stock) {
            allMarketStocks.add(market.Stock(
              symbol: s.ticker,
              name: s.name,
              price: s.price,
              change: 0,
              per: s.per,
              roe: s.roe,
            ));
          }
        }

        if (allMarketStocks.isEmpty) {
          developer.log('No cached stocks found, skipping background check',
              name: 'BackgroundService');
          await _closeHive(stockCache, settings);
          return true;
        }

        developer.log('Loaded ${allMarketStocks.length} stocks from Hive cache',
            name: 'BackgroundService');

        // --- 2. 포트폴리오 티커 로드 (Hive settings) ---
        final portfolioTickersRaw = settings.get('portfolio_tickers');
        final List<String> userPortfolio;
        if (portfolioTickersRaw is List) {
          userPortfolio = portfolioTickersRaw.cast<String>();
        } else {
          developer.log('No portfolio tickers found, skipping',
              name: 'BackgroundService');
          await _closeHive(stockCache, settings);
          return true;
        }

        if (userPortfolio.isEmpty) {
          developer.log('Portfolio is empty, skipping',
              name: 'BackgroundService');
          await _closeHive(stockCache, settings);
          return true;
        }

        developer.log('Portfolio tickers: $userPortfolio',
            name: 'BackgroundService');

        // --- 3. 필터 가중치 로드 (SharedPreferences) ---
        final prefs = await SharedPreferences.getInstance();
        Map<String, double> weights = {'per': 0.5, 'roe': 0.5}; // 기본값
        String sensitivity = 'Medium';

        final activeFilterJson = prefs.getString('active_filter');
        if (activeFilterJson != null) {
          try {
            final filterData = jsonDecode(activeFilterJson) as Map<String, dynamic>;
            final w = filterData['weights'] as Map<String, dynamic>?;
            if (w != null) {
              weights = w.map((k, v) => MapEntry(k, (v as num).toDouble()));
            }
            sensitivity = filterData['sensitivity'] as String? ?? 'Medium';
          } catch (e) {
            developer.log('Failed to parse active filter: $e',
                name: 'BackgroundService');
          }
        }

        developer.log('Weights: $weights, Sensitivity: $sensitivity',
            name: 'BackgroundService');

        // --- 4. 스코어링 엔진 실행 ---
        final engine = ScoringEngine();
        final scoredStocks = engine.calculateScores(
          stocks: allMarketStocks,
          weights: weights,
        );

        // --- 5. 순위 이탈 감지 & 알림 ---
        final rankThreshold = _getRankThreshold(sensitivity);
        final rankedSymbols =
            scoredStocks.map((s) => s.stock.symbol).toList();

        for (final ownedTicker in userPortfolio) {
          final rank = rankedSymbols.indexOf(ownedTicker);

          if (rank == -1 || rank >= rankThreshold) {
            // 보유 종목이 전략 순위권 밖으로 이탈
            final stockName = allMarketStocks
                .where((s) => s.symbol == ownedTicker)
                .map((s) => s.name)
                .firstOrNull ?? ownedTicker;

            await NotificationService().init();
            await NotificationService().showStrategyAlertNotification(
              stockName: stockName,
            );
            developer.log(
                "Sent alert: $stockName (rank: ${rank == -1 ? 'not found' : rank + 1}/$rankThreshold)",
                name: 'BackgroundService');
          }
        }

        developer.log("--- Background Strategy Check Complete ---",
            name: 'BackgroundService');
        await _closeHive(stockCache, settings);
        return true;
      } catch (e, st) {
        developer.log("Error in background task: $e",
            name: 'BackgroundService', error: e, stackTrace: st);
        return false;
      }
    }
    return false;
  });
}

Future<void> _closeHive(Box stockCache, Box settings) async {
  try {
    await stockCache.close();
    await settings.close();
  } catch (_) {}
}

int _getRankThreshold(String sensitivity) {
  switch (sensitivity) {
    case 'High':
      return 10;
    case 'Medium':
      return 20;
    case 'Low':
      return 30;
    default:
      return 20;
  }
}

class BackgroundService {
  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // TODO: Set to false for release
    );
  }

  Future<void> registerDailyTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      backgroundTask,
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: _calculateInitialDelay(),
    );
  }

  /// 오후 4시까지의 지연시간 계산
  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    DateTime nextRun =
        DateTime(now.year, now.month, now.day, 16, 0); // 오후 4시
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }
    return nextRun.difference(now);
  }

  /// 디버그용 즉시 실행
  void forceRunTask() {
    Workmanager().registerOneOffTask("2", backgroundTask);
  }
}
