import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/analysis_simulator_providers.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('observation notes are normalized, limited, and removable', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(observationNotesProvider.future);

    await container.read(observationNotesProvider.notifier).save(
      ticker: ' aapl ',
      name: 'Apple Inc.',
      text: List.filled(350, 'a').join(),
      tags: const ['PER', 'ROE', 'PER', '배당', '데이터', '기타'],
    );

    final note = container.read(observationNotesProvider).value!['AAPL']!;
    expect(note.text.length, maxObservationNoteLength);
    expect(note.tags, hasLength(4));
    expect(note.tags.toSet(), hasLength(4));

    await container.read(observationNotesProvider.notifier).clearAll();
    expect(container.read(observationNotesProvider).value, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(observationNotesStorageKey), isNull);
  });

  test('analysis history keeps only the latest 20 entries', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(analysisHistoryProvider.future);

    for (var index = 0; index < 21; index++) {
      await container.read(analysisHistoryProvider.notifier).add(
            result: _result('실험 $index'),
            marketFilter: MarketFilter.hybrid,
          );
    }

    final history = container.read(analysisHistoryProvider).value!;
    expect(history, hasLength(maxAnalysisHistoryCount));
    expect(history.first.strategyName, '실험 20');
    expect(history.last.strategyName, '실험 1');
    expect(history.first.topSamples.single.ticker, 'AAPL');

    await container
        .read(analysisHistoryProvider.notifier)
        .delete(history.first.id);
    expect(container.read(analysisHistoryProvider).value, hasLength(19));

    await container.read(analysisHistoryProvider.notifier).clearAll();
    expect(container.read(analysisHistoryProvider).value, isEmpty);
  });
}

AnalysisSimulationResult _result(String name) {
  return AnalysisSimulationResult(
    strategyName: name,
    baselineWeights: const {'per': 0.5, 'roe': 0.5},
    simulatedWeights: const {'per': 0.3, 'roe': 0.6, 'dividend': 0.1},
    simulatedTop: const [
      AnalysisSimulationStock(
        ticker: 'AAPL',
        name: 'Apple Inc.',
        price: 200,
        baselineRank: 2,
        simulatedRank: 1,
        baselineScore: 0.7,
        simulatedScore: 0.8,
        baselineContributions: {'per': 0.3, 'roe': 0.4},
        simulatedContributions: {'per': 0.2, 'roe': 0.6},
      ),
    ],
    biggestMovers: const [],
    overlapCount: 1,
    enteredCount: 0,
    exitedCount: 0,
  );
}
