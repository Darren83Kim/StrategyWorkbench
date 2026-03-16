import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart' as strategy_stock;
import 'package:strategy_workbench/features/market/models/stock.dart' as market_stock;

extension StockConversion on strategy_stock.Stock {
  market_stock.Stock toMarketStock() {
    return market_stock.Stock(
      symbol: ticker,
      name: name,
      price: price,
      change: 0,
      per: per,
      roe: roe,
      dividendYield: dividendYield,
    );
  }
}
