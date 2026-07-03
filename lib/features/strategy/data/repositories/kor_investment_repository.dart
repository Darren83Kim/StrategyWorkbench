import 'package:strategy_workbench/core/network/dio_client.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/stock_universe.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 한국투자증권 API를 사용하는 스톡 저장소
class KorInvestmentRepository {
  static const _tokenStorageKey = 'kor_investment_access_token';
  static const _tokenExpiryStorageKey = 'kor_investment_access_token_expiry';

  final DioClient _dioClient;
  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _persistedTokenLoaded = false;
  Future<void>? _authInFlight;

  KorInvestmentRepository({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient();

  /// 여러 종목의 주식 정보를 조회
  Future<List<Stock>> getStocks({
    List<String>? codes,
  }) async {
    final targetCodes = codes ?? koreanUniverseCodes;

    try {
      if (!ApiKeys.isKorInvestmentRuntimeEnabled) {
        developer.log(
          'Korea Investment runtime disabled in debug. Skipping token issue.',
          name: 'KorInvestmentRepository',
        );
        return [];
      }

      // 토큰 확인 및 갱신
      await _ensureAuthenticated();

      final stocks = <Stock>[];

      // 각 종목 정보 조회
      for (final code in targetCodes) {
        try {
          final stock = await _fetchStock(code);
          if (stock != null) {
            stocks.add(stock);
          }
        } catch (e) {
          developer.log('Failed to fetch stock $code: $e',
              name: 'KorInvestmentRepository', error: e);
          // 개별 종목 실패는 계속 진행
        }
      }

      developer.log('Successfully fetched ${stocks.length} Korean stocks',
          name: 'KorInvestmentRepository');
      return stocks;
    } catch (e) {
      developer.log('Error in getStocks: $e',
          name: 'KorInvestmentRepository', error: e);
      rethrow;
    }
  }

  /// 단일 종목 조회
  Future<Stock?> getStockByCode(String code) async {
    try {
      if (!ApiKeys.isKorInvestmentRuntimeEnabled) {
        developer.log(
          'Korea Investment runtime disabled in debug. Skipping token issue.',
          name: 'KorInvestmentRepository',
        );
        return null;
      }

      await _ensureAuthenticated();
      return await _fetchStock(code);
    } catch (e) {
      developer.log('Error fetching stock $code: $e',
          name: 'KorInvestmentRepository', error: e);
      return null;
    }
  }

  Future<void> _ensureAuthenticated() async {
    await _restorePersistedTokenIfNeeded();
    if (_accessToken != null && !_isTokenExpired()) {
      return;
    }

    final existingAuth = _authInFlight;
    if (existingAuth != null) {
      await existingAuth;
      return;
    }

    final authFuture = _authenticate();
    _authInFlight = authFuture;
    try {
      await authFuture;
    } finally {
      if (identical(_authInFlight, authFuture)) {
        _authInFlight = null;
      }
    }
  }

  /// OAuth 인증 (액세스 토큰 획득)
  Future<void> _authenticate() async {
    try {
      developer.log('Authenticating with Korea Investment API',
          name: 'KorInvestmentRepository');

      if (!ApiKeys.isKorInvestmentRuntimeEnabled) {
        throw ApiException(
          'Korea Investment authentication is disabled in debug runtime',
        );
      }

      if (!ApiKeys.isKorInvestmentConfigured) {
        throw ApiException('Korea Investment API keys not configured');
      }

      await _restorePersistedTokenIfNeeded();
      if (_accessToken != null && !_isTokenExpired()) {
        developer.log(
          'Using persisted Korea Investment token',
          name: 'KorInvestmentRepository',
        );
        return;
      }

      final body = {
        'grant_type': 'client_credentials',
        'appkey': ApiKeys.korInvestmentAppKey,
        'appsecret': ApiKeys.korInvestmentSecret,
      };

      final response = await _dioClient.post(
        ApiKeys.korInvestmentAuthUrl,
        data: jsonEncode(body),
      );

      if (response == null) {
        throw ApiException('Empty authentication response');
      }

      _accessToken = response['access_token'];
      final expiresIn = response['expires_in'] ?? 3600;

      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      await _persistToken();

      developer.log(
          'Successfully authenticated. Token expires in $expiresIn seconds',
          name: 'KorInvestmentRepository');
    } catch (e) {
      developer.log('Authentication failed: $e',
          name: 'KorInvestmentRepository', error: e);
      rethrow;
    }
  }

  /// 단일 종목 정보 조회
  Future<Stock?> _fetchStock(String code) async {
    try {
      developer.log('Fetching stock: $code', name: 'KorInvestmentRepository');

      // 현재가 조회 API
      const url =
          '${ApiKeys.korInvestmentBaseUrl}/uapi/domestic-stock/v1/quotations/inquire-price';

      final headers = _getHeaders();

      final queryParams = {
        'FID_COND_MRKT_DIV_CODE': 'J',
        'FID_INPUT_ISCD': code,
      };

      final response = await _dioClient.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      if (response == null || response is! Map) {
        developer.log('Invalid response format for $code',
            name: 'KorInvestmentRepository');
        return null;
      }

      // 응답 검증
      final rtCd = response['rt_cd'];
      if (rtCd != '0') {
        final msg = response['msg1'] ?? 'Unknown error';
        throw ApiException('API returned error: $msg (code: $rtCd)');
      }

      final output = response['output'];
      if (output == null) {
        developer.log('No output data for $code',
            name: 'KorInvestmentRepository');
        return null;
      }

      // 데이터 추출
      final price = _parseDouble(output['stck_prpr']);
      final per = _parseDouble(output['per']);
      final pbr = _parseDouble(output['pbr']);
      final dividendYield = _parseDouble(output['dvd_yld']);

      // ROE 추정 (PBR을 사용하여 대략 계산)
      final estimatedRoe = pbr > 0 ? (per * pbr) : 0.0;

      final stock = Stock(
        ticker: code,
        name: output['hts_kor_isnm'] ?? code,
        price: price,
        per: per,
        roe: estimatedRoe,
        dividendYield: dividendYield,
        lastUpdated: DateTime.now(),
      );

      developer.log('Fetched Korean stock: $code, Price: $price, PER: $per',
          name: 'KorInvestmentRepository');
      return stock;
    } on ApiException {
      rethrow;
    } catch (e) {
      developer.log('Error fetching stock $code: $e',
          name: 'KorInvestmentRepository', error: e);
      return null;
    }
  }

  /// 요청 헤더 생성 (HMAC-SHA256 서명 포함)
  Map<String, dynamic> _getHeaders() {
    if (_accessToken == null) {
      throw ApiException(
          'Access token not available. Please authenticate first.');
    }

    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json; charset=utf-8',
      'appKey': ApiKeys.korInvestmentAppKey,
      'appSecret': ApiKeys.korInvestmentSecret,
      'tr_id': 'FHKST01010100',
    };
  }

  /// 토큰 만료 확인
  bool _isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  Future<void> _restorePersistedTokenIfNeeded() async {
    if (_persistedTokenLoaded) {
      return;
    }

    _persistedTokenLoaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenStorageKey);
      final expiryRaw = prefs.getString(_tokenExpiryStorageKey);

      if (token == null || expiryRaw == null) {
        return;
      }

      final expiry = DateTime.tryParse(expiryRaw);
      if (expiry == null || DateTime.now().isAfter(expiry)) {
        await _clearPersistedToken(prefs);
        return;
      }

      _accessToken = token;
      _tokenExpiry = expiry;
      developer.log(
        'Restored persisted Korea Investment token',
        name: 'KorInvestmentRepository',
      );
    } catch (e) {
      developer.log(
        'Failed to restore persisted Korea Investment token: $e',
        name: 'KorInvestmentRepository',
        error: e,
      );
    }
  }

  Future<void> _persistToken() async {
    if (_accessToken == null || _tokenExpiry == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenStorageKey, _accessToken!);
      await prefs.setString(
        _tokenExpiryStorageKey,
        _tokenExpiry!.toIso8601String(),
      );
    } catch (e) {
      developer.log(
        'Failed to persist Korea Investment token: $e',
        name: 'KorInvestmentRepository',
        error: e,
      );
    }
  }

  Future<void> _clearPersistedToken(SharedPreferences prefs) async {
    _accessToken = null;
    _tokenExpiry = null;
    await prefs.remove(_tokenStorageKey);
    await prefs.remove(_tokenExpiryStorageKey);
  }

  /// 안전한 double 파싱
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
