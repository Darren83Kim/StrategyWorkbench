import 'package:strategy_workbench/features/strategy/data/repositories/finnhub_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/fmp_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/krx_dart_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/yahoo_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/kor_investment_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/mock_stock_repository.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/stock_universe.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';
import 'package:strategy_workbench/features/strategy/domain/repositories/stock_repository.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'dart:developer' as developer;

/// 데이터 소스 우선순위 (2026-03-09 재설계)
///
/// US: Finnhub(1순위) → FMP(2순위) → Yahoo(폴백) → Mock
/// KR: KRX+DART(1순위) + 한국투자증권(보완) → Mock
class HybridStockRepository implements StockRepository {
  final FinnhubStockRepository? _finnhubRepo;
  final FmpStockRepository? _fmpRepo;
  final YahooStockRepository? _yahooRepo;
  final KrxDartStockRepository? _krxDartRepo;
  final KorInvestmentRepository? _korRepo;
  final MockStockRepository _mockRepo;
  final bool _allowKorInvestmentFallback;

  HybridStockRepository({
    FinnhubStockRepository? finnhubRepository,
    FmpStockRepository? fmpRepository,
    YahooStockRepository? yahooRepository,
    KrxDartStockRepository? krxDartRepository,
    KorInvestmentRepository? korRepository,
    MockStockRepository? mockRepository,
    bool? allowKorInvestmentFallback,
  })  : _finnhubRepo = finnhubRepository ??
            (ApiKeys.isFinnhubConfigured ? FinnhubStockRepository() : null),
        _fmpRepo = fmpRepository ??
            (ApiKeys.isFmpConfigured ? FmpStockRepository() : null),
        _yahooRepo = yahooRepository ?? YahooStockRepository(),
        _krxDartRepo = krxDartRepository ??
            (ApiKeys.isKrxConfigured ? KrxDartStockRepository() : null),
        _allowKorInvestmentFallback =
            allowKorInvestmentFallback ?? ApiKeys.isKorInvestmentRuntimeEnabled,
        _korRepo = korRepository ??
            ((allowKorInvestmentFallback ??
                        ApiKeys.isKorInvestmentRuntimeEnabled) &&
                    ApiKeys.isKorInvestmentConfigured
                ? KorInvestmentRepository()
                : null),
        _mockRepo = mockRepository ?? MockStockRepository();

  // ── StockRepository 인터페이스 구현 ──
  @override
  Future<List<Stock>> getStocks() => getAllStocks();

  @override
  Future<Stock?> getStockByTicker(String ticker) => getStock(ticker);

