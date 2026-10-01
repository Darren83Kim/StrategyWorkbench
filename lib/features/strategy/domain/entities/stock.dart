import 'package:hive/hive.dart';

part 'stock.g.dart';

@HiveType(typeId: 0)
class Stock extends HiveObject {
  @HiveField(0)
  final String ticker;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final double per;

  @HiveField(4)
  final double roe;

  @HiveField(5)
  final double dividendYield;

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7)
  final String priceSource;

  @HiveField(8)
  final Map<String, String> metricSources;

  @HiveField(9)
  final DateTime? metricsUpdatedAt;

  Stock({
    required this.ticker,
    required this.name,
    required this.price,
    required this.per,
    required this.roe,
    required this.dividendYield,
    required this.lastUpdated,
    this.priceSource = '출처 미확인',
    this.metricSources = const {},
    this.metricsUpdatedAt,
  });

  bool get usesSampleMetrics =>
      metricSources.values.any((source) => source == '샘플 데이터');

  List<String> get missingMetrics => [
        if (per <= 0) 'PER',
        if (roe <= 0) 'ROE',
        if (dividendYield <= 0) '배당',
      ];

  Stock copyWith({
    String? ticker,
    String? name,
    double? price,
    double? per,
    double? roe,
    double? dividendYield,
    DateTime? lastUpdated,
    String? priceSource,
    Map<String, String>? metricSources,
    DateTime? metricsUpdatedAt,
  }) {
    return Stock(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      price: price ?? this.price,
      per: per ?? this.per,
      roe: roe ?? this.roe,
      dividendYield: dividendYield ?? this.dividendYield,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      priceSource: priceSource ?? this.priceSource,
      metricSources:
          metricSources ?? Map<String, String>.from(this.metricSources),
      metricsUpdatedAt: metricsUpdatedAt ?? this.metricsUpdatedAt,
    );
  }
}
