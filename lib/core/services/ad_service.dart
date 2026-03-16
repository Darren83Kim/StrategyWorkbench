// TODO: google_mobile_ads 광고 연동 시 아래 주석 해제 후 pubspec.yaml에 의존성 추가
// AdMob App ID를 AndroidManifest.xml에 등록 필요:
//   <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"
//              android:value="ca-app-pub-XXXXXXXXXX~XXXXXXXXXX"/>

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  Future<void> init() async {
    // TODO: await MobileAds.instance.initialize();
  }

  Future<bool> canShowInterstitial() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_interstitial_ms') ?? 0;
    if (last == 0) return true;
    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    return DateTime.now().difference(lastDt) > const Duration(hours: 1);
  }

  /// 광고 미연동 상태: [onContinue] 즉시 호출
  Future<void> loadAndShowInterstitial({
    required VoidCallback onContinue,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    if (!await canShowInterstitial()) {
      onContinue();
      return;
    }
    // TODO: 실제 광고 로드/표시 로직 (google_mobile_ads 연동 후 구현)
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(
        'last_interstitial_ms', DateTime.now().millisecondsSinceEpoch);
    onContinue();
  }
}
