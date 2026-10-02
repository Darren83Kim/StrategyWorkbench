import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';
import 'package:strategy_workbench/shared/widgets/transaction_timeline_list.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

class StockDetailScreen extends ConsumerWidget {
  final String symbol;

  const StockDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final detailAsync = ref.watch(stockDetailProvider(symbol));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(strings.stockDetailTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '다른 종목과 비교',
            onPressed: () => context.push(
              Uri(
                path: '/stock-compare',
                queryParameters: {'symbols': normalizeTickerInput(symbol)},
              ).toString(),
            ),
            icon: const Icon(Icons.balance_rounded),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, _) => _DetailStateMessage(
          icon: Icons.error_outline,
          message: '${strings.loadFailed} $error',
          actionLabel: strings.retry,
          onPressed: () => ref.invalidate(stockDetailProvider(symbol)),
        ),
        data: (detail) {
          if (detail == null) {
            return _DetailStateMessage(
              icon: Icons.search_off_rounded,
              message: '종목을 찾을 수 없습니다: $symbol',
              actionLabel: strings.retry,
              onPressed: () => ref.invalidate(stockDetailProvider(symbol)),
            );
          }

          return _StockDetailContent(
            detail: detail,
          );
        },
      ),
    );
  }
}

class _StockDetailContent extends ConsumerWidget {
  final StockDetailViewModel detail;

