import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/stock_detail_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';
import 'package:strategy_workbench/shared/widgets/transaction_timeline_list.dart';

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
    final transactionsAsync =
        ref.watch(transactionsByTickerProvider(detail.stock.ticker));
    final activeInsightAsync =
        ref.watch(activeStockInsightProvider(detail.stock.ticker));
    final stock = detail.stock;
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
                          strings.whyThisStockTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.whyThisStockNoActiveStrategy,
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
                        strings.whyThisStockTitle,
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
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.transactions,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
