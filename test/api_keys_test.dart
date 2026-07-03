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
}
