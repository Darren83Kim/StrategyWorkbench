import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/learning_streak_providers.dart';
import 'package:strategy_workbench/features/learning/domain/daily_question.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class DailyQuestionScreen extends ConsumerStatefulWidget {
  const DailyQuestionScreen({super.key});

  @override
  ConsumerState<DailyQuestionScreen> createState() =>
      _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends ConsumerState<DailyQuestionScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final korean = (ref.watch(languageProvider).value ?? 'en') == 'ko';
    final progress = ref.watch(learningStreakProvider);
    final question = DailyQuestionBank.forDate(DateTime.now(), korean: korean);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(korean ? '오늘의 한 문제' : 'Daily question'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: progress.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, _) => Center(
          child: Text('$error', style: const TextStyle(color: Colors.white70)),
        ),
        data: (snapshot) {
          final done = snapshot.completedOn(DateTime.now());
          final revealed = done || _selected != null;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        korean
                            ? '연속 학습 ${snapshot.streak}일'
                            : 'Learning streak: ${snapshot.streak} day${snapshot.streak == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        korean
                            ? '하루 한 문제를 마치면 연속이 이어집니다. 기록은 이 기기에만 있고 계정은 없습니다.'
                            : 'Finishing one question continues the streak. The record stays on this device. There is no account.',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                question.prompt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < question.choices.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChoiceButton(
                    label: question.choices[i],
                    selected: _selected == i,
                    revealed: revealed,
                    correct: i == question.answerIndex,
                    onPressed: revealed
                        ? null
                        : () async {
                            setState(() => _selected = i);
                            await ref
                                .read(learningStreakProvider.notifier)
                                .completeToday(questionId: question.id);
                          },
                  ),
                ),
              if (revealed) ...[
                const SizedBox(height: 8),
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          done && _selected == null
                              ? (korean
                                    ? '오늘 문제는 이미 마쳤습니다'
                                    : 'Today’s question is done')
                              : (_selected == question.answerIndex
                                    ? (korean ? '맞았습니다' : 'Correct')
                                    : (korean
                                          ? '다시 읽어 볼 부분'
                                          : 'Read this again')),
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool revealed;
  final bool correct;
  final VoidCallback? onPressed;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.revealed,
    required this.correct,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = !revealed
        ? const Color(0xFF334155)
        : correct
        ? const Color(0xFF10B981)
        : selected
        ? const Color(0xFFF87171)
        : const Color(0xFF334155);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, height: 1.35)),
    );
  }
}
