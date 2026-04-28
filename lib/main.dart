import 'dart:async';

import 'package:strategy_workbench/core/router/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:strategy_workbench/core/network/hive_service.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/services/alert_runtime_service.dart';
import 'package:strategy_workbench/core/services/background_service.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/hybrid_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/kor_investment_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/services/data_sync_service.dart';
import 'package:strategy_workbench/core/theme/app_theme.dart';
import 'core/scoring/scoring_engine.dart';
import 'features/market/models/stock.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 예외 핸들러 - 앱 강제 종료 방지 및 원인 로그 기록
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log(
      'FlutterError: ${details.exception}',
      name: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'PlatformError: $error',
      name: 'PlatformError',
      error: error,
      stackTrace: stack,
    );
    return true; // true = 처리됨, 앱 종료 방지
  };

  developer.log('main() started', name: 'main');

  // 1. 환경변수 로드 (빠름)
  try {
    await dotenv.load(fileName: '.env');
    developer.log('.env loaded', name: 'main');
  } catch (e) {
    developer.log('Warning: .env load failed: $e', name: 'main');
  }

  // 2. Hive 초기화 (runApp 전에 반드시 완료해야 함 - providers가 즉시 사용)
  final hiveService = HiveService();
  try {
    await hiveService.init();
    developer.log('HiveService initialized', name: 'main');
  } catch (e, st) {
    developer.log('HiveService init failed: $e',
        name: 'main', error: e, stackTrace: st);
  }

  // 3. 앱 즉시 시작 (스플래시 → 대시보드)
  developer.log('runApp() called', name: 'main');
  runApp(const ProviderScope(child: MyApp()));

  // 활성 전략이 없으면 남아 있는 백그라운드 알림 작업부터 빠르게 정리한다.
  unawaited(_cancelAlertTasksIfIdle());

  // 4. 무거운 초기화는 첫 프레임 이후로 늦춰 초기 반응성을 확보한다.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_deferServiceInit(hiveService));
  });
}

Future<void> _cancelAlertTasksIfIdle() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final activeStrategyName = prefs.getString(activeStrategyNameStorageKey);
    if (activeStrategyName == null || activeStrategyName.isEmpty) {
      await AlertRuntimeService.shared.syncForStrategy(strategyName: null);
      developer.log(
        'Cancelled alert tasks on startup because no active strategy exists',
        name: 'main',
      );
    }
  } catch (e, st) {
    developer.log(
      'Idle alert cleanup failed: $e',
      name: 'main',
      error: e,
      stackTrace: st,
    );
  }
}

Future<void> _deferServiceInit(HiveService hiveService) async {
  const alertDelay = kDebugMode ? 5200 : 900;
  const syncDelay = kDebugMode ? 3200 : 1400;

  await Future<void>.delayed(const Duration(milliseconds: alertDelay));
  await _initAlertRuntimeIfNeeded();

  await Future<void>.delayed(const Duration(milliseconds: syncDelay));
  await _syncStocksAsync(hiveService);
}

/// 활성 전략이 있을 때만 알림/백그라운드 런타임을 올린다.
Future<void> _initAlertRuntimeIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final activeStrategyName = prefs.getString(activeStrategyNameStorageKey);

    await AlertRuntimeService.shared.syncForStrategy(
      strategyName: activeStrategyName,
    );
    developer.log(
      'Alert runtime sync complete (active=$activeStrategyName)',
      name: 'main',
    );
  } catch (e, st) {
    developer.log('Alert runtime init failed: $e',
        name: 'main', error: e, stackTrace: st);
  }
}

