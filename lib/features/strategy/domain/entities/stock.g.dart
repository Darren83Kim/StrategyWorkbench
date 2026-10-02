// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 0;

  @override
  Stock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stock(
      ticker: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      per: fields[3] as double,
      roe: fields[4] as double,
      dividendYield: fields[5] as double,
      lastUpdated: fields[6] as DateTime,
      priceSource: fields[7] as String? ?? '출처 미확인',
      metricSources: fields[8] == null
          ? const {}
          : Map<String, String>.from(fields[8] as Map),
      metricsUpdatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.ticker)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.per)
      ..writeByte(4)
      ..write(obj.roe)
      ..writeByte(5)
      ..write(obj.dividendYield)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.priceSource)
      ..writeByte(8)
      ..write(obj.metricSources)
      ..writeByte(9)
      ..write(obj.metricsUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
