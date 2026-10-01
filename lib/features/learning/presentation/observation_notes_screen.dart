import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class ObservationNotesScreen extends ConsumerWidget {
  const ObservationNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(observationNotesProvider);
    final notes = <ObservationNote>[...?notesAsync.value?.values];
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('관찰 메모'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              tooltip: '전체 삭제',
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (error, _) => Center(
          child: Text(
            '메모를 불러오지 못했습니다.\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _LocalStorageNotice(
              text: '메모와 확인 지표 태그는 이 기기에만 저장됩니다. 수량, 목표가, 매수·매도 상태는 저장하지 않습니다.',
            ),
            const SizedBox(height: 16),
            if (notes.isEmpty)
              const GlassContainer(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      '저장된 관찰 메모가 없습니다.\n종목 상세에서 확인할 내용을 기록해보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.5),
                    ),
                  ),
                ),
              )
            else
              ...notes.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ObservationNoteCard(
                    note: note,
                    onDelete: () => ref
                        .read(observationNotesProvider.notifier)
                        .delete(note.ticker),
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
        title: const Text('관찰 메모 전체 삭제'),
        content: const Text('이 기기에 저장된 모든 관찰 메모를 삭제할까요?'),
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
      await ref.read(observationNotesProvider.notifier).clearAll();
    }
  }
}

class _ObservationNoteCard extends StatelessWidget {
  final ObservationNote note;
  final VoidCallback onDelete;

  const _ObservationNoteCard({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final displayName = resolveInstrumentName(note.ticker, note.name);
    return GlassContainer(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/market/${note.ticker}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${note.ticker} · ${DateFormat('yyyy.MM.dd HH:mm').format(note.updatedAt)}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '메모 삭제',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white38,
                      size: 19,
                    ),
                  ),
                ],
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (note.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  note.text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalStorageNotice extends StatelessWidget {
  final String text;

  const _LocalStorageNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.phonelink_lock_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
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
