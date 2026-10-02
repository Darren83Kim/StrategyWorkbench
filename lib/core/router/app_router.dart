import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/main.dart';
import 'package:strategy_workbench/shared/widgets/root_layout.dart';

import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/features/market/presentation/stock_detail.dart';
import 'package:strategy_workbench/features/dashboard/presentation/dashboard_screen.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/features/strategy/presentation/filter_creation_screen.dart';
import 'package:strategy_workbench/features/strategy/presentation/strategy_screen.dart';
import 'package:strategy_workbench/features/portfolio/presentation/portfolio_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/metric_dictionary_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/analysis_simulator_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/analysis_history_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/observation_notes_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/stock_comparison_screen.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart'
    show MarketFilter;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // state.matchedLocation을 직접 전달 → GoRouterState.of(context) 불필요
        return RootLayout(location: state.matchedLocation, child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/filter',
          builder: (context, state) => FilterCreationScreen(
            initialFilter: state.extra as SavedFilter?,
          ),
        ),
        GoRoute(
          path: '/strategy',
          builder: (context, state) => const StrategyScreen(),
        ),
        GoRoute(
          path: '/portfolio',
          redirect: (context, state) =>
              StorePolicy.showPortfolioFeatures ? null : '/dashboard',
          builder: (context, state) => const PortfolioScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/market/:symbol',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final symbol = state.pathParameters['symbol']!;
        return StockDetailScreen(symbol: symbol);
      },
    ),
    GoRoute(
      path: '/metric-dictionary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MetricDictionaryScreen(),
    ),
    GoRoute(
      path: '/analysis-lab',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final marketName = state.uri.queryParameters['market'];
        final marketFilter = MarketFilter.values
            .where(
              (filter) => filter.name == marketName,
            )
            .firstOrNull;
        return AnalysisSimulatorScreen(
          initialStrategyName: state.uri.queryParameters['strategy'],
          initialMarketFilter: marketFilter ?? MarketFilter.hybrid,
        );
      },
    ),
    GoRoute(
      path: '/analysis-history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AnalysisHistoryScreen(),
    ),
    GoRoute(
      path: '/observation-notes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ObservationNotesScreen(),
    ),
    GoRoute(
      path: '/stock-compare',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final symbols = state.uri.queryParameters['symbols']
                ?.split(',')
                .where((symbol) => symbol.trim().isNotEmpty)
                .toList() ??
            const <String>[];
        return StockComparisonScreen(initialSymbols: symbols);
      },
    ),
    GoRoute(
      path: '/debug',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) =>
          kDebugMode && !StorePolicy.isPersonalMode ? null : '/dashboard',
      builder: (context, state) => const DebugScreen(),
    ),
  ],
);
