import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:strategy_workbench/core/network/hive_service.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/features/strategy/domain/repositories/stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/services/data_sync_service.dart';

class _FakeHiveService extends HiveService {
  _FakeHiveService({
    required Box stockCacheBox,
    required Box settingsBox,
  })  : _stockCacheBox = stockCacheBox,
        _settingsBox = settingsBox;

  final Box _stockCacheBox;
  final Box _settingsBox;

  @override
  Box get stockCache => _stockCacheBox;

  @override
  Box get settings => _settingsBox;
}

class _FakeStockRepository implements StockRepository {
  _FakeStockRepository(this.stocks);

  final List<Stock> stocks;

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    return stocks.where((stock) => stock.ticker == ticker).firstOrNull;
  }

  @override
  Future<List<Stock>> getStocks() async => stocks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box stockCacheBox;
  late Box settingsBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('strategy_workbench_hive_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StockAdapter());
    }
    stockCacheBox = await Hive.openBox('stock_cache');
    settingsBox = await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Stock stock(String ticker) => Stock(
        ticker: ticker,
        name: ticker,
        price: 100,
        per: 10,
        roe: 20,
        dividendYield: 1,
        lastUpdated: DateTime(2026, 4, 20),
      );

  test('keeps existing cache when sync fetch returns empty', () async {
    await stockCacheBox.put('AAPL', stock('AAPL'));
    await settingsBox.put('last_update_date', '2026-04-19');

    final service = DataSyncService(
      hiveService: _FakeHiveService(
        stockCacheBox: stockCacheBox,
        settingsBox: settingsBox,
      ),
      stockRepository: _FakeStockRepository([]),
    );

    await service.syncStocksIfNeeded();

    expect(stockCacheBox.length, 1);
    expect(settingsBox.get('last_update_date'), '2026-04-19');
  });

  test('replaces cache and updates last_update_date when sync succeeds',
      () async {
    await stockCacheBox.put('OLD', stock('OLD'));
    await settingsBox.put('last_update_date', '2026-04-19');

    final service = DataSyncService(
      hiveService: _FakeHiveService(
        stockCacheBox: stockCacheBox,
        settingsBox: settingsBox,
      ),
      stockRepository: _FakeStockRepository([
        stock('AAPL'),
        stock('MSFT'),
      ]),
    );

    await service.syncStocksIfNeeded();

    expect(stockCacheBox.length, 2);
    expect(stockCacheBox.get('AAPL'), isA<Stock>());
    expect(stockCacheBox.get('OLD'), isNull);
    expect(settingsBox.get('last_update_date'), '2026-04-20');
  });
}
