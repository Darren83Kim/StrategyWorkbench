import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_service.dart';
import 'notification_service.dart';

typedef AlertRuntimeCallback = Future<void> Function();

class AlertRuntimeService {
  AlertRuntimeService({
    AlertRuntimeCallback? initNotification,
    AlertRuntimeCallback? initBackground,
    AlertRuntimeCallback? registerBackground,
    AlertRuntimeCallback? cancelBackground,
  })  : _initNotification = initNotification ?? NotificationService().init,
        _initBackground = initBackground ?? BackgroundService().init,
        _registerBackground =
            registerBackground ?? BackgroundService().registerDailyTask,
        _cancelBackground =
            cancelBackground ?? BackgroundService().cancelDailyTask;

  static final AlertRuntimeService shared = AlertRuntimeService();

  final AlertRuntimeCallback _initNotification;
  final AlertRuntimeCallback _initBackground;
  final AlertRuntimeCallback _registerBackground;
  final AlertRuntimeCallback _cancelBackground;

  bool _notificationReady = false;
  bool _backgroundReady = false;
  bool _taskRegistered = false;
  Future<void> _serial = Future<void>.value();

  Future<void> syncForStrategy({
    required String? strategyName,
  }) {
    _serial = _serial
        .catchError((_) {})
        .then((_) => _syncInternal(strategyName?.trim()));
    return _serial;
  }

  Future<void> _syncInternal(String? strategyName) async {
    if (strategyName == null || strategyName.isEmpty) {
      await _cancelBackground();
      _taskRegistered = false;
      developer.log(
        'Alert runtime kept idle: no active strategy',
        name: 'AlertRuntimeService',
      );
      return;
    }

    if (!_notificationReady) {
      await _initNotification();
      _notificationReady = true;
      developer.log(
        'Notification runtime initialized',
        name: 'AlertRuntimeService',
      );
    }

    if (!_backgroundReady) {
      await _initBackground();
      _backgroundReady = true;
      developer.log(
        'Background runtime initialized',
        name: 'AlertRuntimeService',
      );
    }

    if (!_taskRegistered) {
      await _registerBackground();
      _taskRegistered = true;
      developer.log(
        'Background alert task registered for $strategyName',
        name: 'AlertRuntimeService',
      );
    } else {
      developer.log(
        'Alert runtime already active for $strategyName',
        name: 'AlertRuntimeService',
      );
    }
  }
}

final alertRuntimeServiceProvider = Provider<AlertRuntimeService>((ref) {
  return AlertRuntimeService.shared;
});
