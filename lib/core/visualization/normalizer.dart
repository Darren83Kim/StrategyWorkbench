import '../../features/strategy/domain/entities/stock.dart';

class Normalizer {
  /// Normalizes the given list of strategy `Stock` objects for the provided
  /// metrics and returns a map keyed by ticker -> metric -> normalized value (0.0..1.0).
  ///
  /// Supported metrics: 'per', 'roe', 'dividendYield'
  Map<String, Map<String, double>> normalize(List<Stock> stocks, List<String> metrics) {
    final result = <String, Map<String, double>>{};
    if (stocks.isEmpty) return result;

    // Gather values per metric
    final values = <String, List<double>>{};
    for (final m in metrics) {
      values[m] = [];
    }

    for (final s in stocks) {
      for (final m in metrics) {
        double? v;
        switch (m) {
          case 'per':
            v = s.per;
            break;
          case 'roe':
            v = s.roe;
            break;
          case 'dividendYield':
            v = s.dividendYield;
            break;
          default:
            v = null;
        }
        if (v != null) values[m]!.add(v);
      }
    }

    final mins = <String, double>{};
    final maxs = <String, double>{};
    for (final m in metrics) {
      final list = values[m]!;
      if (list.isEmpty) {
        mins[m] = 0.0;
        maxs[m] = 0.0;
      } else {
        list.sort();
        mins[m] = list.first;
        maxs[m] = list.last;
      }
    }

    for (final s in stocks) {
      final map = <String, double>{};
      for (final m in metrics) {
        double raw = 0.0;
        switch (m) {
          case 'per':
            raw = s.per;
            // For PER lower is better; invert after normalization so higher is better
            break;
          case 'roe':
            raw = s.roe;
            break;
          case 'dividendYield':
            raw = s.dividendYield;
            break;
        }
        final min = mins[m]!;
        final max = maxs[m]!;
        double norm;
        if (max - min == 0) {
          norm = 0.5; // neutral if no variation
        } else {
          norm = (raw - min) / (max - min);
        }

        // If metric is PER, lower is better -> invert
        if (m == 'per') norm = 1.0 - norm;
        // Clamp
        if (norm.isNaN) norm = 0.0;
        if (norm < 0) norm = 0.0;
        if (norm > 1) norm = 1.0;

        map[m] = norm;
      }
      result[s.ticker] = map;
    }

    return result;
  }
}
