import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';

import 'banner_ad_widget.dart';

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard),
        label: s.navDashboard,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search),
        label: s.navStrategy,
      ),
      if (StorePolicy.showPortfolioFeatures)
        BottomNavigationBarItem(
          icon: const Icon(Icons.pie_chart),
          label: s.navPortfolio,
        ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          BottomNavigationBar(
            currentIndex: _selectedIndex(location),
            onTap: (index) => _onTap(index, context),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            items: items,
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String loc) {
    if (loc.startsWith('/strategy') || loc.startsWith('/filter')) return 1;
    if (StorePolicy.showPortfolioFeatures && loc.startsWith('/portfolio')) {
      return 2;
    }
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        return;
      case 1:
        context.go('/strategy');
        return;
      case 2:
        if (StorePolicy.showPortfolioFeatures) {
          context.go('/portfolio');
        }
        return;
    }
  }
}
