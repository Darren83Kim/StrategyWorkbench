import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/features/onboarding/onboarding_controller.dart';
import 'package:strategy_workbench/features/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding walks through three steps and completes once',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    onboardingController.completed = false;

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('dashboard-ready')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pick analysis criteria'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Build a watchlist'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Open the metric dictionary'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-ready'), findsOneWidget);
    expect(onboardingController.completed, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(onboardingCompleteKey), isTrue);
  });
}