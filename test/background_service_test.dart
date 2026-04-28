import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/services/background_service.dart';

void main() {
  group('BackgroundService helpers', () {
    test('calculateSensitivityRankThreshold uses percentage thresholds', () {
      expect(
        calculateSensitivityRankThreshold(totalCount: 100, sensitivity: 'High'),
        10,
      );
      expect(
        calculateSensitivityRankThreshold(
            totalCount: 100, sensitivity: 'Medium'),
        20,
      );
      expect(
        calculateSensitivityRankThreshold(totalCount: 100, sensitivity: 'Low'),
        30,
      );
    });

    test('calculateSensitivityRankThreshold keeps a minimum threshold of 1',
        () {
      expect(
        calculateSensitivityRankThreshold(totalCount: 1, sensitivity: 'High'),
        1,
      );
      expect(
        calculateSensitivityRankThreshold(totalCount: 0, sensitivity: 'Low'),
        1,
      );
    });

    test('resolveActiveStrategy prefers saved custom strategy over preset', () {
      final savedFiltersJson = jsonEncode([
        SavedFilter(
          name: '가치주',
          weights: {'per': 0.2, 'roe': 0.8},
          topN: 30,
          sensitivity: 'Low',
        ).toJson(),
      ]);

      final strategy = resolveActiveStrategy(
        activeStrategyName: '가치주',
        savedFiltersJson: savedFiltersJson,
      );

      expect(strategy, isNotNull);
      expect(strategy!.weights['roe'], 0.8);
      expect(strategy.topN, 30);
      expect(strategy.sensitivity, 'Low');
    });
  });
}
