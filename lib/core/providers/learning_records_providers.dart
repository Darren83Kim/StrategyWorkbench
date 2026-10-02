import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strategy_workbench/core/market/market_classification.dart';
import 'package:strategy_workbench/core/providers/analysis_simulator_providers.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';

const observationNotesStorageKey = 'observation_notes_v1';
const analysisHistoryStorageKey = 'analysis_history_v1';
const maxObservationNoteLength = 300;
const maxAnalysisHistoryCount = 20;

class ObservationNote {
  final String ticker;
  final String name;
  final String text;
  final List<String> tags;
  final DateTime updatedAt;

  const ObservationNote({
    required this.ticker,
    required this.name,
    required this.text,
    required this.tags,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'text': text,
        'tags': tags,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ObservationNote.fromJson(Map<String, dynamic> json) {
    return ObservationNote(
      ticker: normalizeTickerInput(json['ticker'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      text: json['text'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ObservationNotesNotifier
    extends AsyncNotifier<Map<String, ObservationNote>> {
  @override
  Future<Map<String, ObservationNote>> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(observationNotesStorageKey);
      if (encoded == null || encoded.isEmpty) {
        return {};
      }
      final raw = jsonDecode(encoded) as Map<String, dynamic>;
      return raw.map(
        (ticker, value) => MapEntry(
          normalizeTickerInput(ticker),
          ObservationNote.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load observation notes: $error',
        name: 'ObservationNotesNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  Future<void> save({
    required String ticker,
    required String name,
    required String text,
    required Iterable<String> tags,
  }) async {
    final normalizedTicker = normalizeTickerInput(ticker);
    final trimmed = text.trim();
    if (normalizedTicker.isEmpty) {
      return;
    }
    if (trimmed.isEmpty && tags.isEmpty) {
      await delete(normalizedTicker);
      return;
    }

    final current = Map<String, ObservationNote>.from(state.value ?? {});
    current[normalizedTicker] = ObservationNote(
      ticker: normalizedTicker,
      name: name.trim(),
      text: trimmed.length > maxObservationNoteLength
          ? trimmed.substring(0, maxObservationNoteLength)
          : trimmed,
      tags: tags.toSet().take(4).toList(),
      updatedAt: DateTime.now(),
    );
    state = AsyncData(current);
    await _persist(current);
  }

  Future<void> delete(String ticker) async {
    final current = Map<String, ObservationNote>.from(state.value ?? {});
    current.remove(normalizeTickerInput(ticker));
    state = AsyncData(current);
    await _persist(current);
  }

  Future<void> clearAll() async {
    state = const AsyncData(<String, ObservationNote>{});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(observationNotesStorageKey);
  }

  Future<void> _persist(Map<String, ObservationNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      notes.map((ticker, note) => MapEntry(ticker, note.toJson())),
    );
    await prefs.setString(observationNotesStorageKey, encoded);
  }
}

final observationNotesProvider = AsyncNotifierProvider<ObservationNotesNotifier,
    Map<String, ObservationNote>>(
  ObservationNotesNotifier.new,
);

class AnalysisHistorySample {
  final String ticker;
  final String name;
  final int rank;

  const AnalysisHistorySample({
    required this.ticker,
    required this.name,
    required this.rank,
  });

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'rank': rank,
      };

  factory AnalysisHistorySample.fromJson(Map<String, dynamic> json) {
    return AnalysisHistorySample(
      ticker: normalizeTickerInput(json['ticker'] as String? ?? ''),
      name: json['name'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalysisHistoryEntry {
  final String id;
  final String strategyName;
  final MarketFilter marketFilter;
  final Map<String, double> weights;
  final List<AnalysisHistorySample> topSamples;
  final DateTime createdAt;

  const AnalysisHistoryEntry({
    required this.id,
    required this.strategyName,
    required this.marketFilter,
    required this.weights,
    required this.topSamples,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'strategyName': strategyName,
        'marketFilter': marketFilter.name,
        'weights': weights,
        'topSamples': topSamples.map((sample) => sample.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnalysisHistoryEntry.fromJson(Map<String, dynamic> json) {
    final marketName = json['marketFilter'] as String?;
    final market = MarketFilter.values
            .where((item) => item.name == marketName)
            .firstOrNull ??
        MarketFilter.hybrid;
    return AnalysisHistoryEntry(
      id: json['id'] as String? ?? '',
      strategyName: json['strategyName'] as String? ?? '',
      marketFilter: market,
      weights: (json['weights'] as Map? ?? const <String, dynamic>{}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
      topSamples: (json['topSamples'] as List<dynamic>? ?? const [])
          .map(
            (item) => AnalysisHistorySample.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AnalysisHistoryNotifier
    extends AsyncNotifier<List<AnalysisHistoryEntry>> {
  int _idSequence = 0;

  @override
  Future<List<AnalysisHistoryEntry>> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(analysisHistoryStorageKey);
      if (encoded == null || encoded.isEmpty) {
        return [];
      }
      final raw = jsonDecode(encoded) as List<dynamic>;
      final entries = raw
          .map(
            (item) => AnalysisHistoryEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries.take(maxAnalysisHistoryCount).toList();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load analysis history: $error',
        name: 'AnalysisHistoryNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<void> add({
    required AnalysisSimulationResult result,
    required MarketFilter marketFilter,
  }) async {
    final now = DateTime.now();
    final entry = AnalysisHistoryEntry(
      id: '${now.microsecondsSinceEpoch}-${_idSequence++}',
      strategyName: result.strategyName,
      marketFilter: marketFilter,
      weights: Map<String, double>.from(result.simulatedWeights),
      topSamples: result.simulatedTop
          .take(10)
          .map(
            (stock) => AnalysisHistorySample(
              ticker: stock.ticker,
              name: stock.name,
              rank: stock.simulatedRank,
            ),
          )
          .toList(),
      createdAt: now,
    );
    final updated = [entry, ...(state.value ?? const <AnalysisHistoryEntry>[])]
        .take(maxAnalysisHistoryCount)
        .toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final updated = (state.value ?? const <AnalysisHistoryEntry>[])
        .where((entry) => entry.id != id)
        .toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> clearAll() async {
    state = const AsyncData(<AnalysisHistoryEntry>[]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(analysisHistoryStorageKey);
  }

  Future<void> _persist(List<AnalysisHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      analysisHistoryStorageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}

final analysisHistoryProvider =
    AsyncNotifierProvider<AnalysisHistoryNotifier, List<AnalysisHistoryEntry>>(
  AnalysisHistoryNotifier.new,
);
