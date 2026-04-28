import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_keys.dart';

const lastInterstitialStorageKey = 'last_interstitial_ms';

typedef MobileAdsInitializer = Future<void> Function();
typedef InterstitialLoader = Future<InterstitialHandle> Function(
    String adUnitId);

abstract class InterstitialHandle {
  void setCallbacks({
    VoidCallback? onAdShowed,
    VoidCallback? onAdDismissed,
    void Function(Object error)? onAdFailedToShow,
  });

  void show();
  void dispose();
}

class GoogleInterstitialHandle implements InterstitialHandle {
  GoogleInterstitialHandle(this._ad);

  final InterstitialAd _ad;

  @override
  void setCallbacks({
    VoidCallback? onAdShowed,
    VoidCallback? onAdDismissed,
    void Function(Object error)? onAdFailedToShow,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onAdShowed?.call(),
      onAdDismissedFullScreenContent: (_) => onAdDismissed?.call(),
      onAdFailedToShowFullScreenContent: (_, error) =>
          onAdFailedToShow?.call(error),
    );
  }

  @override
  void show() => _ad.show();

  @override
  void dispose() => _ad.dispose();
}

Future<InterstitialHandle> _loadGoogleInterstitial(String adUnitId) {
  final completer = Completer<InterstitialHandle>();

  InterstitialAd.load(
    adUnitId: adUnitId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) => completer.complete(GoogleInterstitialHandle(ad)),
      onAdFailedToLoad: (error) => completer.completeError(error),
    ),
  );

  return completer.future;
}

class AdService {
  AdService._internal({
    InterstitialLoader? interstitialLoader,
    MobileAdsInitializer? mobileAdsInitializer,
    DateTime Function()? now,
    TargetPlatform? platformOverride,
    bool? runtimeAdsEnabledOverride,
  })  : _interstitialLoader = interstitialLoader ?? _loadGoogleInterstitial,
        _mobileAdsInitializer = mobileAdsInitializer ??
            (() async {
              await MobileAds.instance.initialize();
            }),
        _now = now ?? DateTime.now,
        _platformOverride = platformOverride,
        _runtimeAdsEnabledOverride = runtimeAdsEnabledOverride;

  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  @visibleForTesting
  static AdService forTesting({
    InterstitialLoader? interstitialLoader,
    MobileAdsInitializer? mobileAdsInitializer,
    DateTime Function()? now,
    TargetPlatform? platformOverride,
    bool? runtimeAdsEnabledOverride,
  }) {
    return AdService._internal(
      interstitialLoader: interstitialLoader,
      mobileAdsInitializer: mobileAdsInitializer,
      now: now,
      platformOverride: platformOverride,
      runtimeAdsEnabledOverride: runtimeAdsEnabledOverride ?? true,
    );
  }

  final InterstitialLoader _interstitialLoader;
  final MobileAdsInitializer _mobileAdsInitializer;
  final DateTime Function() _now;
  final TargetPlatform? _platformOverride;
  final bool? _runtimeAdsEnabledOverride;

  bool _initialized = false;
  bool _adsEnabled = true;
  Future<void>? _initFuture;

  bool get isSupportedPlatform => _resolvedPlatform != null;
  bool get isAvailable =>
      _adsEnabled && _isRuntimeAdsEnabled && isSupportedPlatform;
  bool get isInitialized => _initialized;

  static const bool _disableDebugAds =
      bool.fromEnvironment('DISABLE_DEBUG_ADS');

  bool get _isRuntimeAdsEnabled {
    if (_runtimeAdsEnabledOverride != null) {
      return _runtimeAdsEnabledOverride!;
    }

    if (kDebugMode) {
      return !_disableDebugAds;
    }

    return true;
  }

  TargetPlatform? get _resolvedPlatform {
    if (kIsWeb) {
      return null;
    }

    final platform = _platformOverride ?? defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      return platform;
    }
    return null;
  }

  String? get bannerAdUnitId {
    if (!isAvailable) {
      return null;
    }
    return ApiKeys.admobBannerId;
  }

  String? get interstitialAdUnitId {
    if (!isAvailable) {
      return null;
    }
    return ApiKeys.admobInterstitialId;
  }

  bool get isUsingTestIds {
    final banner = bannerAdUnitId;
    final interstitial = interstitialAdUnitId;
    return banner == ApiKeys.admobAndroidTestBannerId ||
        banner == ApiKeys.admobIosTestBannerId ||
        interstitial == ApiKeys.admobAndroidTestInterstitialId ||
        interstitial == ApiKeys.admobIosTestInterstitialId;
  }

  Future<void> init() async {
    if (!isAvailable) {
      return;
    }

    if (_initialized) {
      return;
    }

    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _initializeInternal();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _initializeInternal() async {
    try {
      await _mobileAdsInitializer();
      _initialized = true;
      developer.log(
        'Mobile Ads initialized${isUsingTestIds ? ' with test ids' : ''}',
        name: 'AdService',
      );
    } on MissingPluginException catch (error, stackTrace) {
      _adsEnabled = false;
      developer.log(
        'Mobile Ads plugin unavailable in this runtime: $error',
        name: 'AdService',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Mobile Ads initialization failed: $error',
        name: 'AdService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> canShowInterstitial() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(lastInterstitialStorageKey) ?? 0;
    if (last == 0) {
      return true;
    }

    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    return _now().difference(lastDt) > const Duration(hours: 1);
  }

  Future<void> markInterstitialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      lastInterstitialStorageKey,
      _now().millisecondsSinceEpoch,
    );
  }

  Future<void> loadAndShowInterstitial({
    required VoidCallback onContinue,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    if (!isAvailable) {
      onContinue();
      return;
    }

    if (!await canShowInterstitial()) {
      developer.log(
        'Interstitial skipped because frequency cap is active',
        name: 'AdService',
      );
      onContinue();
      return;
    }

    await init();
    if (!isInitialized) {
      onContinue();
      return;
    }

    final adUnitId = interstitialAdUnitId;
    if (adUnitId == null || adUnitId.isEmpty) {
      onContinue();
      return;
    }

    final completion = Completer<void>();
    void continueOnce() {
      if (completion.isCompleted) {
        return;
      }
      onContinue();
      completion.complete();
    }

    final timeoutTimer = Timer(timeout, () {
      developer.log(
        'Interstitial load timed out after ${timeout.inMilliseconds}ms',
        name: 'AdService',
      );
      continueOnce();
    });

    unawaited(() async {
      InterstitialHandle? interstitial;
      try {
        interstitial = await _interstitialLoader(adUnitId);
        if (completion.isCompleted) {
          interstitial.dispose();
          return;
        }

        interstitial.setCallbacks(
          onAdShowed: () {
            unawaited(markInterstitialShown());
          },
          onAdDismissed: () {
            interstitial?.dispose();
            continueOnce();
          },
          onAdFailedToShow: (error) {
            developer.log(
              'Interstitial failed to show: $error',
              name: 'AdService',
            );
            interstitial?.dispose();
            continueOnce();
          },
        );

        timeoutTimer.cancel();
        interstitial.show();
      } catch (error, stackTrace) {
        timeoutTimer.cancel();
        developer.log(
          'Interstitial load failed: $error',
          name: 'AdService',
          error: error,
          stackTrace: stackTrace,
        );
        continueOnce();
      }
    }());

    await completion.future;
    timeoutTimer.cancel();
  }
}
