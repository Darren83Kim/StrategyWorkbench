import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/metrics/empty_metric_help.dart';
import 'package:strategy_workbench/core/metrics/sample_metric_policy.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/core/strategy/strategy_names.dart';
import 'package:strategy_workbench/features/learning/domain/daily_question.dart';
import 'package:strategy_workbench/features/learning/domain/metric_calculator.dart';
import 'package:strategy_workbench/features/learning/domain/preset_walkthrough.dart';
import 'package:strategy_workbench/features/learning/presentation/daily_question_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/empty_metric_help_sheet.dart';
import 'package:strategy_workbench/features/learning/presentation/metric_calculator_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/preset_walkthrough_screen.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/features/strategy/presentation/strategy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('empty metric help', () {
    test('explains a missing US PER as a data-path limit', () {
      final explanation = EmptyMetricHelp.forRankingCell(
        ticker: 'AAPL',
        metricKey: 'per',
      );

      expect(explanation.whyEmpty, contains('시세 경로'));
      expect(explanation.whyEmpty, contains('PER 비중은 그 종목 점수에 들어가지 않습니다'));
      expect(explanation.meaning, contains('주가'));
      expect(explanation.scoreNote, contains('매수·매도 신호'));
      expect(explanation.whyEmpty, isNot(contains('급등')));
    });

    test('explains a sample value separately from a missing Korean metric', () {
      final sample = Stock(
        ticker: '005930',
        name: '삼성전자',
        price: 70000,
        per: 12,
        roe: 0,
        dividendYield: 0,
        lastUpdated: DateTime(2026, 10, 1),
        metricSources: const {'per': sampleMetricSource},
      );

      expect(
        EmptyMetricHelp.forStock(stock: sample, metricKey: 'per').whyEmpty,
        contains('샘플'),
      );
      expect(
        EmptyMetricHelp.forStock(stock: sample, metricKey: 'roe').whyEmpty,
        contains('확인하지 못했거나'),
      );
      expect(EmptyMetricHelp.isEmptyMetricLabel('지표 없음'), isTrue);
      expect(EmptyMetricHelp.isEmptyMetricLabel('없음'), isTrue);
      expect(EmptyMetricHelp.isEmptyMetricLabel(''), isTrue);
      expect(EmptyMetricHelp.isEmptyMetricLabel('12.4'), isFalse);
    });
  });

  group('metric calculator', () {
    test('calculates PER, ROE, and dividend yield from inputs', () {
      expect(MetricCalculator.per(price: 100, eps: 5), 20);
      expect(MetricCalculator.roePercent(netIncome: 10, equity: 50), 20);
      expect(MetricCalculator.roePercent(netIncome: -5, equity: 50), -10);
      expect(
        MetricCalculator.dividendYieldPercent(dividendPerShare: 2, price: 50),
        4,
      );
      expect(MetricCalculator.per(price: 100, eps: 0), isNull);
      expect(MetricCalculator.roePercent(netIncome: 10, equity: 0), isNull);
      expect(
        MetricCalculator.dividendYieldPercent(dividendPerShare: -1, price: 50),
        isNull,
      );
      expect(MetricCalculator.parseNumber('1,250.5'), 1250.5);
    });
  });

  group('preset walkthrough', () {
    test('walks the four presets with learning names', () {
      final steps = buildPresetWalkthrough();
      expect(steps.map((step) => step.name), [
        '가치주',
        '배당주',
        '퀀트',
        profitabilityPresetName,
      ]);
      expect(steps.last.weights['roe'], 0.8);
      final copy = steps
          .map((step) => '${step.name} ${step.lesson} ${step.orderEffect}')
          .join('\n');
      expect(copy, isNot(contains('급등')));
      expect(copy, contains('매수'));
      expect(
        presetStrategies.map((preset) => preset.name),
        isNot(contains('급등주')),
      );
    });
  });

  group('daily question and streak', () {
    test(
      'uses one question per day and keeps the same id in both languages',
      () {
        final day = DateTime(2026, 10, 27);
        final korean = DailyQuestionBank.forDate(day);
        final english = DailyQuestionBank.forDate(day, korean: false);
        expect(korean.id, english.id);
        expect(
          DailyQuestionBank.forDate(day).id,
          DailyQuestionBank.forDate(DateTime(2026, 10, 27, 23, 30)).id,
        );

        for (final question in [
          ...DailyQuestionBank.questionsKo,
          ...DailyQuestionBank.questionsEn,
        ]) {
          expect(question.choices[question.answerIndex], isNot(contains('매수')));
          expect(question.choices[question.answerIndex], isNot(contains('매도')));
          expect(
            question.explanation,
            anyOf(contains('아닙니다'), contains('not a')),
          );
        }
      },
    );

    test('counts one completion per local day', () {
      const start = LearningStreakSnapshot.empty;
      final first = LearningProgress.applyAnswer(
        current: start,
        questionId: 'per-meaning',
        now: DateTime(2026, 10, 27, 9),
      );
      final sameDay = LearningProgress.applyAnswer(
        current: first,
        questionId: 'roe-meaning',
        now: DateTime(2026, 10, 27, 21),
      );
      final nextDay = LearningProgress.applyAnswer(
        current: sameDay,
        questionId: 'dividend-meaning',
        now: DateTime(2026, 10, 28, 8),
      );
      final afterGap = LearningProgress.applyAnswer(
        current: nextDay,
        questionId: 'rank-change',
        now: DateTime(2026, 10, 30, 8),
      );

      expect(first.streak, 1);
      expect(sameDay.streak, 1);
      expect(sameDay.answeredQuestionId, 'per-meaning');
      expect(nextDay.streak, 2);
      expect(afterGap.streak, 1);
    });

    test(
      'renames a stored surge preset without dropping the watchlist',
      () async {
        SharedPreferences.setMockInitialValues({
          savedFiltersStorageKey: jsonEncode([
            {
              'name': '급등주',
              'weights': {'roe': 0.8, 'per': 0.2},
              'createdAt': '2026-10-01T00:00:00.000',
              'topN': 12,
              'sensitivity': 'Medium',
              'isPreset': true,
            },
          ]),
          activeStrategyNameStorageKey: '급등주',
          watchlistStorageKey: jsonEncode({
            '급등주': ['005930'],
          }),
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final filters = await container.read(savedFiltersProvider.future);
        final active = await container.read(activeStrategyNameProvider.future);
        final watchlist = await container.read(watchlistProvider.future);

        expect(filters.single.name, profitabilityPresetName);
        expect(filters.single.topN, 12);
        expect(active, profitabilityPresetName);
        expect(watchlist.containsKey('급등주'), isFalse);
        expect(watchlist[profitabilityPresetName], contains('005930'));

        final history = AnalysisHistoryEntry.fromJson({
          'id': '1',
          'strategyName': '급등주',
          'marketFilter': 'hybrid',
          'weights': {'roe': 0.8},
          'topSamples': [],
          'createdAt': '2026-10-01T00:00:00.000',
        });
        expect(history.strategyName, profitabilityPresetName);
      },
    );
  });

  testWidgets('empty ranking cell opens an explanation', (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          strategySnapshotProvider('가치주').overrideWith(
            (ref) async => const StrategySnapshot(
              date: '2026-10-27',
              current: [
                SnapshotStock(
                  ticker: 'AAPL',
                  name: 'Apple',
                  price: 190,
                  score: 0,
                  rank: 0,
                  ranked: false,
                  per: 0,
                  roe: 12,
                  dividendYield: 0,
                  metricsKnown: true,
                ),
              ],
            ),
          ),
          strategyStockInsightsProvider('가치주')
              .overrideWith((ref) async => const {}),
        ],
        child: const MaterialApp(home: StrategyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가치주').first);
    await tester.pumpAndSettle();

    expect(find.text('지표 없음 · 이유 보기'), findsOneWidget);
    final perHelp = find.text('PER · 지표 없음');
    await tester.ensureVisible(perHelp);
    await tester.tap(perHelp);
    await tester.pumpAndSettle();

    expect(find.text('왜 비어 있나요'), findsOneWidget);
    expect(find.textContaining('시세 경로'), findsWidgets);
    expect(find.textContaining('주가'), findsWidgets);
    expect(find.textContaining('매수·매도 신호'), findsWidgets);
  });

  testWidgets('calculator shows a PER result from typed numbers', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MetricCalculatorScreen())),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('per-price')), '100');
    await tester.enterText(find.byKey(const Key('per-eps')), '5');
    await tester.pump();

    expect(find.textContaining('20.00'), findsOneWidget);
    expect(find.textContaining('매수·매도 신호'), findsOneWidget);
  });

  testWidgets(
    'preset walkthrough moves through the renamed profitability preset',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'ko'});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PresetWalkthroughScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('가치주'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('배당주'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('퀀트'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('수익성'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.textContaining('급등'), findsNothing);
      expect(find.textContaining('매수·매도'), findsOneWidget);
    },
  );

  testWidgets('daily question completes once and keeps the streak', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpQuestion() async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: DailyQuestionScreen())),
      );
      await tester.pumpAndSettle();
    }

    await pumpQuestion();
    expect(find.textContaining('연속 학습 0일'), findsOneWidget);

    final question = DailyQuestionBank.forDate(DateTime.now());
    await tester.tap(find.text(question.answer));
    await tester.pumpAndSettle();

    expect(find.textContaining('연속 학습 1일'), findsOneWidget);
    expect(find.text(question.explanation), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpQuestion();
    expect(find.textContaining('연속 학습 1일'), findsOneWidget);
    expect(find.text('오늘 문제는 이미 마쳤습니다'), findsOneWidget);
  });

  testWidgets('empty metric chip opens the learning sheet', (tester) async {
    const explanation = EmptyMetricExplanation(
      title: 'PER · 지표 없음',
      whyEmpty: '이 앱의 미국 시세 경로에는 PER이 없습니다.',
      meaning: 'PER은 주가 ÷ 주당이익입니다.',
      scoreNote: '매수·매도 신호가 아닙니다.',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyMetricChip(label: '지표 없음', explanation: explanation),
        ),
      ),
    );

    await tester.tap(find.text('지표 없음'));
    await tester.pumpAndSettle();
    expect(find.text('학습에서 이 지표는'), findsOneWidget);
    expect(find.textContaining('주당이익'), findsOneWidget);
  });
}
