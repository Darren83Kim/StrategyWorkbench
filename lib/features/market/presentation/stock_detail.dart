import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/mock_stock_repository.dart';
import '../../../core/visualization/normalizer.dart';
import '../../../core/tags/smart_tag.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../strategy/domain/entities/stock.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;

  const StockDetailScreen({super.key, required this.symbol});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late Future<_StockDetailData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_StockDetailData> _loadData() async {
    final stockRepository = MockStockRepository();
    final allStocks = await stockRepository.getStocks();
    final stock = allStocks.firstWhere(
      (s) => s.ticker == widget.symbol,
      orElse: () => allStocks.first,
    );
    final peers = allStocks.where((s) => s.ticker != widget.symbol).toList();

    final normalizer = Normalizer();
    final metrics = ['per', 'roe', 'dividendYield'];
    final normalized = normalizer.normalize([stock, ...peers], metrics);
    final myNorm = normalized[stock.ticker] ?? {for (var m in metrics) m: 0.5};

    final tags = SmartTagger().generateTags(stock);

    return _StockDetailData(
      stock: stock,
      normalizedMetrics: myNorm,
      metrics: metrics,
      tags: tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('종목 상세'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<_StockDetailData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    '데이터 로드 실패: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(_StockDetailData data) {
    final stock = data.stock;
    final myNorm = data.normalizedMetrics;
    final metrics = data.metrics;
    final tags = data.tags;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Header Card ---
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stock.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stock.ticker,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₩${stock.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricBadge('PER', stock.per.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      _buildMetricBadge('ROE', '${stock.roe.toStringAsFixed(1)}%'),
                      const SizedBox(width: 8),
                      _buildMetricBadge('배당', '${stock.dividendYield.toStringAsFixed(1)}%'),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFF10B981),
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Radar Chart (Normalized) ---
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '정규화 지표 차트',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: RadarChart(
                      RadarChartData(
                        dataSets: [
                          RadarDataSet(
                            dataEntries: metrics
                                .map((m) => RadarEntry(value: myNorm[m] ?? 0.0))
                                .toList(),
                            borderColor: const Color(0xFF10B981),
                            fillColor: const Color(0x3310B981),
                          ),
                        ],
                        radarBackgroundColor: Colors.transparent,
                        titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                        getTitle: (index, angle) {
                          switch (index) {
                            case 0:
                              return RadarChartTitle(text: 'PER\n${myNorm['per']?.toStringAsFixed(2) ?? '-'}');
                            case 1:
                              return RadarChartTitle(text: 'ROE\n${myNorm['roe']?.toStringAsFixed(2) ?? '-'}');
                            case 2:
                              return RadarChartTitle(text: '배당\n${myNorm['dividendYield']?.toStringAsFixed(2) ?? '-'}');
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
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF), // 10% white
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

/// Internal data class for passing loaded data from Future to UI.
class _StockDetailData {
  final Stock stock;
  final Map<String, double> normalizedMetrics;
  final List<String> metrics;
  final List<String> tags;

  _StockDetailData({
    required this.stock,
    required this.normalizedMetrics,
    required this.metrics,
    required this.tags,
  });
}
