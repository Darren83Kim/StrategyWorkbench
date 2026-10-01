import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/providers/stock_comparison_providers.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class StockComparisonScreen extends ConsumerStatefulWidget {
  final List<String> initialSymbols;

  const StockComparisonScreen({
    super.key,
    this.initialSymbols = const [],
  });

  @override
  ConsumerState<StockComparisonScreen> createState() =>
      _StockComparisonScreenState();
}

class _StockComparisonScreenState extends ConsumerState<StockComparisonScreen> {
  late final List<String> _selectedSymbols;
  String _query = '';
  String? _strategyName;

  @override
  void initState() {
    super.initState();
    _selectedSymbols = widget.initialSymbols
        .map(normalizeTickerInput)
        .where((symbol) => symbol.isNotEmpty)
        .toSet()
        .take(3)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final strategies = ref.watch(allStrategiesProvider);
    final activeStrategy = ref.watch(activeStrategyProvider);
    final watchlist = ref.watch(watchlistProvider).value ?? {};
    final allStocksAsync = ref.watch(allStocksForSnapshotProvider);
    final selectedStrategyName = _resolveStrategyName(
      strategies,
      activeStrategy,
    );
    final comparisonAsync =
        _selectedSymbols.length >= 2 && selectedStrategyName != null
            ? ref.watch(
                stockComparisonProvider(
                  StockComparisonRequest(
                    symbols: _selectedSymbols,
                    strategyName: selectedStrategyName,
                  ),
                ),
              )
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('종목 지표 비교'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: allStocksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, _) => Center(
          child: Text(
            '비교 데이터를 불러오지 못했습니다.\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        data: (stocks) {
          final selectedStocks = _selectedSymbols
              .map((symbol) => _findStock(stocks, symbol))
              .whereType<Stock>()
              .toList();
          final watchedSymbols =
              watchlist.values.expand((items) => items).toSet();
          final watchedStocks = watchedSymbols
              .map((symbol) => _findStock(stocks, symbol))
              .whereType<Stock>()
              .toList();
          final searchResults = _search(stocks, _query);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _IntroCard(selectedCount: _selectedSymbols.length),
              const SizedBox(height: 16),
              _SelectedStocks(
                stocks: selectedStocks,
                onRemove: _removeSymbol,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '종목명 또는 티커 검색',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_query.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _StockPickerList(
                  stocks: searchResults,
                  selectedSymbols: _selectedSymbols.toSet(),
                  onTap: _toggleSymbol,
                ),
              ] else if (watchedStocks.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  '관심 종목에서 선택',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: watchedStocks.map((stock) {
                    final selected = _selectedSymbols.contains(
                      normalizeTickerInput(stock.ticker),
                    );
                    return FilterChip(
                      selected: selected,
                      label:
                          Text(resolveInstrumentName(stock.ticker, stock.name)),
                      onSelected: (_) => _toggleSymbol(stock.ticker),
                      selectedColor: const Color(0x3310B981),
                      backgroundColor: const Color(0xFF1E293B),
                      checkmarkColor: const Color(0xFF10B981),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF334155),
                      ),
                      labelStyle: TextStyle(
                        color:
                            selected ? const Color(0xFF6EE7B7) : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              if (selectedStrategyName != null)
                DropdownButtonFormField<String>(
                  initialValue: selectedStrategyName,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '점수 계산 기준',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: strategies
                      .map(
                        (strategy) => DropdownMenuItem(
                          value: strategy.name,
                          child: Text(strategy.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _strategyName = value),
                ),
              const SizedBox(height: 16),
              if (_selectedSymbols.length < 2)
                const _EmptyComparisonCard()
              else if (comparisonAsync != null)
                comparisonAsync.when(
                  loading: () => const GlassContainer(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
                  error: (error, _) => GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '비교 계산 중 오류가 발생했습니다: $error',
                        style: const TextStyle(color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ),
                  data: (report) => report == null
                      ? const _EmptyComparisonCard()
                      : _ComparisonReportView(report: report),
                ),
            ],
          );
        },
      ),
    );
  }

  String? _resolveStrategyName(
    List<SavedFilter> strategies,
    SavedFilter? activeStrategy,
  ) {
    if (_strategyName != null &&
        strategies.any((strategy) => strategy.name == _strategyName)) {
      return _strategyName;
    }
    return activeStrategy?.name ?? strategies.firstOrNull?.name;
  }

  Stock? _findStock(List<Stock> stocks, String symbol) {
    final normalized = normalizeTickerInput(symbol);
    return stocks
        .where((stock) => normalizeTickerInput(stock.ticker) == normalized)
        .firstOrNull;
  }

  List<Stock> _search(List<Stock> stocks, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return const [];
    }
    return stocks
        .where((stock) {
          final name =
              resolveInstrumentName(stock.ticker, stock.name).toLowerCase();
          return name.contains(trimmed) ||
              stock.ticker.toLowerCase().contains(trimmed);
        })
        .take(20)
        .toList();
  }

  void _toggleSymbol(String symbol) {
    final normalized = normalizeTickerInput(symbol);
    setState(() {
      if (_selectedSymbols.contains(normalized)) {
        _selectedSymbols.remove(normalized);
      } else if (_selectedSymbols.length < 3) {
        _selectedSymbols.add(normalized);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 3개 종목까지 비교할 수 있습니다.')),
        );
      }
    });
  }

  void _removeSymbol(String symbol) {
    setState(() => _selectedSymbols.remove(normalizeTickerInput(symbol)));
  }
}

class _IntroCard extends StatelessWidget {
  final int selectedCount;

