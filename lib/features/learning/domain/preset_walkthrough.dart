import 'package:strategy_workbench/core/providers/filter_providers.dart';

class PresetWalkthroughStep {
  final String name;
  final Map<String, double> weights;
  final String focus;
  final String lesson;
  final String orderEffect;

  const PresetWalkthroughStep({
    required this.name,
    required this.weights,
    required this.focus,
    required this.lesson,
    required this.orderEffect,
  });
}

const _focusKo = {
  '가치주': 'PER 비중',
  '배당주': '배당수익률 비중',
  '퀀트': '세 지표를 비슷하게',
  '수익성': 'ROE 비중',
};

const _lessonKo = {
  '가치주': 'PER은 주가를 주당이익으로 나눈 값입니다. 이 기준은 PER 70%, ROE 30%라서 같은 표본에서 PER이 낮은 종목이 위로 올라오기 쉽습니다.',
  '배당주': '배당수익률은 주당 배당을 가격으로 나눈 값입니다. 이 기준은 배당 60%라서 배당 축이 샘플 순서를 가장 많이 바꿉니다. 배당이 이어진다는 뜻은 아닙니다.',
  '퀀트': 'PER, ROE, 배당 비중이 거의 같습니다. 한 지표에 치우치지 않았을 때 샘플 순서가 어떻게 달라지는지 비교하는 학습 기준입니다.',
  '수익성': 'ROE는 이익을 자기자본으로 나눈 수익성 지표입니다. 이 기준은 ROE 80%, PER 20%로, 수익성 축이 순서에 크게 반영됩니다. 가격이 올랐다는 뜻이 아니고 매수 신호도 아닙니다.',
};

const _orderKo = {
  '가치주': '비중을 이익 대비 가격 쪽에 두면 순서의 축이 바뀝니다. 낮아 보인다고 해서 사야 한다는 뜻은 아닙니다.',
  '배당주': '배당 비중을 올리면 그 축의 설명력이 커집니다. 특정 종목을 담으라는 뜻이 아닙니다.',
  '퀀트': '세 축이 비슷하면 한 지표의 극단값이 순서를 덜 끌어갑니다. 미래 성과가 아닙니다.',
  '수익성': 'ROE 비중을 높이면 수익성이 좋은 샘플이 위로 오기 쉽습니다. 가격 상승을 뜻하지 않습니다.',
};

const _focusEn = {
  '가치주': 'PER weight',
  '배당주': 'Dividend yield weight',
  '퀀트': 'Balanced weights',
  '수익성': 'ROE weight',
};

const _lessonEn = {
  '가치주': 'PER is price divided by earnings per share. This preset is PER 70% and ROE 30%, so a lower PER tends to move up in the same sample.',
  '배당주': 'Dividend yield is the dividend per share divided by price. This preset puts 60% on dividends, so that axis moves the sample order the most. It does not mean the dividend continues.',
  '퀀트': 'PER, ROE, and dividend weights are almost equal. Use it to see how the order changes when no single metric dominates.',
  '수익성': 'ROE is earnings divided by equity. This preset is ROE 80% and PER 20%, so profitability moves the order. It does not mean the price rose, and it is not a buy signal.',
};

const _orderEn = {
  '가치주': 'Putting weight on price versus earnings changes which axis sorts the sample. A low reading is not an instruction to buy.',
  '배당주': 'Raising the dividend weight gives that axis more influence. It does not tell you to hold a specific symbol.',
  '퀀트': 'Similar weights keep one extreme metric from pulling the order as hard. This is not a future result.',
  '수익성': 'A higher ROE weight tends to lift samples with stronger profitability. It does not mean the price went up.',
};

List<PresetWalkthroughStep> buildPresetWalkthrough({bool korean = true}) {
  final focus = korean ? _focusKo : _focusEn;
  final lesson = korean ? _lessonKo : _lessonEn;
  final orderEffect = korean ? _orderKo : _orderEn;
  return [
    for (final preset in presetStrategies)
      PresetWalkthroughStep(
        name: preset.name,
        weights: Map<String, double>.from(preset.weights),
        focus: focus[preset.name] ?? preset.name,
        lesson:
            lesson[preset.name] ??
            (throw StateError('Missing walkthrough lesson for ${preset.name}')),
        orderEffect:
            orderEffect[preset.name] ??
            (throw StateError(
              'Missing walkthrough order note for ${preset.name}',
            )),
      ),
  ];
}
