// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stock _$StockFromJson(Map<String, dynamic> json) => Stock(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      per: (json['per'] as num?)?.toDouble(),
      roe: (json['roe'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StockToJson(Stock instance) => <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'price': instance.price,
      'change': instance.change,
      'per': instance.per,
      'roe': instance.roe,
      'dividendYield': instance.dividendYield,
    };
