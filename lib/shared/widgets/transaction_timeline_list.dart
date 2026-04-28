import 'package:flutter/material.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;

import 'glass_container.dart';

class TransactionTimelineList extends StatelessWidget {
  final List<model.Transaction> transactions;
  final String emptyMessage;
  final String buyLabel;
  final String sellLabel;
  final int? maxItems;
  final bool showTicker;

  const TransactionTimelineList({
    super.key,
    required this.transactions,
    required this.emptyMessage,
    required this.buyLabel,
    required this.sellLabel,
    this.maxItems,
    this.showTicker = true,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            emptyMessage,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final visibleTransactions =
        maxItems == null ? transactions : transactions.take(maxItems!).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleTransactions.length,
      itemBuilder: (context, index) {
        final tx = visibleTransactions[index];
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
                      color: isBuy ? Colors.blue[700] : Colors.orange[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        isBuy ? Icons.arrow_downward : Icons.arrow_upward,
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
                          _buildTitle(
                            ticker: tx.ticker,
                            isBuy: isBuy,
                          ),
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
                    _formatDate(tx.dateTime),
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
  }

  String _buildTitle({
    required String ticker,
    required bool isBuy,
  }) {
    final action = isBuy ? buyLabel : sellLabel;
    return showTicker ? '$action $ticker' : action;
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
