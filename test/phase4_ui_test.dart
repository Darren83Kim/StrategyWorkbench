import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/l10n/app_strings.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/rebalance_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/features/market/presentation/stock_detail.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'package:strategy_workbench/features/portfolio/presentation/portfolio_screen.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

class _FakeTransactionHistoryNotifier extends TransactionHistoryNotifier {
  @override
  Future<List<model.Transaction>> build() async => const [];

  @override
  Future<void> addTransaction(model.Transaction transaction) async {
    state = AsyncData([...(state.value ?? []), transaction]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StockDetailScreen', () {
    testWidgets(
        'renders real detail content with tags and transaction timeline',
        (tester) async {
      final detail = StockDetailViewModel(
        stock: Stock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 182.35,
          per: 25.1,
          roe: 31.4,
          dividendYield: 0.6,
          lastUpdated: DateTime(2026, 4, 17),
        ),
        normalizedMetrics: const {
          'per': 0.7,
          'roe': 0.8,
          'dividendYield': 0.4,
        },
        metrics: const ['per', 'roe', 'dividendYield'],
        tags: const ['#저평가', '#우량주'],
        peerCount: 12,
      );
      const insight = StockInsightViewModel(
        strategyName: '가치주',
        headline: '가치주 기준 상위 추천 종목입니다.',
        summary: '현재 가치주 Top 10 안에서 #2 입니다. 전일 대비 1계단 상승 했습니다.',
        drivers: [
          StockInsightDriver(
            metricKey: 'per',
            label: 'PER',
            weight: 0.7,
            normalizedValue: 0.8,
            rawValueLabel: '25.1',
            summary: 'PER 25.1로 밸류 부담이 낮은 편입니다.',
          ),
        ],
        rank: 2,
        rankChange: 1,
      );
      final transactions = [
        model.Transaction(
          ticker: 'AAPL',
          type: model.TransactionType.BUY,
          price: 180,
          quantity: 2,
          dateTime: DateTime(2026, 4, 16),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stringsProvider.overrideWith((ref) => AppStrings.ko),
            stockDetailProvider('AAPL').overrideWith((ref) async => detail),
            activeStockInsightProvider('AAPL')
                .overrideWith((ref) async => insight),
            transactionsByTickerProvider('AAPL')
                .overrideWith((ref) => AsyncData(transactions)),
          ],
          child: const MaterialApp(
            home: StockDetailScreen(symbol: 'AAPL'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.ko.stockDetailTitle), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('#저평가'), findsOneWidget);
      expect(find.text('#우량주'), findsOneWidget);
      expect(find.text(AppStrings.ko.whyThisStockTitle), findsOneWidget);
      expect(find.text('가치주 기준 상위 추천 종목입니다.'), findsOneWidget);
      expect(find.text(AppStrings.ko.whyThisStockDriversTitle), findsOneWidget);
      expect(find.text(AppStrings.ko.transactions), findsOneWidget);
      expect(find.text('2 @ \$180.00'), findsOneWidget);
    });

    testWidgets('shows a not found state when detail provider returns null',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stringsProvider.overrideWith((ref) => AppStrings.ko),
            stockDetailProvider('MISSING').overrideWith((ref) async => null),
            activeStockInsightProvider('MISSING')
                .overrideWith((ref) async => null),
            transactionsByTickerProvider('MISSING')
                .overrideWith((ref) => const AsyncData([])),
          ],
          child: const MaterialApp(
            home: StockDetailScreen(symbol: 'MISSING'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('종목을 찾을 수 없습니다'), findsOneWidget);
      expect(find.text(AppStrings.ko.retry), findsOneWidget);
    });
  });

  group('PortfolioScreen UX', () {
    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          stringsProvider.overrideWith((ref) => AppStrings.ko),
          transactionHistoryProvider
              .overrideWith(() => _FakeTransactionHistoryNotifier()),
        ],
      );
      container.read(portfolioProvider.notifier).buy('AAPL', 'Apple', 3, 150.0);
      return container;
    }

    GoRouter createRouter() {
      return GoRouter(
        initialLocation: '/portfolio',
        routes: [
          GoRoute(
            path: '/portfolio',
            builder: (context, state) => const PortfolioScreen(),
          ),
          GoRoute(
            path: '/market/:symbol',
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('detail:${state.pathParameters['symbol']}'),
              ),
            ),
          ),
        ],
      );
    }

    testWidgets('tapping a holding card opens the full detail route',
        (tester) async {
      final container = createContainer();
      addTearDown(container.dispose);
      final router = createRouter();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('AAPL').first);
      await tester.pumpAndSettle();

      expect(find.text('detail:AAPL'), findsOneWidget);
    });

    testWidgets(
        'quick actions sheet still offers detail navigation and trade actions',
        (tester) async {
      final container = createContainer();
      addTearDown(container.dispose);
      final router = createRouter();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.ko.quickActions));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.ko.viewDetails), findsOneWidget);
      expect(find.text(AppStrings.ko.buyMore), findsOneWidget);
      expect(find.text(AppStrings.ko.sell), findsOneWidget);

      await tester.ensureVisible(find.text(AppStrings.ko.viewDetails));
      await tester.tap(find.text(AppStrings.ko.viewDetails));
      await tester.pumpAndSettle();

      expect(find.text('detail:AAPL'), findsOneWidget);
    });

    testWidgets('portfolio shows rebalance coach suggestions', (tester) async {
      final container = createContainer();
      addTearDown(container.dispose);
      final router = createRouter();
      final coach = RebalanceCoach(
        strategy: SavedFilter(
          name: '가치주',
          weights: const {'per': 0.7, 'roe': 0.3},
          topN: 10,
        ),
        holdingsOutsideStrategy: const [
          PortfolioItem(
            ticker: 'IBM',
            name: 'IBM',
            quantity: 1,
            avgPrice: 120,
            currentPrice: 125,
          ),
        ],
        missingTopPicks: const [
          SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 410,
            score: 88,
            rank: 2,
          ),
        ],
        overweightHoldings: const [
          WeightedPortfolioItem(
            item: PortfolioItem(
              ticker: 'AAPL',
              name: 'Apple',
              quantity: 3,
              avgPrice: 150,
              currentPrice: 190,
            ),
            portfolioWeight: 0.58,
          ),
        ],
        suggestions: const [
          RebalanceSuggestion(
            type: RebalanceSuggestionType.review,
            ticker: 'IBM',
            headline: 'IBM 점검',
            reason: '현재 활성 전략 Top 10 밖에 있어 보유 이유를 다시 확인할 시점입니다.',
            supportingLabel: '보유 1주 · \$125.00',
          ),
          RebalanceSuggestion(
            type: RebalanceSuggestionType.add,
            ticker: 'MSFT',
            headline: 'MSFT 편입 후보',
            reason: '활성 전략에서 #2에 올라 있지만 아직 보유하고 있지 않습니다.',
            supportingLabel: '전략 점수 88.0',
          ),
        ],
      );
      final rebalanceContainer = ProviderContainer(
        parent: container,
        overrides: [
          rebalanceCoachProvider.overrideWith((ref) async => coach),
        ],
      );
      addTearDown(rebalanceContainer.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: rebalanceContainer,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.ko.rebalanceCoachTitle), findsOneWidget);
      expect(
          find.text(AppStrings.ko.rebalanceCoachSuggestions), findsOneWidget);
      expect(find.text('IBM 점검'), findsOneWidget);
      expect(find.text('MSFT 편입 후보'), findsOneWidget);
    });
  });
}
