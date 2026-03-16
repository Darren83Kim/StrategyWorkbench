import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'dart:developer' as developer;

/// KRX Open API + DART OpenAPI를 사용하는 한국 주식 데이터 저장소 (KR 1순위)
///
/// KRX: 시세 데이터 (10,000회/일)
/// DART: 재무제표/펀더멘탈 (10,000회/일)
class KrxDartStockRepository {
  final DioClient _dioClient;

  /// 주요 한국 종목 (종목코드 → 종목명)
  static const Map<String, String> defaultTickers = {
    '005930': '삼성전자',
    '000660': 'SK하이닉스',
    '373220': 'LG에너지솔루션',
    '207940': '삼성바이오로직스',
    '005380': '현대자동차',
    '006400': '삼성SDI',
    '051910': 'LG화학',
    '035420': 'NAVER',
    '000270': '기아',
    '035720': '카카오',
  };

  KrxDartStockRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// 여러 종목의 주식 정보를 조회
  Future<List<Stock>> getStocks({
    Map<String, String>? tickers,
  }) async {
    final targetTickers = tickers ?? defaultTickers;

    if (!ApiKeys.isKrxConfigured) {
      developer.log('KRX API key not configured',
          name: 'KrxDartStockRepository');
      return [];
    }

    try {
      final stocks = <Stock>[];

      for (final entry in targetTickers.entries) {
        try {
          final stock = await _fetchStock(entry.key, entry.value);
          if (stock != null) {
            stocks.add(stock);
          }
        } catch (e) {
          developer.log('Failed to fetch ${entry.key}: $e',
              name: 'KrxDartStockRepository');
        }
      }

      developer.log(
          'Successfully fetched ${stocks.length}/${targetTickers.length} stocks from KRX/DART',
          name: 'KrxDartStockRepository');
      return stocks;
    } catch (e) {
      developer.log('Error in getStocks: $e',
          name: 'KrxDartStockRepository', error: e);
      rethrow;
    }
  }

  /// 단일 종목 조회 (종목코드)
  Future<Stock?> getStockByCode(String stockCode) async {
    try {
      final name = defaultTickers[stockCode] ?? stockCode;
      return await _fetchStock(stockCode, name);
    } catch (e) {
      developer.log('Error fetching stock $stockCode: $e',
          name: 'KrxDartStockRepository', error: e);
      return null;
    }
  }

  /// KRX API에서 시세 데이터, DART에서 펀더멘탈 데이터를 통합 조회
  Future<Stock?> _fetchStock(String stockCode, String stockName) async {
    try {
      developer.log('Fetching stock: $stockCode ($stockName)',
          name: 'KrxDartStockRepository');

      // 1. KRX Open API - 시세 데이터
      double price = 0.0;
      try {
        price = await _fetchPriceFromKrx(stockCode);
      } catch (e) {
        developer.log('KRX price fetch failed for $stockCode: $e',
            name: 'KrxDartStockRepository');
        return null; // 시세가 없으면 Stock 생성 불가
      }

      if (price <= 0) {
        developer.log('No price data from KRX for $stockCode',
            name: 'KrxDartStockRepository');
        return null;
      }

      // 2. DART OpenAPI - 펀더멘탈 (PER, ROE 추정)
      double per = 0.0;
      double roe = 0.0;
      double dividendYield = 0.0;

      if (ApiKeys.isDartConfigured) {
        try {
          final fundamentals = await _fetchFundamentalsFromDart(stockCode);
          per = fundamentals['per'] ?? 0.0;
          roe = fundamentals['roe'] ?? 0.0;
          dividendYield = fundamentals['dividendYield'] ?? 0.0;
        } catch (e) {
          developer.log('DART fundamentals fetch failed for $stockCode: $e',
              name: 'KrxDartStockRepository');
          // 펀더멘탈 실패해도 시세 기반 Stock 생성
        }
      }

      final stock = Stock(
        ticker: stockCode,
        name: stockName,
        price: price,
        per: per,
        roe: roe,
        dividendYield: dividendYield,
        lastUpdated: DateTime.now(),
      );

      developer.log(
          'Fetched: $stockCode ($stockName) | Price: ₩$price | PER: $per | ROE: $roe%',
          name: 'KrxDartStockRepository');
      return stock;
    } catch (e) {
      developer.log('Unexpected error for $stockCode: $e',
          name: 'KrxDartStockRepository', error: e);
      return null;
    }
  }

