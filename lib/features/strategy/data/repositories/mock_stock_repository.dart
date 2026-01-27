import '../../domain/entities/stock.dart';
import '../../domain/repositories/stock_repository.dart';

class MockStockRepository implements StockRepository {
  @override
  Future<List<Stock>> getStocks() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();

    return [
      Stock(
        ticker: '005930',
        name: '삼성전자',
        price: 85000,
        per: 15.0,
        roe: 12.5,
        dividendYield: 2.5,
        lastUpdated: now,
      ),
      Stock(
        ticker: '000660',
        name: 'SK하이닉스',
        price: 130000,
        per: 18.0,
        roe: 15.0,
        dividendYield: 1.8,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'AAPL',
        name: 'Apple Inc.',
        price: 175.0,
        per: 28.5,
        roe: 45.0,
        dividendYield: 0.5,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'TSLA',
        name: 'Tesla Inc.',
        price: 700.0,
        per: 60.0,
        roe: 25.0,
        dividendYield: 0.0,
        lastUpdated: now,
      ),
      Stock(
        ticker: 'MSFT',
        name: 'Microsoft Corp.',
        price: 300.0,
        per: 35.0,
        roe: 40.0,
        dividendYield: 0.8,
        lastUpdated: now,
      ),
    ];
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    final stocks = await getStocks();
    try {
      return stocks.firstWhere((stock) => stock.ticker == ticker);
    } catch (e) {
      return null;
    }
  }
}
