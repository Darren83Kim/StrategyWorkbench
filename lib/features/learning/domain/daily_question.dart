import 'package:strategy_workbench/features/learning/domain/study_reminder.dart';

class DailyQuestion {
  final String id;
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
  final String formula;
  final String studyNote;

  const DailyQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    this.formula = '',
    this.studyNote = '',
  });

  String get answer => choices[answerIndex];
}

class LearningStreakSnapshot {
  final int streak;
  final DateTime? lastCompletedDay;
  final String? answeredQuestionId;

  const LearningStreakSnapshot({
    required this.streak,
    this.lastCompletedDay,
    this.answeredQuestionId,
  });

  static const empty = LearningStreakSnapshot(streak: 0);

  bool completedOn(DateTime now) {
    final last = lastCompletedDay;
    if (last == null) {
      return false;
    }
    return isSameLearningDay(last, learningDay(now));
  }
}

/// Calendar day in Asia/Seoul (UTC+9, no daylight saving).
///
/// The result is a UTC date-only value so comparisons do not depend on the
/// device time zone. A Seoul user who answers just after midnight, or whose
/// device clock is set to UTC, still shares one learning day.
DateTime learningDay(DateTime value) {
  final seoul = value.toUtc().add(asiaSeoulOffset);
  return DateTime.utc(seoul.year, seoul.month, seoul.day);
}

/// Absolute instant for a clock reading in Asia/Seoul.
DateTime seoulWallClock(
  int year,
  int month,
  int day, [
  int hour = 0,
  int minute = 0,
]) {
  return DateTime.utc(year, month, day, hour, minute).subtract(asiaSeoulOffset);
}

