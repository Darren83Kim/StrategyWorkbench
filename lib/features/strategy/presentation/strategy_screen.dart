import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart'
    show MarketFilter;
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
  MarketFilter _marketFilter = MarketFilter.hybrid;

  Future<void> _clearStrategySnapshot(String strategyName) async {
    final prefs = await SharedPreferences.getInstance();
    for (final cacheKey in strategySnapshotCacheKeys(strategyName)) {
      await prefs.remove(cacheKey);
    }
    ref.invalidate(strategySnapshotProvider(strategyName));
    for (final marketFilter in MarketFilter.values) {
      if (marketFilter == MarketFilter.hybrid) {
        continue;
      }
      ref.invalidate(
        strategySnapshotByMarketProvider(
          StrategySnapshotMarketRequest(
            strategyName: strategyName,
            marketFilter: marketFilter,
          ),
        ),
      );
    }
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
    if (StorePolicy.enablePortfolioAlerts) {
      unawaited(
        ref
            .read(alertRuntimeServiceProvider)
            .syncForStrategy(strategyName: strategyName),
      );
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(StorePolicy.isPersonalMode
            ? '$strategyName 전략이 분석 기준으로 설정됐습니다.'
            : '$strategyName 전략이 활성 전략으로 설정됐습니다.'),
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
      if (StorePolicy.enablePortfolioAlerts) {
        unawaited(
          AlertRuntimeService.shared.syncForStrategy(strategyName: null),
        );
      }
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
            icon: const Icon(Icons.science_outlined),
            tooltip: lang == 'ko' ? '분석 기준 실험실' : 'Analysis Lab',
            onPressed: strategies.isEmpty
                ? null
                : () {
                    final strategyName =
                        activeStrategy?.name ?? strategies.first.name;
                    context.push(
                      Uri(
                        path: '/analysis-lab',
                        queryParameters: {
                          'strategy': strategyName,
                          'market': _marketFilter.name,
                        },
                      ).toString(),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: lang == 'ko' ? '지표 사전' : 'Metric Dictionary',
            onPressed: () => context.push('/metric-dictionary'),
          ),
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
                        StorePolicy.isPersonalMode
                            ? Icons.insights_rounded
                            : Icons.notifications_active_outlined,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            StorePolicy.isPersonalMode
                                ? '현재 분석 기준'
                                : '현재 활성 전략',
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
                              StorePolicy.isPersonalMode
                                  ? '샘플 ${activeStrategy.topN} · 지표 비교 기준'
                                  : 'Top ${activeStrategy.topN} · ${_sensitivityLabel(activeStrategy.sensitivity)}',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _MarketFilterBar(
              value: _marketFilter,
              onChanged: (value) {
                setState(() {
                  _marketFilter = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Colors.white38,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    lang == 'ko'
                        ? '표시되는 순위와 지표는 학습용 상대 비교이며 투자 자문이나 매수/매도 권유가 아닙니다.'
                        : 'Rankings and indicators are for comparative learning, not financial advice or a buy/sell recommendation.',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
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
                    marketFilter: _marketFilter,
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
                      await refreshStrategySnapshot(
                        ref,
                        strategy.name,
                        marketFilter: _marketFilter,
                        refreshStocks: true,
                      );
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

class _MarketFilterBar extends StatelessWidget {
  final MarketFilter value;
  final ValueChanged<MarketFilter> onChanged;

  const _MarketFilterBar({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MarketFilter.values
          .map(
            (filter) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(marketFilterLabel(filter)),
                selected: value == filter,
                onSelected: (_) => onChanged(filter),
                selectedColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide(
                  color: value == filter
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                ),
                labelStyle: TextStyle(
                  color: value == filter ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight:
                      value == filter ? FontWeight.w700 : FontWeight.w500,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          )
          .toList(),
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
          initialValue: value,
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
            _ComparisonInsightPanel(comparison: comparison),
            if (comparison.weightDeltas.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ComparisonWeightSection(comparison: comparison),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ComparisonStatCard(
                    label: s.strategyCompareOverlap,
                    value: comparison.overlap.length.toString(),
                    accent: const Color(0xFF10B981),
                    helper: '아래 목록',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonStatCard(
                    label: s.strategyCompareOnlyLeft,
                    value: comparison.onlyLeft.length.toString(),
                    accent: const Color(0xFF60A5FA),
                    helper: comparison.leftStrategy.name,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonStatCard(
                    label: s.strategyCompareOnlyRight,
                    value: comparison.onlyRight.length.toString(),
                    accent: const Color(0xFFFB923C),
                    helper: comparison.rightStrategy.name,
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
              _ComparisonOverlapSection(
                title: '${s.strategyCompareOverlap} · 두 기준 모두 포함',
                matches: comparison.overlap,
                leftStrategyName: comparison.leftStrategy.name,
                rightStrategyName: comparison.rightStrategy.name,
              ),
              const SizedBox(height: 16),
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
                (match) => _ComparisonRankGapRow(
                  match: match,
                  leftStrategyName: comparison.leftStrategy.name,
                  rightStrategyName: comparison.rightStrategy.name,
                ),
              ),
            ],
            if (comparison.onlyLeft.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ComparisonChipSection(
                title: '${comparison.leftStrategy.name}에만 있는 샘플',
                stocks: comparison.onlyLeft,
                accent: const Color(0xFF60A5FA),
              ),
            ],
            if (comparison.onlyRight.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ComparisonChipSection(
                title: '${comparison.rightStrategy.name}에만 있는 샘플',
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
  final String? helper;

  const _ComparisonStatCard({
    required this.label,
    required this.value,
    required this.accent,
    this.helper,
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
          if (helper != null) ...[
            const SizedBox(height: 2),
            Text(
              helper!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonWeightSection extends StatelessWidget {
  final StrategyComparisonViewModel comparison;

  const _ComparisonWeightSection({required this.comparison});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기준별 가중치 차이',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...comparison.weightDeltas.map(
          (delta) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    delta.label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: _ComparisonWeightBar(
                    label: comparison.leftStrategy.name,
                    value: delta.leftWeight,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonWeightBar(
                    label: comparison.rightStrategy.name,
                    value: delta.rightWeight,
                    color: const Color(0xFFFB923C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonWeightBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ComparisonWeightBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ComparisonOverlapSection extends StatelessWidget {
  final String title;
  final List<StrategyComparisonMatch> matches;
  final String leftStrategyName;
  final String rightStrategyName;

  const _ComparisonOverlapSection({
    required this.title,
    required this.matches,
    required this.leftStrategyName,
    required this.rightStrategyName,
  });

  @override
  Widget build(BuildContext context) {
    final shown = matches.take(6).toList();

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
        ...shown.map(
          (match) => _ComparisonOverlapRow(
            match: match,
            leftStrategyName: leftStrategyName,
            rightStrategyName: rightStrategyName,
          ),
        ),
        if (matches.length > shown.length) ...[
          const SizedBox(height: 4),
          Text(
            '+${matches.length - shown.length}개 더 있음',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

class _ComparisonOverlapRow extends StatelessWidget {
  final StrategyComparisonMatch match;
  final String leftStrategyName;
  final String rightStrategyName;

  const _ComparisonOverlapRow({
    required this.match,
    required this.leftStrategyName,
    required this.rightStrategyName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = resolveInstrumentName(match.ticker, match.name);
    final hasContributionData = match.leftContributions.isNotEmpty ||
        match.rightContributions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF10B981).withValues(alpha: 0.18),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: const Color(0xFF10B981),
          collapsedIconColor: Colors.white38,
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${match.ticker} · $leftStrategyName #${match.leftStock.rank} · '
            '$rightStrategyName #${match.rightStock.rank}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          children: [
            if (!hasContributionData)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '기여도 데이터를 불러오지 못했습니다.',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              )
            else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '지표별 점수 기여도',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...['per', 'roe', 'dividend'].map(
                (key) => _ContributionDeltaRow(
                  label: _comparisonMetricLabel(key),
                  leftName: leftStrategyName,
                  rightName: rightStrategyName,
                  leftValue: match.leftContributions[key] ?? 0,
                  rightValue: match.rightContributions[key] ?? 0,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push('/market/${match.ticker}');
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('종목 상세'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContributionDeltaRow extends StatelessWidget {
  final String label;
  final String leftName;
  final String rightName;
  final double leftValue;
  final double rightValue;

  const _ContributionDeltaRow({
    required this.label,
    required this.leftName,
    required this.rightName,
    required this.leftValue,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          Expanded(
            child: _ContributionValue(
              name: leftName,
              value: leftValue,
              color: const Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ContributionValue(
              name: rightName,
              value: rightValue,
              color: const Color(0xFFFB923C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionValue extends StatelessWidget {
  final String name;
  final double value;
  final Color color;

  const _ContributionValue({
    required this.name,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _comparisonMetricLabel(String key) {
  switch (key) {
    case 'per':
      return 'PER';
    case 'roe':
      return 'ROE';
    case 'dividend':
      return '배당';
    default:
      return key.toUpperCase();
  }
}

class _ComparisonInsightPanel extends StatelessWidget {
  final StrategyComparisonViewModel comparison;

  const _ComparisonInsightPanel({
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Color(0xFF10B981),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comparison.headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comparison.summary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ComparisonFocusChip(
                label:
                    '${comparison.leftStrategy.name}: ${comparison.leftFocusLabel}',
                accent: const Color(0xFF60A5FA),
              ),
              _ComparisonFocusChip(
                label:
                    '${comparison.rightStrategy.name}: ${comparison.rightFocusLabel}',
                accent: const Color(0xFFFB923C),
              ),
            ],
          ),
          if (comparison.observations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...comparison.observations.map(
              (observation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ComparisonObservationRow(observation: observation),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonFocusChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _ComparisonFocusChip({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ComparisonObservationRow extends StatelessWidget {
  final StrategyComparisonObservation observation;

  const _ComparisonObservationRow({
    required this.observation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(
            Icons.circle,
            color: Color(0xFF10B981),
            size: 6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '${observation.title}: ',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: observation.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRankGapRow extends StatelessWidget {
  final StrategyComparisonMatch match;
  final String leftStrategyName;
  final String rightStrategyName;

  const _ComparisonRankGapRow({
    required this.match,
    required this.leftStrategyName,
    required this.rightStrategyName,
  });

  @override
  Widget build(BuildContext context) {
    final isLeftHigher = match.leftStock.rank < match.rightStock.rank;
    final accent =
        isLeftHigher ? const Color(0xFF60A5FA) : const Color(0xFFFB923C);
    final displayName = resolveInstrumentName(match.ticker, match.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push('/market/${match.ticker}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        match.ticker,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        comparisonLabel(
                            match.leftStock.rank, match.rightStock.rank),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${match.absoluteRankGap}계단 차이',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String comparisonLabel(int leftRank, int rightRank) {
    return '$leftStrategyName #$leftRank · $rightStrategyName #$rightRank';
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
                (stock) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      router.push('/market/${stock.ticker}');
                    },
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolveInstrumentName(stock.ticker, stock.name),
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${stock.ticker} · #${stock.rank}',
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.75),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
  final MarketFilter marketFilter;
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
    required this.marketFilter,
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
    final marketRequest = StrategySnapshotMarketRequest(
      strategyName: strategy.name,
      marketFilter: marketFilter,
    );
    final snapshotAsync = isExpanded
        ? marketFilter == MarketFilter.hybrid
            ? ref.watch(strategySnapshotProvider(strategy.name))
            : ref.watch(strategySnapshotByMarketProvider(marketRequest))
        : null;
    final insightsAsync = isExpanded
        ? marketFilter == MarketFilter.hybrid
            ? ref.watch(strategyStockInsightsProvider(strategy.name))
            : ref.watch(strategyStockInsightsByMarketProvider(marketRequest))
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
                                  StorePolicy.isPersonalMode ? '기준' : '활성',
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
                          StorePolicy.isPersonalMode
                              ? '샘플 ${strategy.topN} · 지표 비교 기준'
                              : 'Top ${strategy.topN} · ${_sensitivityLabel(strategy.sensitivity)}',
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
                              StorePolicy.isPersonalMode
                                  ? Icons.insights_rounded
                                  : isActive
                                      ? Icons.notifications_active_rounded
                                      : Icons.notifications_none_rounded,
                              color: isActive
                                  ? const Color(0xFF10B981)
                                  : Colors.white54,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              StorePolicy.isPersonalMode
                                  ? isActive
                                      ? '분석 기준'
                                      : '기준 설정'
                                  : isActive
                                      ? '활성 전략'
                                      : '활성화',
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
                          '선택한 시장의 종목 데이터 없음',
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
                            onOpenDetails: () =>
                                context.push('/market/${stock.ticker}'),
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
  final VoidCallback onOpenDetails;
  final VoidCallback onToggle;
  final StockInsightViewModel? insight;
  final bool isInsightLoading;

  const _StockRow({
    required this.stock,
    required this.isWatched,
    required this.onOpenDetails,
    required this.onToggle,
    required this.insight,
    required this.isInsightLoading,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = resolveInstrumentName(stock.ticker, stock.name);

    return InkWell(
      onTap: onOpenDetails,
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
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    stock.ticker,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isInsightLoading
                        ? StorePolicy.isPersonalMode
                            ? '지표 설명 생성 중...'
                            : '전략 기준 설명 생성 중...'
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
              formatMarketPrice(stock.ticker, stock.price),
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isWatched ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isWatched ? const Color(0xFFF59E0B) : Colors.white30,
                  size: 22,
                ),
              ),
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
                  StorePolicy.isPersonalMode ? '샘플 수 설정' : 'Top N 설정',
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
                    StorePolicy.isPersonalMode ? '샘플 $option' : 'Top $option',
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
              StorePolicy.isPersonalMode ? '샘플 $current' : 'Top $current',
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
