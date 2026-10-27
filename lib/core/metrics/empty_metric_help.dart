import '../market/market_classification.dart';
import 'sample_metric_policy.dart';
import '../../features/strategy/domain/entities/stock.dart';

class EmptyMetricExplanation {
  final String title;
  final String whyEmpty;
  final String meaning;
  final String scoreNote;

  const EmptyMetricExplanation({
    required this.title,
    required this.whyEmpty,
    required this.meaning,
    required this.scoreNote,
  });
}

class EmptyMetricHelp {
  static const metricKeys = ['per', 'roe', 'dividend'];

  static bool isEmptyMetricLabel(String value) {
    final text = value.trim();
    return text.isEmpty ||
        text == missingMetricLabel ||
        text == '없음' ||
        text == '-' ||
        text == '–' ||
        text.toUpperCase() == 'N/A';
  }

  static String labelFor(String metricKey) {
    return switch (metricKey) {
      'per' => 'PER',
      'roe' => 'ROE',
      'dividend' => '배당',
      _ => metricKey,
    };
  }

  static List<String> emptyKeysFor(Stock stock) {
    return [
      for (final key in metricKeys)
        if (_isDisplayEmpty(stock, key)) key,
    ];
  }

  static bool _isDisplayEmpty(Stock stock, String metricKey) {
    return isEmptyMetricLabel(
      SampleMetricPolicy.fundamentalText(
        stock: stock,
        metric: metricKey,
        formatted: '1',
      ),
    );
  }

  static EmptyMetricExplanation forStock({
    required Stock stock,
    required String metricKey,
    bool korean = true,
  }) {
    return explain(
      metricKey: metricKey,
      ticker: stock.ticker,
      sampleMetric: SampleMetricPolicy.isSampleMetric(stock, metricKey),
      korean: korean,
    );
  }

  static EmptyMetricExplanation forRankingCell({
    required String ticker,
    required String metricKey,
    bool korean = true,
  }) {
    return explain(
      metricKey: metricKey,
      ticker: ticker,
      sampleMetric: false,
      korean: korean,
    );
  }

  static EmptyMetricExplanation forUnrankedRow({
    required String ticker,
    bool korean = true,
  }) {
    final usPer = classifyTicker(ticker) == MarketRegion.us;
    if (korean) {
      final usNote = usPer
          ? ' 미국 종목의 PER은 이 앱의 시세 경로에 없습니다. Nasdaq 공개 응답에서는 배당수익률과 세후 ROE만 읽습니다.'
          : '';
      return EmptyMetricExplanation(
        title: '지표 없음',
        whyEmpty:
            '가격은 확인됐지만, 지금 분석 기준에 넣을 실지표가 없어 순위를 매기지 않았습니다. 샘플로만 채운 값은 빼고 보여 줍니다.$usNote',
        meaning: 'PER은 주가 ÷ 주당이익, ROE는 이익 ÷ 자기자본, 배당수익률은 주당 배당 ÷ 가격입니다. 셋 다 샘플 순서를 배우는 지표이며 미래 성과가 아닙니다.',
        scoreNote: '순위 번호 대신 빈 칸으로 남습니다. 학습용 표시이며 매수·매도 권유가 아닙니다.',
      );
    }

    final usNote = usPer
        ? ' US listings in this app have no PER. The Nasdaq public response only includes dividend yield and after-tax ROE.'
        : '';
    return EmptyMetricExplanation(
      title: 'No metric',
      whyEmpty:
          'A price is available, but there is no confirmed metric for this criteria, so this row is not ranked. Sample-only values are left out.$usNote',
      meaning: 'PER is price ÷ earnings, ROE is earnings ÷ equity, and dividend yield is dividend per share ÷ price. They are for comparing samples, not future results.',
      scoreNote: 'The rank cell stays empty. This is a learning label, not a buy or sell signal.',
    );
  }

