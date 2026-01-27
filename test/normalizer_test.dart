import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/visualization/normalizer.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  test('Normalizer scales per (inverted) and roe/dividend correctly', () {
    final stocks = [
      Stock(ticker: 'A', name: 'A', price: 100, per: 5, roe: 20, dividendYield: 5, lastUpdated: DateTime.now()),
      Stock(ticker: 'B', name: 'B', price: 100, per: 50, roe: 5, dividendYield: 1, lastUpdated: DateTime.now()),
    ];

    final norm = Normalizer().normalize(stocks, ['per', 'roe', 'dividendYield']);

    // For PER: A (5) should be better than B (50) -> A.per normalized > B.per normalized
    expect(norm['A']!['per']! > norm['B']!['per']!, true);
    // For ROE: A.ro e 20 > B.ro e 5
    expect(norm['A']!['roe']! > norm['B']!['roe']!, true);
    // For dividend: A 5 > B 1
    expect(norm['A']!['dividendYield']! > norm['B']!['dividendYield']!, true);
  });
}
