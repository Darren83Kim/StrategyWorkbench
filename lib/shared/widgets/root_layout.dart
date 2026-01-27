import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key, required this.child});

  final Widget child;

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(GoRouterState.of(context).matchedLocation),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_alt),
            label: 'Strategy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
        ],
        // These properties are important for a dark theme with many items
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/dashboard');
        break;
      case 1:
        GoRouter.of(context).go('/market');
        break;
      case 2:
        GoRouter.of(context).go('/strategy');
        break;
      case 3:
        GoRouter.of(context).go('/portfolio');
        break;
    }
  }

    int _calculateSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) {
      return 0;
    }
    if (location.startsWith('/market')) {
      return 1;
    }
    if (location.startsWith('/strategy')) {
      return 2;
    }
    if (location.startsWith('/portfolio')) {
      return 3;
    }
    return 0;
  }
}
