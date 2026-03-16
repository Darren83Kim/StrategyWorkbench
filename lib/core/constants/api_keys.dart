import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  // ── Finnhub API (US 1순위) ──
  static String get finnhubApiKey =>
      dotenv.env['FINNHUB_API_KEY'] ?? '';
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';

  // ── FMP API (US 2순위) ──
  static String get fmpApiKey =>
      dotenv.env['FMP_API_KEY'] ?? '';
  static const String fmpBaseUrl = 'https://financialmodelingprep.com/api/v3';

  // ── KRX Open API (KR 1순위) ──
  static String get krxApiKey =>
      dotenv.env['KRX_API_KEY'] ?? '';
  static const String krxBaseUrl =
      'https://apis.data.go.kr/1160100/service/GetStockSecuritiesInfoService';

  // ── DART OpenAPI (KR 2순위) ──
  static String get dartApiKey =>
      dotenv.env['DART_API_KEY'] ?? '';
  static const String dartBaseUrl = 'https://opendart.fss.or.kr/api';

  // ── Yahoo Finance (US 폴백 - 비공식) ──
  static const String yahooBaseUrl = 'https://query1.finance.yahoo.com';

  // ── Alpha Vantage (폐기 - 하루 25회 한도) ──
  static String get alphaVantageApiKey =>
      dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? 'demo';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co';

  // API 상태 확인
  static bool get isFinnhubConfigured => finnhubApiKey.isNotEmpty;
  static bool get isFmpConfigured => fmpApiKey.isNotEmpty;
  static bool get isKrxConfigured => krxApiKey.isNotEmpty;
  static bool get isDartConfigured => dartApiKey.isNotEmpty;

  // 한국투자증권 API
  static String get korInvestmentAppKey =>
      dotenv.env['KOR_INVESTMENT_APP_KEY'] ?? '';
  static String get korInvestmentSecret =>
      dotenv.env['KOR_INVESTMENT_SECRET'] ?? '';
  static String get korInvestmentAccount =>
      dotenv.env['KOR_INVESTMENT_ACCOUNT'] ?? '';
  static const String korInvestmentBaseUrl =
      'https://openapi.koreainvestment.com:9443';
  static const String korInvestmentAuthUrl =
      'https://openapi.koreainvestment.com:9443/oauth2/tokenP';

  // Google AdMob
  static String get admobBannerId =>
      dotenv.env['ADMOB_BANNER_ID'] ??
      'ca-app-pub-3940256099942544/6300978111'; // 테스트 ID
  static String get admobInterstitialId =>
      dotenv.env['ADMOB_INTERSTITIAL_ID'] ??
      'ca-app-pub-3940256099942544/1033173712'; // 테스트 ID

  // API 상태 확인
  static bool get isKorInvestmentConfigured =>
      korInvestmentAppKey.isNotEmpty && korInvestmentSecret.isNotEmpty;
}
