import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/analysis_simulator_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/features/learning/presentation/analysis_simulator_screen.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('analysis lab shows controls and comparison result',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 7, 10);
    final stocks = [
      Stock(
        ticker: '000001',
        name: '샘플 A',
        price: 10000,
        per: 5,
        roe: 5,
        dividendYield: 1,
        lastUpdated: now,
      ),
      Stock(
        ticker: '000002',
        name: '샘플 B',
        price: 20000,
        per: 20,
        roe: 30,
        dividendYield: 1,
        lastUpdated: now,
      ),
      Stock(
        ticker: '000003',
        name: '샘플 C',
        price: 15000,
        per: 10,
        roe: 10,
        dividendYield: 5,
        lastUpdated: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => stocks),
          analysisSimulationProvider.overrideWith(
            (ref, request) async => AnalysisSimulationResult(
              strategyName: request.strategyName,
              baselineWeights: const {'per': 0.7, 'roe': 0.3},
              simulatedWeights: request.normalizedWeights,
              simulatedTop: const [
                AnalysisSimulationStock(
                  ticker: '000001',
                  name: '샘플 A',
                  price: 10000,
                  baselineRank: 1,
                  simulatedRank: 1,
                  baselineScore: 0.9,
                  simulatedScore: 0.9,
                  baselineContributions: {'per': 0.7, 'roe': 0.2},
                  simulatedContributions: {'per': 0.7, 'roe': 0.2},
                ),
                AnalysisSimulationStock(
                  ticker: '000002',
                  name: '샘플 B',
                  price: 20000,
                  baselineRank: 2,
                  simulatedRank: 2,
                  baselineScore: 0.7,
                  simulatedScore: 0.7,
                  baselineContributions: {'per': 0.4, 'roe': 0.3},
                  simulatedContributions: {'per': 0.4, 'roe': 0.3},
                ),
                AnalysisSimulationStock(
                  ticker: '000003',
                  name: '샘플 C',
                  price: 15000,
                  baselineRank: 3,
                  simulatedRank: 3,
                  baselineScore: 0.5,
                  simulatedScore: 0.5,
                  baselineContributions: {'per': 0.3, 'roe': 0.2},
                  simulatedContributions: {'per': 0.3, 'roe': 0.2},
                ),
              ],
              biggestMovers: const [],
              overlapCount: 3,
              enteredCount: 0,
              exitedCount: 0,
            ),
          ),
        ],
        child: const MaterialApp(
          home: AnalysisSimulatorScreen(initialStrategyName: '가치주'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('분석 기준 실험실'), findsOneWidget);
    expect(find.text('가중치를 바꾸면 무엇이 달라질까요?'), findsOneWidget);
    expect(find.text('실험 조건'), findsOneWidget);
    expect(find.text('기준 대비 변화'), findsOneWidget);
    expect(find.textContaining('실험 결과 · 상위 3개'), findsOneWidget);
    expect(find.text('실험 기록 저장'), findsOneWidget);
    expect(find.textContaining('매수·매도를 권유하지 않습니다.'), findsOneWidget);

    await tester.ensureVisible(find.text('실험 기록 저장'));
    await tester.tap(find.text('실험 기록 저장'));
    await tester.pump();
    expect(find.text('실험 기록을 이 기기에 저장했습니다.'), findsOneWidget);
  });
}
