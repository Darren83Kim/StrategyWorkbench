import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/providers/filter_providers.dart';
import 'package:strategy_workbench/core/providers/snapshot_providers.dart';
import 'package:strategy_workbench/core/services/alert_runtime_service.dart';
import 'package:strategy_workbench/core/services/ad_service.dart';
import 'package:strategy_workbench/shared/widgets/glass_container.dart';

class FilterCreationScreen extends ConsumerStatefulWidget {
  final SavedFilter? initialFilter;

  const FilterCreationScreen({super.key, this.initialFilter});

  @override
  ConsumerState<FilterCreationScreen> createState() =>
      _FilterCreationScreenState();
}

class _FilterCreationScreenState extends ConsumerState<FilterCreationScreen> {
  late TextEditingController _nameController;
  double _perWeight = 0.5;
  double _roeWeight = 0.5;
  double _dividendWeight = 0.0;
  int _topN = 10;
  String _sensitivity = 'Medium';
  bool _isSaving = false;

  static const _topNOptions = [5, 10, 20, 30, 50];
  static const _sensitivityOptions = {
    'High': 'High · 상위 10%',
    'Medium': 'Medium · 상위 20%',
    'Low': 'Low · 상위 30%',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilter;
    _nameController = TextEditingController(
      text: initial?.name ?? '내 전략',
    );
    if (initial != null) {
      _perWeight = initial.weights['per'] ?? 0.5;
      _roeWeight = initial.weights['roe'] ?? 0.5;
      _dividendWeight = initial.weights['dividend'] ?? 0.0;
      _topN = initial.topN;
      _sensitivity = initial.sensitivity;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(SavedFilter preset) {
    setState(() {
      _perWeight = preset.weights['per'] ?? 0.0;
      _roeWeight = preset.weights['roe'] ?? 0.0;
      _dividendWeight = preset.weights['dividend'] ?? 0.0;
      _topN = preset.topN;
      _sensitivity = preset.sensitivity;
      _nameController.text = preset.name;
    });
  }

  Future<void> _saveFilter() async {
    if (_isSaving) {
      return;
    }

    final filterName = _nameController.text.trim();
    if (filterName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('전략 이름을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final weights = <String, double>{
        'per': _perWeight,
        'roe': _roeWeight,
        if (_dividendWeight > 0) 'dividend': _dividendWeight,
      };

      final filter = SavedFilter(
        name: filterName,
        weights: weights,
        topN: _topN,
        sensitivity: _sensitivity,
      );

      final previousName = widget.initialFilter?.name;
      await ref.read(savedFiltersProvider.notifier).upsertFilter(
            filter,
            previousName: previousName,
          );
      await ref
          .read(activeStrategyNameProvider.notifier)
          .setActive(filter.name);
      unawaited(
        ref
            .read(alertRuntimeServiceProvider)
            .syncForStrategy(strategyName: filter.name),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('snap_v1_${filter.name.replaceAll(' ', '_')}');
      ref.invalidate(strategySnapshotProvider(filter.name));

      if (previousName != null && previousName != filter.name) {
        await prefs.remove('snap_v1_${previousName.replaceAll(' ', '_')}');
        ref.invalidate(strategySnapshotProvider(previousName));
      }

      developer.log(
        'Filter saved: $filterName  topN=$_topN  sensitivity=$_sensitivity  PER=$_perWeight ROE=$_roeWeight DIV=$_dividendWeight',
        name: 'FilterCreationScreen',
      );

      await AdService().loadAndShowInterstitial(
        onContinue: () {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${filter.name} 전략이 저장되고 활성 전략으로 설정됐습니다.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialFilter != null;
    final totalWeight = _perWeight + _roeWeight + _dividendWeight;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(isEditing ? '전략 수정' : '전략 만들기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: '전략 이름',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.bookmark, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '프리셋 빠른 적용',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetStrategies
                  .map(
                    (preset) => ElevatedButton(
                      onPressed: () => _applyPreset(preset),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(preset.name),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              '가중치 설정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'PER (낮을수록 유리)',
              value: _perWeight,
              onChanged: (value) => setState(() => _perWeight = value),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'ROE (높을수록 유리)',
              value: _roeWeight,
              onChanged: (value) => setState(() => _roeWeight = value),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: '배당 수익률',
              value: _dividendWeight,
              onChanged: (value) => setState(() => _dividendWeight = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '가중치 합계',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    totalWeight.toStringAsFixed(2),
                    style: TextStyle(
                      color: (totalWeight - 1.0).abs() < 0.01
                          ? const Color(0xFF10B981)
                          : totalWeight > 1.0
                              ? Colors.red
                              : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '검색 종목 수 (Top N)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _topNOptions.map((option) {
                final selected = _topN == option;
                return ChoiceChip(
                  label: Text('Top $option'),
                  selected: selected,
                  onSelected: (_) => setState(() => _topN = option),
                  selectedColor: const Color(0xFF10B981),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF334155),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '알림 민감도',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sensitivityOptions.entries.map((entry) {
                final selected = _sensitivity == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _sensitivity = entry.key),
                  selectedColor: const Color(0xFF10B981),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF334155),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveFilter,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving
                    ? '처리 중...'
                    : isEditing
                        ? '수정 저장'
                        : '전략 저장'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
              divisions: 20,
              activeColor: const Color(0xFF10B981),
              inactiveColor: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }
}
