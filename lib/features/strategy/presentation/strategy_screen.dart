import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/core/providers/strategy_comparison_providers.dart';
import 'package:strategy_workbench/core/services/alert_runtime_service.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class StrategyScreen extends ConsumerStatefulWidget {
  const StrategyScreen({super.key});

  @override
  ConsumerState<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends ConsumerState<StrategyScreen> {
  final Set<String> _expanded = {};

  Future<void> _clearStrategySnapshot(String strategyName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('snap_v1_${strategyName.replaceAll(' ', '_')}');
    ref.invalidate(strategySnapshotProvider(strategyName));
  }

  Future<void> _showComparisonSheet(
    List<SavedFilter> strategies,
    String? activeStrategyName,
  ) async {
    final strings = ref.read(stringsProvider);
    if (strategies.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.strategyCompareNeedTwo),
          backgroundColor: const Color(0xFF334155),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      showDragHandle: true,
      builder: (_) => _StrategyComparisonSheet(
        strategies: strategies,
        activeStrategyName: activeStrategyName,
      ),
    );
  }

  Future<void> _setActiveStrategy(String strategyName) async {
    await ref.read(activeStrategyNameProvider.notifier).setActive(strategyName);
    unawaited(
      ref
          .read(alertRuntimeServiceProvider)
          .syncForStrategy(strategyName: strategyName),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$strategyName 전략이 활성 전략으로 설정됐습니다.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _deleteStrategy(
    SavedFilter strategy,
    String? activeStrategyName,
  ) async {
    await ref.read(savedFiltersProvider.notifier).removeFilter(strategy.name);
    await _clearStrategySnapshot(strategy.name);

    final hasPresetReplacement =
        presetStrategies.any((preset) => preset.name == strategy.name);
    if (activeStrategyName == strategy.name && !hasPresetReplacement) {
      await ref.read(activeStrategyNameProvider.notifier).setActive(null);
      unawaited(AlertRuntimeService.shared.syncForStrategy(strategyName: null));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${strategy.name} 전략이 삭제됐습니다.'),
        backgroundColor: const Color(0xFF334155),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strategies = ref.watch(allStrategiesProvider);
    final activeStrategyName = ref.watch(activeStrategyNameProvider).value;
    final activeStrategy = ref.watch(activeStrategyProvider);
    final watchlistAsync = ref.watch(watchlistProvider);
    final watchlist = watchlistAsync.value ?? {};
    final lang = ref.watch(languageProvider).value ?? 'en';
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(lang == 'ko' ? '전략' : 'Strategy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: strings.strategyCompareAction,
            onPressed: () =>
                _showComparisonSheet(strategies, activeStrategyName),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: lang == 'ko' ? '새 전략 만들기' : 'New Strategy',
            onPressed: () => context.push('/filter'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 활성 전략',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeStrategy?.name ?? '설정되지 않음',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (activeStrategy != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Top ${activeStrategy.topN} · ${_sensitivityLabel(activeStrategy.sensitivity)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                    isActive: activeStrategyName == strategy.name,
                    watchedTickers: watched,
                    onToggleExpand: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(strategy.name);
                      } else {
                        _expanded.add(strategy.name);
                      }
                    }),
                    onToggleWatch: (ticker) => ref
                        .read(watchlistProvider.notifier)
                        .toggle(strategy.name, ticker),
                    onRefresh: () async {
                      await refreshStrategySnapshot(ref, strategy.name);
                    },
                    onUpdateTopN: (topN) async {
                      await ref
                          .read(savedFiltersProvider.notifier)
                          .updateTopN(strategy.name, topN);
                      await _clearStrategySnapshot(strategy.name);
                    },
                    onActivate: () => _setActiveStrategy(strategy.name),
                    onDelete: strategy.isPreset
                        ? null
                        : () => _deleteStrategy(strategy, activeStrategyName),
                    onEdit: strategy.isPreset
                        ? null
                        : () => context.push('/filter', extra: strategy),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyComparisonSheet extends ConsumerStatefulWidget {
  final List<SavedFilter> strategies;
  final String? activeStrategyName;

  const _StrategyComparisonSheet({
    required this.strategies,
    required this.activeStrategyName,
  });

  @override
  ConsumerState<_StrategyComparisonSheet> createState() =>
      _StrategyComparisonSheetState();
}

class _StrategyComparisonSheetState
    extends ConsumerState<_StrategyComparisonSheet> {
  late String _leftStrategyName;
  late String _rightStrategyName;

  @override
  void initState() {
    super.initState();
    final names = widget.strategies.map((strategy) => strategy.name).toList();
    _leftStrategyName = widget.activeStrategyName ?? names.first;
    _rightStrategyName = names.firstWhere(
      (name) => name != _leftStrategyName,
      orElse: () => names.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final hasDifferentSelection = _leftStrategyName != _rightStrategyName;
    final comparisonAsync = hasDifferentSelection
        ? ref.watch(
            strategyComparisonProvider(
              StrategyComparisonRequest(
                leftStrategyName: _leftStrategyName,
                rightStrategyName: _rightStrategyName,
              ),
            ),
          )
        : null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.strategyCompareTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _StrategySelector(
                label: s.strategyCompareLeft,
                value: _leftStrategyName,
                items: widget.strategies,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _leftStrategyName = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _StrategySelector(
                label: s.strategyCompareRight,
                value: _rightStrategyName,
                items: widget.strategies,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _rightStrategyName = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!hasDifferentSelection)
                _StrategyCompareMessage(message: s.strategyCompareSameSelection)
              else if (comparisonAsync == null)
                _StrategyCompareMessage(message: s.loading)
              else
                comparisonAsync.when(
                  loading: () => const GlassContainer(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  error: (error, _) => _StrategyCompareMessage(
                    message: '${s.loadFailed} $error',
                    isError: true,
                  ),
                  data: (comparison) {
                    if (comparison == null) {
                      return _StrategyCompareMessage(
                        message: s.strategyCompareSameSelection,
                      );
                    }
                    return _StrategyComparisonResult(
                      comparison: comparison,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategySelector extends StatelessWidget {
  final String label;
  final String value;
  final List<SavedFilter> items;
  final ValueChanged<String?> onChanged;

  const _StrategySelector({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFF1E293B),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          items: items
              .map(
                (strategy) => DropdownMenuItem<String>(
                  value: strategy.name,
                  child: Text(
                    strategy.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StrategyCompareMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _StrategyCompareMessage({
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(
            color: isError ? const Color(0xFFEF9A9A) : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StrategyComparisonResult extends ConsumerWidget {
  final StrategyComparisonViewModel comparison;

  const _StrategyComparisonResult({
    required this.comparison,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ComparisonStatCard(
                    label: s.strategyCompareOverlap,
                    value: comparison.overlap.length.toString(),
                    accent: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonStatCard(
                    label: s.strategyCompareOnlyLeft,
                    value: comparison.onlyLeft.length.toString(),
                    accent: const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonStatCard(
                    label: s.strategyCompareOnlyRight,
                    value: comparison.onlyRight.length.toString(),
                    accent: const Color(0xFFFB923C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (comparison.overlap.isEmpty)
              Text(
                s.strategyCompareNoOverlap,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              )
            else ...[
              Text(
                s.strategyCompareTopDiffs,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...comparison.topRankDiffs.map(
                (match) => _ComparisonRankGapRow(match: match),
              ),
            ],
            if (comparison.onlyLeft.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ComparisonChipSection(
                title:
                    '${comparison.leftStrategy.name} · ${s.strategyCompareOnlyLeft}',
                stocks: comparison.onlyLeft,
                accent: const Color(0xFF60A5FA),
              ),
            ],
            if (comparison.onlyRight.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ComparisonChipSection(
                title:
                    '${comparison.rightStrategy.name} · ${s.strategyCompareOnlyRight}',
                stocks: comparison.onlyRight,
                accent: const Color(0xFFFB923C),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparisonStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ComparisonStatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRankGapRow extends StatelessWidget {
  final StrategyComparisonMatch match;

  const _ComparisonRankGapRow({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final isLeftHigher = match.leftStock.rank < match.rightStock.rank;
    final accent =
        isLeftHigher ? const Color(0xFF60A5FA) : const Color(0xFFFB923C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.ticker,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  comparisonLabel(match.leftStock.rank, match.rightStock.rank),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${match.absoluteRankGap} rank',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String comparisonLabel(int leftRank, int rightRank) {
    return 'L #$leftRank · R #$rightRank';
  }
}

class _ComparisonChipSection extends StatelessWidget {
  final String title;
  final List<SnapshotStock> stocks;
  final Color accent;

  const _ComparisonChipSection({
    required this.title,
    required this.stocks,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stocks
              .take(5)
              .map(
                (stock) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '${stock.ticker} #${stock.rank}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _StrategyCard extends ConsumerWidget {
  final SavedFilter strategy;
  final bool isExpanded;
  final bool isActive;
  final Set<String> watchedTickers;
  final VoidCallback onToggleExpand;
  final void Function(String) onToggleWatch;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int) onUpdateTopN;
  final Future<void> Function() onActivate;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _StrategyCard({
    required this.strategy,
    required this.isExpanded,
    required this.isActive,
    required this.watchedTickers,
    required this.onToggleExpand,
    required this.onToggleWatch,
    required this.onRefresh,
    required this.onUpdateTopN,
    required this.onActivate,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync =
        isExpanded ? ref.watch(strategySnapshotProvider(strategy.name)) : null;
    final insightsAsync = isExpanded
        ? ref.watch(strategyStockInsightsProvider(strategy.name))
        : null;

    return GlassContainer(
      child: Column(
        children: [
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
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (strategy.isPreset)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A5F),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '프리셋',
                                  style: TextStyle(
                                    color: Color(0xFF60A5FA),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                child: const Text(
                                  '활성',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                        const SizedBox(height: 4),
                        Text(
                          _weightsLabel(strategy.weights),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Top ${strategy.topN} · ${_sensitivityLabel(strategy.sensitivity)}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onActivate,
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.16)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : Colors.white54,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? '활성 전략' : '활성화',
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF10B981)
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _TopNChip(
                    current: strategy.topN,
                    onChanged: onUpdateTopN,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onRefresh,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Colors.white38,
                          size: 17,
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.white24,
                          size: 17,
                        ),
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
                      color: Color(0xFF10B981),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '오류: $error',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
                data: (snapshot) {
                  if (snapshot.current.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          '종목 데이터 없음',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }
                  final insightMap = insightsAsync?.maybeWhen(
                        data: (value) => value,
                        orElse: () => const <String, StockInsightViewModel>{},
                      ) ??
                      const <String, StockInsightViewModel>{};
                  final insightsLoading = insightsAsync?.isLoading ?? false;
                  return Column(
                    children: snapshot.current
                        .map(
                          (stock) => _StockRow(
                            stock: stock,
                            isWatched: watchedTickers.contains(stock.ticker),
                            onToggle: () => onToggleWatch(stock.ticker),
                            insight: insightMap[stock.ticker.toUpperCase()],
                            isInsightLoading: insightsLoading,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  String _weightsLabel(Map<String, double> weights) {
    final parts = <String>[];
    if ((weights['per'] ?? 0) > 0) {
      parts.add('PER ${(weights['per']! * 100).toStringAsFixed(0)}%');
    }
    if ((weights['roe'] ?? 0) > 0) {
      parts.add('ROE ${(weights['roe']! * 100).toStringAsFixed(0)}%');
    }
    if ((weights['dividend'] ?? 0) > 0) {
      parts.add('배당 ${(weights['dividend']! * 100).toStringAsFixed(0)}%');
    }
    return parts.join(' · ');
  }
}

class _StockRow extends StatelessWidget {
  final SnapshotStock stock;
  final bool isWatched;
  final VoidCallback onToggle;
  final StockInsightViewModel? insight;
  final bool isInsightLoading;

  const _StockRow({
    required this.stock,
    required this.isWatched,
    required this.onToggle,
    required this.insight,
    required this.isInsightLoading,
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
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isInsightLoading
                        ? '전략 기준 설명 생성 중...'
                        : insight?.compactSummary ??
                            '점수 ${stock.score.toStringAsFixed(1)} 기준으로 정렬된 종목입니다.',
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '\$${stock.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              color: isWatched ? const Color(0xFFF59E0B) : Colors.white30,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

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
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    fontSize: 14,
                  ),
                ),
              ),
              ..._options.map(
                (option) => ListTile(
                  dense: true,
                  title: Text(
                    'Top $option',
                    style: TextStyle(
                      color: option == current
                          ? const Color(0xFF10B981)
                          : Colors.white,
                    ),
                  ),
                  trailing: option == current
                      ? const Icon(Icons.check, color: Color(0xFF10B981))
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
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
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

String _sensitivityLabel(String sensitivity) {
  switch (sensitivity) {
    case 'High':
      return '상위 10% 알림';
    case 'Low':
      return '상위 30% 알림';
    case 'Medium':
    default:
      return '상위 20% 알림';
  }
}
