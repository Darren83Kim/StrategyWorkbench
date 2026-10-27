import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:strategy_workbench/core/config/store_policy.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/language_provider.dart';
import 'package:strategy_workbench/core/services/alert_runtime_service.dart';
import 'package:strategy_workbench/features/learning/domain/preset_walkthrough.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class PresetWalkthroughScreen extends ConsumerStatefulWidget {
  const PresetWalkthroughScreen({super.key});

  @override
  ConsumerState<PresetWalkthroughScreen> createState() =>
      _PresetWalkthroughScreenState();
}

class _PresetWalkthroughScreenState
    extends ConsumerState<PresetWalkthroughScreen> {
  int _index = 0;

  Future<void> _apply(PresetWalkthroughStep step) async {
    await ref.read(activeStrategyNameProvider.notifier).setActive(step.name);
    if (StorePolicy.enablePortfolioAlerts) {
      unawaited(
        ref
            .read(alertRuntimeServiceProvider)
            .syncForStrategy(strategyName: step.name),
      );
    }
    if (!mounted) {
      return;
    }
    context.go('/strategy');
  }

  @override
  Widget build(BuildContext context) {
    final korean = (ref.watch(languageProvider).value ?? 'en') == 'ko';
    final steps = buildPresetWalkthrough(korean: korean);
    final step = steps[_index];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(korean ? '프리셋 따라 하기' : 'Preset walkthrough'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            korean
                ? '${_index + 1} / ${steps.length}'
                : '${_index + 1} / ${steps.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i <= _index
                          ? const Color(0xFF10B981)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.focus,
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...step.weights.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _WeightBar(
                        label: _weightLabel(entry.key, korean),
                        value: entry.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.lesson,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.orderEffect,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            korean
                ? '비중을 바꾸면 샘플 순서가 달라지는 것을 보는 학습입니다. 특정 종목의 매수·매도를 권하지 않습니다.'
                : 'This walkthrough shows how weights change the sample order. It does not recommend buying or selling a symbol.',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _apply(step),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: const Color(0xFF052E1A),
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(
              korean ? '이 기준으로 랭킹 보기' : 'Open the ranking with this preset',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _index == 0
                      ? null
                      : () => setState(() => _index -= 1),
                  child: Text(korean ? '이전' : 'Back'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _index == steps.length - 1
                      ? null
                      : () => setState(() => _index += 1),
                  child: Text(korean ? '다음' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weightLabel(String key, bool korean) {
    return switch (key) {
      'per' => 'PER',
      'roe' => 'ROE',
      'dividend' => korean ? '배당' : 'Dividend',
      _ => key,
    };
  }
}

class _WeightBar extends StatelessWidget {
  final String label;
  final double value;

  const _WeightBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              color: const Color(0xFF10B981),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
