import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/services/study_reminder_scheduler.dart';
import 'package:strategy_workbench/features/learning/domain/study_reminder.dart';

final studyReminderSchedulerProvider = Provider<StudyReminderScheduler>((ref) {
  return FlutterStudyReminderScheduler();
});

class SharedPreferencesStudyReminderStore implements StudyReminderStore {
  @override
  Future<StudyReminderSettings> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return StudyReminderSettings(
        enabled: prefs.getBool(studyReminderEnabledKey) ?? false,
        hour: _clockPart(prefs.getInt(studyReminderHourKey), 20, 23),
        minute: _clockPart(prefs.getInt(studyReminderMinuteKey), 0, 59),
      );
    } catch (_) {
      return StudyReminderSettings.defaults;
    }
  }

  @override
  Future<void> write(StudyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(studyReminderEnabledKey, settings.enabled);
    await prefs.setInt(studyReminderHourKey, settings.hour);
    await prefs.setInt(studyReminderMinuteKey, settings.minute);
  }
}

int _clockPart(int? value, int fallback, int max) {
  if (value == null || value < 0 || value > max) {
    return fallback;
  }
  return value;
}

class StudyReminderNotifier extends AsyncNotifier<StudyReminderSettings> {
  StudyReminderCoordinator _coordinator() {
    return StudyReminderCoordinator(
      store: SharedPreferencesStudyReminderStore(),
      scheduler: ref.read(studyReminderSchedulerProvider),
    );
  }

  Future<bool> _korean() async {
    final prefs = await SharedPreferences.getInstance();
    return resolveLanguageCode(
          saved: prefs.getString(appLanguageStorageKey),
          deviceLanguageCode: deviceLanguageCode(),
        ) ==
        'ko';
  }

  @override
  Future<StudyReminderSettings> build() => _coordinator().load();

  Future<StudyReminderToggleResult> setEnabled(bool enabled) async {
    final update = await _coordinator().setEnabled(
      enabled,
      korean: await _korean(),
    );
    state = AsyncData(update.settings);
    return update.result;
  }

  Future<void> setTime({required int hour, required int minute}) async {
    final next = await _coordinator().setTime(
      hour: hour,
      minute: minute,
      korean: await _korean(),
    );
    state = AsyncData(next);
  }

  Future<void> restoreScheduledReminder() async {
    final next = await _coordinator().restore(korean: await _korean());
    state = AsyncData(next);
  }
}

final studyReminderProvider =
    AsyncNotifierProvider<StudyReminderNotifier, StudyReminderSettings>(
  StudyReminderNotifier.new,
);
