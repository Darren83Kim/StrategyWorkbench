import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/core/l10n/app_strings.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/daily_brief_providers.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // 펼친 전략만 추적한다. 기본은 모두 접힌 상태로 두어 초기 스냅샷 계산을 늦춘다.
  final Set<String> _expanded = {};
  bool _shouldLoadBrief = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      const delay = kDebugMode
          ? Duration(milliseconds: 2200)
          : Duration(milliseconds: 450);
      await Future<void>.delayed(delay);
      if (!mounted) {
        return;
      }
      setState(() {
        _shouldLoadBrief = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final allStrategies = ref.watch(allStrategiesProvider);
    final activeStrategyNameAsync = ref.watch(activeStrategyNameProvider);
    final activeStrategy = ref.watch(activeStrategyProvider);
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
          IconButton(
            icon: const Icon(Icons.balance_rounded),
            tooltip: lang == 'ko' ? '종목 지표 비교' : 'Compare Metrics',
            onPressed: () {
              final symbols = watchlist.values
                  .expand((items) => items)
                  .toSet()
                  .take(3)
                  .join(',');
              context.push(
                Uri(
                  path: '/stock-compare',
                  queryParameters:
                      symbols.isEmpty ? null : {'symbols': symbols},
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
            icon: const Icon(Icons.sticky_note_2_outlined),
            tooltip: lang == 'ko' ? '관찰 메모' : 'Observation Notes',
            onPressed: () => context.push('/observation-notes'),
          ),
          TextButton(
            onPressed: () => ref.read(languageProvider.notifier).toggle(),
            child: Text(
              s.langToggle,
              style: TextStyle(
                color: lang == 'ko' ? const Color(0xFF10B981) : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeStrategyNameAsync.isLoading)
            _BriefLoadingCard(s: s)
          else if (activeStrategy == null)
            _NoActiveStrategyCard(s: s)
          else if (!_shouldLoadBrief)
            _BriefLoadingCard(s: s)
          else if (StorePolicy.isPersonalMode)
            _LearningBriefCard(
              briefAsync: ref.watch(dailyBriefProvider),
              s: s,
            )
          else
            _DailyBriefCard(
              briefAsync: ref.watch(dailyBriefProvider),
              s: s,
            ),
          const SizedBox(height: 20),
          Text(
            s.watchlistRadarTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (activeStrategies.isEmpty)
            _buildEmpty(s)
          else
            ...activeStrategies.map(
              (strategy) {
                final watched = watchlist[strategy.name] ?? <String>{};
                final isExpanded = _expanded.contains(strategy.name);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StrategyWatchCard(
                    strategy: strategy,
                    watchedTickers: watched,
                    isExpanded: isExpanded,
                    onToggleExpand: () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(strategy.name);
                      } else {
                        _expanded.add(strategy.name);
                      }
                    }),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppStrings s) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.star_border_rounded,
              color: Colors.white24,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              s.watchlistEmptyMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

bool _isKo(AppStrings s) => s.langToggle == 'EN';

String _briefTitle(AppStrings s) {
  if (!StorePolicy.isPersonalMode) {
    return s.dailyBriefTitle;
  }
  return _isKo(s) ? '지표 학습 브리프' : 'Indicator Learning Brief';
}

String _learningBaselineLabel(AppStrings s) {
  return _isKo(s) ? '분석 기준' : 'Analysis criteria';
}

class _BriefLoadingCard extends StatelessWidget {
  final AppStrings s;

  const _BriefLoadingCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_briefTitle(s)} · ${s.loading}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveStrategyCard extends StatelessWidget {
  final AppStrings s;

  const _NoActiveStrategyCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0x1A10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _briefTitle(s),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              StorePolicy.isPersonalMode
                  ? (_isKo(s)
                      ? '전략 탭에서 분석 기준을 설정하면 지표 해설과 샘플 랭킹이 열립니다.'
                      : 'Choose a learning baseline in Strategy to unlock indicator notes and sample rankings.')
                  : s.dailyBriefNoActive,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningBriefCard extends StatelessWidget {
  final AsyncValue<DailyBrief?> briefAsync;
  final AppStrings s;

  const _LearningBriefCard({
    required this.briefAsync,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return briefAsync.when(
      loading: () => _BriefLoadingCard(s: s),
      error: (error, _) => GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            '${_briefTitle(s)} ${s.loadFailed} $error',
            style: const TextStyle(
              color: Color(0xFFEF9A9A),
              fontSize: 12,
            ),
          ),
        ),
      ),
      data: (brief) {
        if (brief == null) {
          return _NoActiveStrategyCard(s: s);
        }

        final isKo = _isKo(s);
        return GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x1A10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _briefTitle(s),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_learningBaselineLabel(s)}: ${brief.strategy.name}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isKo
                            ? '샘플 ${brief.strategy.topN}'
                            : 'Sample ${brief.strategy.topN}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BriefMetric(
                        label: isKo ? '표본 종목' : 'Samples',
                        value: brief.snapshot.current.length.toString(),
                        color: const Color(0xFF10B981),
                        onTap: () => _showLearningMetricSheet(
                          context: context,
                          title: isKo ? '표본 종목' : 'Sample Stocks',
                          accent: const Color(0xFF10B981),
                          description: isKo
                              ? '${brief.strategy.name} 기준으로 정렬한 상위 ${brief.snapshot.current.length}개 샘플입니다. 각 종목은 지표 가중치에 따라 점수가 계산됩니다.'
                              : 'Top ${brief.snapshot.current.length} samples sorted by ${brief.strategy.name}. Scores are calculated from the selected indicator weights.',
                          children: [
                            ...brief.snapshot.current.take(6).map(
                                  (stock) => _LearningStockLine(
                                    stock: stock,
                                    accent: const Color(0xFF10B981),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BriefMetric(
                        label: isKo ? '순위 변화' : 'Rank Moves',
                        value: brief.movers.length.toString(),
                        color: const Color(0xFF60A5FA),
                        onTap: () => _showLearningMetricSheet(
                          context: context,
                          title: isKo ? '순위 변화' : 'Rank Moves',
                          accent: const Color(0xFF60A5FA),
                          description: brief.movers.isEmpty
                              ? (isKo
                                  ? '이전 스냅샷과 비교했을 때 현재 상위 샘플의 순위 이동이 없습니다. 기준이 안정적으로 유지된 상태입니다.'
                                  : 'No rank movement was found compared with the previous snapshot.')
                              : (isKo
                                  ? '이전 스냅샷과 현재 스냅샷을 비교해 순위가 바뀐 샘플입니다.'
                                  : 'Samples whose ranking changed compared with the previous snapshot.'),
                          children: brief.movers.isEmpty
                              ? [
                                  _LearningNoteLine(
                                    icon: Icons.check_circle_outline_rounded,
                                    text: isKo
                                        ? '현재 관찰된 순위 변화가 없습니다.'
                                        : 'No rank movement is currently observed.',
                                    accent: const Color(0xFF60A5FA),
                                  ),
                                ]
                              : brief.movers
                                  .map(
                                    (mover) => _LearningStockLine(
                                      stock: mover.stock,
                                      accent: const Color(0xFF60A5FA),
                                      trailing:
                                          '${mover.isUp ? '+' : '-'}${mover.absoluteChange}',
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BriefMetric(
                        label: isKo ? '비교 지표' : 'Metrics',
                        value: brief.strategy.weights.length.toString(),
                        color: const Color(0xFFFB923C),
                        onTap: () => _showLearningMetricSheet(
                          context: context,
                          title: isKo ? '비교 지표' : 'Compared Metrics',
                          accent: const Color(0xFFFB923C),
                          description: isKo
                              ? '${brief.strategy.name} 기준에서 점수 계산에 사용하는 지표와 비중입니다. 비중이 클수록 샘플 순위에 더 크게 반영됩니다.'
                              : 'Indicators and weights used by ${brief.strategy.name}. Higher weights have more influence on sample ranking.',
                          children: brief.strategy.weights.entries
                              .map(
                                (entry) => _LearningMetricLine(
                                  label: _dashboardMetricLabel(entry.key),
                                  weight: entry.value,
                                  accent: const Color(0xFFFB923C),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (brief.topPicks.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BriefSectionTitle(
                    title: isKo ? '오늘의 샘플 랭킹' : 'Sample Rankings',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: brief.topPicks
                        .map(
                          (stock) => _BriefChip(
                            title: resolveInstrumentName(
                              stock.ticker,
                              stock.name,
                            ),
                            subtitleWidget: _BriefPriceSubtitle(
                              rank: stock.rank,
                              ticker: stock.ticker,
                              fallbackPrice: stock.price,
                            ),
                            icon: Icons.auto_graph_rounded,
                            accent: const Color(0xFF2563EB),
                            onTap: () =>
                                context.push('/market/${stock.ticker}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (brief.movers.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BriefSectionTitle(
                    title: isKo ? '순위 변화 관찰' : 'Rank Movement Notes',
                  ),
                  const SizedBox(height: 8),
                  ...brief.movers.map(
                    (mover) => _BriefInsightRow(
                      title: resolveInstrumentName(
                        mover.stock.ticker,
                        mover.stock.name,
                      ),
                      subtitleWidget: _BriefPriceSubtitle(
                        rank: mover.stock.rank,
                        ticker: mover.stock.ticker,
                        fallbackPrice: mover.stock.price,
                      ),
                      trailing: _RankBadge(change: mover.change),
                      onTap: () =>
                          context.push('/market/${mover.stock.ticker}'),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  isKo
                      ? '지표 학습용 정보이며 매수/매도 권유가 아닙니다.'
                      : 'For indicator learning only. Not a buy or sell recommendation.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyBriefCard extends StatelessWidget {
  final AsyncValue<DailyBrief?> briefAsync;
  final AppStrings s;

  const _DailyBriefCard({
    required this.briefAsync,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return briefAsync.when(
      loading: () => _BriefLoadingCard(s: s),
      error: (error, _) => GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            '${s.dailyBriefTitle} ${s.loadFailed} $error',
            style: const TextStyle(
              color: Color(0xFFEF9A9A),
              fontSize: 12,
            ),
          ),
        ),
      ),
      data: (brief) {
        if (brief == null) {
          return _NoActiveStrategyCard(s: s);
        }

        return GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0x1A10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.dailyBriefTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.activeStrategy}: ${brief.strategy.name}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Top ${brief.strategy.topN}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BriefMetric(
                        label: s.dailyBriefNewIn,
                        value: brief.entered.length.toString(),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BriefMetric(
                        label: s.dailyBriefExited,
                        value: brief.exited.length.toString(),
                        color: const Color(0xFFFB923C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BriefMetric(
                        label: s.dailyBriefRiskHoldings,
                        value: brief.riskHoldings.length.toString(),
                        color: const Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
                if (brief.topPicks.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BriefSectionTitle(title: s.dailyBriefTopPicks),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: brief.topPicks
                        .map(
                          (stock) => _BriefChip(
                            title: resolveInstrumentName(
                              stock.ticker,
                              stock.name,
                            ),
                            subtitleWidget: _BriefPriceSubtitle(
                              rank: stock.rank,
                              ticker: stock.ticker,
                              fallbackPrice: stock.price,
                            ),
                            icon: Icons.auto_awesome,
                            accent: const Color(0xFF2563EB),
                            onTap: () =>
                                context.push('/market/${stock.ticker}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (brief.entered.isNotEmpty || brief.exited.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BriefSectionTitle(title: s.dailyBriefChanges),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...brief.entered.take(3).map(
                            (stock) => _BriefChip(
                              title: resolveInstrumentName(
                                stock.ticker,
                                stock.name,
                              ),
                              subtitle: s.dailyBriefNewIn,
                              icon: Icons.arrow_upward,
                              accent: const Color(0xFF10B981),
                              onTap: () =>
                                  context.push('/market/${stock.ticker}'),
                            ),
                          ),
                      ...brief.exited.take(3).map(
                            (stock) => _BriefChip(
                              title: resolveInstrumentName(
                                stock.ticker,
                                stock.name,
                              ),
                              subtitle: s.dailyBriefExited,
                              icon: Icons.arrow_downward,
                              accent: const Color(0xFFFB923C),
                              onTap: () =>
                                  context.push('/market/${stock.ticker}'),
                            ),
                          ),
                    ],
                  ),
                ],
                if (brief.riskHoldings.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BriefSectionTitle(title: s.dailyBriefRiskHoldings),
                  const SizedBox(height: 8),
                  ...brief.riskHoldings.take(3).map(
                        (risk) => _BriefInsightRow(
                          title: resolveInstrumentName(
                            risk.item.ticker,
                            risk.item.name,
                          ),
                          subtitle: risk.recentlyExited
                              ? s.dailyBriefRecentlyExited
                              : s.dailyBriefOutsideStrategy,
                          trailing: _HoldingPriceText(
                            ticker: risk.item.ticker,
                            quantity: risk.item.quantity,
                            fallbackPrice: risk.item.currentPrice,
                          ),
                          onTap: () =>
                              context.push('/market/${risk.item.ticker}'),
                        ),
                      ),
                ],
                if (brief.movers.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _BriefSectionTitle(title: s.dailyBriefMovers),
                  const SizedBox(height: 8),
                  ...brief.movers.map(
                    (mover) => _BriefInsightRow(
                      title: resolveInstrumentName(
                        mover.stock.ticker,
                        mover.stock.name,
                      ),
                      subtitleWidget: _BriefPriceSubtitle(
                        rank: mover.stock.rank,
                        ticker: mover.stock.ticker,
                        fallbackPrice: mover.stock.price,
                      ),
                      trailing: _RankBadge(change: mover.change),
                      onTap: () =>
                          context.push('/market/${mover.stock.ticker}'),
                    ),
                  ),
                ],
                if (!brief.hasSignals) ...[
                  const SizedBox(height: 18),
                  Text(
                    s.dailyBriefNoChanges,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BriefMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _BriefMetric({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: onTap == null
            ? null
            : Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white38,
                  size: 12,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

void _showLearningMetricSheet({
  required BuildContext context,
  required String title,
  required Color accent,
  required String description,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LearningStockLine extends StatelessWidget {
  final SnapshotStock stock;
  final Color accent;
  final String? trailing;

  const _LearningStockLine({
    required this.stock,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final name = resolveInstrumentName(stock.ticker, stock.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            GoRouter.of(context).push('/market/${stock.ticker}');
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${stock.rank}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        stock.ticker,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningMetricLine extends StatelessWidget {
  final String label;
  final double weight;
  final Color accent;

  const _LearningMetricLine({
    required this.label,
    required this.weight,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (weight * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningNoteLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;

  const _LearningNoteLine({
    required this.icon,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dashboardMetricLabel(String key) {
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

class _BriefSectionTitle extends StatelessWidget {
  final String title;

  const _BriefSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BriefChip extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _BriefChip({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 14),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitleWidget ??
                      Text(
                        subtitle ?? '',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BriefPriceSubtitle extends StatelessWidget {
  final int rank;
  final String ticker;
  final double fallbackPrice;

  const _BriefPriceSubtitle({
    required this.rank,
    required this.ticker,
    required this.fallbackPrice,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white60,
      fontSize: 10,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('#$rank • ', style: style),
        _LivePriceText(
          ticker: ticker,
          fallbackPrice: fallbackPrice,
          style: style,
        ),
      ],
    );
  }
}

class _LivePriceText extends ConsumerWidget {
  final String ticker;
  final double fallbackPrice;
  final TextStyle style;

  const _LivePriceText({
    required this.ticker,
    required this.fallbackPrice,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stockDetailProvider(ticker));
    final detail = detailAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final liveStock = detail?.stock;
    final displayTicker = liveStock?.ticker ?? ticker;
    final price = liveStock?.price ?? fallbackPrice;

    return Text(
      formatMarketPrice(displayTicker, price),
      style: style,
    );
  }
}

class _HoldingPriceText extends StatelessWidget {
  final String ticker;
  final double quantity;
  final double fallbackPrice;

  const _HoldingPriceText({
    required this.ticker,
    required this.quantity,
    required this.fallbackPrice,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white70,
      fontSize: 11,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${quantity.toStringAsFixed(0)} @ ', style: style),
        _LivePriceText(
          ticker: ticker,
          fallbackPrice: fallbackPrice,
          style: style,
        ),
      ],
    );
  }
}

class _BriefInsightRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget trailing;
  final VoidCallback onTap;

  const _BriefInsightRow({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    subtitleWidget ??
                        Text(
                          subtitle ?? '',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── 전략별 관심 종목 카드 ──
class _StrategyWatchCard extends ConsumerWidget {
  final SavedFilter strategy;
  final Set<String> watchedTickers;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _StrategyWatchCard({
    required this.strategy,
    required this.watchedTickers,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isExpanded) {
      return GlassContainer(
        child: InkWell(
          onTap: onToggleExpand,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.chevron_right,
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
                  '★ ${watchedTickers.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final snapshotAsync = ref.watch(strategySnapshotProvider(strategy.name));

    return snapshotAsync.when(
      loading: () => GlassContainer(
        child: InkWell(
          onTap: onToggleExpand,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.expand_more,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  strategy.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (e, _) => GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            '${strategy.name}: 로드 오류',
            style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
          ),
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
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_more : Icons.chevron_right,
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
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      if (exitCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
              const Divider(color: Colors.white12, height: 1),

              // 현재 top-N에 있는 관심 종목
              ...presentStocks.map((stock) {
                final rankChange = snapshot.rankChange(stock.ticker);
                return _WatchedRow(
                  stock: stock,
                  rankChange: rankChange,
                  isExited: false,
                  onTap: () => context.push('/market/${stock.ticker}'),
                  onCompare: () => context.push(
                    Uri(
                      path: '/stock-compare',
                      queryParameters: {'symbols': stock.ticker},
                    ).toString(),
                  ),
                );
              }),

              // 이탈 종목
              ...exitedStocks.map(
                (stock) => _WatchedRow(
                  stock: stock,
                  rankChange: null,
                  isExited: true,
                  onTap: () => context.push('/market/${stock.ticker}'),
                  onCompare: () => context.push(
                    Uri(
                      path: '/stock-compare',
                      queryParameters: {'symbols': stock.ticker},
                    ).toString(),
                  ),
                ),
              ),

              if (total == 0)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '관심 종목 없음',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
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
  final VoidCallback onCompare;

  const _WatchedRow({
    required this.stock,
    required this.rankChange,
    required this.isExited,
    required this.onTap,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = resolveInstrumentName(stock.ticker, stock.name);

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
                        horizontal: 4,
                        vertical: 2,
                      ),
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
                            color: Colors.white54,
                            fontSize: 10,
                          ),
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
                    displayName,
                    style: TextStyle(
                      color: isExited ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    stock.ticker,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 가격
            _LivePriceText(
              ticker: stock.ticker,
              fallbackPrice: stock.price,
              style: TextStyle(
                color: isExited ? Colors.white38 : Colors.white70,
                fontSize: 12,
              ),
            ),
            IconButton(
              tooltip: '지표 비교',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onCompare,
              icon: const Icon(
                Icons.balance_rounded,
                color: Colors.white38,
                size: 17,
              ),
            ),

            // 순위 변동
            if (!isExited && rankChange != null && rankChange != 0) ...[
              const SizedBox(width: 8),
              _RankBadge(change: rankChange!),
            ] else if (!isExited && rankChange == 0) ...[
              const SizedBox(width: 8),
              const Text(
                '—',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
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
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
