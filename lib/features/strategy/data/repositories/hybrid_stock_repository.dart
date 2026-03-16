import 'package:strategy_workbench/features/strategy/data/repositories/finnhub_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/krx_dart_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/yahoo_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/kor_investment_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/mock_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/features/strategy/domain/repositories/stock_repository.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'dart:developer' as developer;

/// 데이터 소스 우선순위 (2026-03-09 재설계)
///
/// US: Finnhub(1순위) → FMP(2순위, 미구현) → Yahoo(폴백) → Mock
/// KR: KRX+DART(1순위) → 한국투자증권(폴백) → Mock
class HybridStockRepository implements StockRepository {
  final FinnhubStockRepository? _finnhubRepo;
  final YahooStockRepository? _yahooRepo;
  final KrxDartStockRepository? _krxDartRepo;
  final KorInvestmentRepository? _korRepo;
  final MockStockRepository _mockRepo;

  HybridStockRepository({
    FinnhubStockRepository? finnhubRepository,
    YahooStockRepository? yahooRepository,
    KrxDartStockRepository? krxDartRepository,
    KorInvestmentRepository? korRepository,
    MockStockRepository? mockRepository,
  })  : _finnhubRepo = finnhubRepository ??
            (ApiKeys.isFinnhubConfigured ? FinnhubStockRepository() : null),
        _yahooRepo = yahooRepository ?? YahooStockRepository(),
        _krxDartRepo = krxDartRepository ??
            (ApiKeys.isKrxConfigured ? KrxDartStockRepository() : null),
        _korRepo = korRepository,
        _mockRepo = mockRepository ?? MockStockRepository();

  // ── StockRepository 인터페이스 구현 ──
  @override
  Future<List<Stock>> getStocks() => getAllStocks();

  @override
  Future<Stock?> getStockByTicker(String ticker) => getStock(ticker);

  /// 모든 주식 데이터 조회 (미국 + 국내)
  Future<List<Stock>> getAllStocks({bool useMock = false}) async {
    try {
      if (useMock) {
        developer.log('Using Mock data', name: 'HybridStockRepository');
        return _mockRepo.getStocks();
      }

      final stocks = <Stock>[];

      // 1. 미국 주식
      try {
        final usStocks = await getUsStocks();
        stocks.addAll(usStocks);
        developer.log('Got ${usStocks.length} US stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('Failed to fetch US stocks: $e',
            name: 'HybridStockRepository', error: e);
      }

      // 2. 국내 주식
      try {
        final krStocks = await getKoreanStocks();
        stocks.addAll(krStocks);
        developer.log('Got ${krStocks.length} Korean stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('Failed to fetch Korean stocks: $e',
            name: 'HybridStockRepository', error: e);
      }

      // 데이터가 없으면 Mock 사용
      if (stocks.isEmpty) {
        developer.log('No data fetched, falling back to Mock',
            name: 'HybridStockRepository');
        return _mockRepo.getStocks();
      }

      return stocks;
    } catch (e) {
      developer.log('Error in getAllStocks: $e',
          name: 'HybridStockRepository', error: e);
      return _mockRepo.getStocks();
    }
  }

