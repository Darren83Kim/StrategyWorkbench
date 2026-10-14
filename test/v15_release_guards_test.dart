import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/config/admob_release_guard.dart';
import 'package:strategy_workbench/core/metrics/sample_metric_policy.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  group('release AdMob guard', () {
    test('rejects empty and Google sample ids', () {
      expect(isRejectedProductionAdmobId(''), isTrue);
      expect(isRejectedProductionAdmobId('your_admob_id'), isTrue);
      expect(
        isRejectedProductionAdmobId(
          'ca-app-pub-3940256099942544/9214589741',
        ),
        isTrue,
      );
      expect(
        isRejectedProductionAdmobId(
          'ca-app-pub-8022343674155817/1234567890',
        ),
        isFalse,
      );
    });

    test('release build throws when ids are missing', () {
      expect(
        () => ensureReleaseAdmobIds(
          isReleaseBuild: true,
          appId: '',
          bannerId: 'ca-app-pub-8022343674155817/1234567890',
          interstitialId: 'ca-app-pub-8022343674155817/1234567891',
          forceTestIds: false,
        ),
        throwsStateError,
      );
    });

    test('debug build allows empty production ids', () {
      ensureReleaseAdmobIds(
        isReleaseBuild: false,
        appId: '',
        bannerId: '',
        interstitialId: '',
        forceTestIds: true,
      );
    });
  });

  group('sample metric policy', () {
    test('does not rank stocks that only have sample fundamentals', () {
      final sample = Stock(
        ticker: '005930',
        name: '삼성전자',
        price: 70000,
        per: 12,
        roe: 11,
        dividendYield: 2,
        lastUpdated: DateTime(2026, 10, 1),
        metricSources: const {
          'per': sampleMetricSource,
          'roe': sampleMetricSource,
          'dividend': sampleMetricSource,
        },
      );
      final real = Stock(
        ticker: '000660',
        name: 'SK하이닉스',
        price: 200000,
        per: 8,
        roe: 0,
        dividendYield: 0,
        lastUpdated: DateTime(2026, 10, 1),
        metricSources: const {'per': 'Naver'},
      );

      final ranked = SampleMetricPolicy.rankableStocks(
        [sample, real],
        const {'per': 0.5, 'roe': 0.5},
        rejectSampleMetrics: true,
      );

      expect(ranked.map((stock) => stock.ticker), ['000660']);
      expect(
        SampleMetricPolicy.fundamentalText(
          stock: sample,
          metric: 'per',
          formatted: '12.0',
          rejectSampleMetrics: true,
        ),
        missingMetricLabel,
      );
    });

    test('keeps a real metric after stripping a sample sibling', () {
      final mixed = Stock(
        ticker: 'AAPL',
        name: 'Apple',
        price: 200,
        per: 28,
        roe: 90,
        dividendYield: 0,
        lastUpdated: DateTime(2026, 10, 1),
        metricSources: const {
          'per': 'Finnhub',
          'roe': sampleMetricSource,
        },
      );

      final ranked = SampleMetricPolicy.rankableStocks(
        [mixed],
        const {'per': 0.5, 'roe': 0.5},
        rejectSampleMetrics: true,
      );

      expect(ranked.single.per, 28);
      expect(ranked.single.roe, 0);
      expect(ranked.single.usesSampleMetrics, isFalse);
    });

    test('keeps priced stocks visible when nothing is rankable', () {
      final priced = Stock(
        ticker: '005930',
        name: '삼성전자',
        price: 70000,
        per: 0,
        roe: 0,
        dividendYield: 0,
        lastUpdated: DateTime(2026, 10, 14),
      );

      final partition = SampleMetricPolicy.partitionForDisplay(
        [priced],
        const {'per': 0.7, 'roe': 0.3},
        rejectSampleMetrics: true,
      );

      expect(partition.ranked, isEmpty);
      expect(partition.unranked.single.ticker, '005930');
    });
  });

  group('device language', () {
    test('uses Korean for ko device locale when nothing is saved', () {
      expect(
        resolveLanguageCode(deviceLanguageCode: 'ko'),
        'ko',
      );
      expect(
        resolveLanguageCode(deviceLanguageCode: 'ko-KR'),
        'ko',
      );
      expect(
        resolveLanguageCode(saved: 'en', deviceLanguageCode: 'ko'),
        'en',
      );
      expect(
        resolveLanguageCode(deviceLanguageCode: 'en'),
        'en',
      );
    });
  });
}
