import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/main.dart';
import 'package:strategy_workbench/shared/widgets/placeholder_screen.dart';
import 'package:strategy_workbench/shared/widgets/root_layout.dart';

import 'package:strategy_workbench/features/market/presentation/market_screen.dart';
import 'package:strategy_workbench/features/market/presentation/stock_detail.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return RootLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const PlaceholderScreen(screenName: 'Dashboard'),
        ),
        GoRoute(
          path: '/market',
          builder: (context, state) =>
              const MarketScreen(),
        ),
        GoRoute(
          path: '/strategy',
          builder: (context, state) =>
              const PlaceholderScreen(screenName: 'Strategy'),
        ),
        GoRoute(
          path: '/portfolio',
          builder: (context, state) =>
              const PlaceholderScreen(screenName: 'Portfolio'),
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