  /// 미국 주식만 조회 (Finnhub → Yahoo → Mock 순서)
  Future<List<Stock>> getUsStocks() async {
    // 1순위: Finnhub (60회/분)
    if (_finnhubRepo != null) {
      try {
        developer.log('Trying Finnhub (US 1순위)...',
            name: 'HybridStockRepository');
        final stocks = await _finnhubRepo!.getStocks();
        if (stocks.isNotEmpty) {
          developer.log('Finnhub: ${stocks.length} stocks fetched',
              name: 'HybridStockRepository');
          return stocks;
        }
      } catch (e) {
        developer.log('Finnhub failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 폴백: Yahoo Finance (비공식)
    if (_yahooRepo != null) {
      try {
        developer.log('Trying Yahoo Finance (US 폴백)...',
            name: 'HybridStockRepository');
        final stocks = await _yahooRepo!.getStocks();
        if (stocks.isNotEmpty) {
          developer.log('Yahoo: ${stocks.length} stocks fetched',
              name: 'HybridStockRepository');
          return stocks;
        }
      } catch (e) {
        developer.log('Yahoo failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 최종 폴백: Mock 데이터 (US 종목만 필터링)
    developer.log('All US sources failed, using Mock',
        name: 'HybridStockRepository');
    final mockStocks = await _mockRepo.getStocks();
    return mockStocks
        .where((s) => !RegExp(r'^\d+$').hasMatch(s.ticker))
        .toList();
  }

  /// 국내 주식만 조회 (KRX+DART → 한국투자증권 → Mock 순서)
  Future<List<Stock>> getKoreanStocks() async {
    // 1순위: KRX + DART (10,000회/일)
    if (_krxDartRepo != null) {
      try {
        developer.log('Trying KRX+DART (KR 1순위)...',
            name: 'HybridStockRepository');
        final stocks = await _krxDartRepo!.getStocks();
        if (stocks.isNotEmpty) {
          developer.log('KRX+DART: ${stocks.length} stocks fetched',
              name: 'HybridStockRepository');
          return stocks;
        }
      } catch (e) {
        developer.log('KRX+DART failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 폴백: 한국투자증권 (사용자 키 필요)
    if (ApiKeys.isKorInvestmentConfigured && _korRepo != null) {
      try {
        developer.log('Trying 한국투자증권 (KR 폴백)...',
            name: 'HybridStockRepository');
        final stocks = await _korRepo!.getStocks();
        if (stocks.isNotEmpty) {
          developer.log('한국투자증권: ${stocks.length} stocks fetched',
              name: 'HybridStockRepository');
          return stocks;
        }
      } catch (e) {
        developer.log('한국투자증권 failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 최종 폴백: Mock 데이터 (KR 종목만 필터링)
    developer.log('All KR sources failed, using Mock',
        name: 'HybridStockRepository');
    final mockStocks = await _mockRepo.getStocks();
    return mockStocks
        .where((s) => RegExp(r'^\d+$').hasMatch(s.ticker))
        .toList();
  }

  /// 단일 주식 조회 (모든 소스 검색)
  Future<Stock?> getStock(String symbol) async {
    try {
      // 종목코드가 숫자면 한국 주식
      final isKorean = RegExp(r'^\d+$').hasMatch(symbol);

      if (isKorean) {
        // KRX+DART → 한국투자증권 → Mock
        if (_krxDartRepo != null) {
          final stock = await _krxDartRepo!.getStockByCode(symbol);
          if (stock != null) return stock;
        }
        if (_korRepo != null && ApiKeys.isKorInvestmentConfigured) {
          final stock = await _korRepo!.getStockByCode(symbol);
          if (stock != null) return stock;
        }
      } else {
        // Finnhub → Yahoo → Mock
        if (_finnhubRepo != null) {
          final stock = await _finnhubRepo!.getStockByTicker(symbol);
          if (stock != null) return stock;
        }
        if (_yahooRepo != null) {
          final stock = await _yahooRepo!.getStockByTicker(symbol);
          if (stock != null) return stock;
        }
      }

      // Mock에서 확인
      return await _mockRepo.getStockByTicker(symbol);
    } catch (e) {
      developer.log('Error fetching stock $symbol: $e',
          name: 'HybridStockRepository', error: e);
      return null;
    }
  }

  /// 데이터 소스 상태 확인
  Map<String, dynamic> getStatus() {
    return {
      'finnhubConfigured': ApiKeys.isFinnhubConfigured,
      'finnhubAvailable': _finnhubRepo != null,
      'yahooAvailable': _yahooRepo != null,
      'krxDartConfigured': ApiKeys.isKrxConfigured,
      'krxDartAvailable': _krxDartRepo != null,
      'korInvestmentConfigured': ApiKeys.isKorInvestmentConfigured,
      'korInvestmentAvailable': _korRepo != null,
      'dartConfigured': ApiKeys.isDartConfigured,
      'priority': {
        'US': 'Finnhub → Yahoo → Mock',
        'KR': 'KRX+DART → 한국투자증권 → Mock',
      },
    };
  }
}
