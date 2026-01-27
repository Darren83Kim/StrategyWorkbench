import '../entities/stock.dart';

abstract class StockRepository {
  Future<List<Stock>> getStocks();
  Future<Stock?> getStockByTicker(String ticker);
}
