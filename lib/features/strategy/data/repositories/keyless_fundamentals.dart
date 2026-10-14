/// Parsers for public Naver and Nasdaq responses that already back the
/// keyless quote fallbacks. Values stay 0 when a field is missing.
class KeylessFundamentals {
  final double per;
  final double roe;
  final double dividendYield;

  const KeylessFundamentals({
    this.per = 0,
    this.roe = 0,
    this.dividendYield = 0,
  });

  bool get hasAny => per > 0 || roe > 0 || dividendYield > 0;
}

double? parseLoosePositiveNumber(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is num) {
    final value = raw.toDouble();
    return value > 0 ? value : null;
  }

  final text = raw.toString().trim();
  if (text.isEmpty || text == '-' || text.toUpperCase() == 'N/A') {
    return null;
  }
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text.replaceAll(',', ''));
  if (match == null) {
    return null;
  }
  final value = double.tryParse(match.group(0)!);
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}

KeylessFundamentals parseNaverIntegration(Map<dynamic, dynamic> json) {
  final infos = json['totalInfos'];
  var per = 0.0;
  var dividendYield = 0.0;
  if (infos is List) {
    for (final info in infos) {
      if (info is! Map) {
        continue;
      }
      final value = parseLoosePositiveNumber(info['value']);
      if (value == null) {
        continue;
      }
      if (info['code'] == 'per') {
        per = value;
      } else if (info['code'] == 'dividendYieldRatio') {
        dividendYield = value;
      }
    }
  }
  return KeylessFundamentals(per: per, dividendYield: dividendYield);
}

double? parseNaverAnnualRoe(Map<dynamic, dynamic> json) {
  final financeInfo = json['financeInfo'];
  if (financeInfo is! Map) {
    return null;
  }
  final rowList = financeInfo['rowList'];
  if (rowList is! List) {
    return null;
  }

  Map<dynamic, dynamic>? roeRow;
  for (final row in rowList) {
    if (row is Map && row['title'] == 'ROE') {
      roeRow = row;
      break;
    }
  }
  final columns = roeRow?['columns'];
  if (columns is! Map) {
    return null;
  }

  final actualKeys = <String>[];
  final titles = financeInfo['trTitleList'];
  if (titles is List) {
    for (final title in titles) {
      if (title is Map && title['isConsensus'] != 'Y' && title['key'] != null) {
        actualKeys.add(title['key'].toString());
      }
    }
  }
  actualKeys.sort();
  for (final key in actualKeys.reversed) {
    final cell = columns[key];
    if (cell is! Map) {
      continue;
    }
    final value = parseLoosePositiveNumber(cell['value']);
    if (value != null) {
      return value;
    }
  }
  return null;
}

double? parseNasdaqDividendYield(Map<dynamic, dynamic> json) {
  final data = json['data'];
  if (data is! Map) {
    return null;
  }
  final summary = data['summaryData'];
  if (summary is! Map) {
    return null;
  }
  final yieldField = summary['Yield'];
  if (yieldField is! Map) {
    return null;
  }
  return parseLoosePositiveNumber(yieldField['value']);
}

double? parseNasdaqAfterTaxRoe(Map<dynamic, dynamic> json) {
  final data = json['data'];
  if (data is! Map) {
    return null;
  }
  final table = data['financialRatiosTable'];
  if (table is! Map) {
    return null;
  }
  final rows = table['rows'];
  if (rows is! List) {
    return null;
  }
  for (final row in rows) {
    if (row is Map && row['value1'] == 'After Tax ROE') {
      return parseLoosePositiveNumber(row['value2']);
    }
  }
  return null;
}
