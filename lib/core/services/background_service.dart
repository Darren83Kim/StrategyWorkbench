import 'package:workmanager/workmanager.dart';

import '../scoring/scoring_engine.dart';
import 'notification_service.dart';
import '../../features/market/models/stock.dart';

const backgroundTask = "backgroundStrategyCheck";

// This needs to be a top-level function or a static method.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundTask) {
      print("--- Running Background Strategy Check ---");
      try {
        // --- 1. Mock Data (to be replaced with real data services) ---
        final allStocks = _getMockStockData();
        final userPortfolio = _getMockUserPortfolio();
        final userStrategy = _getMockUserStrategy();

        // --- 2. Run Scoring Engine ---
        final engine = ScoringEngine();
        final scoredStocks = engine.calculateScores(
          stocks: allStocks,
          weights: userStrategy['weights'],
        );
        
        // --- 3. Check for Rank Drops (Sensitivity Logic) ---
        final sensitivity = userStrategy['sensitivity']; // e.g., 'High', 'Medium', 'Low'
        final rankThreshold = _getRankThreshold(sensitivity); // e.g., 10, 20, 30

        final rankedSymbols = scoredStocks.map((s) => s.stock.symbol).toList();

        for (final ownedStockSymbol in userPortfolio) {
          final rank = rankedSymbols.indexOf(ownedStockSymbol);
          
          // If the stock is not in the top N ranks, send a notification.
          if (rank == -1 || rank >= rankThreshold) {
            final stock = allStocks.firstWhere((s) => s.symbol == ownedStockSymbol);
            await NotificationService().init(); // Ensure initialized
            await NotificationService().showStrategyAlertNotification(
              stockName: stock.name,
            );
            print("--- Sent notification for ${stock.name} ---");
          }
        }
        
        print("--- Background Strategy Check Complete ---");
        return Future.value(true);
      } catch (e) {
        print("Error in background task: $e");
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}

int _getRankThreshold(String sensitivity) {
    switch (sensitivity) {
        case 'High': return 10;
        case 'Medium': return 20;
        case 'Low': return 30;
        default: return 20;
    }
}

// MOCK: Replace with actual data fetching
List<Stock> _getMockStockData() {
    return [
        Stock(symbol: "AAPL", name: "Apple Inc.", price: 170.0, change: 1.5, per: 28.0, roe: 0.4),
        Stock(symbol: "GOOGL", name: "Alphabet Inc.", price: 2800.0, change: -10.0, per: 26.0, roe: 0.25),
        Stock(symbol: "MSFT", name: "Microsoft Corp.", price: 300.0, change: 2.0, per: 35.0, roe: 0.3),
        // Add 30+ stocks to make ranking meaningful
        ...List.generate(30, (i) => Stock(symbol: "STK$i", name: "Stock $i", price: 100.0 + i, change: i % 2, per: 15.0 + i, roe: 0.1 + (i*0.01))),
        Stock(symbol: "TSLA", name: "Tesla Inc.", price: 700.0, change: 20.0, per: 90.0, roe: 0.2), // User's stock, will drop rank
    ];
}

// MOCK: Replace with actual portfolio service
List<String> _getMockUserPortfolio() {
    return ["TSLA"];
}

// MOCK: Replace with actual strategy service
Map<String, dynamic> _getMockUserStrategy() {
    return {
        'weights': {'per': 0.6, 'roe': 0.4},
        'sensitivity': 'Medium', // High, Medium, Low
    };
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
      // Android-specific constraints
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      // This is not a guaranteed exact time, but the task will run around this time.
      initialDelay: _calculateInitialDelay(),
    );
  }

  // Calculate the delay until the next 4 PM
  Duration _calculateInitialDelay() {
    final now = DateTime.now();
    DateTime nextRun = DateTime(now.year, now.month, now.day, 16, 0); // 4 PM today
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1)); // 4 PM tomorrow
    }
    return nextRun.difference(now);
  }

  // For testing purposes
  void forceRunTask() {
      Workmanager().registerOneOffTask("2", backgroundTask);
  }
}
