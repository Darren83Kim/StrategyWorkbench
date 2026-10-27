import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/providers/learning_streak_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class LearningToolsCard extends ConsumerWidget {
  const LearningToolsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final korean = (ref.watch(languageProvider).value ?? 'en') == 'ko';
    final streak = ref.watch(learningStreakProvider).value?.streak ?? 0;
    final done =
        ref.watch(learningStreakProvider).value?.completedOn(DateTime.now()) ??
        false;

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            _ToolRow(
              icon: Icons.quiz_outlined,
              title: korean ? '오늘의 한 문제' : 'Daily question',
              subtitle: korean
                  ? (done
                        ? '오늘 완료 · 연속 학습 $streak일'
                        : '연속 학습 $streak일 · 기기 안에만 저장')
                  : (done
                        ? 'Done today · streak $streak'
                        : 'Streak $streak · stored on this device'),
              onTap: () => context.push('/daily-question'),
            ),
            _ToolRow(
              icon: Icons.calculate_outlined,
              title: korean
                  ? 'PER · ROE · 배당 계산기'
                  : 'PER, ROE, dividend calculator',
              subtitle: korean
                  ? '숫자를 넣어 공식을 확인합니다'
                  : 'Type numbers and read the formulas',
              onTap: () => context.push('/metric-calculator'),
            ),
            _ToolRow(
              icon: Icons.route_outlined,
              title: korean ? '프리셋 따라 하기' : 'Preset walkthrough',
              subtitle: korean
                  ? '기본 비중 네 가지를 순서대로 봅니다'
                  : 'Walk through the four built-in weights',
              onTap: () => context.push('/preset-walkthrough'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6EE7B7)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
