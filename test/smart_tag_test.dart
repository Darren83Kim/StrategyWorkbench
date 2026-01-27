import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/tags/smart_tag.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

void main() {
  test('SmartTagger generates expected tags', () {
    final s = Stock(ticker: 'T', name: 'T', price: 100, per: 8, roe: 20, dividendYield: 5, lastUpdated: DateTime.now());
    final tags = SmartTagger().generateTags(s);
    expect(tags.contains('#저평가'), true);
    expect(tags.contains('#우량주'), true);
    expect(tags.contains('#고배당'), true);
  });
}
