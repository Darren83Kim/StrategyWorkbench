import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/mock_stock_repository.dart';
import '../../../core/visualization/normalizer.dart';
import '../../../core/tags/smart_tag.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../strategy/domain/entities/stock.dart' as StrategyStock;

class StockDetailScreen extends StatelessWidget {
  final String symbol;

  const StockDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    // Using the MockStockRepository for now.
    final stockRepository = MockStockRepository();
    final allStocks = stockRepository.getStocks();
    final stock = allStocks.firstWhere((s) => s.symbol == symbol, orElse: () => allStocks.first);
    final peers = allStocks.where((s) => s.symbol != symbol).toList();

    final normalizer = Normalizer();
    final metrics = ['per', 'roe', 'dividendYield'];
    final normalized = normalizer.normalize([stock, ...peers], metrics);
    final myNorm = normalized[stock.ticker] ?? {for (var m in metrics) m: 0.5};

    final tags = SmartTagger().generateTags(stock);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: Text(stock.name), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stock.ticker, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('${stock.price}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: tags.map((t) => Chip(label: Text(t))).toList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries: metrics.map((m) => RadarEntry(value: myNorm[m] ?? 0.0)).toList(),
                          borderColor: Colors.greenAccent,
                          fillColor: Colors.greenAccent.withOpacity(0.2),
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                      tickCount: 4,
                    ),
                    // animation handled by chart defaults
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, idx) {
                    return ListTile(
                      title: Text('Transaction ${idx + 1}', style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('Buy 10 @ 100000', style: TextStyle(color: Colors.white70)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
