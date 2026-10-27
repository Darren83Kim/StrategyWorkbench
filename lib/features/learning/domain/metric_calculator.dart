class MetricCalculatorInput {
  final double? price;
  final double? earningsPerShare;
  final double? netIncome;
  final double? equity;
  final double? dividendPerShare;

  const MetricCalculatorInput({
    this.price,
    this.earningsPerShare,
    this.netIncome,
    this.equity,
    this.dividendPerShare,
  });
}

class MetricCalculatorResult {
  final double? per;
  final double? roePercent;
  final double? dividendYieldPercent;

  const MetricCalculatorResult({
    this.per,
    this.roePercent,
    this.dividendYieldPercent,
  });
}

/// Formulas for learning. Results are calculations of the typed numbers.
class MetricCalculator {
  static double? per({required double? price, required double? eps}) {
    if (price == null || eps == null || price <= 0 || eps <= 0) {
      return null;
    }
    return price / eps;
  }

  static double? roePercent({
    required double? netIncome,
    required double? equity,
  }) {
    if (netIncome == null || equity == null || equity <= 0) {
      return null;
    }
    return netIncome / equity * 100;
  }

  static double? dividendYieldPercent({
    required double? dividendPerShare,
    required double? price,
  }) {
    if (dividendPerShare == null || price == null || price <= 0) {
      return null;
    }
    if (dividendPerShare < 0) {
      return null;
    }
    return dividendPerShare / price * 100;
  }

  static double? parseNumber(String raw) {
    final cleaned = raw.trim().replaceAll(',', '').replaceAll(' ', '');
    if (cleaned.isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
  }

  static MetricCalculatorResult evaluate(MetricCalculatorInput input) {
    return MetricCalculatorResult(
      per: per(price: input.price, eps: input.earningsPerShare),
      roePercent: roePercent(netIncome: input.netIncome, equity: input.equity),
      dividendYieldPercent: dividendYieldPercent(
        dividendPerShare: input.dividendPerShare,
        price: input.price,
      ),
    );
  }
}
