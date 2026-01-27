import 'package:intl/intl.dart';
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
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

    print('Last update date: $lastUpdateDateString, Today: $todayString');

    if (lastUpdateDateString != todayString) {
      print('Date is different. Syncing stocks...');
      
      final stocks = await _stockRepository.getStocks();
      final stockCache = _hiveService.stockCache;
      
      await stockCache.clear();
      
      final stockMap = {for (var stock in stocks) stock.ticker: stock};
      await stockCache.putAll(stockMap);
      
      await settings.put('last_update_date', todayString);
      
      print('Sync complete. ${stocks.length} stocks cached. New update date: $todayString');
    } else {
      print('Data is already up-to-date.');
    }
  }
}
