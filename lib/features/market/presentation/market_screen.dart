import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stockListProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.marketTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.refresh,
            onPressed: () => ref.invalidate(stockListProvider),
          ),
        ],
      ),
      body: stocksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                '${s.loadFailed} $error',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(stockListProvider),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
        data: (stocks) {
          if (stocks.isEmpty) {
            return Center(
              child: Text(s.noStocksAvailable,
                  style: const TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => context.push('/market/${stock.ticker}'),
                  child: GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                                Text(stock.ticker,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.white70)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${stock.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTag('PER ${stock.per.toStringAsFixed(1)}'),
                                  const SizedBox(width: 4),
                                  _buildTag('ROE ${stock.roe.toStringAsFixed(1)}%'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.grey[800], borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
    );
  }
}
