import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/core/l10n/app_strings.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/shared/widgets/root_layout.dart';

void main() {
  testWidgets('root navigation follows the store policy mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stringsProvider.overrideWith((ref) => AppStrings.ko),
        ],
        child: const MaterialApp(
          home: RootLayout(
            location: '/dashboard',
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.ko.navDashboard), findsOneWidget);
    expect(find.text(AppStrings.ko.navStrategy), findsOneWidget);

    if (StorePolicy.showPortfolioFeatures) {
      expect(find.text(AppStrings.ko.navPortfolio), findsOneWidget);
    } else {
      expect(find.text(AppStrings.ko.navPortfolio), findsNothing);
    }
  });
}
