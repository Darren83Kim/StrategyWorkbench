import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';

void main() {
  group('market price formatting', () {
    test('uses grouped won values for Korean tickers', () {
      expect(formatMarketPrice('005380', 10040000), '₩10,040,000');
    });

    test('uses grouped dollar values for US tickers', () {
      expect(formatMarketPrice('AAPL', 10040000), r'$10,040,000.00');
    });

    test('adds signs without losing market-specific formatting', () {
      expect(formatSignedMarketPrice('005380', 220000), '+₩220,000');
      expect(formatSignedMarketPrice('AAPL', -220000), r'-$220,000.00');
    });
  });
}
