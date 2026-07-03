import 'dart:developer' as developer;

import 'package:intl/intl.dart';
import 'package:strategy_workbench/core/cache/stock_cache_keys.dart';
import 'package:strategy_workbench/core/network/hive_service.dart';
import 'package:strategy_workbench/features/strategy/domain/repositories/stock_repository.dart';

class DataSyncService {
  final HiveService _hiveService;
  final StockRepository _stockRepository;

  DataSyncService({
    required HiveService hiveService,
    required StockRepository stockRepository,
  })  : _hiveService = hiveService,
        _stockRepository = stockRepository;

  Future<void> syncStocksIfNeeded() async {
    final settings = _hiveService.settings;
    final lastUpdateDateString = settings.get('last_update_date');
    final cachedVersion = settings.get(stockCacheVersionKey);
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    developer.log(
        'Last update date: $lastUpdateDateString, Today: $todayString, Cache version: $cachedVersion',
        name: 'DataSyncService');

    if (lastUpdateDateString != todayString ||
        cachedVersion != stockCacheVersion) {
      developer.log('Date is different. Syncing stocks...',
          name: 'DataSyncService');

      final stocks = await _stockRepository.getStocks();
      if (stocks.isEmpty) {
        developer.log(
            'Sync skipped because fetch returned 0 stocks. Keeping existing cache.',
            name: 'DataSyncService');
        return;
      }

      final stockCache = _hiveService.stockCache;

      await stockCache.clear();

      final stockMap = {for (var stock in stocks) stock.ticker: stock};
      await stockCache.putAll(stockMap);

      await settings.put('last_update_date', todayString);
      await settings.put(stockCacheVersionKey, stockCacheVersion);

      developer.log(
          'Sync complete. ${stocks.length} stocks cached. New update date: $todayString',
          name: 'DataSyncService');
    } else {
      developer.log('Data is already up-to-date.', name: 'DataSyncService');
    }
  }
}
