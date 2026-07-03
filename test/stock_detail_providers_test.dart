import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'package:strategy_workbench/features/strategy/data/repositories/hybrid_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

class _FakeHybridStockRepository extends HybridStockRepository {
  final Stock? stockToReturn;

  _FakeHybridStockRepository({this.stockToReturn});

  @override
  Future<Stock?> getStock(String symbol) async {
    return stockToReturn;
  }

  @override
  Future<List<Stock>> getAllStocks({bool useMock = false}) async {
    return stockToReturn == null ? [] : [stockToReturn!];
  }
}

class _StaticPortfolioNotifier extends PortfolioNotifier {
  _StaticPortfolioNotifier(this.items);

  final List<PortfolioItem> items;

  @override
  List<PortfolioItem> build() => items;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('stockDetailProvider', () {
    test('returns the exact stock from the cached universe', () async {
      final stocks = [
        Stock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 190,
          per: 28,
          roe: 35,
          dividendYield: 0.5,
          lastUpdated: DateTime(2026, 4, 17),
        ),
        Stock(
          ticker: 'MSFT',
          name: 'Microsoft',
          price: 410,
          per: 30,
          roe: 31,
          dividendYield: 0.7,
          lastUpdated: DateTime(2026, 4, 17),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => stocks),
          hybridRepositoryProvider.overrideWith(
            (ref) => _FakeHybridStockRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(stockDetailProvider('AAPL').future);

      expect(detail, isNotNull);
      expect(detail!.stock.ticker, 'AAPL');
      expect(detail.peerCount, 1);
      expect(detail.normalizedMetrics.keys, contains('per'));
    });

    test('prefers live repository detail over a stale cached universe',
        () async {
      final cachedStocks = [
        Stock(
          ticker: '000660',
          name: 'SK하이닉스',
          price: 196000,
          per: 13.1,
          roe: 38.5,
          dividendYield: 0.9,
          lastUpdated: DateTime(2026, 4, 17),
        ),
      ];
      final liveStock = Stock(
        ticker: '000660',
        name: 'SK하이닉스',
        price: 2723000,
        per: 13.1,
        roe: 38.5,
        dividendYield: 0.9,
        lastUpdated: DateTime(2026, 6, 26),
      );

      final container = ProviderContainer(
        overrides: [
          allStocksForSnapshotProvider
              .overrideWith((ref) async => cachedStocks),
          hybridRepositoryProvider.overrideWith(
            (ref) => _FakeHybridStockRepository(stockToReturn: liveStock),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(stockDetailProvider('000660').future);

      expect(detail, isNotNull);
      expect(detail!.stock.price, 2723000);
    });

    test('falls back to repository lookup when stock is missing from cache',
        () async {
      final fallbackStock = Stock(
        ticker: 'TSLA',
        name: 'Tesla',
        price: 210,
        per: 55,
        roe: 18,
        dividendYield: 0.0,
        lastUpdated: DateTime(2026, 4, 17),
      );

      final container = ProviderContainer(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => []),
          hybridRepositoryProvider.overrideWith(
            (ref) => _FakeHybridStockRepository(stockToReturn: fallbackStock),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(stockDetailProvider('TSLA').future);

      expect(detail, isNotNull);
      expect(detail!.stock.ticker, 'TSLA');
      expect(detail.peerCount, 0);
    });

    test('falls back to a portfolio holding when market data is unavailable',
        () async {
      final container = ProviderContainer(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => []),
          hybridRepositoryProvider.overrideWith(
            (ref) => _FakeHybridStockRepository(),
          ),
          portfolioProvider.overrideWith(
            () => _StaticPortfolioNotifier(
              const [
                PortfolioItem(
                  ticker: '442580',
                  name: '442580',
                  quantity: 200,
                  avgPrice: 55550,
                  currentPrice: 55550,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(stockDetailProvider('442580').future);

      expect(detail, isNotNull);
      expect(detail!.stock.ticker, '442580');
      expect(detail.stock.name, 'PLUS 글로벌HBM반도체');
      expect(detail.stock.price, 55550);
      expect(detail.tags, isEmpty);
    });

    test('returns null when the symbol is unavailable everywhere', () async {
      final container = ProviderContainer(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => []),
          hybridRepositoryProvider.overrideWith(
            (ref) => _FakeHybridStockRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final detail =
          await container.read(stockDetailProvider('MISSING').future);

      expect(detail, isNull);
    });
  });

  group('stock detail helpers', () {
    test('findStockBySymbol matches symbols case-insensitively', () {
      final stocks = [
        Stock(
          ticker: 'NVDA',
          name: 'NVIDIA',
          price: 900,
          per: 60,
          roe: 40,
          dividendYield: 0.1,
          lastUpdated: DateTime(2026, 4, 17),
        ),
      ];

      final stock = findStockBySymbol(stocks, 'nvda');

      expect(stock, isNotNull);
      expect(stock!.name, 'NVIDIA');
    });

    test('findStockBySymbol pads omitted leading zeros for Korean codes', () {
      final stocks = [
        Stock(
          ticker: '033780',
          name: 'KT&G',
          price: 111500,
          per: 10.5,
          roe: 14.2,
          dividendYield: 7.8,
          lastUpdated: DateTime(2026, 4, 17),
        ),
      ];

      final stock = findStockBySymbol(stocks, '33780');

      expect(normalizeTickerInput('33780'), '033780');
      expect(stock, isNotNull);
      expect(stock!.ticker, '033780');
    });

    test('filterTransactionsByTicker filters and sorts by date descending', () {
      final filtered = filterTransactionsByTicker(
        [
          model.Transaction(
            ticker: 'AAPL',
            type: model.TransactionType.BUY,
            price: 100,
            quantity: 1,
            dateTime: DateTime(2026, 4, 14),
          ),
          model.Transaction(
            ticker: 'MSFT',
            type: model.TransactionType.BUY,
            price: 200,
            quantity: 2,
            dateTime: DateTime(2026, 4, 15),
          ),
          model.Transaction(
            ticker: 'aapl',
            type: model.TransactionType.SELL,
            price: 110,
            quantity: 1,
            dateTime: DateTime(2026, 4, 16),
          ),
        ],
        'AAPL',
      );

      expect(filtered.length, 2);
      expect(filtered.first.type, model.TransactionType.SELL);
      expect(filtered.last.type, model.TransactionType.BUY);
    });

    test('buildStockInsight summarizes strategy fit and rank movement', () {
      final insight = buildStockInsight(
        strategy: SavedFilter(
          name: '가치주',
          weights: const {'per': 0.7, 'roe': 0.3},
          topN: 10,
        ),
        detail: StockDetailViewModel(
          stock: Stock(
            ticker: 'AAPL',
            name: 'Apple',
            price: 190,
            per: 12,
            roe: 28,
            dividendYield: 0.6,
            lastUpdated: DateTime(2026, 4, 17),
          ),
          normalizedMetrics: const {
            'per': 0.82,
            'roe': 0.76,
            'dividendYield': 0.20,
          },
          metrics: const ['per', 'roe', 'dividendYield'],
          tags: const ['#저평가'],
          peerCount: 8,
        ),
        snapshot: const StrategySnapshot(
          date: '2026-04-20',
          current: [
            SnapshotStock(
              ticker: 'AAPL',
              name: 'Apple',
              price: 190,
              score: 91,
              rank: 2,
            ),
          ],
          previous: [
            SnapshotStock(
              ticker: 'AAPL',
              name: 'Apple',
              price: 186,
              score: 86,
              rank: 4,
            ),
          ],
        ),
      );

      expect(insight.strategyName, '가치주');
      expect(insight.rank, 2);
      expect(insight.rankChange, 2);
      expect(insight.drivers.first.metricKey, 'per');
      expect(insight.headline, contains('상위 추천 종목'));
      expect(insight.summary, contains('Top 10'));
      expect(insight.summary, contains('2계단 상승'));
      expect(insight.compactSummary, contains('#2'));
      expect(insight.compactSummary, contains('↑2'));
    });
  });

  group('strategyStockInsightsProvider', () {
    test('builds a batched insight map for the expanded strategy list',
        () async {
      final stocks = [
        Stock(
          ticker: 'AAPL',
          name: 'Apple',
          price: 190,
          per: 12,
          roe: 28,
          dividendYield: 0.6,
          lastUpdated: DateTime(2026, 4, 17),
        ),
        Stock(
          ticker: 'MSFT',
          name: 'Microsoft',
          price: 410,
          per: 30,
          roe: 22,
          dividendYield: 0.9,
          lastUpdated: DateTime(2026, 4, 17),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          allStocksForSnapshotProvider.overrideWith((ref) async => stocks),
          strategySnapshotProvider('가치주').overrideWith(
            (ref) async => const StrategySnapshot(
              date: '2026-04-21',
              current: [
                SnapshotStock(
                  ticker: 'AAPL',
                  name: 'Apple',
                  price: 190,
                  score: 92,
                  rank: 1,
                ),
              ],
              previous: [
                SnapshotStock(
                  ticker: 'AAPL',
                  name: 'Apple',
                  price: 186,
                  score: 88,
                  rank: 3,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final insights =
          await container.read(strategyStockInsightsProvider('가치주').future);

      expect(insights.keys, contains('AAPL'));
      expect(insights['AAPL']?.rank, 1);
      expect(insights['AAPL']?.compactSummary, contains('↑2'));
    });
  });
}
