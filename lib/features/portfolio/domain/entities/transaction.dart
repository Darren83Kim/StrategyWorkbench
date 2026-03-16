// ignore: constant_identifier_names
enum TransactionType { BUY, SELL }

class Transaction {
  final int? id;
  final String ticker;
  final TransactionType type;
  final double price;
  final int quantity;
  final DateTime dateTime;

  Transaction({
    this.id,
    required this.ticker,
    required this.type,
    required this.price,
    required this.quantity,
    required this.dateTime,
  });
}
