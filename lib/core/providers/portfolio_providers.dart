import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strategy_workbench/core/network/database_helper.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'package:strategy_workbench/features/portfolio/domain/services/portfolio_service.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart'
    as strategy;
import 'dart:developer' as developer;

const portfolioSnapshotStorageKey = 'portfolio_snapshot_v1';

// ── 포트폴리오 아이템 모델 ──
class PortfolioItem {
  final String ticker;
  final String name;
  final double quantity;
  final double avgPrice;
  final double currentPrice;

  const PortfolioItem({
    required this.ticker,
    required this.name,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
  });

  double get totalCost => quantity * avgPrice;
  double get currentValue => quantity * currentPrice;
  double get gainLoss => currentValue - totalCost;
  double get gainLossPercent =>
      totalCost > 0 ? (gainLoss / totalCost * 100) : 0;

  PortfolioItem copyWith({
    String? ticker,
    String? name,
    double? quantity,
    double? avgPrice,
    double? currentPrice,
  }) {
    return PortfolioItem(
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      avgPrice: avgPrice ?? this.avgPrice,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'name': name,
        'quantity': quantity,
        'avgPrice': avgPrice,
        'currentPrice': currentPrice,
      };

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      ticker: json['ticker'] as String,
      name: json['name'] as String? ?? json['ticker'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      avgPrice: (json['avgPrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
    );
  }
}

// ── 포트폴리오 상태 관리 ──
class PortfolioNotifier extends Notifier<List<PortfolioItem>> {
  @override
  List<PortfolioItem> build() {
    final initial = _loadFromStorage();
    unawaited(syncFromTransactions());
    return initial;
  }

  List<PortfolioItem> _loadFromStorage() {
    try {
      if (!Hive.isBoxOpen('settings')) {
        return [];
      }

      final settings = Hive.box('settings');
      final raw = settings.get(portfolioSnapshotStorageKey);
      if (raw is! String || raw.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => PortfolioItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Failed to load portfolio snapshot: $e',
        name: 'PortfolioNotifier',
      );
      return [];
    }
  }

  Future<void> syncFromTransactions() async {
    try {
      final transactions = await DatabaseHelper.instance.readAllTransactions();
      final rebuilt = buildPortfolioFromTransactions(
        transactions,
        existingItems: state,
        cachedStocks: _readCachedStocks(),
      );

      if (!_samePortfolio(state, rebuilt)) {
        state = rebuilt;
      }

      await _persistPortfolioState();
      developer.log(
        'Portfolio rebuilt from ${transactions.length} transactions: ${rebuilt.length} holdings',
        name: 'PortfolioNotifier',
      );
    } catch (e) {
      developer.log(
        'Failed to rebuild portfolio from transactions: $e',
        name: 'PortfolioNotifier',
      );
    }
  }

  Map<String, strategy.Stock> _readCachedStocks() {
    final stocks = <String, strategy.Stock>{};
    if (!Hive.isBoxOpen('stock_cache')) {
      return stocks;
    }

    final stockCache = Hive.box('stock_cache');
    for (final key in stockCache.keys) {
      final value = stockCache.get(key);
      if (value is strategy.Stock) {
        stocks[value.ticker.toUpperCase()] = value;
      }
    }
    return stocks;
  }

  /// 매수 (추가 매수 시 평단가 자동 계산)
  void buy(String ticker, String name, int quantity, double price) {
    final normalizedTicker = ticker.trim().toUpperCase();
    final normalizedName = name.trim().isEmpty ? normalizedTicker : name.trim();
    final existing = state
        .indexWhere((item) => item.ticker.toUpperCase() == normalizedTicker);

    if (existing >= 0) {
      // 추가 매수 → 평단가 재계산
      final item = state[existing];
      final portfolioService = PortfolioService();
      final newAvgPrice = portfolioService.calculateAveragePrice(
        existingQuantity: item.quantity.toInt(),
        existingAveragePrice: item.avgPrice,
        newQuantity: quantity,
        newPrice: price,
      );

      state = [
        ...state.sublist(0, existing),
        PortfolioItem(
          ticker: normalizedTicker,
          name: item.name,
          quantity: item.quantity + quantity,
          avgPrice: newAvgPrice,
          currentPrice: item.currentPrice,
        ),
        ...state.sublist(existing + 1),
      ];
    } else {
      // 신규 매수
      state = [
        ...state,
        PortfolioItem(
          ticker: normalizedTicker,
          name: normalizedName,
          quantity: quantity.toDouble(),
          avgPrice: price,
          currentPrice: price,
        ),
      ];
    }

    developer.log('BUY: $normalizedTicker x$quantity @ $price',
        name: 'PortfolioNotifier');
    _syncPortfolioToHive();
  }

  /// 매도
  void sell(String ticker, int quantity) {
    final normalizedTicker = ticker.trim().toUpperCase();
    final existing = state.indexWhere(
      (item) => item.ticker.toUpperCase() == normalizedTicker,
    );
    if (existing < 0) return;

    final item = state[existing];
    final remainingQty = item.quantity - quantity;

    if (remainingQty <= 0) {
      state = state
          .where((item) => item.ticker.toUpperCase() != normalizedTicker)
          .toList();
    } else {
      state = [
        ...state.sublist(0, existing),
        PortfolioItem(
          ticker: item.ticker,
          name: item.name,
          quantity: remainingQty,
          avgPrice: item.avgPrice,
          currentPrice: item.currentPrice,
        ),
        ...state.sublist(existing + 1),
      ];
    }

    developer.log(
      'SELL: $normalizedTicker x$quantity',
      name: 'PortfolioNotifier',
    );
    _syncPortfolioToHive();
  }

  /// 포트폴리오 티커 목록을 Hive settings에 저장 (BackgroundService용)
  void _syncPortfolioToHive() {
    unawaited(_persistPortfolioState());
  }

  Future<void> _persistPortfolioState() async {
    try {
      final tickers = state.map((item) => item.ticker).toList();
      if (!Hive.isBoxOpen('settings')) {
        return;
      }

      final settings = Hive.box('settings');
      await settings.put('portfolio_tickers', tickers);
      await settings.put(
        portfolioSnapshotStorageKey,
        jsonEncode(state.map((item) => item.toJson()).toList()),
      );
      developer.log('Synced portfolio tickers to Hive: $tickers',
          name: 'PortfolioNotifier');
    } catch (e) {
      developer.log('Failed to sync portfolio to Hive: $e',
          name: 'PortfolioNotifier');
    }
  }

  /// 현재가 업데이트
  void updatePrice(String ticker, double newPrice) {
    final normalizedTicker = ticker.trim().toUpperCase();
    state = state.map((item) {
      if (item.ticker.toUpperCase() == normalizedTicker) {
        return PortfolioItem(
          ticker: normalizedTicker,
          name: item.name,
          quantity: item.quantity,
          avgPrice: item.avgPrice,
          currentPrice: newPrice,
        );
      }
      return item;
    }).toList();
    _syncPortfolioToHive();
  }
}

final portfolioProvider =
    NotifierProvider<PortfolioNotifier, List<PortfolioItem>>(
  PortfolioNotifier.new,
);

// ── 거래 내역 (SQLite 연동) ──
class TransactionHistoryNotifier
    extends AsyncNotifier<List<model.Transaction>> {
  @override
  Future<List<model.Transaction>> build() async {
    try {
      final db = DatabaseHelper.instance;
      return await db.readAllTransactions();
    } catch (e) {
      developer.log('Error loading transactions: $e',
          name: 'TransactionHistoryNotifier');
      return [];
    }
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    try {
      final db = DatabaseHelper.instance;
      final created = await db.create(transaction);
      state = AsyncData([...(state.value ?? []), created]);
      await ref.read(portfolioProvider.notifier).syncFromTransactions();
      developer.log(
          'Transaction added: ${transaction.type} ${transaction.ticker}',
          name: 'TransactionHistoryNotifier');
    } catch (e) {
      developer.log('Error adding transaction: $e',
          name: 'TransactionHistoryNotifier');
    }
  }
}

final transactionHistoryProvider =
    AsyncNotifierProvider<TransactionHistoryNotifier, List<model.Transaction>>(
  TransactionHistoryNotifier.new,
);

// ── 포트폴리오 요약 (계산된 값) ──
final portfolioSummaryProvider = Provider<Map<String, double>>((ref) {
  final portfolio = ref.watch(portfolioProvider);

  final totalCost =
      portfolio.fold<double>(0, (sum, item) => sum + item.totalCost);
  final totalValue =
      portfolio.fold<double>(0, (sum, item) => sum + item.currentValue);
  final gainLoss = totalValue - totalCost;
  final gainLossPercent = totalCost > 0 ? (gainLoss / totalCost * 100) : 0.0;

  return {
    'totalCost': totalCost,
    'totalValue': totalValue,
    'gainLoss': gainLoss,
    'gainLossPercent': gainLossPercent,
    'stockCount': portfolio.length.toDouble(),
  };
});

List<PortfolioItem> buildPortfolioFromTransactions(
  List<model.Transaction> transactions, {
  List<PortfolioItem> existingItems = const [],
  Map<String, strategy.Stock> cachedStocks = const {},
}) {
  final portfolioService = PortfolioService();
  final holdings = <String, PortfolioItem>{};
  final knownNames = <String, String>{
    for (final item in existingItems) item.ticker.toUpperCase(): item.name,
  };
  final knownPrices = <String, double>{
    for (final item in existingItems)
      item.ticker.toUpperCase(): item.currentPrice,
  };

  for (final entry in cachedStocks.entries) {
    knownNames.putIfAbsent(entry.key, () => entry.value.name);
    knownPrices[entry.key] = entry.value.price;
  }

  final ordered = [...transactions]
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  for (final tx in ordered) {
    final ticker = tx.ticker.trim().toUpperCase();
    if (ticker.isEmpty) {
      continue;
    }

    final currentPrice = knownPrices[ticker] ?? tx.price;
    final name = knownNames[ticker] ?? ticker;
    final existing = holdings[ticker];

    if (tx.type == model.TransactionType.BUY) {
      if (existing == null) {
        holdings[ticker] = PortfolioItem(
          ticker: ticker,
          name: name,
          quantity: tx.quantity.toDouble(),
          avgPrice: tx.price,
          currentPrice: currentPrice,
        );
      } else {
        final newAvgPrice = portfolioService.calculateAveragePrice(
          existingQuantity: existing.quantity.toInt(),
          existingAveragePrice: existing.avgPrice,
          newQuantity: tx.quantity,
          newPrice: tx.price,
        );
        holdings[ticker] = existing.copyWith(
          name: name,
          quantity: existing.quantity + tx.quantity,
          avgPrice: newAvgPrice,
          currentPrice: currentPrice,
        );
      }
      continue;
    }

    if (existing == null) {
      continue;
    }

    final remainingQuantity = existing.quantity - tx.quantity;
    if (remainingQuantity <= 0) {
      holdings.remove(ticker);
      continue;
    }

    holdings[ticker] = existing.copyWith(
      name: name,
      quantity: remainingQuantity,
      currentPrice: currentPrice,
    );
  }

  return holdings.values
      .map((item) => item.copyWith(
            name: knownNames[item.ticker.toUpperCase()] ?? item.name,
            currentPrice:
                knownPrices[item.ticker.toUpperCase()] ?? item.currentPrice,
          ))
      .toList()
    ..sort((a, b) => a.ticker.compareTo(b.ticker));
}

bool _samePortfolio(List<PortfolioItem> a, List<PortfolioItem> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i].ticker != b[i].ticker ||
        a[i].name != b[i].name ||
        a[i].quantity != b[i].quantity ||
        a[i].avgPrice != b[i].avgPrice ||
        a[i].currentPrice != b[i].currentPrice) {
      return false;
    }
  }

  return true;
}
