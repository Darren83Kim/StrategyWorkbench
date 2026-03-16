import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strategy_workbench/core/network/database_helper.dart';
import 'package:strategy_workbench/features/portfolio/domain/entities/transaction.dart'
    as model;
import 'package:strategy_workbench/features/portfolio/domain/services/portfolio_service.dart';
import 'dart:developer' as developer;

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
}

// ── 포트폴리오 상태 관리 ──
class PortfolioNotifier extends Notifier<List<PortfolioItem>> {
  @override
  List<PortfolioItem> build() => [];

  /// 매수 (추가 매수 시 평단가 자동 계산)
  void buy(String ticker, String name, int quantity, double price) {
    final existing = state.indexWhere((item) => item.ticker == ticker);

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
          ticker: item.ticker,
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
          ticker: ticker,
          name: name,
          quantity: quantity.toDouble(),
          avgPrice: price,
          currentPrice: price,
        ),
      ];
    }

    developer.log('BUY: $ticker x$quantity @ $price',
        name: 'PortfolioNotifier');
    _syncPortfolioToHive();
  }

  /// 매도
  void sell(String ticker, int quantity) {
    final existing = state.indexWhere((item) => item.ticker == ticker);
    if (existing < 0) return;

    final item = state[existing];
    final remainingQty = item.quantity - quantity;

    if (remainingQty <= 0) {
      state = state.where((i) => i.ticker != ticker).toList();
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

    developer.log('SELL: $ticker x$quantity', name: 'PortfolioNotifier');
    _syncPortfolioToHive();
  }

  /// 포트폴리오 티커 목록을 Hive settings에 저장 (BackgroundService용)
  void _syncPortfolioToHive() {
    try {
      final tickers = state.map((item) => item.ticker).toList();
      final settings = Hive.box('settings');
      settings.put('portfolio_tickers', tickers);
      developer.log('Synced portfolio tickers to Hive: $tickers',
          name: 'PortfolioNotifier');
    } catch (e) {
      developer.log('Failed to sync portfolio to Hive: $e',
          name: 'PortfolioNotifier');
    }
  }

  /// 현재가 업데이트
  void updatePrice(String ticker, double newPrice) {
    state = state.map((item) {
      if (item.ticker == ticker) {
        return PortfolioItem(
          ticker: item.ticker,
          name: item.name,
          quantity: item.quantity,
          avgPrice: item.avgPrice,
          currentPrice: newPrice,
        );
      }
      return item;
    }).toList();
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
      await db.create(transaction);
      state = AsyncData([...(state.value ?? []), transaction]);
      developer.log(
          'Transaction added: ${transaction.type} ${transaction.ticker}',
          name: 'TransactionHistoryNotifier');
    } catch (e) {
      developer.log('Error adding transaction: $e',
          name: 'TransactionHistoryNotifier');
    }
  }
}

final transactionHistoryProvider = AsyncNotifierProvider<
    TransactionHistoryNotifier, List<model.Transaction>>(
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
