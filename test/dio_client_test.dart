import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/network/dio_client.dart';

void main() {
  group('buildResponsePreview', () {
    test('returns short payloads without throwing or truncating', () {
      const payload = '{"ok":true}';

      final preview = buildResponsePreview(payload);

      expect(preview, payload);
    });

    test('truncates long payloads to the requested max length', () {
      final payload = 'a' * 250;

      final preview = buildResponsePreview(payload, maxLength: 20);

      expect(preview, '${'a' * 20}...');
    });
  });
}