  /// 모든 주식 데이터 조회 (미국 + 국내)
  /// [useMock] = true 이면 강제로 Mock 사용 (개발/테스트 전용)
  Future<List<Stock>> getAllStocks({bool useMock = false}) async {
    if (useMock) {
      developer.log('Using Mock data (forced)', name: 'HybridStockRepository');
      return _mockRepo.getStocks();
    }

    // API 키가 전혀 없으면 Mock 사용 (첫 설치, 키 미설정 상태)
    if (!ApiKeys.isAnyRealApiConfigured) {
      developer.log('No API keys configured, using Mock data',
          name: 'HybridStockRepository');
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

    developer.log('Total stocks fetched: ${stocks.length}',
        name: 'HybridStockRepository');
    return stocks; // 빈 리스트 그대로 반환 (Mock으로 숨기지 않음)
  }

  /// 미국 주식만 조회 (Finnhub → FMP → Yahoo → Mock 순서)
  Future<List<Stock>> getUsStocks() async {
    final mergedStocks = <String, Stock>{};

    // 1순위: Finnhub (60회/분)
    if (_finnhubRepo != null) {
      try {
        developer.log('Trying Finnhub (US 1순위)...',
            name: 'HybridStockRepository');
        final stocks = await _finnhubRepo!.getStocks();
        _mergeStocksInto(mergedStocks, stocks);
        developer.log('Finnhub contributed ${stocks.length} US stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('Finnhub failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 2순위: FMP (가격/이름 위주 폴백)
    if (_fmpRepo != null && mergedStocks.length < usUniverseTickers.length) {
      try {
        developer.log('Trying FMP (US 2순위)...', name: 'HybridStockRepository');
        final stocks = await _fmpRepo!.getStocks();
        _mergeStocksInto(mergedStocks, stocks);
        developer.log('FMP contributed ${stocks.length} US stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('FMP failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 3순위: Yahoo Finance (비공식)
    if (_yahooRepo != null && mergedStocks.length < usUniverseTickers.length) {
      try {
        developer.log('Trying Yahoo Finance (US 폴백)...',
            name: 'HybridStockRepository');
        final stocks = await _yahooRepo!.getStocks();
        _mergeStocksInto(mergedStocks, stocks);
        developer.log('Yahoo contributed ${stocks.length} US stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('Yahoo failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    if (mergedStocks.isNotEmpty) {
      final orderedStocks = _sortStocksByUniverse(
        mergedStocks.values,
        usUniverseTickers,
      );
      developer.log('US sources merged into ${orderedStocks.length} stocks',
          name: 'HybridStockRepository');
      return orderedStocks;
    }

    // API 키가 없을 때만 Mock 사용
    if (!ApiKeys.isAnyRealApiConfigured) {
      developer.log('No API keys, using Mock for US',
          name: 'HybridStockRepository');
      final mockStocks = await _mockRepo.getStocks();
      return mockStocks
          .where((s) => !RegExp(r'^\d+$').hasMatch(s.ticker))
          .toList();
    }
    developer.log('All US sources failed, returning empty',
        name: 'HybridStockRepository');
    return [];
  }

  /// 국내 주식만 조회 (KRX+DART + 한국투자증권 보완 → Mock 순서)
  Future<List<Stock>> getKoreanStocks() async {
    final mergedStocks = <String, Stock>{};
    final hasKrRealSource = _krxDartRepo != null ||
        (_allowKorInvestmentFallback && _korRepo != null);

    // 1순위: KRX + DART (10,000회/일)
    if (_krxDartRepo != null) {
      try {
        developer.log('Trying KRX+DART (KR 1순위)...',
            name: 'HybridStockRepository');
        final stocks = await _krxDartRepo!.getStocks();
        _mergeStocksInto(mergedStocks, stocks);
        developer.log('KRX+DART contributed ${stocks.length} Korean stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('KRX+DART failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    // 폴백: 한국투자증권 (사용자 키 필요)
    if (_allowKorInvestmentFallback && _korRepo != null) {
      try {
        developer.log('Trying 한국투자증권 (KR 보완)...',
            name: 'HybridStockRepository');
        final stocks = await _korRepo!.getStocks();
        _mergeStocksInto(mergedStocks, stocks);
        developer.log('한국투자증권 contributed ${stocks.length} Korean stocks',
            name: 'HybridStockRepository');
      } catch (e) {
        developer.log('한국투자증권 failed: $e',
            name: 'HybridStockRepository', error: e);
      }
    }

    if (mergedStocks.isNotEmpty) {
      final orderedStocks = _sortStocksByUniverse(
        mergedStocks.values,
        koreanUniverseCodes,
      );
      developer.log(
        'KR sources merged into ${orderedStocks.length} stocks',
        name: 'HybridStockRepository',
      );
      return orderedStocks;
    }

    // debug에서 KIS 자동 인증을 막는 경우를 포함해 KR 소스가 없으면 Mock 사용
    if (!hasKrRealSource) {
      developer.log('No enabled KR sources, using Mock for KR',
          name: 'HybridStockRepository');
      final mockStocks = await _mockRepo.getStocks();
      return mockStocks
          .where((s) => RegExp(r'^\d+$').hasMatch(s.ticker))
          .toList();
    }
    developer.log('All KR sources failed, returning empty',
        name: 'HybridStockRepository');
    return [];
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
        if (_korRepo != null && _allowKorInvestmentFallback) {
          final stock = await _korRepo!.getStockByCode(symbol);
          if (stock != null) return stock;
        }
      } else {
        // Finnhub → FMP → Yahoo → Mock
        if (_finnhubRepo != null) {
          final stock = await _finnhubRepo!.getStockByTicker(symbol);
          if (stock != null) return stock;
        }
        if (_fmpRepo != null) {
          final stock = await _fmpRepo!.getStockByTicker(symbol);
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
      'fmpConfigured': ApiKeys.isFmpConfigured,
      'fmpAvailable': _fmpRepo != null,
      'yahooAvailable': _yahooRepo != null,
      'krxDartConfigured': ApiKeys.isKrxConfigured,
      'krxDartAvailable': _krxDartRepo != null,
      'korInvestmentConfigured': ApiKeys.isKorInvestmentConfigured,
      'korInvestmentRuntimeEnabled': _allowKorInvestmentFallback,
      'korInvestmentAvailable': _korRepo != null,
      'dartConfigured': ApiKeys.isDartConfigured,
      'priority': {
        'US': 'Finnhub → FMP → Yahoo → Mock',
        'KR': 'KRX+DART + 한국투자증권 → Mock',
      },
    };
  }
}

void _mergeStocksInto(Map<String, Stock> target, List<Stock> incoming) {
  for (final stock in incoming) {
    final key = stock.ticker.toUpperCase();
    final existing = target[key];
    target[key] =
        existing == null ? stock : _fillMissingFields(existing, stock);
  }
}

Stock _fillMissingFields(Stock primary, Stock fallback) {
  return Stock(
    ticker: primary.ticker,
    name: _pickBetterName(primary, fallback),
    price: primary.price > 0 ? primary.price : fallback.price,
    per: primary.per > 0 ? primary.per : fallback.per,
    roe: primary.roe > 0 ? primary.roe : fallback.roe,
    dividendYield: primary.dividendYield > 0
        ? primary.dividendYield
        : fallback.dividendYield,
    lastUpdated: primary.lastUpdated.isAfter(fallback.lastUpdated)
        ? primary.lastUpdated
        : fallback.lastUpdated,
  );
}

String _pickBetterName(Stock primary, Stock fallback) {
  final primaryLooksResolved =
      primary.name.isNotEmpty && primary.name != primary.ticker;
  if (primaryLooksResolved) {
    return primary.name;
  }
  return fallback.name.isNotEmpty ? fallback.name : primary.name;
}

List<Stock> _sortStocksByUniverse(
  Iterable<Stock> stocks,
  List<String> preferredOrder,
) {
  final orderIndex = {
    for (final entry in preferredOrder.asMap().entries) entry.value: entry.key,
  };
  final sorted = stocks.toList();
  sorted.sort((a, b) {
    final aIndex = orderIndex[a.ticker.toUpperCase()] ?? 9999;
    final bIndex = orderIndex[b.ticker.toUpperCase()] ?? 9999;
    if (aIndex != bIndex) {
      return aIndex.compareTo(bIndex);
    }
    return a.ticker.compareTo(b.ticker);
  });
  return sorted;
}
