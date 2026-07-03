import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/stock_universe.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

/// Keyless US quote fallback.
///
/// Nasdaq responses can be delayed, but they are good enough for release-device
/// smoke testing when no paid/free API keys are bundled into the app.
class NasdaqStockRepository {
  static const _baseUrl = 'https://api.nasdaq.com/api/quote';

  final DioClient _dioClient;

  NasdaqStockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  Future<List<Stock>> getStocks({
    List<String> tickers = usUniverseTickers,
  }) async {
    final futures = tickers.map(getStockByTicker);
    final results = await Future.wait(futures, eagerError: false);
    final stocks = results.whereType<Stock>().toList();

    developer.log(
      'Successfully fetched ${stocks.length}/${tickers.length} stocks from Nasdaq quotes',
      name: 'NasdaqStockRepository',
    );
    return stocks;
  }

  Future<Stock?> getStockByTicker(String ticker) async {
    try {
      final response = await _dioClient.get(
        '$_baseUrl/$ticker/info?assetclass=stocks',
        options: Options(
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) StrategyWorkbench/1.0',
            'Accept': 'application/json, text/plain, */*',
          },
        ),
      );

      if (response == null || response is! Map) {
        return null;
      }

      final data = response['data'];
      if (data is! Map) {
        return null;
      }

      final primaryData = data['primaryData'];
      if (primaryData is! Map) {
        return null;
      }

      final price = _extractPrice(primaryData['lastSalePrice']);
      if (price <= 0) {
        return null;
      }

      final symbol = (data['symbol'] as String?)?.trim();
      final name = (data['companyName'] as String?)?.trim();

      return Stock(
        ticker: symbol?.isNotEmpty == true ? symbol! : ticker,
        name: _cleanCompanyName(name) ?? ticker,
        price: price,
        per: 0,
        roe: 0,
        dividendYield: 0,
        lastUpdated: DateTime.now(),
      );
    } on ApiException catch (error) {
      developer.log(
        'Nasdaq quote API error for $ticker: ${error.message}',
        name: 'NasdaqStockRepository',
        error: error,
      );
      return null;
    } catch (error) {
      developer.log(
        'Nasdaq quote fetch failed for $ticker: $error',
        name: 'NasdaqStockRepository',
        error: error,
      );
      return null;
    }
  }

  double _extractPrice(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final normalized = value
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .replaceAll('N/A', '')
          .trim();
      return double.tryParse(normalized) ?? 0;
    }
    return 0;
  }

  String? _cleanCompanyName(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return value
        .replaceAll(' Class A Common Stock', '')
        .replaceAll(' Common Stock', '')
        .replaceAll(' Ordinary Shares', '')
        .trim();
  }
}
