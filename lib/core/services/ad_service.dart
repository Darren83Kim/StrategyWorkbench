import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitial;

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  Future<bool> canShowInterstitial() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_interstitial_ms') ?? 0;
    if (last == 0) return true;
    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    return DateTime.now().difference(lastDt) > const Duration(hours: 1);
  }

  Future<void> loadAndShowInterstitial({required VoidCallback onContinue, Duration timeout = const Duration(milliseconds: 500)}) async {
    // Fail-safe: don't block user indefinitely. If ad not loaded within [timeout], continue.
    final completer = Completer<void>();
    bool completed = false;

    if (!await canShowInterstitial()) {
      onContinue();
      return;
    }

    void finishAndContinue() async {
      if (completed) return;
      completed = true;
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('last_interstitial_ms', DateTime.now().millisecondsSinceEpoch);
      onContinue();
      completer.complete();
    }

    final timer = Timer(timeout, () {
      finishAndContinue();
    });

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Interstitial test ad unit (Android/iOS)
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => finishAndContinue(),
            onAdFailedToShowFullScreenContent: (ad, err) => finishAndContinue(),
          );
          timer.cancel();
          _interstitial?.show();
        },
        onAdFailedToLoad: (err) {
          timer.cancel();
          finishAndContinue();
        },
      ),
    );

    return completer.future;
  }
}
