import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // 접힌 전략 이름 Set (기본값: 모두 펼쳐짐)
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final allStrategies = ref.watch(allStrategiesProvider);
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider).value ?? 'en';
    final watchlist = watchlistAsync.value ?? {};

    // 관심 종목이 있는 전략만 표시
    final activeStrategies = allStrategies
        .where((strat) => (watchlist[strat.name] ?? <String>{}).isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(s.dashboardTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => ref.read(languageProvider.notifier).toggle(),
            child: Text(
              s.langToggle,
              style: TextStyle(
                color:
                    lang == 'ko' ? const Color(0xFF10B981) : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: activeStrategies.isEmpty
          ? _buildEmpty(lang)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeStrategies.length,
              itemBuilder: (context, index) {
                final strategy = activeStrategies[index];
                final watched =
                    watchlist[strategy.name] ?? <String>{};
                final isCollapsed =
                    _collapsed.contains(strategy.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StrategyWatchCard(
                    strategy: strategy,
                    watchedTickers: watched,
                    isCollapsed: isCollapsed,
                    onToggleCollapse: () => setState(() {
                      if (isCollapsed) {
                        _collapsed.remove(strategy.name);
                      } else {
                        _collapsed.add(strategy.name);
                      }
                    }),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(String lang) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border_rounded,
              color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          Text(
            lang == 'ko'
                ? '관심 종목이 없습니다.\n전략 탭에서 ★ 표시로 종목을 선택하세요.'
                : 'No watchlisted stocks.\nStar stocks in the Strategy tab.',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── 전략별 관심 종목 카드 ──
class _StrategyWatchCard extends ConsumerWidget {
  final SavedFilter strategy;
  final Set<String> watchedTickers;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const _StrategyWatchCard({
    required this.strategy,
    required this.watchedTickers,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync =
        ref.watch(strategySnapshotProvider(strategy.name));

    return snapshotAsync.when(
      loading: () => GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(strategy.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF10B981))),
            ],
          ),
        ),
      ),
      error: (e, _) => GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('${strategy.name}: 로드 오류',
              style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12)),
        ),
      ),
      data: (snapshot) {
        // 관심 등록 + 현재 top-N에 있는 종목
        final presentStocks = snapshot.current
            .where((s) => watchedTickers.contains(s.ticker))
            .toList();

        // 관심 등록 + top-N 이탈한 종목
        final exitedStocks = snapshot.exitedStocks(watchedTickers);

        final exitCount = exitedStocks.length;
        final total = presentStocks.length + exitedStocks.length;

        return GlassContainer(
          child: Column(
            children: [
              // ── 헤더 (접기/펼치기) ──
              InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        isCollapsed
                            ? Icons.chevron_right
                            : Icons.expand_more,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          strategy.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '★ $total',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      if (exitCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[900],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$exitCount 이탈',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── 종목 목록 (펼쳐진 경우) ──
              if (!isCollapsed) ...[
                const Divider(color: Colors.white12, height: 1),

                // 현재 top-N에 있는 관심 종목
                ...presentStocks.map((stock) {
                  final rankChange = snapshot.rankChange(stock.ticker);
                  return _WatchedRow(
                    stock: stock,
                    rankChange: rankChange,
                    isExited: false,
                    onTap: () =>
                        context.push('/market/${stock.ticker}'),
                  );
                }),

                // 이탈 종목
                ...exitedStocks.map((stock) => _WatchedRow(
                      stock: stock,
                      rankChange: null,
                      isExited: true,
                      onTap: () =>
                          context.push('/market/${stock.ticker}'),
                    )),

                if (total == 0)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('관심 종목 없음',
                        style: TextStyle(color: Colors.white38)),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── 관심 종목 행 ──
class _WatchedRow extends StatelessWidget {
  final SnapshotStock stock;
  final int? rankChange;
  final bool isExited;
  final VoidCallback onTap;

  const _WatchedRow({
    required this.stock,
    required this.rankChange,
    required this.isExited,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            // 순위 / 이탈 배지
            SizedBox(
              width: 38,
              child: isExited
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C2D12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '이탈',
                        style: TextStyle(
                          color: Color(0xFFFB923C),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '#${stock.rank}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),

            // 종목 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.ticker,
                    style: TextStyle(
                      color: isExited ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    stock.name,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 가격
            Text(
              '\$${stock.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: isExited ? Colors.white38 : Colors.white70,
                fontSize: 12,
              ),
            ),

            // 순위 변동
            if (!isExited && rankChange != null && rankChange != 0) ...[
              const SizedBox(width: 8),
              _RankBadge(change: rankChange!),
            ] else if (!isExited && rankChange == 0) ...[
              const SizedBox(width: 8),
              const Text('—',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 순위 변동 배지 ──
class _RankBadge extends StatelessWidget {
  final int change;
  const _RankBadge({required this.change});

  @override
  Widget build(BuildContext context) {
    final isUp = change > 0;
    final color = isUp ? Colors.green[400]! : Colors.red[400]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
          size: 11,
        ),
        Text(
          '${change.abs()}',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
