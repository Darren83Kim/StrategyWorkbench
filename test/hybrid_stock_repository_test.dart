import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/finnhub_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/fmp_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/hybrid_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/kor_investment_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/krx_dart_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/mock_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/nasdaq_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/yahoo_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

class _FakeFinnhubStockRepository extends FinnhubStockRepository {
  _FakeFinnhubStockRepository(this.stocksByTicker);

  final Map<String, Stock> stocksByTicker;

  @override
  Future<List<Stock>> getStocks({List<String> tickers = const []}) async {
    return stocksByTicker.values.toList();
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    return stocksByTicker[ticker];
  }
}

class _FakeFmpStockRepository extends FmpStockRepository {
  _FakeFmpStockRepository(this.stocksByTicker);

  final Map<String, Stock> stocksByTicker;

  @override
  Future<List<Stock>> getStocks({List<String> tickers = const []}) async {
    return stocksByTicker.values.toList();
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    return stocksByTicker[ticker];
  }
}

class _FakeYahooStockRepository extends YahooStockRepository {
  _FakeYahooStockRepository(this.stocksByTicker);

  final Map<String, Stock> stocksByTicker;

  @override
  Future<List<Stock>> getStocks({List<String> tickers = const []}) async {
    return stocksByTicker.values.toList();
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    return stocksByTicker[ticker];
  }
}

class _FakeNasdaqStockRepository extends NasdaqStockRepository {
  _FakeNasdaqStockRepository(this.stocksByTicker);

  final Map<String, Stock> stocksByTicker;

  @override
  Future<List<Stock>> getStocks({List<String> tickers = const []}) async {
    return stocksByTicker.values.toList();
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    return stocksByTicker[ticker];
  }
}

class _FakeKrxDartStockRepository extends KrxDartStockRepository {
  _FakeKrxDartStockRepository(this.stocksByTicker);

  final Map<String, Stock> stocksByTicker;

  @override
  Future<List<Stock>> getStocks({Map<String, String>? tickers}) async {
    return stocksByTicker.values.toList();
  }

  @override
  Future<Stock?> getStockByCode(String stockCode) async {
    return stocksByTicker[stockCode];
  }
}

class _FakeKorInvestmentRepository extends KorInvestmentRepository {
  _FakeKorInvestmentRepository(this.stocksByTicker);

  final Map<String, Stock> stocksByTicker;

  @override
  Future<List<Stock>> getStocks({List<String>? codes}) async {
    return stocksByTicker.values.toList();
  }

  @override
  Future<Stock?> getStockByCode(String code) async {
    return stocksByTicker[code];
  }
}

class _FakeMockStockRepository extends MockStockRepository {
  _FakeMockStockRepository(this.stocks);

  final List<Stock> stocks;

  @override
  Future<List<Stock>> getStocks() async {
    return stocks;
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    try {
      return stocks.firstWhere((stock) => stock.ticker == ticker);
    } catch (_) {
      return null;
    }
  }
}

Stock stock({
  required String ticker,
  required String name,
  required double price,
  double per = 0,
  double roe = 0,
  double dividendYield = 0,
}) {
  return Stock(
    ticker: ticker,
    name: name,
    price: price,
    per: per,
    roe: roe,
    dividendYield: dividendYield,
    lastUpdated: DateTime(2026, 4, 20),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('getUsStocks merges Finnhub primary with FMP and Yahoo fallbacks',
      () async {
    final repository = HybridStockRepository(
      finnhubRepository: _FakeFinnhubStockRepository({
        'AAPL': stock(
          ticker: 'AAPL',
          name: 'Apple Inc.',
          price: 200,
          per: 20,
          roe: 30,
        ),
        'MSFT': stock(
          ticker: 'MSFT',
          name: 'Microsoft',
          price: 300,
          per: 25,
          roe: 28,
        ),
      }),
      fmpRepository: _FakeFmpStockRepository({
        'GOOGL': stock(
          ticker: 'GOOGL',
          name: 'Alphabet',
          price: 150,
        ),
      }),
      yahooRepository: _FakeYahooStockRepository({
        'AMZN': stock(
          ticker: 'AMZN',
          name: 'Amazon',
          price: 180,
        ),
      }),
      nasdaqRepository: _FakeNasdaqStockRepository({
        'NVDA': stock(
          ticker: 'NVDA',
          name: 'NVIDIA Corp.',
          price: 192.53,
        ),
      }),
      mockRepository: _FakeMockStockRepository([
        stock(
          ticker: 'NVDA',
          name: 'NVIDIA Corp.',
          price: 875.4,
          per: 30,
          roe: 90,
        ),
      ]),
    );

    final stocks = await repository.getUsStocks();

    expect(stocks.map((stock) => stock.ticker).toList(),
        ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'NVDA']);
    expect(stocks.first.per, 20);
    expect(stocks.first.roe, 30);
    final nvidia = stocks.firstWhere((stock) => stock.ticker == 'NVDA');
    expect(nvidia.price, 192.53);
    expect(nvidia.roe, 90);
  });

  test('getKoreanStocks merges KRX fundamentals with Kor fallback coverage',
      () async {
    final repository = HybridStockRepository(
      krxDartRepository: _FakeKrxDartStockRepository({
        '005930': stock(
          ticker: '005930',
          name: '삼성전자',
          price: 100,
          per: 0,
          roe: 25,
        ),
      }),
      korRepository: _FakeKorInvestmentRepository({
        '005930': stock(
          ticker: '005930',
          name: '삼성전자',
          price: 101,
          per: 12,
          roe: 18,
          dividendYield: 2,
        ),
        '000660': stock(
          ticker: '000660',
          name: 'SK하이닉스',
          price: 200,
          per: 8,
          roe: 15,
          dividendYield: 1,
        ),
      }),
      allowKorInvestmentFallback: true,
    );

    final stocks = await repository.getKoreanStocks();

    expect(stocks.map((stock) => stock.ticker).toList(), ['005930', '000660']);
    final samsung = stocks.firstWhere((stock) => stock.ticker == '005930');
    expect(samsung.price, 100);
    expect(samsung.per, 12);
    expect(samsung.roe, 25);
    expect(samsung.dividendYield, 2);
  });

  test('getKoreanStocks falls back to mock when Kor runtime is disabled',
      () async {
    final repository = HybridStockRepository(
      korRepository: _FakeKorInvestmentRepository({
        '005930': stock(
          ticker: '005930',
          name: '삼성전자',
          price: 100,
          per: 12,
          roe: 18,
        ),
      }),
      mockRepository: _FakeMockStockRepository([
        stock(
          ticker: '005930',
          name: 'Mock 삼성전자',
          price: 99,
          per: 10,
          roe: 14,
        ),
      ]),
      allowKorInvestmentFallback: false,
    );

    final stocks = await repository.getKoreanStocks();

    expect(stocks.length, 1);
    expect(stocks.first.name, 'Mock 삼성전자');
  });
}
