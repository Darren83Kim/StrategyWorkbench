import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/services/ad_service.dart';

class _FakeInterstitialHandle implements InterstitialHandle {
  VoidCallback? _onAdShowed;
  VoidCallback? _onAdDismissed;
  void Function(Object error)? _onAdFailedToShow;

  bool showCalled = false;
  bool disposeCalled = false;

  @override
  void setCallbacks({
    VoidCallback? onAdShowed,
    VoidCallback? onAdDismissed,
    void Function(Object error)? onAdFailedToShow,
  }) {
    _onAdShowed = onAdShowed;
    _onAdDismissed = onAdDismissed;
    _onAdFailedToShow = onAdFailedToShow;
  }

  @override
  void show() {
    showCalled = true;
  }

  @override
  void dispose() {
    disposeCalled = true;
  }

  void triggerShown() => _onAdShowed?.call();
  void triggerDismissed() => _onAdDismissed?.call();
  void triggerFailedToShow(Object error) => _onAdFailedToShow?.call(error);
}

void main() {
  group('AdService', () {
    test('canShowInterstitial respects one-hour frequency cap', () async {
      final fixedNow = DateTime(2026, 4, 20, 12, 0);
      SharedPreferences.setMockInitialValues({
        lastInterstitialStorageKey: fixedNow
            .subtract(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
      });

      final service = AdService.forTesting(
        mobileAdsInitializer: () async {},
        platformOverride: TargetPlatform.android,
        now: () => fixedNow,
      );

      expect(await service.canShowInterstitial(), isFalse);
    });

    test('loadAndShowInterstitial falls through on timeout', () async {
      SharedPreferences.setMockInitialValues({});

      final neverCompletes = Completer<InterstitialHandle>();
      final service = AdService.forTesting(
        mobileAdsInitializer: () async {},
        interstitialLoader: (_) => neverCompletes.future,
        platformOverride: TargetPlatform.android,
      );

      var continued = 0;
      await service.loadAndShowInterstitial(
        timeout: const Duration(milliseconds: 20),
        onContinue: () {
          continued++;
        },
      );

      expect(continued, 1);
    });

    test('loadAndShowInterstitial waits for dismiss and records show time',
        () async {
      SharedPreferences.setMockInitialValues({});
      final fixedNow = DateTime(2026, 4, 20, 12, 30);
      final handle = _FakeInterstitialHandle();

      final service = AdService.forTesting(
        mobileAdsInitializer: () async {},
        interstitialLoader: (_) async => handle,
        platformOverride: TargetPlatform.android,
        now: () => fixedNow,
      );

      var continued = 0;
      final future = service.loadAndShowInterstitial(
        timeout: const Duration(milliseconds: 100),
        onContinue: () {
          continued++;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(handle.showCalled, isTrue);
      expect(continued, 0);

      handle.triggerShown();
      handle.triggerDismissed();
      await future;

      final prefs = await SharedPreferences.getInstance();
      expect(continued, 1);
      expect(
        prefs.getInt(lastInterstitialStorageKey),
        fixedNow.millisecondsSinceEpoch,
      );
      expect(handle.disposeCalled, isTrue);
    });

    test('loadAndShowInterstitial falls through when runtime ads are disabled',
        () async {
      SharedPreferences.setMockInitialValues({});

      final service = AdService.forTesting(
        mobileAdsInitializer: () async {},
        interstitialLoader: (_) async => _FakeInterstitialHandle(),
        platformOverride: TargetPlatform.android,
        runtimeAdsEnabledOverride: false,
      );

      var continued = 0;
      await service.loadAndShowInterstitial(
        onContinue: () {
          continued++;
        },
      );

      expect(continued, 1);
      expect(service.isAvailable, isFalse);
    });
  });
}
