import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart'
    as strategy;

void main() {
  group('buildPortfolioFromTransactions', () {
    test('rebuilds holdings from buy and sell history', () {
      final transactions = [
        model.Transaction(
          ticker: 'aapl',
          type: model.TransactionType.BUY,
          price: 100,
          quantity: 2,
          dateTime: DateTime(2026, 4, 19, 9),
        ),
        model.Transaction(
          ticker: 'AAPL',
          type: model.TransactionType.BUY,
          price: 130,
          quantity: 1,
          dateTime: DateTime(2026, 4, 19, 10),
        ),
        model.Transaction(
          ticker: 'AAPL',
          type: model.TransactionType.SELL,
          price: 140,
          quantity: 1,
          dateTime: DateTime(2026, 4, 19, 11),
        ),
      ];

      final items = buildPortfolioFromTransactions(transactions);

      expect(items, hasLength(1));
      expect(items.single.ticker, 'AAPL');
      expect(items.single.quantity, 2);
      expect(items.single.avgPrice, closeTo(110, 0.001));
      expect(items.single.currentPrice, 140);
    });

    test('prefers cached stock metadata for name and current price', () {
      final transactions = [
        model.Transaction(
          ticker: 'msft',
          type: model.TransactionType.BUY,
          price: 200,
          quantity: 3,
          dateTime: DateTime(2026, 4, 20, 9),
        ),
      ];

      final cachedStocks = {
        'MSFT': strategy.Stock(
          ticker: 'MSFT',
          name: 'Microsoft Corp.',
          price: 415.25,
          per: 30,
          roe: 25,
          dividendYield: 0.8,
          lastUpdated: DateTime(2026, 4, 20, 9, 30),
        ),
      };

      final items = buildPortfolioFromTransactions(
        transactions,
        cachedStocks: cachedStocks,
      );

      expect(items, hasLength(1));
      expect(items.single.name, 'Microsoft Corp.');
      expect(items.single.currentPrice, 415.25);
    });

    test('uses known Korean instrument names when transaction has only a code',
        () {
      final transactions = [
        model.Transaction(
          ticker: '442580',
          type: model.TransactionType.BUY,
          price: 55550,
          quantity: 200,
          dateTime: DateTime(2026, 6, 26, 9),
        ),
      ];

      final items = buildPortfolioFromTransactions(transactions);

      expect(items, hasLength(1));
      expect(items.single.ticker, '442580');
      expect(items.single.name, 'PLUS 글로벌HBM반도체');
    });

    test('resolves KOSDAQ and ETF names from known instrument map', () {
      final transactions = [
        model.Transaction(
          ticker: '089030',
          type: model.TransactionType.BUY,
          price: 56885,
          quantity: 153,
          dateTime: DateTime(2026, 6, 29, 9),
        ),
        model.Transaction(
          ticker: '486450',
          type: model.TransactionType.BUY,
          price: 25000,
          quantity: 300,
          dateTime: DateTime(2026, 6, 29, 10),
        ),
      ];

      final items = buildPortfolioFromTransactions(transactions);

      expect(items.map((item) => item.name), [
        '테크윙',
        'SOL 미국AI전력인프라',
      ]);
    });

    test('drops holdings whose net quantity becomes zero', () {
      final transactions = [
        model.Transaction(
          ticker: 'TSLA',
          type: model.TransactionType.BUY,
          price: 220,
          quantity: 1,
          dateTime: DateTime(2026, 4, 20, 9),
        ),
        model.Transaction(
          ticker: 'TSLA',
          type: model.TransactionType.SELL,
          price: 230,
          quantity: 1,
          dateTime: DateTime(2026, 4, 20, 10),
        ),
      ];

      final items = buildPortfolioFromTransactions(transactions);

      expect(items, isEmpty);
    });
  });
}
