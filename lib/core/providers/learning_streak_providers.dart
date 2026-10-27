import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/features/learning/domain/daily_question.dart';

const learningStreakCountKey = 'learning_streak_count_v1';
const learningStreakDayKey = 'learning_streak_day_v1';
const learningAnsweredQuestionKey = 'learning_answered_question_v1';

class LearningStreakNotifier extends AsyncNotifier<LearningStreakSnapshot> {
  @override
  Future<LearningStreakSnapshot> build() => _read();

  Future<LearningStreakSnapshot> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return LearningStreakSnapshot(
        streak: prefs.getInt(learningStreakCountKey) ?? 0,
        lastCompletedDay: parseLearningDay(
          prefs.getString(learningStreakDayKey),
        ),
        answeredQuestionId: prefs.getString(learningAnsweredQuestionKey),
      );
    } catch (_) {
      return LearningStreakSnapshot.empty;
    }
  }

  Future<void> completeToday({
    required String questionId,
    DateTime? now,
  }) async {
    final current = state.value ?? await _read();
    final next = LearningProgress.applyAnswer(
      current: current,
      questionId: questionId,
      now: now ?? DateTime.now(),
    );
    if (identical(next, current) ||
        (next.streak == current.streak &&
            next.lastCompletedDay == current.lastCompletedDay &&
            next.answeredQuestionId == current.answeredQuestionId)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(learningStreakCountKey, next.streak);
    await prefs.setString(
      learningStreakDayKey,
      formatLearningDay(next.lastCompletedDay!),
    );
    await prefs.setString(
      learningAnsweredQuestionKey,
      next.answeredQuestionId!,
    );
    state = AsyncData(next);
  }
}

final learningStreakProvider =
    AsyncNotifierProvider<LearningStreakNotifier, LearningStreakSnapshot>(
      LearningStreakNotifier.new,
    );
