/// Opt-in daily study reminder. Off unless the user turns it on.
///
/// Scheduling is inexact on purpose: the app does not request
/// SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM. Asia/Seoul is UTC+9 and does not
/// observe daylight saving time, so a fixed offset is enough.
const asiaSeoulOffset = Duration(hours: 9);

const studyReminderEnabledKey = 'study_reminder_enabled_v1';
const studyReminderHourKey = 'study_reminder_hour_v1';
const studyReminderMinuteKey = 'study_reminder_minute_v1';
const studyReminderNotificationId = 17017;
const studyReminderPayload = 'study-reminder';
const studyReminderChannelId = 'study_reminder_channel';

enum StudyReminderPermission { granted, denied }

enum StudyReminderToggleResult {
  enabled,
  disabled,
  permissionDenied,
  scheduleFailed,
}

/// The Android schedule mode the study reminder is allowed to use.
class StudyReminderPlan {
  static const usesExactAlarmPermission = false;
  static const scheduleModeName = 'inexactAllowWhileIdle';
}

class StudyReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const StudyReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  static const defaults = StudyReminderSettings(
    enabled: false,
    hour: 20,
    minute: 0,
  );

  StudyReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return StudyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class StudyReminderUpdate {
  final StudyReminderSettings settings;
  final StudyReminderToggleResult result;

  const StudyReminderUpdate({
    required this.settings,
    required this.result,
  });
}

abstract class StudyReminderStore {
  Future<StudyReminderSettings> read();
  Future<void> write(StudyReminderSettings settings);
}

abstract class StudyReminderScheduler {
  Future<StudyReminderPermission> requestPermission();
  Future<bool> notificationsAllowed();
  Future<void> schedule({
    required int hour,
    required int minute,
    required bool korean,
  });
  Future<void> cancel();
}

class StudyReminderCopy {
  static String screenTitle({required bool korean}) =>
      korean ? '학습 설정' : 'Learning settings';

  static String toggleTitle({required bool korean}) =>
      korean ? '오늘의 학습 알림' : 'Daily study reminder';

  static String toggleSubtitle({required bool korean}) => korean
      ? '하루 한 번, 지표 문제를 읽어 보라고 알려 줍니다. 기본값은 꺼짐입니다.'
      : 'Once a day, a nudge to read one indicator question. Off unless you turn it on.';

  static String timeLabel({required bool korean}) =>
      korean ? '알림 시각' : 'Reminder time';

  static String timeHelp({required bool korean}) => korean
      ? '한국 시간(서울)입니다. 정확한 시각이 아니라 그 전후에 도착할 수 있습니다. 가격 알림이 아닙니다.'
      : 'Times use Korea (Seoul). It can arrive around that time, not on the exact minute. This is not a price alert.';

  static String permissionDenied({required bool korean}) => korean
      ? '알림 권한이 없어 리마인더를 켜지 않았습니다. 기기 알림을 허용한 뒤 다시 켤 수 있습니다.'
      : 'The reminder stayed off because notifications are not allowed. You can allow them and try again.';

  static String scheduleFailed({required bool korean}) => korean
      ? '알림을 예약하지 못해 리마인더를 켜지 않았습니다.'
      : 'The reminder stayed off because it could not be scheduled.';

  static String rebootNote({required bool korean}) => korean
      ? '기기를 다시 켜면 같은 학습 알림을 이어 가도록 맞춰 두었습니다. 배터리 제한에 따라 조금 늦을 수 있고, 앱을 다시 열면 한 번 더 맞춥니다.'
      : 'After a restart the same study reminder is restored. Power limits can delay it, and opening the app schedules it again.';

  static String notificationTitle({required bool korean}) =>
      korean ? '오늘의 학습' : 'Time to study';

  static String notificationBody({required bool korean}) => korean
      ? '지표 한 문제를 읽어 볼 시간입니다.'
      : 'One indicator question is ready to read.';

  static String channelName({required bool korean}) =>
      korean ? '학습 리마인더' : 'Study reminder';

  static String channelDescription({required bool korean}) => korean
      ? '하루 한 번 지표 문제를 읽어 보라는 학습 알림입니다. 가격 알림이 아닙니다.'
      : 'An optional daily reminder to read one indicator question. Not a price alert.';

  static String settingsEntryTitle({required bool korean}) =>
      korean ? '학습 설정' : 'Learning settings';