  /// KRX Open API에서 현재가 조회
  Future<double> _fetchPriceFromKrx(String stockCode) async {
    // 오늘 날짜 기준으로 최근 시세 조회
    final now = DateTime.now();
    final beginDate = now.subtract(const Duration(days: 7));
    final beginDateStr =
        '${beginDate.year}${beginDate.month.toString().padLeft(2, '0')}${beginDate.day.toString().padLeft(2, '0')}';

    final url = '${ApiKeys.krxBaseUrl}/getStockPriceInfo'
        '?serviceKey=${Uri.encodeComponent(ApiKeys.krxApiKey)}'
        '&numOfRows=1'
        '&pageNo=1'
        '&resultType=json'
        '&likeSrtnCd=$stockCode'
        '&beginBasDt=$beginDateStr';

    final response = await _dioClient.get(url);

    if (response == null || response is! Map) {
      throw Exception('Invalid KRX response for $stockCode');
    }

    final items = response['response']?['body']?['items']?['item'];
    if (items == null || (items is List && items.isEmpty)) {
      throw Exception('No KRX data for $stockCode');
    }

    final item = items is List ? items[0] : items;
    final priceStr = item['clpr']; // 종가
    return _extractDouble(priceStr, fallback: 0.0);
  }

  /// DART OpenAPI에서 펀더멘탈 데이터 조회 (재무제표 기반)
  Future<Map<String, double>> _fetchFundamentalsFromDart(
      String stockCode) async {
    final result = <String, double>{
      'per': 0.0,
      'roe': 0.0,
      'dividendYield': 0.0,
    };

    try {
      // DART에서는 corp_code(기업 고유번호)가 필요하지만,
      // 종목코드 → corp_code 매핑이 필요합니다.
      // 현재는 간소화를 위해 주요 종목의 정적 매핑을 사용합니다.
      final corpCode = _stockCodeToCorpCode[stockCode];
      if (corpCode == null) {
        developer.log('No corp_code mapping for $stockCode',
            name: 'KrxDartStockRepository');
        return result;
      }

      final currentYear = DateTime.now().year - 1; // 최근 결산 연도

      final url = '${ApiKeys.dartBaseUrl}/fnlttSinglAcntAll.json'
          '?crtfc_key=${ApiKeys.dartApiKey}'
          '&corp_code=$corpCode'
          '&bsns_year=$currentYear'
          '&reprt_code=11011' // 사업보고서
          '&fs_div=CFS'; // 연결재무제표

      final response = await _dioClient.get(url);

      if (response == null || response is! Map) return result;
      if (response['status'] != '000') {
        developer.log('DART API error: ${response['message']}',
            name: 'KrxDartStockRepository');
        return result;
      }

      final list = response['list'];
      if (list == null || list is! List) return result;

      // 재무제표에서 당기순이익과 자본총계를 추출하여 ROE 계산
      double netIncome = 0.0;
      double totalEquity = 0.0;

      for (final item in list) {
        final accountName = item['account_nm'] as String? ?? '';
        final amountStr = (item['thstrm_amount'] as String? ?? '0')
            .replaceAll(',', '');

        if (accountName.contains('당기순이익')) {
          netIncome = double.tryParse(amountStr) ?? 0.0;
        }
        if (accountName.contains('자본총계')) {
          totalEquity = double.tryParse(amountStr) ?? 0.0;
        }
      }

      // ROE = 당기순이익 / 자본총계 * 100
      if (totalEquity > 0 && netIncome != 0) {
        result['roe'] = (netIncome / totalEquity) * 100;
      }

      developer.log(
          'DART fundamentals for $stockCode: netIncome=$netIncome, equity=$totalEquity, ROE=${result['roe']}',
          name: 'KrxDartStockRepository');
    } catch (e) {
      developer.log('DART fetch error for $stockCode: $e',
          name: 'KrxDartStockRepository');
    }

    return result;
  }

  /// 종목코드 → DART 기업고유번호 매핑 (주요 종목)
  /// 전체 매핑은 DART의 corpCode.xml을 앱 초기화 시 다운로드하여 로컬 캐시
  static const Map<String, String> _stockCodeToCorpCode = {
    '005930': '00126380', // 삼성전자
    '000660': '00164779', // SK하이닉스
    '373220': '01634886', // LG에너지솔루션
    '207940': '00927579', // 삼성바이오로직스
    '005380': '00164742', // 현대자동차
    '006400': '00164529', // 삼성SDI
    '051910': '00356361', // LG화학
    '035420': '00258801', // NAVER
    '000270': '00164655', // 기아
    '035720': '00301766', // 카카오
  };

  /// 안전한 double 추출 헬퍼
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
