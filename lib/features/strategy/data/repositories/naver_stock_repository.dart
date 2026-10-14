import 'dart:developer' as developer;

import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/keyless_fundamentals.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/stock_universe.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

/// Keyless Korean quote fallback used when KRX/KIS is unavailable.
///
/// This is not the final production data contract, but it keeps release-device
/// testing honest by avoiding stale mock prices for Korean tickers.
class NaverStockRepository {
  static const _baseUrl =
      'https://polling.finance.naver.com/api/realtime/domestic/stock';
  static const _integrationUrl = 'https://m.stock.naver.com/api/stock';

  final DioClient _dioClient;

  NaverStockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  Future<List<Stock>> getStocks({
    Map<String, String>? tickers,
  }) async {
    final targetTickers = tickers ?? koreanUniverseTickers;
    final futures = targetTickers.entries.map(
      (entry) => getStockByCode(entry.key, fallbackName: entry.value),
    );
    final results = await Future.wait(futures, eagerError: false);
    final stocks = results.whereType<Stock>().toList();

    developer.log(
      'Successfully fetched ${stocks.length}/${targetTickers.length} stocks from Naver quotes',
      name: 'NaverStockRepository',
    );
    return stocks;
  }

  Future<Stock?> getStockByCode(
    String stockCode, {
    String? fallbackName,
  }) async {
    try {
      final response = await _dioClient.get('$_baseUrl/$stockCode');
      if (response == null || response is! Map) {
        return null;
      }

      final datas = response['datas'];
      if (datas is! List || datas.isEmpty) {
        return null;
      }

      final item = datas.first;
      if (item is! Map) {
        return null;
      }

      final price = _extractPrice(
        item['closePriceRaw'] ?? item['closePrice'],
      );
      if (price <= 0) {
        return null;
      }

      final ticker = (item['itemCode'] as String?)?.trim();
      final name = (item['stockName'] as String?)?.trim();

      return Stock(
        ticker: ticker?.isNotEmpty == true ? ticker! : stockCode,
        name: name?.isNotEmpty == true ? name! : (fallbackName ?? stockCode),
        price: price,
        per: 0,
        roe: 0,
        dividendYield: 0,
        lastUpdated: DateTime.now(),
        priceSource: 'Naver Finance',
      );
    } on ApiException catch (error) {
      developer.log(
        'Naver quote API error for $stockCode: ${error.message}',
        name: 'NaverStockRepository',
        error: error,
      );
      return null;
    } catch (error) {
      developer.log(
        'Naver quote fetch failed for $stockCode: $error',
        name: 'NaverStockRepository',
        error: error,
      );
      return null;
    }
  }

  /// PER, ROE, and dividend yield from Naver's public stock pages.
  /// Price stays 0 so callers can merge this onto an existing quote.
  Future<Stock?> getFundamentals(String stockCode) async {
    try {
      final responses = await Future.wait([
        _getJson('$_integrationUrl/$stockCode/integration'),
        _getJson('$_integrationUrl/$stockCode/finance/annual'),
      ]);
      final integration = responses[0] is Map
          ? parseNaverIntegration(Map<dynamic, dynamic>.from(responses[0] as Map))
          : const KeylessFundamentals();
      final roe = responses[1] is Map
          ? parseNaverAnnualRoe(Map<dynamic, dynamic>.from(responses[1] as Map))
          : null;
      final fundamentals = KeylessFundamentals(
        per: integration.per,
        roe: roe ?? 0,
        dividendYield: integration.dividendYield,
      );
      if (!fundamentals.hasAny) {
        return null;
      }

      final now = DateTime.now();
      return Stock(
        ticker: stockCode,
        name: stockCode,
        price: 0,
        per: fundamentals.per,
        roe: fundamentals.roe,
        dividendYield: fundamentals.dividendYield,
        lastUpdated: now,
        metricSources: {
          if (fundamentals.per > 0) 'per': 'Naver Finance',
          if (fundamentals.roe > 0) 'roe': 'Naver Finance',
          if (fundamentals.dividendYield > 0) 'dividend': 'Naver Finance',
        },
        metricsUpdatedAt: now,
      );
    } catch (error) {
      developer.log(
        'Naver fundamentals failed for $stockCode: $error',
        name: 'NaverStockRepository',
        error: error,
      );
      return null;
    }
  }

  Future<dynamic> _getJson(String url) async {
    try {
      return await _dioClient.get(url);
    } catch (error) {
      developer.log(
        'Naver fundamentals request failed: $error',
        name: 'NaverStockRepository',
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
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }
}
