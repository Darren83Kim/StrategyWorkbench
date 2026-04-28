import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/core/providers/strategy_comparison_providers.dart';
import 'package:strategy_workbench/core/services/alert_runtime_service.dart';
import 'package:strategy_workbench/features/strategy/presentation/strategy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('strategy screen can set a preset as the active strategy',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final fakeAlertRuntime = AlertRuntimeService(
      initNotification: () async {},
      initBackground: () async {},
      registerBackground: () async {},
      cancelBackground: () async {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertRuntimeServiceProvider.overrideWithValue(fakeAlertRuntime),
        ],
        child: const MaterialApp(
          home: StrategyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정되지 않음'), findsOneWidget);
    expect(find.text('활성화'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('활성화').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('설정되지 않음'), findsNothing);
    expect(find.text('가치주 전략이 활성 전략으로 설정됐습니다.'), findsOneWidget);
    expect(find.text('활성 전략'), findsAtLeastNWidgets(1));
  });

  testWidgets('expanded strategy card shows one-line insight summaries',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          strategySnapshotProvider('가치주').overrideWith(
            (ref) async => const StrategySnapshot(
              date: '2026-04-21',
              current: [
                SnapshotStock(
                  ticker: 'AAPL',
                  name: 'Apple',
                  price: 190,
                  score: 92,
                  rank: 1,
                ),
              ],
            ),
          ),
          strategyStockInsightsProvider('가치주').overrideWith(
            (ref) async => const {
              'AAPL': StockInsightViewModel(
                strategyName: '가치주',
                headline: '가치주 기준 상위 추천 종목입니다.',
                summary: '현재 가치주 Top 10 안에서 #1 입니다.',
                drivers: [
                  StockInsightDriver(
                    metricKey: 'per',
                    label: 'PER',
                    weight: 0.7,
                    normalizedValue: 0.82,
                    rawValueLabel: '12.0',
                    summary: 'PER 12.0로 밸류 부담이 낮은 편입니다.',
                  ),
                ],
                rank: 1,
                rankChange: 2,
              ),
            },
          ),
        ],
        child: const MaterialApp(
          home: StrategyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가치주').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('PER 12.0로 밸류 부담이 낮은 편입니다.'), findsOneWidget);
  });

  testWidgets('strategy comparison sheet shows overlap summary',
      (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          strategyComparisonProvider(
            const StrategyComparisonRequest(
              leftStrategyName: '가치주',
              rightStrategyName: '배당주',
            ),
          ).overrideWith(
            (ref) async => StrategyComparisonViewModel(
              leftStrategy: SavedFilter(
                name: '가치주',
                weights: const {'per': 0.7, 'roe': 0.3},
              ),
              rightStrategy: SavedFilter(
                name: '배당주',
                weights: const {'per': 0.2, 'roe': 0.2, 'dividend': 0.6},
              ),
              overlap: const [
                StrategyComparisonMatch(
                  leftStock: SnapshotStock(
                    ticker: 'AAPL',
                    name: 'Apple',
                    price: 190,
                    score: 92,
                    rank: 1,
                  ),
                  rightStock: SnapshotStock(
                    ticker: 'AAPL',
                    name: 'Apple',
                    price: 190,
                    score: 74,
                    rank: 4,
                  ),
                ),
              ],
              onlyLeft: const [
                SnapshotStock(
                  ticker: 'MSFT',
                  name: 'Microsoft',
                  price: 410,
                  score: 88,
                  rank: 2,
                ),
              ],
              onlyRight: const [
                SnapshotStock(
                  ticker: 'KO',
                  name: 'Coca-Cola',
                  price: 61,
                  score: 80,
                  rank: 1,
                ),
              ],
              topRankDiffs: const [
                StrategyComparisonMatch(
                  leftStock: SnapshotStock(
                    ticker: 'AAPL',
                    name: 'Apple',
                    price: 190,
                    score: 92,
                    rank: 1,
                  ),
                  rightStock: SnapshotStock(
                    ticker: 'AAPL',
                    name: 'Apple',
                    price: 190,
                    score: 74,
                    rank: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: StrategyScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.compare_arrows_rounded));
    await tester.pumpAndSettle();

    expect(find.text('전략 비교'), findsOneWidget);
    expect(find.text('겹치는 종목'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
    expect(find.textContaining('L #1 · R #4'), findsOneWidget);
  });
}
