import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const savedFiltersStorageKey = 'saved_filters';
const activeStrategyNameStorageKey = 'active_strategy_name';
const watchlistStorageKey = 'strategy_watchlist_v1';

// ── 저장된 필터 모델 ──
class SavedFilter {
  final String name;
  final Map<String, double> weights;
  final DateTime createdAt;
  final int topN;
  final String sensitivity;
  final bool isPreset;

  SavedFilter({
    required this.name,
    required this.weights,
    DateTime? createdAt,
    this.topN = 10,
    this.sensitivity = 'Medium',
    this.isPreset = false,
  }) : createdAt = createdAt ?? DateTime.now();

  SavedFilter copyWith({
    String? name,
    Map<String, double>? weights,
    int? topN,
    String? sensitivity,
  }) {
    return SavedFilter(
      name: name ?? this.name,
      weights: weights ?? Map<String, double>.from(this.weights),
      createdAt: createdAt,
      topN: topN ?? this.topN,
      sensitivity: sensitivity ?? this.sensitivity,
      isPreset: isPreset,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'weights': weights,
        'createdAt': createdAt.toIso8601String(),
        'topN': topN,
        'sensitivity': sensitivity,
        'isPreset': isPreset,
      };

  factory SavedFilter.fromJson(Map<String, dynamic> json) {
    return SavedFilter(
      name: json['name'] as String,
      weights: Map<String, double>.from(json['weights'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      topN: (json['topN'] as int?) ?? 10,
      sensitivity: json['sensitivity'] as String? ?? 'Medium',
      isPreset: (json['isPreset'] as bool?) ?? false,
    );
  }
}

// ── 기본 프리셋 전략 ──
final presetStrategies = [
  SavedFilter(
    name: '가치주',
    weights: {'per': 0.70, 'roe': 0.30},
    topN: 10,
    isPreset: true,
  ),
  SavedFilter(
    name: '배당주',
    weights: {'per': 0.20, 'roe': 0.20, 'dividend': 0.60},
    topN: 10,
    isPreset: true,
  ),
  SavedFilter(
    name: '퀀트',
    weights: {'per': 0.34, 'roe': 0.33, 'dividend': 0.33},
    topN: 10,
    isPreset: true,
  ),
  SavedFilter(
    name: '급등주',
    weights: {'roe': 0.80, 'per': 0.20},
    topN: 10,
    isPreset: true,
  ),
];

// ── 저장된 필터 목록 관리 (SharedPreferences) ──
class SavedFiltersNotifier extends AsyncNotifier<List<SavedFilter>> {
  @override
  Future<List<SavedFilter>> build() async {
    return await _loadFromStorage();
  }

  Future<List<SavedFilter>> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(savedFiltersStorageKey);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((j) => SavedFilter.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error loading filters: $e', name: 'SavedFiltersNotifier');
      return [];
    }
  }

  Future<void> _saveToStorage(List<SavedFilter> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(filters.map((f) => f.toJson()).toList());
      await prefs.setString(savedFiltersStorageKey, jsonString);
    } catch (e) {
      developer.log('Error saving filters: $e', name: 'SavedFiltersNotifier');
    }
  }

  Future<void> upsertFilter(
    SavedFilter filter, {
    String? previousName,
  }) async {
    final current = state.value ?? [];
    final updated = [
      ...current.where(
        (f) => f.name != filter.name && f.name != previousName,
      ),
      filter,
    ];
    state = AsyncData(updated);
    await _saveToStorage(updated);
    developer.log('Filter saved: ${filter.name}', name: 'SavedFiltersNotifier');
  }

  Future<void> addFilter(SavedFilter filter) async {
    await upsertFilter(filter);
  }

  Future<void> removeFilter(String name) async {
    final current = state.value ?? [];
    final updated = current.where((f) => f.name != name).toList();
    state = AsyncData(updated);
    await _saveToStorage(updated);
    developer.log('Filter removed: $name', name: 'SavedFiltersNotifier');
  }

  Future<void> updateTopN(String filterName, int topN) async {
    final current = state.value ?? [];
    if (current.any((f) => f.name == filterName)) {
      final updated = current
          .map((f) => f.name == filterName ? f.copyWith(topN: topN) : f)
          .toList();
      state = AsyncData(updated);
      await _saveToStorage(updated);
    } else {
      final preset = presetStrategies.firstWhere(
        (p) => p.name == filterName,
        orElse: () => SavedFilter(name: filterName, weights: {}),
      );
      await addFilter(preset.copyWith(topN: topN));
    }
  }
}

final savedFiltersProvider =
    AsyncNotifierProvider<SavedFiltersNotifier, List<SavedFilter>>(
  SavedFiltersNotifier.new,
);

// ── 전체 전략 목록 (프리셋 + 커스텀) ──
// 커스텀에 같은 이름이 있으면 커스텀이 프리셋을 대체
final allStrategiesProvider = Provider<List<SavedFilter>>((ref) {
  final custom = ref.watch(savedFiltersProvider).value ?? [];
  final customNames = custom.map((f) => f.name).toSet();
  final filteredPresets =
      presetStrategies.where((p) => !customNames.contains(p.name)).toList();
  return [...filteredPresets, ...custom];
});

// ── 관심 종목 (전략별 ★ 체크된 종목) ──
class WatchlistNotifier extends AsyncNotifier<Map<String, Set<String>>> {
  @override
  Future<Map<String, Set<String>>> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(watchlistStorageKey);
      if (json == null) return {};
      final Map<String, dynamic> raw = jsonDecode(json);
      return raw.map(
        (k, v) => MapEntry(k, Set<String>.from((v as List).cast<String>())),
      );
    } catch (e) {
      developer.log('Error loading watchlist: $e', name: 'WatchlistNotifier');
      return {};
    }
  }

  Future<void> toggle(String strategyName, String ticker) async {
    final current = (state.value ?? {}).map(
      (k, v) => MapEntry(k, Set<String>.from(v)),
    );
    final watches = current[strategyName] ?? <String>{};
    if (watches.contains(ticker)) {
      watches.remove(ticker);
    } else {
      watches.add(ticker);
    }
    current[strategyName] = watches;
    state = AsyncData(current);
    await _persist(current);
    developer.log(
      'Watchlist toggled: $strategyName / $ticker',
      name: 'WatchlistNotifier',
    );
  }

  Future<void> _persist(Map<String, Set<String>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = data.map((k, v) => MapEntry(k, v.toList()));
      await prefs.setString(watchlistStorageKey, jsonEncode(map));
    } catch (e) {
      developer.log('Error saving watchlist: $e', name: 'WatchlistNotifier');
    }
  }
}

