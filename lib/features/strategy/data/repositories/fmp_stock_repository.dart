import 'dart:developer' as developer;

import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/stock_universe.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

/// Financial Modeling Prep API를 사용하는 미국 주식 폴백 저장소 (US 2순위)
///
/// 현재 free tier에서 안정적으로 확인된 stable endpoint는 `profile`이다.
/// PER/ROE 같은 세부 펀더멘탈이 응답되지 않을 수 있어, price/name 위주 폴백으로 사용한다.
class FmpStockRepository {
  final DioClient _dioClient;

  FmpStockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  Future<List<Stock>> getStocks({
    List<String> tickers = usUniverseTickers,
  }) async {
    if (!ApiKeys.isFmpConfigured) {
      developer.log('FMP API key not configured', name: 'FmpStockRepository');
      return [];
    }

    final stocks = <Stock>[];
    for (final ticker in tickers) {
      final stock = await getStockByTicker(ticker);
      if (stock != null) {
        stocks.add(stock);
      }
    }

    developer.log(
      'Successfully fetched ${stocks.length}/${tickers.length} stocks from FMP',
      name: 'FmpStockRepository',
    );
    return stocks;
  }

  Future<Stock?> getStockByTicker(String ticker) async {
    try {
      developer.log('Fetching stock: $ticker', name: 'FmpStockRepository');
      final url =
          'https://financialmodelingprep.com/stable/profile?symbol=$ticker&apikey=${ApiKeys.fmpApiKey}';
      final response = await _dioClient.get(url);

      final payload = switch (response) {
        final List<dynamic> list when list.isNotEmpty => list.first,
        final Map<dynamic, dynamic> map => map,
        _ => null,
      };

      if (payload is! Map) {
        developer.log('Invalid response format for $ticker',
            name: 'FmpStockRepository');
        return null;
      }

      final price = _extractDouble(payload['price'], fallback: 0.0);
      if (price <= 0) {
        developer.log('No price data for $ticker', name: 'FmpStockRepository');
        return null;
      }

      final stock = Stock(
        ticker: ticker,
        name: (payload['companyName'] as String?) ?? ticker,
        price: price,
        per: 0.0,
        roe: 0.0,
        dividendYield: 0.0,
        lastUpdated: DateTime.now(),
      );

      developer.log(
        'Fetched stock: $ticker via FMP profile fallback',
        name: 'FmpStockRepository',
      );
      return stock;
    } on ApiException catch (e) {
      developer.log('API Error for $ticker: ${e.message}',
          name: 'FmpStockRepository', error: e);
      return null;
    } catch (e) {
      developer.log('Unexpected error for $ticker: $e',
          name: 'FmpStockRepository', error: e);
      return null;
    }
  }

  double _extractDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? fallback;
    }
    return fallback;
  }
}
