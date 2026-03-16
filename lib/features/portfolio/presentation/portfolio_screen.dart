import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/portfolio_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'dart:developer' as developer;

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final summary = ref.watch(portfolioSummaryProvider);
    final transactionsAsync = ref.watch(transactionHistoryProvider);
    final s = ref.watch(stringsProvider);

    final totalCost = summary['totalCost'] ?? 0.0;
    final totalValue = summary['totalValue'] ?? 0.0;
    final totalGainLoss = summary['gainLoss'] ?? 0.0;
    final totalGainLossPercent = summary['gainLossPercent'] ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(s.portfolioTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: s.addStock,
            onPressed: () => _showAddStockDialog(s),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(
              totalCost: totalCost,
              totalValue: totalValue,
              totalGainLoss: totalGainLoss,
              totalGainLossPercent: totalGainLossPercent,
              s: s,
            ),
            const SizedBox(height: 20),

            Text(
              '${s.holdingsList} (${portfolio.length})',
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (portfolio.isEmpty)
              Center(
                child: Text(s.noStocksAvailable,
                    style: const TextStyle(color: Colors.white70)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: portfolio.length,
                itemBuilder: (context, index) =>
                    _buildPortfolioCard(portfolio[index], index, s),
              ),

            const SizedBox(height: 20),

            Text(
              s.transactions,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTransactionHistory(transactionsAsync, s),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalCost,
    required double totalValue,
    required double totalGainLoss,
    required double totalGainLossPercent,
    required dynamic s,
  }) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.portfolioTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: totalGainLoss >= 0
                        ? Colors.green[700]
                        : Colors.red[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${totalGainLoss >= 0 ? '+' : ''}${totalGainLossPercent.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.totalInvestment,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s.currentValue,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.gainLoss,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${totalGainLoss >= 0 ? '+' : ''}\$${totalGainLoss.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: totalGainLoss >= 0
                              ? Colors.green[400]
                              : Colors.red[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Gain/Loss %',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${totalGainLoss >= 0 ? '+' : ''}${totalGainLossPercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: totalGainLoss >= 0
                              ? Colors.green[400]
                              : Colors.red[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(PortfolioItem item, int index, dynamic s) {
    final isGain = item.gainLoss >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showStockDetailDialog(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            item.ticker[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.ticker,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${item.currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${isGain ? '+' : ''}${item.gainLossPercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color:
                                  isGain ? Colors.green[400] : Colors.red[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn(
                            s.quantity, item.quantity.toStringAsFixed(0)),
                        _buildInfoColumn(
                            s.price,
                            '\$${item.avgPrice.toStringAsFixed(2)}'),
                        _buildInfoColumn(
                            'Total',
                            '\$${item.totalCost.toStringAsFixed(2)}'),
                        _buildInfoColumn(
                            s.currentValue,
                            '\$${item.currentValue.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory(
      AsyncValue<List<model.Transaction>> transactionsAsync, dynamic s) {
    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('${s.error}: $e',
            style: const TextStyle(color: Colors.white70)),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.noTransactions,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        // 최근 거래부터 표시
        final sorted = [...transactions]
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final recent = sorted.take(10).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          itemBuilder: (context, index) {
            final tx = recent[index];
            final isBuy = tx.type == model.TransactionType.BUY;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              isBuy ? Colors.blue[700] : Colors.orange[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Icon(
                            isBuy
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isBuy ? s.buy : s.sell} ${tx.ticker}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${tx.quantity} @ \$${tx.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}-${tx.dateTime.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddStockDialog(dynamic s) {
    final tickerController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.addStock),
        backgroundColor: const Color(0xFF1E293B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tickerController,
              decoration: InputDecoration(
                hintText: 'Ticker (e.g., AAPL)',
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                hintText: 'Quantity',
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                hintText: 'Average Price',
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final ticker = tickerController.text.trim().toUpperCase();
              final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;

              if (ticker.isEmpty || quantity <= 0 || price <= 0) return;

              ref.read(portfolioProvider.notifier).buy(ticker, ticker, quantity, price);
              ref.read(transactionHistoryProvider.notifier).addTransaction(
                model.Transaction(
                  ticker: ticker,
                  type: model.TransactionType.BUY,
                  price: price,
                  quantity: quantity,
                  dateTime: DateTime.now(),
                ),
              );
              developer.log('Added: $ticker x$quantity @ \$$price', name: 'PortfolioScreen');
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$ticker ${s.buy} ✓'),
                backgroundColor: const Color(0xFF10B981),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }

  void _showStockDetailDialog(PortfolioItem item) {
    final s = ref.read(stringsProvider);
    developer.log('Viewing stock detail: ${item.ticker}', name: 'PortfolioScreen');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.ticker} - ${item.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                'Current Price',
                '\$${item.currentPrice.toStringAsFixed(2)}'),
            _buildDetailRow(
                'Quantity', item.quantity.toStringAsFixed(0)),
            _buildDetailRow(
                'Avg Price',
                '\$${item.avgPrice.toStringAsFixed(2)}'),
            _buildDetailRow(
              'Gain/Loss',
              '${item.gainLoss >= 0 ? '+' : ''}\$${item.gainLoss.toStringAsFixed(2)} (${item.gainLossPercent.toStringAsFixed(2)}%)',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showBuyMoreDialog(item);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(s.buyMore),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showSellDialog(item);
                  },
                  icon: const Icon(Icons.remove),
                  label: Text(s.sell),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyMoreDialog(PortfolioItem item) {
    final s = ref.read(stringsProvider);
    final quantityController = TextEditingController();
    final priceController = TextEditingController(
      text: item.currentPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${s.buyMore} ${item.ticker}'),
        backgroundColor: const Color(0xFF1E293B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                hintText: s.quantity,
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                hintText: s.price,
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(quantityController.text.trim()) ?? 0;
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              if (qty <= 0 || price <= 0) return;

              ref
                  .read(portfolioProvider.notifier)
                  .buy(item.ticker, item.name, qty, price);

              ref
                  .read(transactionHistoryProvider.notifier)
                  .addTransaction(model.Transaction(
                    ticker: item.ticker,
                    type: model.TransactionType.BUY,
                    price: price,
                    quantity: qty,
                    dateTime: DateTime.now(),
                  ));

              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
            child: Text(s.buy),
          ),
        ],
      ),
    );
  }

  void _showSellDialog(PortfolioItem item) {
    final s = ref.read(stringsProvider);
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${s.sell} ${item.ticker}'),
        backgroundColor: const Color(0xFF1E293B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Available: ${item.quantity.toStringAsFixed(0)} shares',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                hintText: s.quantity,
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(quantityController.text.trim()) ?? 0;
              if (qty <= 0 || qty > item.quantity) return;

              ref.read(portfolioProvider.notifier).sell(item.ticker, qty);

              ref
                  .read(transactionHistoryProvider.notifier)
                  .addTransaction(model.Transaction(
                    ticker: item.ticker,
                    type: model.TransactionType.SELL,
                    price: item.currentPrice,
                    quantity: qty,
                    dateTime: DateTime.now(),
                  ));

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${item.ticker} ${s.sell} $qty ✓'),
                backgroundColor: Colors.orange[700],
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: Text(s.sell),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