final watchlistProvider =
    AsyncNotifierProvider<WatchlistNotifier, Map<String, Set<String>>>(
  WatchlistNotifier.new,
);

// ── 현재 활성 전략 이름 ──
class ActiveStrategyNameNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(activeStrategyNameStorageKey);
    } catch (e) {
      developer.log(
        'Error loading active strategy: $e',
        name: 'ActiveStrategyNameNotifier',
      );
      return null;
    }
  }

  Future<void> setActive(String? strategyName) async {
    state = AsyncData(strategyName);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (strategyName == null || strategyName.isEmpty) {
        await prefs.remove(activeStrategyNameStorageKey);
      } else {
        await prefs.setString(activeStrategyNameStorageKey, strategyName);
      }
    } catch (e) {
      developer.log(
        'Error saving active strategy: $e',
        name: 'ActiveStrategyNameNotifier',
      );
    }
  }
}

final activeStrategyNameProvider =
    AsyncNotifierProvider<ActiveStrategyNameNotifier, String?>(
  ActiveStrategyNameNotifier.new,
);

final activeStrategyProvider = Provider<SavedFilter?>((ref) {
  final activeName = ref.watch(activeStrategyNameProvider).value;
  if (activeName == null || activeName.isEmpty) {
    return null;
  }

  final strategies = ref.watch(allStrategiesProvider);
  return strategies.where((s) => s.name == activeName).firstOrNull;
});

// ── 현재 활성 필터 (호환성 유지) ──
final activeFilterProvider = Provider<SavedFilter?>((ref) {
  return ref.watch(activeStrategyProvider);
});

// ── 프리셋 맵 (filter_creation_screen 호환성 유지) ──
final presetsProvider = Provider<Map<String, Map<String, double>>>((ref) {
  return {for (final p in presetStrategies) p.name: p.weights};
});