  static EmptyMetricExplanation explain({
    required String metricKey,
    required String ticker,
    required bool sampleMetric,
    bool korean = true,
  }) {
    final usPer =
        metricKey == 'per' && classifyTicker(ticker) == MarketRegion.us;
    if (korean) {
      return EmptyMetricExplanation(
        title: '${labelFor(metricKey)} · $missingMetricLabel',
        whyEmpty: _whyEmptyKo(
          metricKey: metricKey,
          sampleMetric: sampleMetric,
          usPer: usPer,
        ),
        meaning: _meaningKo(metricKey),
        scoreNote: '값이 없으면 그 지표는 이 종목 점수에 더해지지 않습니다. 빈 칸은 좋은 값도 나쁜 값도 아니며, 매수·매도 신호가 아닙니다.',
      );
    }
    return EmptyMetricExplanation(
      title: '${_labelEn(metricKey)} · no metric',
      whyEmpty: _whyEmptyEn(
        metricKey: metricKey,
        sampleMetric: sampleMetric,
        usPer: usPer,
      ),
      meaning: _meaningEn(metricKey),
      scoreNote: 'An empty value is not added to this symbol’s score. Empty is neither good nor bad, and it is not a buy or sell signal.',
    );
  }

  static String _whyEmptyKo({
    required String metricKey,
    required bool sampleMetric,
    required bool usPer,
  }) {
    if (sampleMetric) {
      return '이 칸은 실데이터가 아니라 샘플로 채운 값입니다. 학습 화면에서는 샘플을 빼고 지표 없음으로 보여 줍니다. 샘플 숫자는 점수에 넣지 않습니다.';
    }
    if (usPer) {
      return '이 앱의 미국 시세 경로에는 PER이 없습니다. Nasdaq 공개 응답에서는 배당수익률과 세후 ROE만 읽습니다. 빈 PER은 오류가 아니라 그 경로의 한계이고, PER 비중은 그 종목 점수에 들어가지 않습니다.';
    }
    return '${labelFor(metricKey)} 값을 공개 응답에서 확인하지 못했거나, 샘플로만 채워져 점수에서 빠졌습니다. 값이 없으면 그 비중은 이 종목 점수에 들어가지 않습니다.';
  }

  static String _whyEmptyEn({
    required String metricKey,
    required bool sampleMetric,
    required bool usPer,
  }) {
    if (sampleMetric) {
      return 'This cell was filled with a sample value, not a confirmed figure. The learning view hides samples and shows no metric. Sample numbers are not scored.';
    }
    if (usPer) {
      return 'This app’s US quote path has no PER. The Nasdaq public response only includes dividend yield and after-tax ROE. An empty PER is a limit of that path, and the PER weight is not added to this symbol’s score.';
    }
    return '${_labelEn(metricKey)} was not in the public response, or only a sample value was available and it was left out of the score.';
  }

  static String _meaningKo(String metricKey) {
    return switch (metricKey) {
      'per' => 'PER은 주가가 이익 대비 어느 정도로 평가되는지 보는 지표입니다. 주가 ÷ 주당이익으로 계산합니다. 낮아 보일 수 있어도 업황이나 이익 감소를 함께 봐야 하며, 미래 성과가 아닙니다.',
      'roe' => 'ROE는 자기자본으로 얼마나 효율적으로 이익을 만들었는지 보는 수익성 지표입니다. 이익 ÷ 자기자본으로 계산합니다. 높다고 해서 사야 한다는 뜻은 아니며, 일회성 이익과 부채도 구분해야 합니다.',
      'dividend' => '배당수익률은 현재 가격 대비 배당이 어느 정도인지 보는 지표입니다. 주당 배당 ÷ 가격으로 계산합니다. 높아 보여도 배당이 이어진다는 뜻은 아닙니다.',
      _ => '이 칸은 샘플 순서를 비교하는 학습용 지표입니다.',
    };
  }

  static String _meaningEn(String metricKey) {
    return switch (metricKey) {
      'per' => 'PER asks how the price compares with earnings. It is price ÷ earnings per share. A low reading can still reflect weaker earnings. It is not a future result.',
      'roe' => 'ROE asks how efficiently equity produced earnings. It is earnings ÷ equity. A high reading is not an instruction to buy.',
      'dividend' => 'Dividend yield compares the dividend with the current price. It is dividend per share ÷ price. A high reading does not promise that the dividend continues.',
      _ => 'This cell is a learning metric for comparing sample order.',
    };
  }

  static String _labelEn(String metricKey) {
    return switch (metricKey) {
      'per' => 'PER',
      'roe' => 'ROE',
      'dividend' => 'Dividend',
      _ => metricKey,
    };
  }
}
