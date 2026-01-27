import '../../features/strategy/domain/entities/stock.dart';

class SmartTagger {
  /// Returns a list of tags based on simple threshold rules.
  ///
  /// Rules (as in phase4):
  /// - PER < 10 => '#저평가'
  /// - ROE > 15 => '#우량주'
  /// - DividendYield > 4 => '#고배당'
  List<String> generateTags(Stock stock) {
    final tags = <String>[];
    try {
      if (stock.per < 10) tags.add('#저평가');
    } catch (_) {}
    try {
      if (stock.roe > 15) tags.add('#우량주');
    } catch (_) {}
    try {
      if (stock.dividendYield > 4) tags.add('#고배당');
    } catch (_) {}
    return tags;
  }
}
