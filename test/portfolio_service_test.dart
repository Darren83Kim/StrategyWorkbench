import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/features/portfolio/domain/services/portfolio_service.dart';

void main() {
  group('PortfolioService', () {
    test('평단가 계산 유닛 테스트', () {
      // Arrange
      final service = PortfolioService();
      const existingQuantity = 10;
      const existingAveragePrice = 100000.0;
      const newQuantity = 5;
      const newPrice = 130000.0;
      const expectedAveragePrice = 110000.0;

      // Act
      final newAveragePrice = service.calculateAveragePrice(
        existingQuantity: existingQuantity,
        existingAveragePrice: existingAveragePrice,
        newQuantity: newQuantity,
        newPrice: newPrice,
      );

      // Assert
      expect(newAveragePrice, expectedAveragePrice);
    });
  });
}
