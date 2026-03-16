import 'package:json_annotation/json_annotation.dart';

part 'stock.g.dart';

@JsonSerializable()
class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double? per;
  final double? roe;
  final double? dividendYield;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    this.per,
    this.roe,
    this.dividendYield,
  });

  factory Stock.fromJson(Map<String, dynamic> json) => _$StockFromJson(json);
  Map<String, dynamic> toJson() => _$StockToJson(this);
}
