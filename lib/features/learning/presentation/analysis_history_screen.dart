import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class AnalysisHistoryScreen extends ConsumerWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(analysisHistoryProvider);
    final history = historyAsync.value ?? const <AnalysisHistoryEntry>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('실험 기록'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: '전체 삭제',
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, _) => Center(
          child: Text(
            '실험 기록을 불러오지 못했습니다.\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        data: (entries) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HistoryNotice(),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const GlassContainer(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      '저장된 실험 기록이 없습니다.\n분석 기준 실험실에서 결과를 기록할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.5),
                    ),
                  ),
                ),
              )
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    entry: entry,
                    onDelete: () => ref
                        .read(analysisHistoryProvider.notifier)
                        .delete(entry.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('실험 기록 전체 삭제'),
        content: const Text('이 기기에 저장된 모든 분석 기준 실험 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(analysisHistoryProvider.notifier).clearAll();
    }
  }
}

class _HistoryNotice extends StatelessWidget {
  const _HistoryNotice();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.history_edu_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '최근 20개의 가중치와 상위 샘플만 이 기기에 저장합니다. 투자 성과, 수익률 또는 포트폴리오 변화는 기록하지 않습니다.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AnalysisHistoryEntry entry;
  final VoidCallback onDelete;

  const _HistoryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          iconColor: const Color(0xFF10B981),
          collapsedIconColor: Colors.white38,
          title: Text(
            entry.strategyName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${marketFilterLabel(entry.marketFilter)} · '
            '${DateFormat('yyyy.MM.dd HH:mm').format(entry.createdAt)}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '기록 삭제',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
              ),
              const Icon(Icons.expand_more, color: Colors.white38),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['per', 'roe', 'dividend'].map((key) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_metricLabel(key)} ${((entry.weights[key] ?? 0) * 100).round()}%',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '당시 상위 샘플',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...entry.topSamples.map(
              (sample) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '#${sample.rank}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        resolveInstrumentName(sample.ticker, sample.name),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                      ),
                    ),
                    Text(
                      sample.ticker,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _metricLabel(String key) {
  switch (key) {
    case 'per':
      return 'PER';
    case 'roe':
      return 'ROE';
    case 'dividend':
      return '배당';
    default:
      return key.toUpperCase();
  }
}
