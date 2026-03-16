import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/main.dart';
import 'package:strategy_workbench/shared/widgets/root_layout.dart';

import 'package:strategy_workbench/features/market/presentation/stock_detail.dart';
import 'package:strategy_workbench/features/dashboard/presentation/dashboard_screen.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/features/strategy/presentation/filter_creation_screen.dart';
import 'package:strategy_workbench/features/strategy/presentation/strategy_screen.dart';
import 'package:strategy_workbench/features/portfolio/presentation/portfolio_screen.dart';

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
          builder: (context, state) =>
              const DashboardScreen(),
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
          builder: (context, state) =>
              const PortfolioScreen(),
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
      path: '/debug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DebugScreen(),
    ),
  ],
);
