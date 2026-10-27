import 'package:flutter/material.dart';
import 'package:strategy_workbench/core/metrics/empty_metric_help.dart';

Future<void> showEmptyMetricHelp(
  BuildContext context,
  EmptyMetricExplanation explanation, {
  bool korean = true,
}) {
  final whyTitle = korean ? '왜 비어 있나요' : 'Why it is empty';
  final meaningTitle = korean ? '학습에서 이 지표는' : 'What it means for learning';
  final scoreTitle = korean ? '점수에서는' : 'In the score';
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F172A),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                explanation.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _HelpBlock(
                title: whyTitle,
                body: explanation.whyEmpty,
                accent: const Color(0xFFFDBA74),
              ),
              const SizedBox(height: 10),
              _HelpBlock(
                title: meaningTitle,
                body: explanation.meaning,
                accent: const Color(0xFF93C5FD),
              ),
              const SizedBox(height: 10),
              _HelpBlock(
                title: scoreTitle,
                body: explanation.scoreNote,
                accent: const Color(0xFF6EE7B7),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class EmptyMetricChip extends StatelessWidget {
  final String label;
  final EmptyMetricExplanation explanation;

  const EmptyMetricChip({
    super.key,
    required this.label,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF7C2D12).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showEmptyMetricHelp(context, explanation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFDBA74),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFFFDBA74),
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpBlock extends StatelessWidget {
  final String title;
  final String body;
  final Color accent;

  const _HelpBlock({
    required this.title,
    required this.body,
    this.accent = const Color(0xFFFDBA74),
  });

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