  const _IntroCard({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.balance_rounded,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택 $selectedCount/3',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '같은 비교군 안에서 지표와 기준별 기여도 차이를 확인합니다.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedStocks extends StatelessWidget {
  final List<Stock> stocks;
  final ValueChanged<String> onRemove;

  const _SelectedStocks({required this.stocks, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return const Text(
        '검색하거나 관심 종목에서 비교할 샘플을 선택하세요.',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stocks
          .map(
            (stock) => InputChip(
              label: Text(resolveInstrumentName(stock.ticker, stock.name)),
              deleteIconColor: Colors.white54,
              onDeleted: () => onRemove(stock.ticker),
              backgroundColor: const Color(0xFF1E293B),
              side: const BorderSide(color: Color(0xFF10B981)),
              labelStyle: const TextStyle(color: Color(0xFF6EE7B7)),
            ),
          )
          .toList(),
    );
  }
}

class _StockPickerList extends StatelessWidget {
  final List<Stock> stocks;
  final Set<String> selectedSymbols;
  final ValueChanged<String> onTap;

  const _StockPickerList({
    required this.stocks,
    required this.selectedSymbols,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        children: stocks.map((stock) {
          final selected = selectedSymbols.contains(
            normalizeTickerInput(stock.ticker),
          );
          return ListTile(
            dense: true,
            title: Text(
              resolveInstrumentName(stock.ticker, stock.name),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              stock.ticker,
              style: const TextStyle(color: Colors.white38),
            ),
            trailing: Icon(
              selected ? Icons.check_circle : Icons.add_circle_outline,
              color: selected ? const Color(0xFF10B981) : Colors.white38,
            ),
            onTap: () => onTap(stock.ticker),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyComparisonCard extends StatelessWidget {
  const _EmptyComparisonCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            '2개 이상 선택하면 비교 리포트가 열립니다.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ),
    );
  }
}

class _ComparisonReportView extends StatelessWidget {
  static const colors = [
    Color(0xFF10B981),
    Color(0xFF60A5FA),
    Color(0xFFFB923C),
  ];

  final StockComparisonReport report;

  const _ComparisonReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '비교 리포트',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.headline,
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.summary,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                if (report.hasMixedMarkets) ...[
                  const SizedBox(height: 10),
                  const _ReportNotice(
                    icon: Icons.currency_exchange_rounded,
                    text: '국내와 미국 시장이 함께 선택되어 가격 우열은 계산하지 않습니다.',
                  ),
                ],
                if (report.missingMetricCount > 0) ...[
                  const SizedBox(height: 8),
                  _ReportNotice(
                    icon: Icons.info_outline_rounded,
                    text: '비어 있는 지표 ${report.missingMetricCount}개는 0점으로 표시됩니다.',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '정규화 지표 차트',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: report.items.asMap().entries.map((entry) {
                    return _Legend(
                      color: colors[entry.key],
                      label: resolveInstrumentName(
                        entry.value.stock.ticker,
                        entry.value.stock.name,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: report.items.asMap().entries.map((entry) {
                        final color = colors[entry.key];
                        return RadarDataSet(
                          dataEntries: comparisonMetricKeys
                              .map(
                                (key) => RadarEntry(
                                  value: entry.value.normalizedScores[key] ?? 0,
                                ),
                              )
                              .toList(),
                          borderColor: color,
                          fillColor: color.withValues(alpha: 0.10),
                          entryRadius: 2,
                          borderWidth: 2,
                        );
                      }).toList(),
                      getTitle: (index, angle) => RadarChartTitle(
                        text: comparisonMetricLabel(
                          comparisonMetricKeys[index],
                        ),
                      ),
                      titleTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      tickCount: 4,
                      ticksTextStyle: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 8,
                      ),
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
        ...report.items.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StockMetricCard(
                  item: entry.value,
                  color: colors[entry.key],
                ),
              ),
            ),
        const Text(
          '정규화 점수와 기여도는 지표 학습용 상대 비교이며 특정 종목의 매수·매도를 권유하지 않습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _StockMetricCard extends StatelessWidget {
  final StockComparisonItem item;
  final Color color;

  const _StockMetricCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final stock = item.stock;
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolveInstrumentName(stock.ticker, stock.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${stock.ticker} · ${formatMarketPrice(stock.ticker, stock.price)}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '기준 점수 ${item.score.toStringAsFixed(1)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  tooltip: '종목 상세',
                  onPressed: () => context.push('/market/${stock.ticker}'),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...comparisonMetricKeys.map(
              (key) => _MetricComparisonRow(
                label: comparisonMetricLabel(key),
                rawValue: _formatRawValue(item, key),
                normalized: item.normalizedScores[key] ?? 0,
                contribution: item.contributions[key] ?? 0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRawValue(StockComparisonItem item, String key) {
    final value = item.rawMetric(key);
    if (value <= 0) {
      return '없음';
    }
    return key == 'per'
        ? value.toStringAsFixed(1)
        : '${value.toStringAsFixed(1)}%';
  }
}

class _MetricComparisonRow extends StatelessWidget {
  final String label;
  final String rawValue;
  final double normalized;
  final double contribution;
  final Color color;

  const _MetricComparisonRow({
    required this.label,
    required this.rawValue,
    required this.normalized,
    required this.contribution,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              rawValue,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: (normalized / 100).clamp(0, 1),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              '정규 ${normalized.round()} · 기여 ${contribution.round()}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReportNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFBBF24), size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
