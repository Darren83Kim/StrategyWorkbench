import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/core/services/alert_runtime_service.dart';

void main() {
  group('AlertRuntimeService', () {
    test('keeps runtime idle when there is no active strategy', () async {
      final calls = <String>[];
      final service = AlertRuntimeService(
        initNotification: () async => calls.add('initNotification'),
        initBackground: () async => calls.add('initBackground'),
        registerBackground: () async => calls.add('registerBackground'),
        cancelBackground: () async => calls.add('cancelBackground'),
      );

      await service.syncForStrategy(strategyName: null);

      expect(calls, ['cancelBackground']);
    });

    test('initializes alert runtime only once while strategy stays active',
        () async {
      final calls = <String>[];
      final service = AlertRuntimeService(
        initNotification: () async => calls.add('initNotification'),
        initBackground: () async => calls.add('initBackground'),
        registerBackground: () async => calls.add('registerBackground'),
        cancelBackground: () async => calls.add('cancelBackground'),
      );

      await service.syncForStrategy(strategyName: '가치주');
      await service.syncForStrategy(strategyName: '배당주');

      expect(
        calls,
        ['initNotification', 'initBackground', 'registerBackground'],
      );
    });

    test('re-registers background task after strategy is cleared', () async {
      final calls = <String>[];
      final service = AlertRuntimeService(
        initNotification: () async => calls.add('initNotification'),
        initBackground: () async => calls.add('initBackground'),
        registerBackground: () async => calls.add('registerBackground'),
        cancelBackground: () async => calls.add('cancelBackground'),
      );

      await service.syncForStrategy(strategyName: '가치주');
      await service.syncForStrategy(strategyName: null);
      await service.syncForStrategy(strategyName: '퀀트');

      expect(
        calls,
        [
          'initNotification',
          'initBackground',
          'registerBackground',
          'cancelBackground',
          'registerBackground',
        ],
      );
    });
  });
}
