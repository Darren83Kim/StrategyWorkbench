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

  Stock({
    required this.ticker,
    required this.name,
    required this.price,
    required this.per,
    required this.roe,
    required this.dividendYield,
    required this.lastUpdated,
  });
}