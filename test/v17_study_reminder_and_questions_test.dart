import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/study_reminder_providers.dart';
import 'package:strategy_workbench/core/services/study_reminder_scheduler.dart';
import 'package:strategy_workbench/features/learning/domain/daily_question.dart';
import 'package:strategy_workbench/features/learning/domain/study_reminder.dart';
import 'package:strategy_workbench/features/learning/presentation/learning_settings_screen.dart';
import 'package:strategy_workbench/features/learning/presentation/learning_tools_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('study reminder defaults', () {
    test('stored settings are off until the user opts in', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesStudyReminderStore();
      final settings = await store.read();

      expect(settings.enabled, isFalse);
      expect(settings.hour, 20);
      expect(settings.minute, 0);
      expect(StudyReminderSettings.defaults.enabled, isFalse);
      expect(StudyReminderPlan.usesExactAlarmPermission, isFalse);
      expect(StudyReminderPlan.scheduleModeName, 'inexactAllowWhileIdle');
    });

    test('opening settings does not ask for notification permission', () async {
      final fake = _FakeScheduler();
      final coordinator = StudyReminderCoordinator(
        store: _MemoryStore(),
        scheduler: fake,
      );

      final loaded = await coordinator.load();
      final restored = await coordinator.restore(korean: true);

      expect(loaded.enabled, isFalse);
      expect(restored.enabled, isFalse);
      expect(fake.requestCount, 0);
      expect(fake.scheduleCount, 0);
    });

    test('turning the reminder on asks once and schedules only if allowed',
        () async {
      final fake = _FakeScheduler()
        ..permission = StudyReminderPermission.denied;
      final store = _MemoryStore();
      final coordinator =
          StudyReminderCoordinator(store: store, scheduler: fake);

      final denied = await coordinator.setEnabled(true, korean: true);
      expect(denied.result, StudyReminderToggleResult.permissionDenied);
      expect(denied.settings.enabled, isFalse);
      expect((await store.read()).enabled, isFalse);
      expect(fake.requestCount, 1);
      expect(fake.scheduleCount, 0);

      fake.permission = StudyReminderPermission.granted;
      final enabled = await coordinator.setEnabled(true, korean: true);
      expect(enabled.result, StudyReminderToggleResult.enabled);
      expect(enabled.settings.enabled, isTrue);
      expect(fake.requestCount, 2);
      expect(fake.schedules, [(20, 0, true)]);

      final changed =
          await coordinator.setTime(hour: 7, minute: 30, korean: true);
      expect(changed.hour, 7);
      expect(changed.minute, 30);
      expect(fake.requestCount, 2);
      expect(fake.schedules.last, (7, 30, true));

      final off = await coordinator.setEnabled(false, korean: true);
      expect(off.settings.enabled, isFalse);
      expect(fake.requestCount, 2);
      expect(fake.cancelCount, greaterThan(0));
    });

    test('a failed schedule leaves the reminder off', () async {
      final fake = _FakeScheduler()..throwOnSchedule = true;
      final coordinator = StudyReminderCoordinator(
        store: _MemoryStore(),
        scheduler: fake,
      );

      final update = await coordinator.setEnabled(true, korean: false);
      expect(update.result, StudyReminderToggleResult.scheduleFailed);
      expect(update.settings.enabled, isFalse);
    });

    test('restore reschedules an opted-in reminder without asking again',
        () async {
      final fake = _FakeScheduler();
      final store = _MemoryStore(
        const StudyReminderSettings(enabled: true, hour: 8, minute: 15),
      );
      final coordinator =
          StudyReminderCoordinator(store: store, scheduler: fake);

      final restored = await coordinator.restore(korean: false);
      expect(restored.enabled, isTrue);
      expect(fake.requestCount, 0);
      expect(fake.schedules, [(8, 15, false)]);

      fake.allowed = false;
      final revoked = await coordinator.restore(korean: false);
      expect(revoked.enabled, isFalse);
      expect(fake.requestCount, 0);
      expect((await store.read()).enabled, isFalse);
    });

    test('changing the time while off does not schedule or ask', () async {
      final fake = _FakeScheduler();
      final coordinator = StudyReminderCoordinator(
        store: _MemoryStore(),
        scheduler: fake,
      );

      final next = await coordinator.setTime(hour: 9, minute: 5, korean: true);
      expect(next.enabled, isFalse);
      expect(next.hour, 9);
      expect(fake.requestCount, 0);
      expect(fake.scheduleCount, 0);
    });

    test('the next reminder instant follows Seoul and is not exact-only', () {
      expect(
        nextSeoulReminderInstant(
          now: seoulWallClock(2026, 5, 2, 19),
          hour: 20,
          minute: 0,
        ),
        seoulWallClock(2026, 5, 2, 20),
      );
      expect(
        nextSeoulReminderInstant(
          now: seoulWallClock(2026, 5, 2, 20),
          hour: 20,
          minute: 0,
        ),
        seoulWallClock(2026, 5, 3, 20),
      );
      expect(
        nextSeoulReminderInstant(
          now: DateTime.utc(2026, 5, 2, 11, 30),
          hour: 20,
          minute: 0,
        ),
        seoulWallClock(2026, 5, 3, 20),
      );
      expect(
        studyReminderAndroidScheduleMode(),
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
      expect(
        studyReminderAndroidScheduleMode(),
        isNot(AndroidScheduleMode.exact),
      );
      expect(
        studyReminderAndroidScheduleMode(),
        isNot(AndroidScheduleMode.exactAllowWhileIdle),
      );
      expect(
        studyReminderAndroidScheduleMode(),
        isNot(AndroidScheduleMode.alarmClock),
      );
    });

    test('reminder copy stays on a learning tone', () {
      const banned = ['급등', '매수', '추천'];
      for (final korean in [true, false]) {
        final text =
            StudyReminderCopy.scannedSurfaces(korean: korean).join('\n');
        for (final word in banned) {
          expect(text, isNot(contains(word)));
        }
        expect(text.replaceAll('배당수익률', ''), isNot(contains('수익률')));
      }
      expect(StudyReminderCopy.notificationBody(korean: true), contains('지표'));
      expect(StudyReminderCopy.toggleSubtitle(korean: true), contains('꺼짐'));
    });
  });

  group('daily question selection and streak', () {
    test('covers the metric concepts and keeps both languages aligned', () {
      expect(
        DailyQuestionBank.questionsKo.length,
        greaterThan(DailyQuestionBank.repeatAvoidanceWindowDays),
      );
      expect(
        DailyQuestionBank.questionsKo.length,
        DailyQuestionBank.questionsEn.length,
      );
      final ids = DailyQuestionBank.questionsKo.map((question) => question.id);
      expect(
          ids,
          containsAll([
            'per-meaning',
            'pbr-meaning',
            'roe-meaning',
            'dividend-meaning',
            'payout-meaning',
            'eps-meaning',
          ]));
      for (var i = 0; i < DailyQuestionBank.questionsKo.length; i++) {
        final korean = DailyQuestionBank.questionsKo[i];
        final english = DailyQuestionBank.questionsEn[i];
        expect(korean.id, english.id);
        expect(korean.answerIndex, english.answerIndex);
        expect(
            korean.answerIndex, inInclusiveRange(0, korean.choices.length - 1));
        expect(korean.explanation, contains('아닙니다'));
        expect(english.explanation.toLowerCase(), contains('not a'));
        expect(
            korean.formula.isNotEmpty || korean.studyNote.isNotEmpty, isTrue);
      }
      expect(
        DailyQuestionBank.questionsKo
            .map((question) => question.answerIndex)
            .toSet(),
        containsAll([0, 1, 2]),
      );
    });

    test('does not repeat a question inside the avoidance window', () {
      final start = seoulWallClock(2026, 6, 1, 8);
      final ids =
          List.generate(DailyQuestionBank.repeatAvoidanceWindowDays, (offset) {
        return DailyQuestionBank.forDate(
          seoulWallClock(2026, 6, 1 + offset, 8),
        ).id;
      });
      expect(ids.toSet().length, ids.length);
      expect(
        DailyQuestionBank.forDate(start).id,
        DailyQuestionBank.forDate(start, korean: false).id,
      );
      expect(
        DailyQuestionBank.forDate(seoulWallClock(2026, 10, 27, 23, 30)).id,
        isNot(
          DailyQuestionBank.forDate(seoulWallClock(2026, 10, 28, 0, 30)).id,
        ),
      );
      final length = DailyQuestionBank.questionsKo.length;
      expect(
        DailyQuestionBank.forDate(seoulWallClock(2026, 1, 1, 12)).id,
        DailyQuestionBank.forDate(seoulWallClock(2026, 1, 1 + length, 12)).id,
      );
    });

    test('streak follows Seoul midnights, including a UTC evening', () {
      const start = LearningStreakSnapshot.empty;
      final late = LearningProgress.applyAnswer(
        current: start,
        questionId: 'per-meaning',
        now: seoulWallClock(2026, 10, 27, 23, 50),
      );
      final stillToday = LearningProgress.applyAnswer(
        current: late,
        questionId: 'pbr-meaning',
        now: DateTime.utc(2026, 10, 27, 14, 59),
      );
      final nextSeoulDay = LearningProgress.applyAnswer(
        current: stillToday,
        questionId: 'eps-meaning',
        now: DateTime.utc(2026, 10, 27, 15, 10),
      );
      final afterGap = LearningProgress.applyAnswer(
        current: nextSeoulDay,
        questionId: 'payout-meaning',
        now: seoulWallClock(2026, 10, 30, 9),
      );

      expect(formatLearningDay(late.lastCompletedDay!), '2026-10-27');
      expect(stillToday.streak, 1);
      expect(stillToday.answeredQuestionId, 'per-meaning');
      expect(formatLearningDay(nextSeoulDay.lastCompletedDay!), '2026-10-28');
      expect(nextSeoulDay.streak, 2);
      expect(afterGap.streak, 1);
      expect(late.completedOn(DateTime.utc(2026, 10, 27, 14, 30)), isTrue);
      expect(late.completedOn(DateTime.utc(2026, 10, 27, 15, 30)), isFalse);
    });

    test('a year boundary continues only on the next Seoul day', () {
      final dec31 = LearningProgress.applyAnswer(
        current: LearningStreakSnapshot.empty,
        questionId: 'bps-meaning',
        now: seoulWallClock(2026, 12, 31, 22),
      );
      final jan1 = LearningProgress.applyAnswer(
        current: dec31,
        questionId: 'roe-meaning',
        now: seoulWallClock(2027, 1, 1, 0, 5),
      );
      final skipped = LearningProgress.applyAnswer(
        current: dec31,
        questionId: 'roe-meaning',
        now: seoulWallClock(2027, 1, 2, 0, 5),
      );

      expect(jan1.streak, 2);
      expect(skipped.streak, 1);
    });

    test('question copy avoids surge, buy, and recommendation wording', () {
      const banned = ['급등', '매수', '추천'];
      for (final question in [
        ...DailyQuestionBank.questionsKo,
        ...DailyQuestionBank.questionsEn,
      ]) {
        final text = [
          question.prompt,
          ...question.choices,
          question.explanation,
          question.formula,
          question.studyNote,
        ].join('\n');
        for (final word in banned) {
          expect(text, isNot(contains(word)), reason: question.id);
        }
        expect(
          text.replaceAll('배당수익률', ''),
          isNot(contains('수익률')),
          reason: question.id,
        );
        expect(question.choices[question.answerIndex], isNot(contains('매수')));
      }
    });
  });

  testWidgets('settings switch stays off when permission is denied',
      (tester) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});
    final fake = _FakeScheduler()..permission = StudyReminderPermission.denied;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyReminderSchedulerProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(home: LearningSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 학습 알림'), findsOneWidget);
    expect(find.textContaining('기본값은 꺼짐'), findsOneWidget);
    expect(fake.requestCount, 0);
    Switch switchWidget() => tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget().value, isFalse);

    await tester.tap(find.byKey(const Key('study-reminder-switch')));
    await tester.pumpAndSettle();

    expect(fake.requestCount, 1);
    expect(fake.scheduleCount, 0);
    expect(switchWidget().value, isFalse);
    expect(find.textContaining('알림 권한이 없어'), findsOneWidget);
    expect(find.textContaining('급등'), findsNothing);
    expect(find.textContaining('매수'), findsNothing);

    fake.permission = StudyReminderPermission.granted;
    await tester.tap(find.byKey(const Key('study-reminder-switch')));
    await tester.pumpAndSettle();

    expect(switchWidget().value, isTrue);
    expect(find.text('20:00'), findsOneWidget);
    expect(fake.schedules, [(20, 0, true)]);
  });

  testWidgets('learning tools link to settings without enabling the reminder', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ko'});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: LearningToolsCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('학습 설정'), findsOneWidget);
    expect(find.textContaining('기본으로 꺼져 있습니다'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(studyReminderEnabledKey), isNull);
  });
}

class _MemoryStore implements StudyReminderStore {
  StudyReminderSettings value;

  _MemoryStore([this.value = StudyReminderSettings.defaults]);

  @override
  Future<StudyReminderSettings> read() async => value;

  @override
  Future<void> write(StudyReminderSettings settings) async {
    value = settings;
  }
}

class _FakeScheduler implements StudyReminderScheduler {
  StudyReminderPermission permission = StudyReminderPermission.granted;
  bool allowed = true;
  bool throwOnSchedule = false;
  int requestCount = 0;
  int cancelCount = 0;
  final schedules = <(int, int, bool)>[];

  int get scheduleCount => schedules.length;

  @override
  Future<void> cancel() async {
    cancelCount += 1;
  }

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<StudyReminderPermission> requestPermission() async {
    requestCount += 1;
    return permission;
  }

  @override
  Future<void> schedule({
    required int hour,
    required int minute,
    required bool korean,
  }) async {
    if (throwOnSchedule) {
      throw StateError('schedule failed');
    }
    schedules.add((hour, minute, korean));
  }
}
