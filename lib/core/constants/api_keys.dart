import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiKeys {
  static String _env(String key, {String fallback = ''}) {
    try {
      return dotenv.env[key] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // ── Finnhub API (US 1순위) ──
  static String get finnhubApiKey => _env('FINNHUB_API_KEY');
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';

  // ── FMP API (US 2순위) ──
  static String get fmpApiKey => _env('FMP_API_KEY');
  static const String fmpBaseUrl = 'https://financialmodelingprep.com/api/v3';

  // ── KRX Open API (KR 1순위) ──
  static String get krxApiKey => _env('KRX_API_KEY');
  static const String krxBaseUrl =
      'https://apis.data.go.kr/1160100/service/GetStockSecuritiesInfoService';

  // ── DART OpenAPI (KR 2순위) ──
  static String get dartApiKey => _env('DART_API_KEY');
  static const String dartBaseUrl = 'https://opendart.fss.or.kr/api';

  // ── Yahoo Finance (US 폴백 - 비공식) ──
  static const String yahooBaseUrl = 'https://query1.finance.yahoo.com';

  // ── Alpha Vantage (폐기 - 하루 25회 한도) ──
  static String get alphaVantageApiKey =>
      _env('ALPHA_VANTAGE_API_KEY', fallback: 'demo');
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co';

  // API 상태 확인
  static bool get isFinnhubConfigured => finnhubApiKey.isNotEmpty;
  static bool get isFmpConfigured => fmpApiKey.isNotEmpty;
  static bool get isKrxConfigured => krxApiKey.isNotEmpty;
  static bool get isDartConfigured => dartApiKey.isNotEmpty;
  static bool get isKorInvestmentRuntimeEnabled =>
      isKorInvestmentConfigured && !kDebugMode;

  /// 실제 API 키가 하나라도 설정되어 있으면 true → Mock 폴백 비활성화
  static bool get isAnyRealApiConfigured =>
      isFinnhubConfigured ||
      isFmpConfigured ||
      isKrxConfigured ||
      isDartConfigured ||
      isKorInvestmentRuntimeEnabled;

  // 한국투자증권 API
  static String get korInvestmentAppKey => _env('KOR_INVESTMENT_APP_KEY');
  static String get korInvestmentSecret => _env('KOR_INVESTMENT_SECRET');
  static String get korInvestmentAccount => _env('KOR_INVESTMENT_ACCOUNT');
  static const String korInvestmentBaseUrl =
      'https://openapi.koreainvestment.com:9443';
  static const String korInvestmentAuthUrl =
      'https://openapi.koreainvestment.com:9443/oauth2/tokenP';

  // Google AdMob
  static const String admobAndroidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String admobIosTestAppId =
      'ca-app-pub-3940256099942544~1458002511';

  static const String admobAndroidTestBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String admobIosTestBannerId =
      'ca-app-pub-3940256099942544/2435281174';

  static const String admobAndroidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String admobIosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static String get admobAndroidAppId =>
      _env('ADMOB_ANDROID_APP_ID', fallback: admobAndroidTestAppId);
  static String get admobIosAppId =>
      _env('ADMOB_IOS_APP_ID', fallback: admobIosTestAppId);

  static String get admobAndroidBannerId =>
      _env('ADMOB_ANDROID_BANNER_ID', fallback: admobAndroidTestBannerId);
  static String get admobIosBannerId =>
      _env('ADMOB_IOS_BANNER_ID', fallback: admobIosTestBannerId);

  static String get admobAndroidInterstitialId => _env(
        'ADMOB_ANDROID_INTERSTITIAL_ID',
        fallback: admobAndroidTestInterstitialId,
      );
  static String get admobIosInterstitialId => _env(
        'ADMOB_IOS_INTERSTITIAL_ID',
        fallback: admobIosTestInterstitialId,
      );

  static String get admobBannerId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return admobAndroidBannerId;
      case TargetPlatform.iOS:
        return admobIosBannerId;
      default:
        return '';
    }
  }

  static String get admobInterstitialId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return admobAndroidInterstitialId;
      case TargetPlatform.iOS:
        return admobIosInterstitialId;
      default:
        return '';
    }
  }

  // API 상태 확인
  static bool get isKorInvestmentConfigured =>
      korInvestmentAppKey.isNotEmpty && korInvestmentSecret.isNotEmpty;
}
