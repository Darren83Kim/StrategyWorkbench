import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'dart:developer' as developer;

/// 야후 파이낸스 API를 사용하는 스톡 저장소
class YahooStockRepository {
  final DioClient _dioClient;

  YahooStockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// 여러 티커의 주식 정보를 조회
  Future<List<Stock>> getStocks({
    List<String> tickers = const [
      'AAPL',
      'GOOGL',
      'MSFT',
      'AMZN',
      'NVDA',
      'TSLA',
      'META',
      'JNPR'
    ],
  }) async {
    try {
      final stocks = <Stock>[];

      // 병렬로 모든 티커 조회
      final futures = tickers.map((ticker) => _fetchStock(ticker));
      final results = await Future.wait(futures, eagerError: false);

      for (final result in results) {
        if (result != null) {
          stocks.add(result);
        }
      }

      developer.log('Successfully fetched ${stocks.length} stocks from Yahoo',
          name: 'YahooStockRepository');
      return stocks;
    } catch (e) {
      developer.log('Error fetching stocks: $e',
          name: 'YahooStockRepository', error: e);
      rethrow;
    }
  }

  /// 단일 티커 주식 정보 조회
  Future<Stock?> getStockByTicker(String ticker) async {
    try {
      return await _fetchStock(ticker);
    } catch (e) {
      developer.log('Error fetching stock $ticker: $e',
          name: 'YahooStockRepository', error: e);
      return null;
    }
  }

  /// Yahoo Finance API에서 주식 정보 가져오기
  Future<Stock?> _fetchStock(String ticker) async {
    try {
      developer.log('Fetching stock: $ticker', name: 'YahooStockRepository');

      // Yahoo Finance API 엔드포인트
      final url =
          '${ApiKeys.yahooBaseUrl}/v10/finance/quoteSummary/$ticker?modules=price,summaryDetail,defaultKeyStatistics';

      final response = await _dioClient.get(url);

      if (response == null || response is! Map) {
        developer.log('Invalid response format for $ticker',
            name: 'YahooStockRepository');
        return null;
      }

      final result = response['quoteSummary']?['result'];
      if (result == null || (result is List && result.isEmpty)) {
        developer.log('No data found for $ticker', name: 'YahooStockRepository');
        return null;
      }

      final data = result is List ? result[0] : result;

      // 데이터 추출
      final price = _extractDouble(
          data['price']?['regularMarketPrice']?['raw'], fallback: 0.0);
      final per = _extractDouble(
          data['summaryDetail']?['trailingPE']?['raw'],
          fallback: 0.0);
      final roe = _extractDouble(
          data['defaultKeyStatistics']?['returnOnEquity']?['raw'],
          fallback: 0.0);
      final dividendYield = _extractDouble(
          data['summaryDetail']?['dividendYield']?['raw'],
          fallback: 0.0);

      final stock = Stock(
        ticker: ticker,
        name: data['price']?['longName'] ?? ticker,
        price: price,
        per: per,
        roe: roe > 0 ? roe * 100 : 0.0, // ROE는 0~100 범위로 정규화
        dividendYield: dividendYield > 0 ? dividendYield * 100 : 0.0,
        lastUpdated: DateTime.now(),
      );

      developer.log('Fetched stock: $ticker, PER: $per, ROE: $roe',
          name: 'YahooStockRepository');
      return stock;
    } on ApiException catch (e) {
      developer.log('API Error for $ticker: ${e.message}',
          name: 'YahooStockRepository', error: e);
      return null;
    } catch (e) {
      developer.log('Unexpected error for $ticker: $e',
          name: 'YahooStockRepository', error: e);
      return null;
    }
  }

  /// 안전한 double 추출 헬퍼
  double _extractDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}
