class PortfolioService {
  /// Calculates the new average price after a new purchase.
  ///
  /// [existingQuantity] is the number of shares already held.
  /// [existingAveragePrice] is the average price of the existing shares.
  /// [newQuantity] is the number of new shares being purchased.
  /// [newPrice] is the price of the new shares.
  ///
  /// Returns the new average price.
  double calculateAveragePrice({
    required int existingQuantity,
    required double existingAveragePrice,
    required int newQuantity,
    required double newPrice,
  }) {
    if (existingQuantity < 0 || newQuantity <= 0) {
      throw ArgumentError("Quantities must be positive.");
    }

    final totalValue = (existingQuantity * existingAveragePrice) + (newQuantity * newPrice);
    final totalQuantity = existingQuantity + newQuantity;

    if (totalQuantity == 0) {
      return 0;
    }

    return totalValue / totalQuantity;
  }
}
