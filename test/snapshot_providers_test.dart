import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('strategySnapshotProvider recomputes when same-day cache is empty',
      () async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    SharedPreferences.setMockInitialValues({
      'snap_v1_배당주': jsonEncode({
        'date': today,
        'current': <Map<String, dynamic>>[],
        'previous': [
          {
            'ticker': 'OLD',
            'name': 'Old Snapshot',
            'price': 99.0,
            'score': 12.0,
            'rank': 1,
          }
        ],
      }),
    });

    final stocks = [
      Stock(
        ticker: 'AAPL',
        name: 'Apple',
        price: 190,
        per: 20,
        roe: 30,
        dividendYield: 1.2,
        lastUpdated: DateTime(2026, 4, 20),
      ),
      Stock(
        ticker: 'MSFT',
        name: 'Microsoft',
        price: 410,
        per: 22,
        roe: 28,
        dividendYield: 0.9,
        lastUpdated: DateTime(2026, 4, 20),
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        allStocksForSnapshotProvider.overrideWith((ref) async => stocks),
      ],
    );
    addTearDown(container.dispose);

    final snapshot =
        await container.read(strategySnapshotProvider('배당주').future);

    expect(snapshot.current, isNotEmpty);
    expect(snapshot.current.first.ticker, 'AAPL');
    expect(snapshot.previous.single.ticker, 'OLD');

    final prefs = await SharedPreferences.getInstance();
    final cached =
        jsonDecode(prefs.getString('snap_v1_배당주')!) as Map<String, dynamic>;
    final current = cached['current'] as List<dynamic>;
    expect(current, isNotEmpty);
    expect((current.first as Map<String, dynamic>)['ticker'], 'AAPL');
  });
}
