import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';

void main() {
  group('SavedFilter', () {
    test('fromJson defaults sensitivity to Medium when omitted', () {
      final filter = SavedFilter.fromJson({
        'name': '테스트 전략',
        'weights': {'per': 0.6, 'roe': 0.4},
        'createdAt': DateTime(2026, 4, 17).toIso8601String(),
        'topN': 20,
      });

      expect(filter.sensitivity, 'Medium');
    });
  });
}
