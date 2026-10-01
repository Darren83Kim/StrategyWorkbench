import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/hybrid_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  test('hybrid merge keeps price and metric provenance separately', () {
    final quoteTime = DateTime(2026, 7, 10, 10);
    final sampleTime = DateTime(2026, 7, 9, 10);
    final quote = Stock(
      ticker: '005930',
      name: '삼성전자',
      price: 80000,
      per: 0,
      roe: 0,
      dividendYield: 0,
      lastUpdated: quoteTime,
      priceSource: 'Naver Finance',
    );
    final sample = Stock(
      ticker: '005930',
      name: '삼성전자',
      price: 70000,
      per: 12,
      roe: 10,
      dividendYield: 2,
      lastUpdated: sampleTime,
      priceSource: '샘플 데이터',
      metricSources: const {
        'per': '샘플 데이터',
        'roe': '샘플 데이터',
        'dividend': '샘플 데이터',
      },
      metricsUpdatedAt: sampleTime,
    );

    final merged = mergeStockData(quote, sample);

    expect(merged.price, 80000);
    expect(merged.priceSource, 'Naver Finance');
    expect(merged.per, 12);
    expect(merged.metricSources['per'], '샘플 데이터');
    expect(merged.usesSampleMetrics, isTrue);
    expect(merged.metricsUpdatedAt, sampleTime);
    expect(merged.missingMetrics, isEmpty);
  });

  test('stock reports missing metrics without treating zero as a source', () {
    final stock = Stock(
      ticker: 'AAPL',
      name: 'Apple',
      price: 200,
      per: 30,
      roe: 0,
      dividendYield: 0,
      lastUpdated: DateTime(2026, 7, 10),
      priceSource: 'Nasdaq',
      metricSources: const {'per': 'Finnhub'},
    );

    expect(stock.missingMetrics, ['ROE', '배당']);
    expect(stock.usesSampleMetrics, isFalse);
  });
}