  const _StockDetailContent({
    required this.detail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final transactionsAsync = StorePolicy.showPortfolioFeatures
        ? ref.watch(transactionsByTickerProvider(detail.stock.ticker))
        : null;
    final activeInsightAsync =
        ref.watch(activeStockInsightProvider(detail.stock.ticker));
    final stock = detail.stock;
    final normalizedTicker = normalizeTickerInput(stock.ticker);
    final observationNote = StorePolicy.isPersonalMode
        ? (ref.watch(observationNotesProvider).value ??
            const <String, ObservationNote>{})[normalizedTicker]
        : null;
    final displayName = resolveInstrumentName(stock.ticker, stock.name);
    final normalizedMetrics = detail.normalizedMetrics;
    final tags = detail.tags;
    final hasMetricData =
        stock.per > 0 || stock.roe > 0 || stock.dividendYield > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stock.ticker,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          '비교군 ${detail.peerCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatMarketPrice(stock.ticker, stock.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricBadge(
                        'PER',
                        stock.per > 0 ? stock.per.toStringAsFixed(1) : '없음',
                      ),
                      _MetricBadge(
                        'ROE',
                        stock.roe > 0
                            ? '${stock.roe.toStringAsFixed(1)}%'
                            : '없음',
                      ),
                      _MetricBadge(
                        '배당',
                        stock.dividendYield > 0
                            ? '${stock.dividendYield.toStringAsFixed(1)}%'
                            : '없음',
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tags
                          .map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              labelStyle: const TextStyle(color: Colors.white),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DataConfidenceCard(stock: stock),
          const SizedBox(height: 16),
          if (StorePolicy.isPersonalMode) ...[
            _ObservationNoteSummaryCard(
              note: observationNote,
              onEdit: () => _showObservationNoteEditor(
                context: context,
                ref: ref,
                stock: stock,
                existing: observationNote,
              ),
            ),
            const SizedBox(height: 16),
          ],
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: activeInsightAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (error, _) => Text(
                  '${strings.loadFailed} $error',
                  style: const TextStyle(
                    color: Color(0xFFEF9A9A),
                    fontSize: 12,
                  ),
                ),
                data: (insight) {
                  if (insight == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StorePolicy.isPersonalMode
                              ? '지표 해설'
                              : strings.whyThisStockTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          StorePolicy.isPersonalMode
                              ? '전략 탭에서 분석 기준을 선택하면 이 종목의 주요 지표를 기준별로 해석합니다.'
                              : strings.whyThisStockNoActiveStrategy,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StorePolicy.isPersonalMode
                            ? '지표 해설'
                            : strings.whyThisStockTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InsightBadge(
                            label: insight.strategyName,
                            accent: const Color(0xFF10B981),
                          ),
                          if (insight.rank != null)
                            _InsightBadge(
                              label: 'Rank #${insight.rank}',
                              accent: const Color(0xFF2563EB),
                            ),
                          if (insight.rankChange != null &&
                              insight.rankChange != 0)
                            _InsightBadge(
                              label:
                                  '${insight.rankChange! > 0 ? '+' : '-'}${insight.rankChange!.abs()}',
                              accent: insight.rankChange! > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFFB923C),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        insight.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight.summary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      if (insight.drivers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ContributionOverview(drivers: insight.drivers),
                      ],
                      if (insight.comparisonNote.isNotEmpty ||
                          insight.watchPoint.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        if (insight.comparisonNote.isNotEmpty)
                          _InsightNoteCard(
                            icon: Icons.compare_arrows_rounded,
                            title: '비교 관점',
                            body: insight.comparisonNote,
                            accent: const Color(0xFF60A5FA),
                          ),
                        if (insight.watchPoint.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InsightNoteCard(
                            icon: Icons.manage_search_rounded,
                            title: '확인 포인트',
                            body: insight.watchPoint,
                            accent: const Color(0xFFFB923C),
                          ),
                        ],
                      ],
                      if (insight.drivers.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          strings.whyThisStockDriversTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...insight.drivers.map(
                          (driver) => _InsightDriverRow(driver: driver),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '정규화 지표 차트',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$displayName 기준 실데이터 비교',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  if (!hasMetricData)
                    const _MetricUnavailableMessage()
                  else
                    SizedBox(
                      height: 260,
                      child: RadarChart(
                        RadarChartData(
                          dataSets: [
                            RadarDataSet(
                              dataEntries: detail.metrics
                                  .map(
                                    (metric) => RadarEntry(
                                      value: normalizedMetrics[metric] ?? 0.0,
                                    ),
                                  )
                                  .toList(),
                              borderColor: const Color(0xFF10B981),
                              fillColor: const Color(0x3310B981),
                            ),
                          ],
                          radarBackgroundColor: Colors.transparent,
                          titleTextStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          getTitle: (index, angle) {
                            switch (index) {
                              case 0:
                                return RadarChartTitle(
                                  text:
                                      'PER\n${normalizedMetrics['per']?.toStringAsFixed(2) ?? '-'}',
                                );
                              case 1:
                                return RadarChartTitle(
                                  text:
                                      'ROE\n${normalizedMetrics['roe']?.toStringAsFixed(2) ?? '-'}',
                                );
                              case 2:
                                return RadarChartTitle(
                                  text:
                                      '배당\n${normalizedMetrics['dividendYield']?.toStringAsFixed(2) ?? '-'}',
                                );
                              default:
                                return const RadarChartTitle(text: '');
                            }
                          },
                          tickCount: 4,
                          tickBorderData: const BorderSide(
                            color: Color(0x26FFFFFF),
                          ),
                          gridBorderData: const BorderSide(
                            color: Color(0x33FFFFFF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (transactionsAsync != null)
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.transactions,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    transactionsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '거래 이력 로드 실패: $error',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      data: (transactions) => TransactionTimelineList(
                        transactions: transactions,
                        emptyMessage: strings.noTransactions,
                        buyLabel: strings.buy,
                        sellLabel: strings.sell,
                        showTicker: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricUnavailableMessage extends StatelessWidget {
  const _MetricUnavailableMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: const Text(
        '현재가와 종목명은 확인됐지만 PER, ROE, 배당 지표는 아직 확보되지 않았습니다. 지표 차트는 펀더멘탈 데이터가 들어오면 표시됩니다.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ObservationNoteSummaryCard extends StatelessWidget {
  final ObservationNote? note;
  final VoidCallback onEdit;

  const _ObservationNoteSummaryCard({
    required this.note,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '관찰 메모',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(
                    note == null ? Icons.add_rounded : Icons.edit_outlined,
                    size: 17,
                  ),
                  label: Text(note == null ? '기록' : '수정'),
                ),
              ],
            ),
            if (note == null)
              const Text(
                '다시 확인할 지표와 짧은 관찰 내용을 이 기기에만 기록할 수 있습니다.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.45,
                ),
              )
            else ...[
              if (note!.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note!.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          labelStyle: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 10,
                          ),
                          backgroundColor:
                              const Color(0xFF10B981).withValues(alpha: 0.12),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              if (note!.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note!.text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                '로컬 저장 · 투자 판단이나 거래 상태는 기록하지 않습니다.',
                style: TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showObservationNoteEditor({
  required BuildContext context,
  required WidgetRef ref,
  required Stock stock,
  required ObservationNote? existing,
}) async {
  const availableTags = ['PER', 'ROE', '배당', '데이터'];
  final controller = TextEditingController(text: existing?.text ?? '');
  final selectedTags = <String>{...?existing?.tags};

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${resolveInstrumentName(stock.ticker, stock.name)} 관찰 메모',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '다시 살펴볼 지표와 관찰 내용만 기록하세요. 목표가, 수량, 매수·매도 상태는 저장하지 않습니다.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTags
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: selectedTags.contains(tag),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLength: maxObservationNoteLength,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '예: ROE 데이터 갱신 여부를 다음 확인 때 다시 살펴보기',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (existing != null)
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(observationNotesProvider.notifier)
                              .delete(stock.ticker);
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        child: const Text('삭제'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        await ref.read(observationNotesProvider.notifier).save(
                              ticker: stock.ticker,
                              name: stock.name,
                              text: controller.text,
                              tags: selectedTags,
                            );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  controller.dispose();
}

class _DataConfidenceCard extends StatelessWidget {
  final Stock stock;

  const _DataConfidenceCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final missingMetrics = stock.missingMetrics;
    final status = _confidenceStatus(stock);
    final accent = _confidenceColor(stock);
    final metricSources = const {
      'per': 'PER',
      'roe': 'ROE',
      'dividend': '배당',
    }
        .entries
        .where((entry) => stock.metricSources.containsKey(entry.key))
        .map((entry) => '${entry.value} · ${stock.metricSources[entry.key]}')
        .toList();

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '데이터 확인 정보',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '가격과 지표의 출처 및 누락 여부',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DataInfoRow(
              label: '가격',
              value: stock.priceSource,
            ),
            _DataInfoRow(
              label: '가격 갱신',
              value: _relativeUpdatedAt(stock.lastUpdated),
            ),
            const SizedBox(height: 8),
            const Text(
              '지표 출처',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 6),
            if (metricSources.isEmpty)
              const Text(
                '확인 가능한 펀더멘털 지표가 없습니다.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: metricSources
                    .map(
                      (source) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          source,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (stock.metricsUpdatedAt != null) ...[
              const SizedBox(height: 8),
              _DataInfoRow(
                label: '지표 갱신',
                value: _relativeUpdatedAt(stock.metricsUpdatedAt!),
              ),
            ],
            if (missingMetrics.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DataInfoRow(
                label: '누락 지표',
                value: missingMetrics.join(', '),
                valueColor: const Color(0xFFFB923C),
              ),
            ],
            if (stock.usesSampleMetrics) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB923C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFB923C).withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  '일부 지표는 실데이터 누락을 보완한 샘플 값입니다. 순위와 기여도는 학습용 비교로만 확인해주세요.',
                  style: TextStyle(
                    color: Color(0xFFFDBA74),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '표시되는 가격, 지표, 순위는 참고용 정보이며 투자 자문이나 특정 종목의 매수·매도 권유가 아닙니다.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DataInfoRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _confidenceStatus(Stock stock) {
  if (stock.usesSampleMetrics) {
    return '샘플 포함';
  }
  if (stock.priceSource == '출처 미확인' || stock.metricSources.isEmpty) {
    return '확인 필요';
  }
  if (stock.missingMetrics.isNotEmpty) {
    return '일부 누락';
  }
  return '출처 확인됨';
}

Color _confidenceColor(Stock stock) {
  if (stock.usesSampleMetrics) {
    return const Color(0xFFFB923C);
  }
  if (stock.priceSource == '출처 미확인' || stock.metricSources.isEmpty) {
    return const Color(0xFF94A3B8);
  }
  if (stock.missingMetrics.isNotEmpty) {
    return const Color(0xFF60A5FA);
  }
  return const Color(0xFF10B981);
}

String _relativeUpdatedAt(DateTime updatedAt) {
  final difference = DateTime.now().difference(updatedAt);
  if (difference.isNegative || difference.inMinutes < 1) {
    return '방금 전';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  }
  return '${updatedAt.year}.${updatedAt.month.toString().padLeft(2, '0')}.${updatedAt.day.toString().padLeft(2, '0')}';
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _InsightNoteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  const _InsightNoteCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _InsightBadge({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
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

class _ContributionOverview extends StatelessWidget {
  final List<StockInsightDriver> drivers;

  const _ContributionOverview({required this.drivers});

  @override
  Widget build(BuildContext context) {
    final contributions = drivers
        .map((driver) => _MetricContribution(driver))
        .where((item) => item.score > 0)
        .toList();
    final total = contributions.fold<double>(
      0,
      (sum, item) => sum + item.score,
    );

    if (contributions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x3345B7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Color(0xFF60A5FA),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                '지표 기여도',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '선택한 분석 기준에서 각 지표가 샘플 점수에 얼마나 설명력을 더했는지 보여줍니다.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          ...contributions.map(
            (item) => _ContributionBar(
              item: item,
              total: total,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricContribution {
  final StockInsightDriver driver;
  final double score;

  _MetricContribution(this.driver)
      : score = (driver.weight * driver.normalizedValue * 100).clamp(0, 100);

  double shareOf(double total) {
    if (total <= 0) {
      return 0;
    }
    return (score / total).clamp(0, 1);
  }
}

class _ContributionBar extends StatelessWidget {
  final _MetricContribution item;
  final double total;

  const _ContributionBar({
    required this.item,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final share = item.shareOf(total);
    final driver = item.driver;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 46,
                child: Text(
                  driver.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${driver.rawValueLabel} · 비중 ${(driver.weight * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${item.score.round()}점',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 7,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(
                _contributionColor(driver.metricKey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _contributionColor(String metricKey) {
  switch (metricKey) {
    case 'per':
      return const Color(0xFF60A5FA);
    case 'roe':
      return const Color(0xFF10B981);
    case 'dividend':
      return const Color(0xFFFB923C);
    default:
      return const Color(0xFFA78BFA);
  }
}

class _InsightDriverRow extends StatelessWidget {
  final StockInsightDriver driver;

  const _InsightDriverRow({required this.driver});

  @override
  Widget build(BuildContext context) {
    final contribution = (driver.weight * driver.normalizedValue * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                driver.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      driver.rawValueLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Weight ${(driver.weight * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Fit $contribution',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  driver.summary,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _DetailStateMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