bool isSameLearningDay(DateTime a, DateTime b) {
  final left = learningDay(a);
  final right = learningDay(b);
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String formatLearningDay(DateTime day) {
  final local = learningDay(day);
  final month = local.month.toString().padLeft(2, '0');
  final date = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$date';
}

DateTime? parseLearningDay(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final parts = raw.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  return DateTime.utc(year, month, day);
}

class LearningProgress {
  static LearningStreakSnapshot applyAnswer({
    required LearningStreakSnapshot current,
    required String questionId,
    required DateTime now,
  }) {
    final today = learningDay(now);
    if (current.completedOn(today)) {
      return current;
    }
    final yesterday = today.subtract(const Duration(days: 1));
    final continues = current.lastCompletedDay != null &&
        isSameLearningDay(current.lastCompletedDay!, yesterday);
    return LearningStreakSnapshot(
      streak: continues ? current.streak + 1 : 1,
      lastCompletedDay: today,
      answeredQuestionId: questionId,
    );
  }
}

class DailyQuestionBank {
  /// Consecutive Seoul days inside this window never repeat a question.
  /// The bank is longer than the window, and the daily index walks the bank
  /// in order before it cycles.
  static const repeatAvoidanceWindowDays = 14;

  static const questionsKo = <DailyQuestion>[
    DailyQuestion(
      id: 'per-meaning',
      prompt: 'PER은 무엇을 보는 지표인가요?',
      choices: [
        '내일 가격이 오른다는 신호',
        '주가가 이익 대비 어느 정도로 평가되는지',
        '계좌에 쌓인 금액',
      ],
      answerIndex: 1,
      formula: 'PER = 주가 ÷ 주당이익',
      explanation:
          'PER은 주가 ÷ 주당이익입니다. 낮아 보여도 이익이 줄어든 결과일 수 있습니다. 앞으로의 가격을 알려 주지 않으며, 투자 권유가 아닙니다.',
      studyNote: '숫자 하나만 보고 판단을 끝내지 말고, 이익이 어디서 났는지를 같이 읽습니다.',
    ),
    DailyQuestion(
      id: 'roe-meaning',
      prompt: 'ROE는 무엇을 보나요?',
      choices: [
        '자기자본으로 얼마나 효율적으로 이익을 만들었는지',
        '오늘 사야 하는지',
        '배당이 들어오는 날짜',
      ],
      answerIndex: 0,
      formula: 'ROE = 이익 ÷ 자기자본',
      explanation:
          'ROE는 이익 ÷ 자기자본입니다. 높다고 해서 행동 지시가 아닙니다. 일회성 이익과 부채도 구분해야 하며, 투자 권유가 아닙니다.',
      studyNote: '자기자본이 줄어도 ROE는 높아 보일 수 있습니다. 분모가 작아진 경우인지 확인합니다.',
    ),
    DailyQuestion(
      id: 'dividend-meaning',
      prompt: '배당수익률은 무엇인가요?',
      choices: [
        '배당이 계속 늘어난다는 약속',
        '주가가 오른 비율',
        '현재 가격 대비 배당이 어느 정도인지',
      ],
      answerIndex: 2,
      formula: '배당수익률 = 주당 배당 ÷ 주가',
      explanation:
          '배당수익률은 주당 배당 ÷ 가격입니다. 높아 보여도 배당이 이어진다는 뜻은 아닙니다. 투자 권유가 아닙니다.',
      studyNote: '가격이 내려 그 숫자만 커진 경우와, 배당 자체가 늘어난 경우를 구분합니다.',
    ),
    DailyQuestion(
      id: 'rank-change',
      prompt: '순위 변화는 무엇을 뜻하나요?',
      choices: [
        '앞으로의 가격 변화',
        '이전 계산과 현재 계산의 상대 순위 차이',
        '주문이 체결됐다는 기록',
      ],
      answerIndex: 1,
      formula: '순위 변화 = 이전 순위 − 현재 순위',
      explanation: '순위 변화는 지표와 표본의 상대 비교이며 미래 성과가 아닙니다.',
      studyNote: '표본이 바뀌면 같은 종목의 순위도 움직일 수 있습니다.',
    ),
    DailyQuestion(
      id: 'score-meaning',
      prompt: '이 앱의 지표 점수는 어떻게 만들어지나요?',
      choices: [
        '단위가 다른 지표를 같은 범위로 바꾼 뒤 비중을 곱합니다',
        '다른 앱의 순위를 그대로 가져옵니다',
        '계좌의 성과를 계산합니다',
      ],
      answerIndex: 0,
      formula: '점수 = 정규화한 지표 × 비중',
      explanation:
          'PER은 낮을수록, ROE와 배당은 높을수록 좋은 방향으로 정규화한 뒤 비중을 곱합니다. 학습용 비교이며 투자 권유가 아닙니다.',
      studyNote: '비중을 바꾸면 표본 순서가 달라지는 것을 보는 연습입니다.',
    ),
    DailyQuestion(
      id: 'per-reading',
      prompt: 'PER이 낮을 때 맞는 설명은 무엇인가요?',
      choices: [
        '가격이 반드시 오릅니다',
        '배당이 확정됩니다',
        '저평가처럼 보일 수 있지만 업황이나 이익 감소도 함께 봐야 합니다',
      ],
      answerIndex: 2,
      formula: 'PER = 주가 ÷ 주당이익',
      explanation: '낮은 PER은 해석의 시작일 뿐입니다. 미래 성과가 아닙니다.',
      studyNote: '이익 추정이 바뀌면 같은 주가라도 PER은 달라집니다.',
    ),
    DailyQuestion(
      id: 'sample-change',
      prompt: '비교하는 표본이 바뀌면 어떻게 되나요?',
      choices: [
        '같은 종목도 상대 위치가 달라질 수 있습니다',
        '그 종목의 미래 이익이 확정됩니다',
        '빈 지표가 좋은 값이 됩니다',
      ],
      answerIndex: 0,
      explanation: '표본이 바뀌면 상대 순위도 바뀝니다. 미래 성과가 아닙니다.',
      studyNote: '국내만 보는지, 전체를 보는지에 따라 같은 숫자의 위치가 달라질 수 있습니다.',
    ),
    DailyQuestion(
      id: 'empty-metric',
      prompt: "지표가 비어 있거나 '지표 없음'이면 무슨 뜻인가요?",
      choices: [
        '그 종목을 정리해야 한다는 신호',
        '이 경로에서 확인되지 않은 값이며, 그 지표는 점수에 넣지 않습니다',
        '앱을 지워야 하는 오류',
      ],
      answerIndex: 1,
      explanation:
          '미국 종목 PER은 이 앱의 시세 경로에 없을 수 있습니다. 빈 값은 좋은 값도 나쁜 값도 아니고, 투자 권유가 아닙니다.',
      studyNote: '없는 값을 0으로 두고 순위에 넣지 않습니다. 비어 있음은 그 자체로 해석이 아닙니다.',
    ),
    DailyQuestion(
      id: 'pbr-meaning',
      prompt: 'PBR은 무엇을 비교하나요?',
      choices: [
        '주가와 주당순자산',
        '하루 동안의 거래량',
        '배당이 지급되는 요일',
      ],
      answerIndex: 0,
      formula: 'PBR = 주가 ÷ 주당순자산',
      explanation:
          'PBR은 주가 ÷ 주당순자산입니다. 1보다 낮아 보여도 자산의 질을 말해 주지 않으며, 투자 권유가 아닙니다.',
      studyNote: '장부상의 자산과 시장이 매기는 가격이 다르면 PBR이 벌어집니다.',
    ),
    DailyQuestion(
      id: 'payout-meaning',
      prompt: '배당성향은 무엇인가요?',
      choices: [
        '주가가 배당보다 얼마나 높은지',
        '다음 배당이 늘어난다는 약속',
        '이익 가운데 배당으로 나간 비율',
      ],
      answerIndex: 2,
      formula: '배당성향 = 배당 ÷ 이익',
      explanation: '배당성향은 배당 ÷ 이익입니다. 높다고 해서 배당이 유지된다는 뜻은 아니며, 투자 권유가 아닙니다.',
      studyNote: '이익이 얇은데 배당 비율만 높으면, 그 배당이 오래 가기 어려울 수 있습니다.',
    ),
    DailyQuestion(
      id: 'eps-meaning',
      prompt: 'EPS는 무엇을 나누나요?',
      choices: [
        '주가를 매출로 나눈 값',
        '이익을 발행주식수로 나눈 값',
        '배당을 자기자본으로 나눈 값',
      ],
      answerIndex: 1,
      formula: 'EPS = 이익 ÷ 발행주식수',
      explanation:
          'EPS는 주당이익입니다. 주식 수가 늘면 이익이 같아도 EPS는 작아질 수 있으며, 투자 권유가 아닙니다.',
      studyNote: 'PER의 분모가 EPS입니다. EPS가 흔들리면 PER도 같이 흔들립니다.',
    ),
    DailyQuestion(
      id: 'bps-meaning',
      prompt: 'BPS는 어떤 값인가요?',
      choices: [
        '자기자본을 발행주식수로 나눈 주당순자산',
        '하루 가격의 중간값',
        '배당을 주가로 나눈 값',
      ],
      answerIndex: 0,
      formula: 'BPS = 자기자본 ÷ 발행주식수',
      explanation:
          'BPS는 주당순자산입니다. PBR의 분모이며, 그 자체로 가격의 방향을 말하지 않습니다. 투자 권유가 아닙니다.',
      studyNote: '무형자산이나 일회성 항목이 자기자본에 섞여 있으면 BPS도 같이 읽어야 합니다.',
    ),
    DailyQuestion(
      id: 'per-and-eps',
      prompt: 'PER과 EPS의 관계로 맞는 것은 무엇인가요?',
      choices: [
        'EPS가 커지면 PER의 분모가 커집니다',
        'EPS는 배당 지급일이 정해진 뒤에만 계산됩니다',
        'EPS와 PER은 서로 관련이 없습니다',
      ],
      answerIndex: 0,
      formula: 'PER = 주가 ÷ EPS',
      explanation:
          'PER의 분모는 EPS입니다. 주가가 그대로여도 EPS가 늘면 PER은 낮아집니다. 그 변화가 투자 권유가 아닙니다.',
      studyNote: 'PER이 낮아진 이유가 주가 하락인지, EPS 증가인지 나눠 봅니다.',
    ),
    DailyQuestion(
      id: 'yield-and-payout',
      prompt: '배당수익률과 배당성향은 어떻게 다른가요?',
      choices: [
        '둘 다 주가의 오름폭을 뜻합니다',
        '배당수익률은 가격과 배당을, 성향은 이익과 배당을 비교합니다',
        '성향이 높으면 배당수익률도 항상 높습니다',
      ],
      answerIndex: 1,
      formula: '배당수익률 = 주당 배당 ÷ 주가, 배당성향 = 배당 ÷ 이익',
      explanation:
          '배당수익률은 가격 기준이고 배당성향은 이익 기준입니다. 둘 중 하나만으로 배당의 질이 정해지지 않으며, 투자 권유가 아닙니다.',
      studyNote: '가격이 싸 보여 배당수익률이 높아도, 이익 대비 배당 비율은 별도로 봅니다.',
    ),
    DailyQuestion(
      id: 'roe-and-equity',
      prompt: 'ROE가 높아질 수 있는 이유로 맞는 것은 무엇인가요?',
      choices: [
        '이익이 늘거나, 자기자본이 줄어도 숫자가 커질 수 있습니다',
        '거래량이 늘면 ROE가 자동으로 오릅니다',
        '배당 요일을 바꾸면 ROE가 오릅니다',
      ],
      answerIndex: 0,
      formula: 'ROE = 이익 ÷ 자기자본',
      explanation: '분모인 자기자본이 줄어도 ROE는 높아 보입니다. 이익의 질과 따로 봐야 하며, 투자 권유가 아닙니다.',
      studyNote: '이익이 같은 해에만 일시적으로 커졌는지도 같이 확인합니다.',
    ),
    DailyQuestion(
      id: 'negative-earnings',
      prompt: '이익이 적자일 때 PER은 어떻게 읽는 편이 맞나요?',
      choices: [
        '적자여도 PER이 낮으면 항상 유리합니다',
        '분모가 음수라 낮고 높음으로 비교하기 어렵습니다',
        '적자면 배당수익률과 같은 값이 됩니다',
      ],
      answerIndex: 1,
      formula: 'PER = 주가 ÷ 주당이익',
      explanation:
          '주당이익이 0 이하면 PER을 다른 종목의 PER과 나란히 비교하기 어렵습니다. 빈칸으로 두는 편이 나을 수 있으며, 투자 권유가 아닙니다.',
      studyNote: '이 앱은 확인되지 않은 값을 좋은 점수로 채우지 않습니다.',
    ),
    DailyQuestion(
      id: 'weight-changes-order',
      prompt: '분석 기준의 비중을 바꾸면 무엇이 달라지나요?',
      choices: [
        '그 종목의 다음 가격이 정해집니다',
        '배당 지급일이 바뀝니다',
        '같은 표본 안에서 지표 점수의 순서가 달라질 수 있습니다',
      ],
      answerIndex: 2,
      formula: '점수 = 정규화한 지표 × 비중',
      explanation: '비중은 어떤 지표를 더 크게 볼지의 학습 장치입니다. 순서가 바뀌어도 투자 권유가 아닙니다.',
      studyNote: '가치주 기준과 배당주 기준은 같은 종목을 다른 자리에 둘 수 있습니다.',
    ),
    DailyQuestion(
      id: 'dividend-and-price',
      prompt: '배당금이 그대로인데 주가가 내리면 배당수익률은 어떻게 되나요?',
      choices: [
        '분모가 작아져 배당수익률 숫자는 커집니다',
        '배당수익률은 주가와 무관하게 고정됩니다',
        '주가가 내리면 배당수익률도 항상 내려갑니다',
      ],
      answerIndex: 0,
      formula: '배당수익률 = 주당 배당 ÷ 주가',
      explanation:
          '주당 배당이 같고 주가만 낮아지면 배당수익률 숫자는 커집니다. 배당이 안전해졌다는 뜻은 아니며, 투자 권유가 아닙니다.',
      studyNote: '커진 숫자 뒤에는 가격 하락이 있을 수 있습니다. 배당의 재원도 따로 봅니다.',
    ),
  ];

  static const questionsEn = <DailyQuestion>[
    DailyQuestion(
      id: 'per-meaning',
      prompt: 'What does PER describe?',
      choices: [
        'A signal that the price rises tomorrow',
        'How price compares with earnings',
        'The balance of an account',
      ],
      answerIndex: 1,
      formula: 'PER = price ÷ earnings per share',
      explanation:
          'PER is price ÷ earnings per share. A low reading can still reflect weaker earnings. It is not a forecast or investment advice.',
      studyNote:
          'Read where the earnings came from before stopping at the number.',
    ),
    DailyQuestion(
      id: 'roe-meaning',
      prompt: 'What does ROE describe?',
      choices: [
        'How efficiently equity produced earnings',
        'Whether to act on the symbol today',
        'The day a dividend is paid',
      ],
      answerIndex: 0,
      formula: 'ROE = earnings ÷ equity',
      explanation:
          'ROE is earnings ÷ equity. A high reading is not an instruction. One-off gains and debt still need a separate look. It is not a forecast.',
      studyNote: 'ROE can rise because equity shrank. Check the denominator.',
    ),
    DailyQuestion(
      id: 'dividend-meaning',
      prompt: 'What is dividend yield?',
      choices: [
        'A promise that the dividend keeps growing',
        'How much the price rose',
        'The dividend compared with the current price',
      ],
      answerIndex: 2,
      formula: 'Dividend yield = dividend per share ÷ price',
      explanation:
          'Dividend yield is dividend per share ÷ price. A high reading does not mean the dividend continues. It is not a forecast.',
      studyNote:
          'Separate a lower price from a larger dividend. Both can raise the figure.',
    ),
    DailyQuestion(
      id: 'rank-change',
      prompt: 'What does a rank change mean?',
      choices: [
        'A future price result',
        'The difference in relative rank between two calculations',
        'A filled order',
      ],
      answerIndex: 1,
      formula: 'Rank change = previous rank − current rank',
      explanation:
          'A rank change compares metrics and the sample. It is not a future result.',
      studyNote: 'The same symbol can move when the sample changes.',
    ),
    DailyQuestion(
      id: 'score-meaning',
      prompt: 'How does this app build an indicator score?',
      choices: [
        'It rescales different units, then multiplies by the weights',
        'It copies a ranking from somewhere else',
        'It calculates how an account performed',
      ],
      answerIndex: 0,
      formula: 'Score = scaled indicator × weight',
      explanation:
          'Lower PER and higher ROE or dividend yield score higher after scaling, then the weights are applied. It is a learning comparison, not a forecast.',
      studyNote: 'Changing a weight is a way to see the sample order move.',
    ),
    DailyQuestion(
      id: 'per-reading',
      prompt: 'Which reading of a low PER fits this app?',
      choices: [
        'The price must rise',
        'The dividend is guaranteed',
        'It can look inexpensive, but weaker business conditions or earnings still matter',
      ],
      answerIndex: 2,
      formula: 'PER = price ÷ earnings per share',
      explanation:
          'A low PER is only the start of a reading. It is not a future result.',
      studyNote:
          'If the earnings estimate changes, PER changes even when the price does not.',
    ),
    DailyQuestion(
      id: 'sample-change',
      prompt: 'What happens when the comparison sample changes?',
      choices: [
        'The same symbol can move to a different relative place',
        'That symbol’s future earnings become certain',
        'An empty metric becomes a good value',
      ],
      answerIndex: 0,
      explanation:
          'A different sample can change the relative rank. It is not a future result.',
      studyNote:
          'A Korea-only sample and the full sample can place the same number differently.',
    ),
    DailyQuestion(
      id: 'empty-metric',
      prompt: 'What does an empty metric, or “no metric”, mean?',
      choices: [
        'A signal to remove that symbol',
        'The value was not confirmed on this path, so it is not added to the score',
        'An error that means the app should be deleted',
      ],
      answerIndex: 1,
      explanation:
          'US PER can be missing on this app’s quote path. An empty value is neither good nor bad, and it is not a forecast.',
      studyNote:
          'A missing value is not filled with zero and then ranked. Empty is not a reading.',
    ),
    DailyQuestion(
      id: 'pbr-meaning',
      prompt: 'What does PBR compare?',
      choices: [
        'Price and book value per share',
        'Volume during one day',
        'The weekday a dividend is paid',
      ],
      answerIndex: 0,
      formula: 'PBR = price ÷ book value per share',
      explanation:
          'PBR is price ÷ book value per share. A reading below one does not describe the quality of the assets. It is not a forecast.',
      studyNote:
          'PBR widens when the market price and the accounting book value differ.',
    ),
    DailyQuestion(
      id: 'payout-meaning',
      prompt: 'What is the dividend payout ratio?',
      choices: [
        'How far price sits above the dividend',
        'A promise that the next dividend grows',
        'The share of earnings paid out as dividends',
      ],
      answerIndex: 2,
      formula: 'Payout ratio = dividends ÷ earnings',
      explanation:
          'The payout ratio is dividends ÷ earnings. A high ratio does not mean the dividend lasts. It is not a forecast.',
      studyNote: 'A high payout on thin earnings can be hard to keep.',
    ),
    DailyQuestion(
      id: 'eps-meaning',
      prompt: 'What does EPS divide?',
      choices: [
        'Price divided by sales',
        'Earnings divided by shares outstanding',
        'Dividends divided by equity',
      ],
      answerIndex: 1,
      formula: 'EPS = earnings ÷ shares outstanding',
      explanation:
          'EPS is earnings per share. More shares can shrink EPS even when earnings stay the same. It is not a forecast.',
      studyNote:
          'EPS is the denominator of PER. If EPS moves, PER moves with it.',
    ),
    DailyQuestion(
      id: 'bps-meaning',
      prompt: 'What is BPS?',
      choices: [
        'Book value per share, equity divided by shares outstanding',
        'The middle price of the day',
        'The dividend divided by price',
      ],
      answerIndex: 0,
      formula: 'BPS = equity ÷ shares outstanding',
      explanation:
          'BPS is book value per share. It is the denominator of PBR and does not by itself point to a price direction. It is not a forecast.',
      studyNote:
          'If one-off items sit inside equity, read BPS with that in mind.',
    ),
    DailyQuestion(
      id: 'per-and-eps',
      prompt: 'Which link between PER and EPS is right?',
      choices: [
        'A larger EPS makes the PER denominator larger',
        'EPS is calculated only after a dividend date is set',
        'EPS and PER are unrelated',
      ],
      answerIndex: 0,
      formula: 'PER = price ÷ EPS',
      explanation:
          'EPS is the denominator of PER. If price stays put and EPS rises, PER falls. That change is not a forecast.',
      studyNote:
          'Ask whether a lower PER came from a lower price or from higher EPS.',
    ),
    DailyQuestion(
      id: 'yield-and-payout',
      prompt: 'How do dividend yield and the payout ratio differ?',
      choices: [
        'Both describe how far the price rose',
        'Yield compares the dividend with price, and the payout compares it with earnings',
        'A higher payout always means a higher yield',
      ],
      answerIndex: 1,
      formula:
          'Yield = dividend per share ÷ price; payout = dividends ÷ earnings',
      explanation:
          'Yield uses price. The payout ratio uses earnings. Neither one settles the quality of the dividend. It is not a forecast.',
      studyNote:
          'A lower price can lift the yield while the payout ratio tells a different story.',
    ),
    DailyQuestion(
      id: 'roe-and-equity',
      prompt: 'Which reason can make ROE look higher?',
      choices: [
        'Earnings rose, or equity shrank',
        'Higher volume raises ROE on its own',
        'Changing the dividend weekday raises ROE',
      ],
      answerIndex: 0,
      formula: 'ROE = earnings ÷ equity',
      explanation:
          'A smaller equity denominator can lift ROE. The quality of earnings still needs its own look. It is not a forecast.',
      studyNote: 'Check whether earnings were large in only one period.',
    ),
    DailyQuestion(
      id: 'negative-earnings',
      prompt: 'How should a PER be read when earnings are negative?',
      choices: [
        'A low PER is always favorable in a loss',
        'A negative denominator makes high and low hard to compare',
        'A loss makes PER equal to dividend yield',
      ],
      answerIndex: 1,
      formula: 'PER = price ÷ earnings per share',
      explanation:
          'When earnings per share are below zero, PER is a poor side-by-side comparison. Leaving it out can be clearer. It is not a forecast.',
      studyNote:
          'This app does not fill an unconfirmed value with a flattering score.',
    ),
    DailyQuestion(
      id: 'weight-changes-order',
      prompt: 'What changes when you edit an analysis weight?',
      choices: [
        'The next price of that symbol is set',
        'The dividend payment date changes',
        'The indicator-score order inside the same sample can change',
      ],
      answerIndex: 2,
      formula: 'Score = scaled indicator × weight',
      explanation:
          'A weight is a learning control for which indicator counts more. A new order is not a forecast.',
      studyNote:
          'A value baseline and a dividend baseline can place the same symbol in different spots.',
    ),
    DailyQuestion(
      id: 'dividend-and-price',
      prompt:
          'If the dividend stays the same and the price falls, what happens to dividend yield?',
      choices: [
        'The smaller denominator makes the yield figure larger',
        'Dividend yield stays fixed no matter the price',
        'A lower price always lowers the yield',
      ],
      answerIndex: 0,
      formula: 'Dividend yield = dividend per share ÷ price',
      explanation:
          'The same dividend over a lower price produces a larger yield figure. That does not mean the dividend is safer. It is not a forecast.',
      studyNote:
          'A larger figure can be a fallen price. Look at what funds the dividend as well.',
    ),
  ];

  static DailyQuestion forDate(DateTime now, {bool korean = true}) {
    final questions = korean ? questionsKo : questionsEn;
    assert(questions.length > repeatAvoidanceWindowDays);
    final day = learningDay(now);
    final index = day.difference(DateTime.utc(2026, 1, 1)).inDays.abs() %
        questions.length;
    return questions[index];
  }
}