  static String settingsEntrySubtitle({required bool korean}) => korean
      ? '학습 알림은 기본으로 꺼져 있습니다'
      : 'The study reminder is off until you turn it on';

  static String openSettingsWhenOff({required bool korean}) => korean
      ? '학습 알림은 기본으로 꺼져 있습니다'
      : 'The study reminder is off until you turn it on';

  static String openSettingsWhenOn(
          {required bool korean, required String time}) =>
      korean ? '학습 알림 $time · 설정' : 'Study reminder $time · Settings';

  static List<String> scannedSurfaces({required bool korean}) => [
        screenTitle(korean: korean),
        toggleTitle(korean: korean),
        toggleSubtitle(korean: korean),
        timeLabel(korean: korean),
        timeHelp(korean: korean),
        permissionDenied(korean: korean),
        scheduleFailed(korean: korean),
        rebootNote(korean: korean),
        notificationTitle(korean: korean),
        notificationBody(korean: korean),
        channelName(korean: korean),
        channelDescription(korean: korean),
        settingsEntryTitle(korean: korean),
        settingsEntrySubtitle(korean: korean),
        openSettingsWhenOff(korean: korean),
      ];
}

String formatStudyReminderTime(int hour, int minute) {
  final hh = hour.toString().padLeft(2, '0');
  final mm = minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Next UTC instant for a Seoul wall-clock time. If that minute has passed
/// (or it is exactly now), the result is the same clock time on the next
/// Seoul day.
DateTime nextSeoulReminderInstant({
  required DateTime now,
  required int hour,
  required int minute,
}) {
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    throw ArgumentError('Reminder time must be a valid clock time.');
  }
  final seoulNow = now.toUtc().add(asiaSeoulOffset);
  var wall = DateTime.utc(
    seoulNow.year,
    seoulNow.month,
    seoulNow.day,
    hour,
    minute,
  );
  if (!wall.isAfter(seoulNow)) {
    wall = wall.add(const Duration(days: 1));
  }
  return wall.subtract(asiaSeoulOffset);
}

class StudyReminderCoordinator {
  final StudyReminderStore store;
  final StudyReminderScheduler scheduler;

  StudyReminderCoordinator({
    required this.store,
    required this.scheduler,
  });

  Future<StudyReminderSettings> load() => store.read();

  Future<StudyReminderUpdate> setEnabled(
    bool enabled, {
    required bool korean,
  }) async {
    final current = await store.read();
    if (!enabled) {
      await scheduler.cancel();
      final next = current.copyWith(enabled: false);
      await store.write(next);
      return StudyReminderUpdate(
        settings: next,
        result: StudyReminderToggleResult.disabled,
      );
    }

    final permission = await scheduler.requestPermission();
    if (permission != StudyReminderPermission.granted) {
      await scheduler.cancel();
      final next = current.copyWith(enabled: false);
      await store.write(next);
      return StudyReminderUpdate(
        settings: next,
        result: StudyReminderToggleResult.permissionDenied,
      );
    }

    try {
      await scheduler.schedule(
        hour: current.hour,
        minute: current.minute,
        korean: korean,
      );
    } catch (_) {
      await scheduler.cancel();
      final next = current.copyWith(enabled: false);
      await store.write(next);
      return StudyReminderUpdate(
        settings: next,
        result: StudyReminderToggleResult.scheduleFailed,
      );
    }

    final next = current.copyWith(enabled: true);
    await store.write(next);
    return StudyReminderUpdate(
      settings: next,
      result: StudyReminderToggleResult.enabled,
    );
  }

  Future<StudyReminderSettings> setTime({
    required int hour,
    required int minute,
    required bool korean,
  }) async {
    final current = await store.read();
    final next = current.copyWith(hour: hour, minute: minute);
    await store.write(next);
    if (next.enabled) {
      await scheduler.schedule(hour: hour, minute: minute, korean: korean);
    }
    return next;
  }

  /// Restores an already opted-in reminder. Does not request permission.
  Future<StudyReminderSettings> restore({required bool korean}) async {
    final current = await store.read();
    if (!current.enabled) {
      return current;
    }
    try {
      final allowed = await scheduler.notificationsAllowed();
      if (!allowed) {
        await scheduler.cancel();
        final next = current.copyWith(enabled: false);
        await store.write(next);
        return next;
      }
      await scheduler.schedule(
        hour: current.hour,
        minute: current.minute,
        korean: korean,
      );
      return current;
    } catch (_) {
      return current;
    }
  }
}
