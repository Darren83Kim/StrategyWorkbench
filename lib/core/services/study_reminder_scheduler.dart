import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:strategy_workbench/features/learning/domain/study_reminder.dart';

/// Where a tapped study reminder should go. Set from `main` so this file
/// does not import the router.
class StudyReminderNavigation {
  static void Function(String? payload)? onTap;
}

/// Inexact daily reminder. [StudyReminderPlan.usesExactAlarmPermission] stays
/// false: this class never selects an exact or alarm-clock schedule mode.
///
/// Reboot: the manifest registers the plugin's
/// `ScheduledNotificationBootReceiver` with the existing
/// RECEIVE_BOOT_COMPLETED permission. That receiver restores the saved
/// inexact alarm. Opening the app schedules it again if the user left the
/// reminder on. No SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM permission.
class FlutterStudyReminderScheduler implements StudyReminderScheduler {
  FlutterStudyReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _handledLaunch = false;

  Future<void> _ensureReady() async {
    if (_ready) {
      return;
    }
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == studyReminderPayload) {
          StudyReminderNavigation.onTap?.call(response.payload);
        }
      },
    );
    _ready = true;
    if (_handledLaunch) {
      return;
    }
    _handledLaunch = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        payload == studyReminderPayload) {
      StudyReminderNavigation.onTap?.call(payload);
    }
  }

  @override
  Future<StudyReminderPermission> requestPermission() async {
    await _ensureReady();
    if (kIsWeb) {
      return StudyReminderPermission.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) {
        return StudyReminderPermission.granted;
      }
      if (granted == null) {
        final enabled = await android?.areNotificationsEnabled();
        if (enabled == true) {
          return StudyReminderPermission.granted;
        }
      }
      return StudyReminderPermission.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      return granted == true
          ? StudyReminderPermission.granted
          : StudyReminderPermission.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      return granted == true
          ? StudyReminderPermission.granted
          : StudyReminderPermission.denied;
    }
    return StudyReminderPermission.denied;
  }

  @override
  Future<bool> notificationsAllowed() async {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _ensureReady();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled != false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _ensureReady();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      if (options == null) {
        return true;
      }
      return options.isEnabled;
    }
    return true;
  }

  @override
  Future<void> schedule({
    required int hour,
    required int minute,
    required bool korean,
  }) async {
    await _ensureReady();
    final seoul = tz.getLocation('Asia/Seoul');
    final utc = nextSeoulReminderInstant(
      now: DateTime.now(),
      hour: hour,
      minute: minute,
    );
    final scheduled = tz.TZDateTime.from(utc, seoul);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        studyReminderChannelId,
        StudyReminderCopy.channelName(korean: korean),
        channelDescription:
            StudyReminderCopy.channelDescription(korean: korean),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );
    await _plugin.zonedSchedule(
      studyReminderNotificationId,
      StudyReminderCopy.notificationTitle(korean: korean),
      StudyReminderCopy.notificationBody(korean: korean),
      scheduled,
      details,
      androidScheduleMode: studyReminderAndroidScheduleMode(),
      payload: studyReminderPayload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await _ensureReady();
    await _plugin.cancel(studyReminderNotificationId);
  }
}

/// The only Android schedule mode used for the study reminder.
AndroidScheduleMode studyReminderAndroidScheduleMode() {
  assert(!StudyReminderPlan.usesExactAlarmPermission);
  assert(StudyReminderPlan.scheduleModeName == 'inexactAllowWhileIdle');
  return AndroidScheduleMode.inexactAllowWhileIdle;
}
