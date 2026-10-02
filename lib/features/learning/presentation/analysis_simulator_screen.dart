import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/analysis_simulator_providers.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/learning_records_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class AnalysisSimulatorScreen extends ConsumerStatefulWidget {
  final String? initialStrategyName;
  final MarketFilter initialMarketFilter;

  const AnalysisSimulatorScreen({
    super.key,
    this.initialStrategyName,
    this.initialMarketFilter = MarketFilter.hybrid,
  });

  @override
  ConsumerState<AnalysisSimulatorScreen> createState() =>
      _AnalysisSimulatorScreenState();
}

class _AnalysisSimulatorScreenState
    extends ConsumerState<AnalysisSimulatorScreen> {
  String? _strategyName;
  late MarketFilter _marketFilter;
  double _perWeight = 50;
  double _roeWeight = 50;
  double _dividendWeight = 0;
  int _appliedPerWeight = 50;
  int _appliedRoeWeight = 50;
  int _appliedDividendWeight = 0;
  String? _loadedStrategyName;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _strategyName = widget.initialStrategyName;
    _marketFilter = widget.initialMarketFilter;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _loadStrategy(SavedFilter strategy) {
    final per = (strategy.weights['per'] ?? 0) * 100;
    final roe = (strategy.weights['roe'] ?? 0) * 100;
    final dividend = (strategy.weights['dividend'] ?? 0) * 100;
    setState(() {
      _strategyName = strategy.name;
      _loadedStrategyName = strategy.name;
      _perWeight = per;
      _roeWeight = roe;
      _dividendWeight = dividend;
      _appliedPerWeight = per.round();
      _appliedRoeWeight = roe.round();
      _appliedDividendWeight = dividend.round();
    });
  }

  void _scheduleSimulation() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _appliedPerWeight = _perWeight.round();
        _appliedRoeWeight = _roeWeight.round();
        _appliedDividendWeight = _dividendWeight.round();
      });
    });
  }

  void _updateWeight(String metric, double value) {
    setState(() {
      switch (metric) {
        case 'per':
          _perWeight = value;
        case 'roe':
          _roeWeight = value;
        case 'dividend':
          _dividendWeight = value;
      }
    });
    _scheduleSimulation();
  }

  @override
  Widget build(BuildContext context) {
    final strategies = ref.watch(allStrategiesProvider);
    final activeStrategy = ref.watch(activeStrategyProvider);
    final selected = _resolveSelectedStrategy(strategies, activeStrategy);

    if (selected != null && _loadedStrategyName != selected.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedStrategyName != selected.name) {
          _loadStrategy(selected);
        }
      });
    }

    final total = _perWeight + _roeWeight + _dividendWeight;
    final request = selected == null || total <= 0
        ? null
        : AnalysisSimulationRequest(
            strategyName: selected.name,
            marketFilter: _marketFilter,
            perWeight: _appliedPerWeight,
            roeWeight: _appliedRoeWeight,
            dividendWeight: _appliedDividendWeight,
            sampleCount: selected.topN,
          );
    final simulation =
        request == null ? null : ref.watch(analysisSimulationProvider(request));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('분석 기준 실험실'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: '저장한 실험 기록',
            onPressed: () => context.push('/analysis-history'),
            icon: const Icon(Icons.history_edu_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IntroCard(sampleCount: selected?.topN ?? 10),
            const SizedBox(height: 16),
            if (selected != null)
              _ControlsCard(
                strategies: strategies,
                selected: selected,
                marketFilter: _marketFilter,
                perWeight: _perWeight,
                roeWeight: _roeWeight,
                dividendWeight: _dividendWeight,
                onStrategyChanged: (name) {
                  final strategy =
                      strategies.where((item) => item.name == name).firstOrNull;
                  if (strategy != null) {
                    _loadStrategy(strategy);
                  }
                },
                onMarketChanged: (filter) {
                  setState(() {
                    _marketFilter = filter;
                  });
                },
                onWeightChanged: _updateWeight,
                onReset: () => _loadStrategy(selected),
              )
            else
              const _EmptyCard(message: '사용할 분석 기준이 없습니다.'),
            const SizedBox(height: 16),
            if (total <= 0)
              const _EmptyCard(message: '하나 이상의 지표 가중치를 설정해주세요.')
            else if (simulation != null)
              simulation.when(
                loading: () => const _LoadingCard(),
                error: (error, stackTrace) => const _EmptyCard(
                  message: '실험 결과를 계산하지 못했습니다. 잠시 후 다시 시도해주세요.',
                ),
                data: (result) => result == null
                    ? const _EmptyCard(message: '비교할 샘플 데이터가 없습니다.')
                    : _SimulationResultView(
                        result: result,
                        onSave: () async {
                          await ref.read(analysisHistoryProvider.notifier).add(
                                result: result,
                                marketFilter: _marketFilter,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('실험 기록을 이 기기에 저장했습니다.'),
                              ),
                            );
                          }
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  SavedFilter? _resolveSelectedStrategy(
    List<SavedFilter> strategies,
    SavedFilter? activeStrategy,
  ) {
    final requested = _strategyName;
    if (requested != null) {
      final match =
          strategies.where((item) => item.name == requested).firstOrNull;
      if (match != null) {
        return match;
      }
    }
    return activeStrategy ?? strategies.firstOrNull;
  }
}

class _IntroCard extends StatelessWidget {
  final int sampleCount;

  const _IntroCard({required this.sampleCount});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '가중치를 바꾸면 무엇이 달라질까요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '저장된 기준과 임시 실험값으로 계산한 상위 $sampleCount개 샘플을 나란히 비교합니다. 실험값은 저장되거나 현재 기준에 반영되지 않습니다.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final List<SavedFilter> strategies;
  final SavedFilter selected;
  final MarketFilter marketFilter;
  final double perWeight;
  final double roeWeight;
  final double dividendWeight;
  final ValueChanged<String> onStrategyChanged;
  final ValueChanged<MarketFilter> onMarketChanged;
  final void Function(String metric, double value) onWeightChanged;
  final VoidCallback onReset;

  const _ControlsCard({
    required this.strategies,
    required this.selected,
    required this.marketFilter,
    required this.perWeight,
    required this.roeWeight,
    required this.dividendWeight,
    required this.onStrategyChanged,
    required this.onMarketChanged,
    required this.onWeightChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final total = perWeight + roeWeight + dividendWeight;
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '실험 조건',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('초기화'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selected.name,
              dropdownColor: const Color(0xFF1E293B),
              decoration: const InputDecoration(
                labelText: '기준값',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF10B981)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              items: strategies
                  .map(
                    (strategy) => DropdownMenuItem(
                      value: strategy.name,
                      child: Text(strategy.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onStrategyChanged(value);
                }
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MarketFilter.values
                  .map(
                    (filter) => ChoiceChip(
                      label: Text(marketFilterLabel(filter)),
                      selected: marketFilter == filter,
                      onSelected: (_) => onMarketChanged(filter),
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFF111827),
                      side: BorderSide(
                        color: marketFilter == filter
                            ? const Color(0xFF10B981)
                            : const Color(0xFF334155),
                      ),
                      labelStyle: TextStyle(
                        color: marketFilter == filter
                            ? Colors.white
                            : Colors.white60,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _WeightSlider(
              label: 'PER',
              hint: '낮을수록 상대 점수가 높아집니다.',
              value: perWeight,
              onChanged: (value) => onWeightChanged('per', value),
            ),
            _WeightSlider(
              label: 'ROE',
              hint: '높을수록 상대 점수가 높아집니다.',
              value: roeWeight,
              onChanged: (value) => onWeightChanged('roe', value),
            ),
            _WeightSlider(
              label: '배당',
              hint: '높을수록 상대 점수가 높아집니다.',
              value: dividendWeight,
              onChanged: (value) => onWeightChanged('dividend', value),
            ),
            const SizedBox(height: 6),
            Text(
              total > 0
                  ? '입력 합계 ${total.round()}% · 계산 시 100% 기준으로 자동 환산됩니다.'
                  : '입력 합계 0% · 하나 이상의 지표를 선택해주세요.',
              style: TextStyle(
                color: total > 0 ? Colors.white54 : const Color(0xFFFB923C),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final String hint;
  final double value;
  final ValueChanged<double> onChanged;

  const _WeightSlider({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
              Text(
                '${value.round()}%',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: const Color(0xFF10B981),
            inactiveColor: const Color(0xFF334155),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SimulationResultView extends StatelessWidget {
  final AnalysisSimulationResult result;
  final VoidCallback onSave;

  const _SimulationResultView({
    required this.result,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '기준 대비 변화',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryMetric(
                        label: '공통 샘플',
                        value: result.overlapCount,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryMetric(
                        label: '새 진입',
                        value: result.enteredCount,
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryMetric(
                        label: '기준 이탈',
                        value: result.exitedCount,
                        color: const Color(0xFFFB923C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...const ['per', 'roe', 'dividend'].map(
                  (metric) => _WeightDeltaRow(
                    metric: metric,
                    before: result.baselineWeights[metric] ?? 0,
                    after: result.simulatedWeights[metric] ?? 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (result.biggestMovers.isNotEmpty) ...[
          const Text(
            '순위 변화가 큰 샘플',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: result.biggestMovers
                    .map((stock) => _SimulationStockRow(stock: stock))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '실험 결과 · 상위 ${result.simulatedTop.length}개',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: result.simulatedTop
                  .map((stock) => _SimulationStockRow(stock: stock))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('실험 기록 저장'),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '가중치에 따른 상대 비교 실험이며 특정 종목의 매수·매도를 권유하지 않습니다.',
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightDeltaRow extends StatelessWidget {
  final String metric;
  final double before;
  final double after;

  const _WeightDeltaRow({
    required this.metric,
    required this.before,
    required this.after,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              _metricLabel(metric),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: after.clamp(0, 1),
                minHeight: 7,
                backgroundColor: const Color(0xFF1E293B),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(
              '${(before * 100).round()}% → ${(after * 100).round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationStockRow extends StatelessWidget {
  final AnalysisSimulationStock stock;

  const _SimulationStockRow({required this.stock});

  @override
  Widget build(BuildContext context) {
    final change = stock.rankChange;
    final accent = change > 0
        ? const Color(0xFF10B981)
        : change < 0
            ? const Color(0xFFFB923C)
            : Colors.white38;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/market/${stock.ticker}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '#${stock.simulatedRank}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name.isEmpty ? stock.ticker : stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${stock.ticker} · 기준 #${stock.baselineRank} → 실험 #${stock.simulatedRank}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _priceLabel(stock),
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  Text(
                    change == 0
                        ? '변화 없음'
                        : change > 0
                            ? '${change.abs()}계단 상승'
                            : '${change.abs()}계단 하락',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priceLabel(AnalysisSimulationStock stock) {
    final isKorean = RegExp(r'^\d{6}$').hasMatch(stock.ticker);
    if (isKorean) {
      return '₩${NumberFormat('#,##0').format(stock.price)}';
    }
    return '\$${stock.price.toStringAsFixed(2)}';
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, height: 1.4),
          ),
        ),
      ),
    );
  }
}

String _metricLabel(String metric) {
  switch (metric) {
    case 'per':
      return 'PER';
    case 'roe':
      return 'ROE';
    case 'dividend':
      return '배당';
    default:
      return metric;
  }
}
