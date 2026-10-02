import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';

void main() {
  group('ApiKeys KIS runtime policy', () {
    test('keeps Korea Investment disabled for release/profile builds', () {
      final enabled = ApiKeys.shouldEnableKorInvestmentRuntime(
        isConfigured: true,
        isDebugBuild: false,
        debugOptIn: true,
      );

      expect(enabled, isFalse);
    });

    test('requires an explicit debug opt-in even when keys are configured', () {
      final enabled = ApiKeys.shouldEnableKorInvestmentRuntime(
        isConfigured: true,
        isDebugBuild: true,
        debugOptIn: false,
      );

      expect(enabled, isFalse);
    });

    test('allows Korea Investment only for configured debug opt-in builds', () {
      final enabled = ApiKeys.shouldEnableKorInvestmentRuntime(
        isConfigured: true,
        isDebugBuild: true,
        debugOptIn: true,
      );

      expect(enabled, isTrue);
    });
  });

  group('ApiKeys AdMob runtime policy', () {
    test('uses Google sample ids only when test ids are enabled', () {
      final resolved = ApiKeys.resolveAdmobId(
        useTestIds: true,
        testId: ApiKeys.admobAndroidTestBannerId,
        productionId: 'ca-app-pub-1234567890123456/1234567890',
      );

      expect(resolved, ApiKeys.admobAndroidTestBannerId);
    });

    test('keeps a missing production id empty', () {
      final resolved = ApiKeys.resolveAdmobId(
        useTestIds: false,
        testId: ApiKeys.admobAndroidTestBannerId,
        productionId: '',
      );

      expect(resolved, isEmpty);
    });

    test('uses the configured production id in a release runtime', () {
      const productionId = 'ca-app-pub-1234567890123456/1234567890';
      final resolved = ApiKeys.resolveAdmobId(
        useTestIds: false,
        testId: ApiKeys.admobAndroidTestBannerId,
        productionId: productionId,
      );

      expect(resolved, productionId);
    });
  });
}
