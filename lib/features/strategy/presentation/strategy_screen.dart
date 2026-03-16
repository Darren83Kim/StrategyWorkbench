import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key});

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final strategies = ref.watch(allStrategiesProvider);
    final watchlistAsync = ref.watch(watchlistProvider);
    final watchlist = watchlistAsync.value ?? {};
    final lang = ref.watch(languageProvider).value ?? 'en';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(lang == 'ko' ? '전략' : 'Strategy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: lang == 'ko' ? '새 전략 만들기' : 'New Strategy',
            onPressed: () => context.push('/filter'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: strategies.length,
        itemBuilder: (context, index) {
          final strategy = strategies[index];
          final isExpanded = _expanded.contains(strategy.name);
          final watched = watchlist[strategy.name] ?? <String>{};
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StrategyCard(
              strategy: strategy,
              isExpanded: isExpanded,
              watchedTickers: watched,
              onToggleExpand: () => setState(() {
                if (isExpanded) {
                  _expanded.remove(strategy.name);
                } else {
                  _expanded.add(strategy.name);
                }
              }),
              onToggleWatch: (ticker) =>
                  ref.read(watchlistProvider.notifier).toggle(strategy.name, ticker),
              onRefresh: () async {
                await refreshStrategySnapshot(ref, strategy.name);
              },
              onUpdateTopN: (topN) async {
                await ref
                    .read(savedFiltersProvider.notifier)
                    .updateTopN(strategy.name, topN);
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(
                    'snap_v1_${strategy.name.replaceAll(' ', '_')}');
                ref.invalidate(strategySnapshotProvider(strategy.name));
              },
              onDelete: strategy.isPreset
                  ? null
                  : () => ref
                      .read(savedFiltersProvider.notifier)
                      .removeFilter(strategy.name),
              onEdit: strategy.isPreset
                  ? null
                  : () => context.push('/filter', extra: strategy),
            ),
          );
        },
      ),
    );
  }
}

// ── 전략 카드 ──
class _StrategyCard extends ConsumerWidget {
  final SavedFilter strategy;
  final bool isExpanded;
  final Set<String> watchedTickers;
  final VoidCallback onToggleExpand;
  final void Function(String) onToggleWatch;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int) onUpdateTopN;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _StrategyCard({
    required this.strategy,
    required this.isExpanded,
    required this.watchedTickers,
    required this.onToggleExpand,
    required this.onToggleWatch,
    required this.onRefresh,
    required this.onUpdateTopN,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = isExpanded
        ? ref.watch(strategySnapshotProvider(strategy.name))
        : null;

    return GlassContainer(
      child: Column(
        children: [
          // ── 카드 헤더 ──
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (strategy.isPreset)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A5F),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('프리셋',
                                    style: TextStyle(
                                        color: Color(0xFF60A5FA),
                                        fontSize: 9)),
                              ),
                            Text(
                              strategy.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _weightsLabel(strategy.weights),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _TopNChip(
                    current: strategy.topN,
                    onChanged: onUpdateTopN,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onRefresh,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.refresh,
                          color: Colors.white38, size: 18),
                    ),
                  ),
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            color: Colors.white38, size: 17),
                      ),
                    ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            color: Colors.white24, size: 17),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── 펼쳐진 종목 목록 ──
          if (isExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            if (snapshotAsync == null)
              const SizedBox()
            else
              snapshotAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF10B981), strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('오류: $e',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
                data: (snapshot) {
                  if (snapshot.current.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('종목 데이터 없음',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    );
                  }
                  return Column(
                    children: snapshot.current
                        .map((stock) => _StockRow(
                              stock: stock,
                              isWatched: watchedTickers
                                  .contains(stock.ticker),
                              onToggle: () =>
                                  onToggleWatch(stock.ticker),
                            ))
                        .toList(),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  String _weightsLabel(Map<String, double> w) {
    final parts = <String>[];
    if ((w['per'] ?? 0) > 0) {
      parts.add('PER ${((w['per']!) * 100).toStringAsFixed(0)}%');
    }
    if ((w['roe'] ?? 0) > 0) {
      parts.add('ROE ${((w['roe']!) * 100).toStringAsFixed(0)}%');
    }
    if ((w['dividend'] ?? 0) > 0) {
      parts.add('배당 ${((w['dividend']!) * 100).toStringAsFixed(0)}%');
    }
    return parts.join(' · ');
  }
}

// ── 종목 행 ──
class _StockRow extends StatelessWidget {
  final SnapshotStock stock;
  final bool isWatched;
  final VoidCallback onToggle;

  const _StockRow({
    required this.stock,
    required this.isWatched,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  '#${stock.rank}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.ticker,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    stock.name,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '\$${stock.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              stock.score.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isWatched ? Icons.star_rounded : Icons.star_border_rounded,
              color: isWatched
                  ? const Color(0xFFF59E0B)
                  : Colors.white30,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top-N 선택 칩 ──
class _TopNChip extends StatelessWidget {
  final int current;
  final Future<void> Function(int) onChanged;

  static const _options = [5, 10, 20, 30, 50];

  const _TopNChip({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Top N 설정',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              ..._options.map((n) => ListTile(
                    dense: true,
                    title: Text(
                      'Top $n',
                      style: TextStyle(
                        color: n == current
                            ? const Color(0xFF10B981)
                            : Colors.white,
                      ),
                    ),
                    trailing: n == current
                        ? const Icon(Icons.check,
                            color: Color(0xFF10B981))
                        : null,
                    onTap: () => Navigator.pop(context, n),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
        if (selected != null && selected != current) {
          await onChanged(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top $current',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11),
            ),
            const Icon(Icons.arrow_drop_down,
                color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}
