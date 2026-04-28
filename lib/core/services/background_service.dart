import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/market/models/stock.dart' as market;
import '../../features/strategy/domain/entities/stock.dart' as strategy;
import '../providers/filter_providers.dart';
import '../scoring/scoring_engine.dart';
import 'notification_service.dart';

const backgroundTask = 'backgroundStrategyCheck';
const backgroundTaskUniqueName = 'backgroundStrategyCheck.daily';
const backgroundTaskDebugUniqueName = 'backgroundStrategyCheck.debug';
const legacyBackgroundTaskUniqueName = '1';
const legacyBackgroundTaskDebugUniqueName = '2';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundTask) {
      return false;
    }

    developer.log(
      '--- Running Background Strategy Check ---',
      name: 'BackgroundService',
    );

    Box<dynamic>? stockCache;
    Box<dynamic>? settings;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(strategy.StockAdapter());
      }

      stockCache = await Hive.openBox('stock_cache');
      settings = await Hive.openBox('settings');

      final allMarketStocks = <market.Stock>[];
      for (final key in stockCache.keys) {
        final cached = stockCache.get(key);
        if (cached is strategy.Stock) {
          allMarketStocks.add(
            market.Stock(
              symbol: cached.ticker,
              name: cached.name,
              price: cached.price,
              change: 0,
              per: cached.per,
              roe: cached.roe,
              dividendYield: cached.dividendYield,
            ),
          );
        }
      }

      if (allMarketStocks.isEmpty) {
        developer.log(
          'No cached stocks found, skipping background check',
          name: 'BackgroundService',
        );
        return true;
      }

      final portfolioTickersRaw = settings.get('portfolio_tickers');
      final userPortfolio = portfolioTickersRaw is List
          ? List<String>.from(portfolioTickersRaw)
          : <String>[];

      if (userPortfolio.isEmpty) {
        developer.log(
          'Portfolio is empty, skipping',
          name: 'BackgroundService',
        );
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final activeStrategyName = prefs.getString(activeStrategyNameStorageKey);
      final savedFiltersJson = prefs.getString(savedFiltersStorageKey);
      final activeStrategy = resolveActiveStrategy(
        activeStrategyName: activeStrategyName,
        savedFiltersJson: savedFiltersJson,
      );

      if (activeStrategy == null) {
        developer.log(
          'No persisted active strategy found, skipping background check',
          name: 'BackgroundService',
        );
        return true;
      }

      developer.log(
        'Using strategy: ${activeStrategy.name} / sensitivity=${activeStrategy.sensitivity}',
        name: 'BackgroundService',
      );

      final engine = ScoringEngine();
      final scoredStocks = engine.calculateScores(
        stocks: allMarketStocks,
        weights: activeStrategy.weights,
      );

      if (scoredStocks.isEmpty) {
        developer.log(
          'No scored stocks available, skipping background check',
          name: 'BackgroundService',
        );
        return true;
      }

      final rankThreshold = calculateSensitivityRankThreshold(
        totalCount: scoredStocks.length,
        sensitivity: activeStrategy.sensitivity,
      );
      final rankedSymbols =
          scoredStocks.map((item) => item.stock.symbol).toList();
      final notificationService = NotificationService();
      await notificationService.init();

      for (final ownedTicker in userPortfolio) {
        final rankIndex = rankedSymbols.indexOf(ownedTicker);
        if (rankIndex == -1 || rankIndex >= rankThreshold) {
          final matchingStock =
              allMarketStocks.where((stock) => stock.symbol == ownedTicker);
          final stockName =
              matchingStock.isEmpty ? ownedTicker : matchingStock.first.name;

          await notificationService.showStrategyAlertNotification(
            stockName: stockName,
          );
          developer.log(
            'Sent alert: $stockName (rank: ${rankIndex == -1 ? 'not found' : rankIndex + 1}/$rankThreshold)',
            name: 'BackgroundService',
          );
        }
      }

      developer.log(
        '--- Background Strategy Check Complete ---',
        name: 'BackgroundService',
      );
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Error in background task: $error',
        name: 'BackgroundService',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      await _closeHive(stockCache, settings);
    }
  });
}

Future<void> _closeHive(
    Box<dynamic>? stockCache, Box<dynamic>? settings) async {
  try {
    await stockCache?.close();
    await settings?.close();
  } catch (_) {}
}

double sensitivityRatioForLevel(String sensitivity) {
  switch (sensitivity) {
    case 'High':
      return 0.10;
    case 'Low':
      return 0.30;
    case 'Medium':
    default:
      return 0.20;
  }
}

int calculateSensitivityRankThreshold({
  required int totalCount,
  required String sensitivity,
}) {
  if (totalCount <= 0) {
    return 1;
  }

  final ratio = sensitivityRatioForLevel(sensitivity);
  return max(1, (totalCount * ratio).ceil());
}

SavedFilter? resolveActiveStrategy({
  required String? activeStrategyName,
  required String? savedFiltersJson,
}) {
  if (activeStrategyName == null || activeStrategyName.isEmpty) {
    return null;
  }

  final merged = <String, SavedFilter>{
    for (final preset in presetStrategies) preset.name: preset,
  };

  if (savedFiltersJson != null && savedFiltersJson.isNotEmpty) {
    try {
      final decoded = jsonDecode(savedFiltersJson) as List<dynamic>;
      for (final item in decoded) {
        final filter = SavedFilter.fromJson(item as Map<String, dynamic>);
        merged[filter.name] = filter;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to parse saved filters in background isolate: $error',
        name: 'BackgroundService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  return merged[activeStrategyName];
}

class BackgroundService {
  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  Future<void> registerDailyTask() async {
    await _cancelKnownTasks();
    await Workmanager().registerPeriodicTask(
      backgroundTaskUniqueName,
      backgroundTask,
      frequency: const Duration(days: 1),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: _calculateInitialDelay(),
    );
  }

  Future<void> cancelDailyTask() async {
    await _cancelKnownTasks();
  }

  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, 16, 0);
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }
    return nextRun.difference(now);
  }

  void forceRunTask() {
    Workmanager().registerOneOffTask(
      backgroundTaskDebugUniqueName,
      backgroundTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> _cancelKnownTasks() async {
    await Future.wait([
      Workmanager().cancelByUniqueName(backgroundTaskUniqueName),
      Workmanager().cancelByUniqueName(backgroundTaskDebugUniqueName),
      Workmanager().cancelByUniqueName(legacyBackgroundTaskUniqueName),
      Workmanager().cancelByUniqueName(legacyBackgroundTaskDebugUniqueName),
    ]);
  }
}
