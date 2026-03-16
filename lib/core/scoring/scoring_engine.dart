import 'dart:math';

import '../../features/market/models/stock.dart';

// A simple class to hold the stock and its calculated score.
class ScoredStock {
  final Stock stock;
  final double score;
  final Map<String, double> normalizedScores;

  ScoredStock({
    required this.stock,
    required this.score,
    required this.normalizedScores,
  });
}

class ScoringEngine {
  // Calculates scores for a list of stocks based on metric weights.
  List<ScoredStock> calculateScores({
    required List<Stock> stocks,
    required Map<String, double> weights,
  }) {
    if (stocks.isEmpty) {
      return [];
    }

    // --- 1. Data Validation and Pre-processing ---
    // Handle invalid data as per requirements (PER <= 0, ROE is null -> treat as worst)
    final List<double> validPerValues = [];
    for (final stock in stocks) {
      final per = stock.per;
      if (per != null && per > 0) {
        validPerValues.add(per);
      }
    }
    final List<double> validRoeValues = [];
    for (final stock in stocks) {
      final roe = stock.roe;
      if (roe != null) {
        validRoeValues.add(roe);
      }
    }

    final List<double> validDivValues = [];
    for (final stock in stocks) {
      final div = stock.dividendYield;
      if (div != null && div > 0) {
        validDivValues.add(div);
      }
    }

    final minPer = validPerValues.isEmpty ? 0.0 : validPerValues.reduce(min);
    final maxPer = validPerValues.isEmpty ? 0.0 : validPerValues.reduce(max);
    final minRoe = validRoeValues.isEmpty ? 0.0 : validRoeValues.reduce(min);
    final maxRoe = validRoeValues.isEmpty ? 0.0 : validRoeValues.reduce(max);
    final minDiv = validDivValues.isEmpty ? 0.0 : validDivValues.reduce(min);
    final maxDiv = validDivValues.isEmpty ? 0.0 : validDivValues.reduce(max);

    final List<ScoredStock> scoredStocks = [];

    for (final stock in stocks) {
      final normalizedScores = <String, double>{};

      // --- 2. Min-Max Scaling (Normalization) ---

      // PER: Lower is better. Score is 0 if per is null or <= 0.
      double perScore = 0.0;
      final currentPer = stock.per;
      if (currentPer != null && currentPer > 0) {
        // Avoid division by zero if all values are the same
        if (maxPer - minPer != 0) {
          perScore = (maxPer - currentPer) / (maxPer - minPer) * 100;
        } else {
          perScore = 50.0; // or 100.0, or 0.0; depends on desired behavior for single/uniform values
        }
      }
      normalizedScores['per'] = perScore;

      // ROE: Higher is better. Score is 0 if roe is null.
      double roeScore = 0.0;
      final currentRoe = stock.roe;
      if (currentRoe != null) {
        if (maxRoe - minRoe != 0) {
          roeScore = (currentRoe - minRoe) / (maxRoe - minRoe) * 100;
        } else {
          roeScore = 50.0;
        }
      }
      normalizedScores['roe'] = roeScore;

      // Dividend: Higher is better. Score is 0 if null or <= 0.
      double divScore = 0.0;
      final currentDiv = stock.dividendYield;
      if (currentDiv != null && currentDiv > 0) {
        if (maxDiv - minDiv != 0) {
          divScore = (currentDiv - minDiv) / (maxDiv - minDiv) * 100;
        } else {
          divScore = 50.0;
        }
      }
      normalizedScores['dividend'] = divScore;

      // --- 3. Weighted Sum ---
      double totalScore = 0.0;
      weights.forEach((metric, weight) {
        totalScore += (normalizedScores[metric] ?? 0.0) * weight;
      });

      scoredStocks.add(ScoredStock(
        stock: stock,
        score: totalScore,
        normalizedScores: normalizedScores,
      ));
    }

    // --- 4. Sort by Score ---
    scoredStocks.sort((a, b) => b.score.compareTo(a.score));
    
    return scoredStocks;
  }
}