/// 앱 렌더링 후 캐시 동기화를 더 늦게 수행해 첫 화면 반응성을 우선한다.
Future<void> _syncStocksAsync(HiveService hiveService) async {
  try {
    if (kDebugMode && hiveService.stockCache.isNotEmpty) {
      developer.log(
        'Startup data sync skipped in debug because cache already exists',
        name: 'main',
      );
      return;
    }

    final stockRepository = HybridStockRepository();
    final dataSyncService = DataSyncService(
      hiveService: hiveService,
      stockRepository: stockRepository,
    );
    await dataSyncService.syncStocksIfNeeded();
    developer.log('DataSync complete', name: 'main');
  } catch (e, st) {
    developer.log(
      'DataSync init failed: $e',
      name: 'main',
      error: e,
      stackTrace: st,
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Strategy Workbench',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      // 한국어 로케일 지원
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
      ],
    );
  }
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _statusMessage = 'Ready for testing...';
  bool _isLoading = false;

  void _runScoringTest() {
    developer.log("--- Running Scoring Engine Test ---");
    final engine = ScoringEngine();
    final testStocks = [
      Stock(
          symbol: "GOOD",
          name: "Good Stock",
          price: 100,
          change: 1,
          per: 10,
          roe: 0.2),
      Stock(
          symbol: "BAD_PER",
          name: "Bad PER Stock",
          price: 100,
          change: 1,
          per: 0,
          roe: 0.15),
      Stock(
          symbol: "NULL_ROE",
          name: "Null ROE Stock",
          price: 100,
          change: 1,
          per: 15,
          roe: null),
      Stock(
          symbol: "BEST",
          name: "Best Stock",
          price: 100,
          change: 1,
          per: 5,
          roe: 0.3),
    ];
    final weights = {'per': 0.5, 'roe': 0.5};

    final results =
        engine.calculateScores(stocks: testStocks, weights: weights);

    final logOutput = StringBuffer();
    logOutput.writeln("Scoring Test Results (Sorted by score):");
    for (final res in results) {
      logOutput.writeln(
          "${res.stock.name}: Score = ${res.score.toStringAsFixed(2)}, "
          "PER Score = ${res.normalizedScores['per']?.toStringAsFixed(2)}, "
          "ROE Score = ${res.normalizedScores['roe']?.toStringAsFixed(2)}");
    }
    developer.log(logOutput.toString());
    setState(() {
      _statusMessage = 'Scoring test completed - check logs';
    });
  }

  void _forceBackgroundTask() {
    developer.log("--- Forcing Background Task ---");
    BackgroundService().forceRunTask();
    developer.log(
        "One-off background task has been registered. Check logs/notifications in a few moments.");
    setState(() {
      _statusMessage = 'Background task triggered - check notifications';
    });
  }

  Future<void> _testYahooApi() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching US stocks from Yahoo...';
    });

    try {
      final repo = HybridStockRepository();
      final stocks = await repo.getUsStocks();

      setState(() {
        _statusMessage =
            'Yahoo: ${stocks.length} stocks loaded\n${stocks.take(3).map((s) => '${s.ticker}: \$${s.price.toStringAsFixed(2)}').join('\n')}';
        _isLoading = false;
      });
      developer.log('Yahoo test result: ${stocks.length} stocks',
          name: 'DebugScreen');
    } catch (e) {
      setState(() {
        _statusMessage = 'Yahoo API Error: $e';
        _isLoading = false;
      });
      developer.log('Yahoo API Error: $e', name: 'DebugScreen', error: e);
    }
  }

  Future<void> _testKorInvestmentApi() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching Korean stocks...';
    });

    try {
      final repo = HybridStockRepository(
        korRepository: KorInvestmentRepository(),
      );
      final stocks = await repo.getKoreanStocks();

      setState(() {
        _statusMessage =
            'Korean: ${stocks.length} stocks loaded\n${stocks.take(3).map((s) => '${s.ticker}: \$${s.price.toStringAsFixed(2)}').join('\n')}';
        _isLoading = false;
      });
      developer.log('Korean API test result: ${stocks.length} stocks',
          name: 'DebugScreen');
    } catch (e) {
      setState(() {
        _statusMessage = 'Korean API Error: $e';
        _isLoading = false;
      });
      developer.log('Korean API Error: $e', name: 'DebugScreen', error: e);
    }
  }

  Future<void> _testHybridApi() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching all stocks (Hybrid)...';
    });

    try {
      final repo = HybridStockRepository(
        korRepository: KorInvestmentRepository(),
      );
      final stocks = await repo.getAllStocks();

      setState(() {
        _statusMessage =
            'Hybrid: ${stocks.length} total stocks\n${stocks.take(5).map((s) => '${s.ticker}: \$${s.price.toStringAsFixed(2)}').join('\n')}';
        _isLoading = false;
      });
      developer.log('Hybrid API test result: ${stocks.length} stocks',
          name: 'DebugScreen');
    } catch (e) {
      setState(() {
        _statusMessage = 'Hybrid API Error: $e';
        _isLoading = false;
      });
      developer.log('Hybrid API Error: $e', name: 'DebugScreen', error: e);
    }
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Phase 3 Tests
                ElevatedButton(
                  onPressed: _runScoringTest,
                  child: const Text("Test Scoring Engine"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _forceBackgroundTask,
                  child: const Text("Force Run Background Task"),
                ),
                const Divider(height: 30),

                // API Tests
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testYahooApi,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Test Yahoo API (US Stocks)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testKorInvestmentApi,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Test Korea Investment API"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testHybridApi,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Test Hybrid (All Sources)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
