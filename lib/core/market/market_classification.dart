import 'package:intl/intl.dart';
import 'package:strategy_workbench/core/providers/stock_providers.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/stock_universe.dart';
import 'package:strategy_workbench/features/strategy/domain/entities/stock.dart';

enum MarketRegion { korea, us, unknown }

const knownInstrumentNames = {
  ...koreanUniverseTickers,
};

String normalizeTickerInput(String value) {
  final compact = value.trim().replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) {
    return '';
  }

  if (RegExp(r'^\d{1,6}$').hasMatch(compact)) {
    return compact.padLeft(6, '0');
  }

  return compact.toUpperCase();
}

String resolveInstrumentName(String ticker, String? name) {
  final normalizedTicker = normalizeTickerInput(ticker);
  final trimmedName = name?.trim() ?? '';
  final knownName = knownInstrumentNames[normalizedTicker];
  final nameIsMissingOrCode = trimmedName.isEmpty ||
      normalizeTickerInput(trimmedName) == normalizedTicker;

  if (knownName != null && nameIsMissingOrCode) {
    return knownName;
  }

  if (trimmedName.isNotEmpty) {
    return trimmedName;
  }

  return knownName ?? normalizedTicker;
}

bool isKoreanTicker(String ticker) {
  return RegExp(r'^\d{6}$').hasMatch(normalizeTickerInput(ticker));
}

bool isUsTicker(String ticker) {
  final normalized = normalizeTickerInput(ticker);
  if (normalized.isEmpty || isKoreanTicker(normalized)) {
    return false;
  }
  return RegExp(r'^[A-Z][A-Z0-9.-]{0,9}$').hasMatch(normalized);
}

MarketRegion classifyTicker(String ticker) {
  if (isKoreanTicker(ticker)) {
    return MarketRegion.korea;
  }
  if (isUsTicker(ticker)) {
    return MarketRegion.us;
  }
  return MarketRegion.unknown;
}

List<Stock> filterStocksByMarket(List<Stock> stocks, MarketFilter filter) {
  switch (filter) {
    case MarketFilter.korea:
      return stocks.where((stock) => isKoreanTicker(stock.ticker)).toList();
    case MarketFilter.us:
      return stocks.where((stock) => isUsTicker(stock.ticker)).toList();
    case MarketFilter.hybrid:
      return stocks;
  }
}

String marketFilterLabel(MarketFilter filter) {
  switch (filter) {
    case MarketFilter.hybrid:
      return '전체';
    case MarketFilter.korea:
      return '국내';
    case MarketFilter.us:
      return '미국';
  }
}

String formatMarketPrice(String ticker, double price) {
  if (isKoreanTicker(ticker)) {
    final formatter = NumberFormat.decimalPattern('ko_KR');
    return '₩${formatter.format(price.round())}';
  }

  return '\$${price.toStringAsFixed(2)}';
}
