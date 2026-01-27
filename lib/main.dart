import 'package:strategy_workbench/core/router/app_router.dart';
import 'package:flutter/material.dart';

import 'package:strategy_workbench/core/network/hive_service.dart';
import 'package:strategy_workbench/core/services/background_service.dart';
import 'package:strategy_workbench/core/services/notification_service.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/mock_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/services/data_sync_service.dart';
import 'package:strategy_workbench/core/theme/app_theme.dart';
import 'core/scoring/scoring_engine.dart';
import 'features/market/models/stock.dart';
import 'dart:developer' as developer;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  developer.log('main() started', name: 'main');

  try {
    developer.log('Initializing HiveService...', name: 'main');
    final hiveService = HiveService();
    await hiveService.init();
    developer.log('HiveService initialized', name: 'main');

    developer.log('Initializing NotificationService...', name: 'main');
    final notificationService = NotificationService();
    await notificationService.init();
    developer.log('NotificationService initialized', name: 'main');

    developer.log('Initializing BackgroundService...', name: 'main');
    final backgroundService = BackgroundService();
    await backgroundService.init();
    developer.log('BackgroundService initialized', name: 'main');
    await backgroundService.registerDailyTask();
    developer.log('BackgroundService registered daily task', name: 'main');

    developer.log('Setting up repositories and data sync...', name: 'main');
    final stockRepository = MockStockRepository();
    final dataSyncService = DataSyncService(
      hiveService: hiveService,
      stockRepository: stockRepository,
    );

    developer.log('Syncing data if needed...', name: 'main');
    await dataSyncService.syncStocksIfNeeded();
    developer.log('Data sync complete', name: 'main');
  } catch (e, st) {
    developer.log('App initialization failed: $e', name: 'main', error: e, stackTrace: st);
  }

  developer.log('Calling runApp()', name: 'main');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Strategy Workbench',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  void _runScoringTest() {
    developer.log("--- Running Scoring Engine Test ---");
    final engine = ScoringEngine();
    final testStocks = [
      Stock(symbol: "GOOD", name: "Good Stock", price: 100, change: 1, per: 10, roe: 0.2),
      Stock(symbol: "BAD_PER", name: "Bad PER Stock", price: 100, change: 1, per: 0, roe: 0.15),
      Stock(symbol: "NULL_ROE", name: "Null ROE Stock", price: 100, change: 1, per: 15, roe: null),
      Stock(symbol: "BEST", name: "Best Stock", price: 100, change: 1, per: 5, roe: 0.3),
    ];
    final weights = {'per': 0.5, 'roe': 0.5};

    final results = engine.calculateScores(stocks: testStocks, weights: weights);

    final logOutput = StringBuffer();
    logOutput.writeln("Scoring Test Results (Sorted by score):");
    for (final res in results) {
      logOutput.writeln(
        "${res.stock.name}: Score = ${res.score.toStringAsFixed(2)}, "
        "PER Score = ${res.normalizedScores['per']?.toStringAsFixed(2)}, "
        "ROE Score = ${res.normalizedScores['roe']?.toStringAsFixed(2)}"
      );
    }
    developer.log(logOutput.toString());
  }

  void _forceBackgroundTask() {
    developer.log("--- Forcing Background Task ---");
    BackgroundService().forceRunTask();
    developer.log("One-off background task has been registered. Check logs/notifications in a few moments.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Debug & Verification"),
        backgroundColor: Colors.black26,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _runScoringTest,
                child: const Text("Test Scoring Engine"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _forceBackgroundTask,
                child: const Text("Force Run Background Task"),
              ),
              const SizedBox(height: 40),
              const Text(
                "Use the buttons above to verify phase 3 features.\n\n"
                "1. 'Test Scoring' runs the engine with normal and abnormal data (PER=0, ROE=null). Check the console log for results.\n\n"
                "2. 'Force Run' triggers the background task. A notification for 'Tesla Inc.' should appear shortly if it falls out of the top 20 ranks.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
