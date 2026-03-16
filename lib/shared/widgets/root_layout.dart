import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';

class RootLayout extends ConsumerWidget {
  const RootLayout({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(location),
        onTap: (index) => _onTap(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: s.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: s.navStrategy,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart),
            label: s.navPortfolio,
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String loc) {
    if (loc.startsWith('/strategy') || loc.startsWith('/filter')) return 1;
    if (loc.startsWith('/portfolio')) return 2;
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/strategy');
      case 2: context.go('/portfolio');
    }
  }
}
