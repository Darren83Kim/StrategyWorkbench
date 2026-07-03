import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/l10n/app_strings.dart';
import 'package:strategy_workbench/core/providers/daily_brief_providers.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/features/dashboard/presentation/dashboard_screen.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Dashboard renders today brief insights for the active strategy',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {'app_language': 'ko'});

    final strategy = SavedFilter(
      name: '가치주',
      weights: const {'per': 0.7, 'roe': 0.3},
      topN: 10,
    );
    final brief = DailyBrief(
      strategy: strategy,
      snapshot: const StrategySnapshot(
        date: '2026-04-20',
        current: [
          SnapshotStock(
            ticker: 'AAPL',
            name: 'Apple',
            price: 190,
            score: 92,
            rank: 1,
          ),
          SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 410,
            score: 88,
            rank: 2,
          ),
        ],
        previous: [
          SnapshotStock(
            ticker: 'OLD',
            name: 'Old Co',
            price: 80,
            score: 84,
            rank: 2,
          ),
        ],
      ),
      entered: const [
        SnapshotStock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 190,
          score: 92,
          rank: 1,
        ),
      ],
      exited: const [
        SnapshotStock(
          ticker: 'OLD',
          name: 'Old Co',
          price: 80,
          score: 84,
          rank: 2,
        ),
      ],
      riskHoldings: const [
        DailyBriefRiskHolding(
          item: PortfolioItem(
            ticker: 'OLD',
            name: 'Old Co',
            quantity: 2,
            avgPrice: 90,
            currentPrice: 80,
          ),
          previousRank: 2,
        ),
      ],
      topPicks: const [
        SnapshotStock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 190,
          score: 92,
          rank: 1,
        ),
        SnapshotStock(
          ticker: 'MSFT',
          name: 'Microsoft',
          price: 410,
          score: 88,
          rank: 2,
        ),
      ],
      movers: const [
        DailyBriefMover(
          stock: SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 410,
            score: 88,
            rank: 2,
          ),
          change: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stringsProvider.overrideWith((ref) => AppStrings.ko),
          activeStrategyProvider.overrideWith((ref) => strategy),
          dailyBriefProvider.overrideWith((ref) async => brief),
          stockDetailProvider.overrideWith((ref, symbol) async {
            final prices = {
              'AAPL': 199.0,
              'MSFT': 420.0,
              'OLD': 81.0,
            };
            final price = prices[symbol] ?? 100.0;
            return StockDetailViewModel(
              stock: Stock(
                ticker: symbol,
                name: symbol,
                price: price,
                per: 20,
                roe: 15,
                dividendYield: 1,
                lastUpdated: DateTime(2026, 6, 26),
              ),
              normalizedMetrics: const {},
              metrics: const [],
              tags: const [],
              peerCount: 0,
            );
          }),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.ko.dailyBriefTitle), findsOneWidget);
    expect(find.textContaining('가치주'), findsOneWidget);
    expect(find.text(AppStrings.ko.dailyBriefTopPicks), findsOneWidget);
    expect(find.text(AppStrings.ko.dailyBriefRiskHoldings),
        findsAtLeastNWidgets(1));
    expect(find.text('Apple'), findsAtLeastNWidgets(1));
    expect(find.textContaining(r'$199.00'), findsOneWidget);
    expect(find.text('Old Co'), findsAtLeastNWidgets(1));
  });
}
