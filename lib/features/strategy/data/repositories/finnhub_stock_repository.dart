import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'dart:developer' as developer;

/// Finnhub API를 사용하는 미국 주식 데이터 저장소 (US 1순위)
///
/// 무료 한도: 60 calls/minute
/// 제공 데이터: 실시간 시세, 펀더멘탈(PER, ROE, 배당), 기업 프로필
class FinnhubStockRepository {
  final DioClient _dioClient;

  FinnhubStockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// 여러 티커의 주식 정보를 조회
  Future<List<Stock>> getStocks({
    List<String> tickers = const [
      'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'NVDA',
      'TSLA', 'META', 'JPM', 'V', 'JNJ',
    ],
  }) async {
    if (!ApiKeys.isFinnhubConfigured) {
      developer.log('Finnhub API key not configured',
          name: 'FinnhubStockRepository');
      return [];
    }

    try {
      final stocks = <Stock>[];

      for (final ticker in tickers) {
        try {
          final stock = await _fetchStock(ticker);
          if (stock != null) {
            stocks.add(stock);
          }
        } catch (e) {
          developer.log('Failed to fetch $ticker: $e',
              name: 'FinnhubStockRepository');
          // 개별 종목 실패 시 계속 진행
        }
      }

      developer.log('Successfully fetched ${stocks.length}/${tickers.length} stocks from Finnhub',
          name: 'FinnhubStockRepository');
      return stocks;
    } catch (e) {
      developer.log('Error in getStocks: $e',
          name: 'FinnhubStockRepository', error: e);
      rethrow;
    }
  }

  /// 단일 티커 주식 정보 조회
  Future<Stock?> getStockByTicker(String ticker) async {
    try {
      return await _fetchStock(ticker);
    } catch (e) {
      developer.log('Error fetching stock $ticker: $e',
          name: 'FinnhubStockRepository', error: e);
      return null;
    }
  }

  /// Finnhub API에서 주식 정보 가져오기 (Quote + Metric + Profile)
  Future<Stock?> _fetchStock(String ticker) async {
    try {
      developer.log('Fetching stock: $ticker', name: 'FinnhubStockRepository');

      final token = ApiKeys.finnhubApiKey;

      // 1. Quote API - 실시간 시세
      final quoteUrl = '${ApiKeys.finnhubBaseUrl}/quote?symbol=$ticker&token=$token';
      final quoteResponse = await _dioClient.get(quoteUrl);

      if (quoteResponse == null || quoteResponse is! Map) {
        developer.log('Invalid quote response for $ticker',
            name: 'FinnhubStockRepository');
        return null;
      }

      final price = _extractDouble(quoteResponse['c'], fallback: 0.0);
      if (price <= 0) {
        developer.log('No price data for $ticker', name: 'FinnhubStockRepository');
        return null;
      }

      // 2. Metric API - 펀더멘탈 (PER, ROE, 배당수익률)
      double per = 0.0;
      double roe = 0.0;
      double dividendYield = 0.0;

      try {
        final metricUrl =
            '${ApiKeys.finnhubBaseUrl}/stock/metric?symbol=$ticker&metric=all&token=$token';
        final metricResponse = await _dioClient.get(metricUrl);

        if (metricResponse != null && metricResponse is Map) {
          final metric = metricResponse['metric'];
          if (metric != null && metric is Map) {
            per = _extractDouble(metric['peBasicExclExtraTTM'], fallback: 0.0);
            roe = _extractDouble(metric['roeTTM'], fallback: 0.0);
            dividendYield = _extractDouble(
                metric['dividendYieldIndicatedAnnual'], fallback: 0.0);
          }
        }
      } catch (e) {
        developer.log('Metric fetch failed for $ticker: $e',
            name: 'FinnhubStockRepository');
        // 펀더멘탈 실패해도 시세 데이터로 Stock 생성
      }

      // 3. Profile API - 기업명 (선택적)
      String name = ticker;
      try {
        final profileUrl =
            '${ApiKeys.finnhubBaseUrl}/stock/profile2?symbol=$ticker&token=$token';
        final profileResponse = await _dioClient.get(profileUrl);

        if (profileResponse != null && profileResponse is Map) {
          name = (profileResponse['name'] as String?) ?? ticker;
        }
      } catch (e) {
        developer.log('Profile fetch failed for $ticker: $e',
            name: 'FinnhubStockRepository');
        // 프로필 실패해도 ticker를 이름으로 사용
      }

      final stock = Stock(
        ticker: ticker,
        name: name,
        price: price,
        per: per,
        roe: roe, // Finnhub은 이미 % 단위로 반환 (예: 160.58 = 160.58%)
        dividendYield: dividendYield,
        lastUpdated: DateTime.now(),
      );

      developer.log(
          'Fetched: $ticker | Price: \$$price | PER: $per | ROE: $roe% | Div: $dividendYield%',
          name: 'FinnhubStockRepository');
      return stock;
    } on ApiException catch (e) {
      developer.log('API Error for $ticker: ${e.message}',
          name: 'FinnhubStockRepository', error: e);
      return null;
    } catch (e) {
      developer.log('Unexpected error for $ticker: $e',
          name: 'FinnhubStockRepository', error: e);
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
