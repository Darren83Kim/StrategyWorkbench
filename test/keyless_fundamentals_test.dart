import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/keyless_fundamentals.dart';

void main() {
  test('parses Naver PER, dividend yield, and reported ROE', () {
    final integration = parseNaverIntegration({
      'totalInfos': [
        {'code': 'per', 'value': '10.43배'},
        {'code': 'dividendYieldRatio', 'value': '0.72%'},
        {'code': 'cnsPer', 'value': '5.11배'},
      ],
    });
    final roe = parseNaverAnnualRoe({
      'financeInfo': {
        'trTitleList': [
          {'isConsensus': 'N', 'key': '202512'},
          {'isConsensus': 'Y', 'key': '202612'},
        ],
        'rowList': [
          {
            'title': 'ROE',
            'columns': {
              '202512': {'value': '10.85'},
              '202612': {'value': '53.60'},
            },
          },
        ],
      },
    });

    expect(integration.per, 10.43);
    expect(integration.dividendYield, 0.72);
    expect(roe, 10.85);
  });

  test('parses Nasdaq dividend yield and after-tax ROE', () {
    expect(
      parseNasdaqDividendYield({
        'data': {
          'summaryData': {
            'Yield': {'value': '0.32%'},
          },
        },
      }),
      0.32,
    );
    expect(
      parseNasdaqAfterTaxRoe({
        'data': {
          'financialRatiosTable': {
            'rows': [
              {'value1': 'Pre-Tax ROE', 'value2': '180.01%'},
              {'value1': 'After Tax ROE', 'value2': '151.91%'},
            ],
          },
        },
      }),
      151.91,
    );
  });
}