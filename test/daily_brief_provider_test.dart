import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/daily_brief_providers.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';

class _StaticPortfolioNotifier extends PortfolioNotifier {
  _StaticPortfolioNotifier(this.items);

  final List<PortfolioItem> items;

  @override
  List<PortfolioItem> build() => items;
}

void main() {
  group('dailyBriefProvider', () {
    test('calculates entered, exited, risk holdings and movers', () async {
      final strategy = SavedFilter(
        name: '가치주',
        weights: const {'per': 0.7, 'roe': 0.3},
        topN: 10,
      );
      const snapshot = StrategySnapshot(
        date: '2026-04-20',
        current: [
          SnapshotStock(
            ticker: 'AAPL',
            name: 'Apple',
            price: 190,
            score: 92,
            rank: 1,
          ),
          SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 410,
            score: 88,
            rank: 2,
          ),
          SnapshotStock(
            ticker: 'TSLA',
            name: 'Tesla',
            price: 260,
            score: 80,
            rank: 3,
          ),
        ],
        previous: [
          SnapshotStock(
            ticker: 'OLD',
            name: 'Old Co',
            price: 70,
            score: 90,
            rank: 1,
          ),
          SnapshotStock(
            ticker: 'AAPL',
            name: 'Apple',
            price: 188,
            score: 86,
            rank: 2,
          ),
          SnapshotStock(
            ticker: 'NVDA',
            name: 'NVIDIA',
            price: 900,
            score: 83,
            rank: 3,
          ),
          SnapshotStock(
            ticker: 'MSFT',
            name: 'Microsoft',
            price: 405,
            score: 79,
            rank: 4,
          ),
        ],
      );
      final portfolio = [
        const PortfolioItem(
          ticker: 'OLD',
          name: 'Old Co',
          quantity: 2,
          avgPrice: 80,
          currentPrice: 70,
        ),
        const PortfolioItem(
          ticker: 'IBM',
          name: 'IBM',
          quantity: 1,
          avgPrice: 120,
          currentPrice: 123,
        ),
        const PortfolioItem(
          ticker: 'AAPL',
          name: 'Apple',
          quantity: 3,
          avgPrice: 150,
          currentPrice: 190,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          activeStrategyProvider.overrideWith((ref) => strategy),
          portfolioProvider.overrideWith(
            () => _StaticPortfolioNotifier(portfolio),
          ),
          strategySnapshotProvider(strategy.name)
              .overrideWith((ref) async => snapshot),
        ],
      );
      addTearDown(container.dispose);

      final brief = await container.read(dailyBriefProvider.future);

      expect(brief, isNotNull);
      expect(brief!.entered.map((stock) => stock.ticker), ['TSLA']);
      expect(brief.exited.map((stock) => stock.ticker), ['OLD', 'NVDA']);
      expect(
          brief.riskHoldings.map((risk) => risk.item.ticker), ['OLD', 'IBM']);
      expect(brief.riskHoldings.first.recentlyExited, isTrue);
      expect(brief.topPicks.map((stock) => stock.ticker),
          ['AAPL', 'MSFT', 'TSLA']);
      expect(brief.movers.map((mover) => mover.stock.ticker), ['MSFT', 'AAPL']);
      expect(brief.movers.map((mover) => mover.change), [2, 1]);
    });

    test('returns null when no active strategy is configured', () async {
      final container = ProviderContainer(
        overrides: [
          activeStrategyProvider.overrideWith((ref) => null),
          portfolioProvider.overrideWith(
            () => _StaticPortfolioNotifier(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final brief = await container.read(dailyBriefProvider.future);

      expect(brief, isNull);
    });
  });
}
