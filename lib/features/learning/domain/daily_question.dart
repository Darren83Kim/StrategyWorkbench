class DailyQuestion {
  final String id;
  final String prompt;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  const DailyQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
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
    return isSameLearningDay(last, now);
  }
}

DateTime learningDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameLearningDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
  return DateTime(year, month, day);
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
    final continues =
        current.lastCompletedDay != null &&
        isSameLearningDay(current.lastCompletedDay!, yesterday);
    return LearningStreakSnapshot(
      streak: continues ? current.streak + 1 : 1,
      lastCompletedDay: today,
      answeredQuestionId: questionId,
    );
  }
}

class DailyQuestionBank {
  static const questionsKo = <DailyQuestion>[
    DailyQuestion(
      id: 'per-meaning',
      prompt: 'PER은 무엇을 보는 지표인가요?',
      choices: ['주가가 이익 대비 어느 정도로 평가되는지', '내일 주가가 오른다는 신호', '계좌의 수익률'],
      answerIndex: 0,
      explanation:
          'PER은 주가 ÷ 주당이익입니다. 낮아 보여도 이익 감소일 수 있고, 미래 성과나 매수·매도 신호가 아닙니다.',
    ),
    DailyQuestion(
      id: 'roe-meaning',
      prompt: 'ROE는 무엇을 보나요?',
      choices: ['자기자본으로 얼마나 효율적으로 이익을 만들었는지', '오늘 사야 하는 종목인지', '배당이 들어오는 날짜'],
      answerIndex: 0,
      explanation:
          'ROE는 이익 ÷ 자기자본입니다. 높다고 해서 매수·매도 신호가 아닙니다. 일회성 이익과 부채도 구분해야 합니다.',
    ),
    DailyQuestion(
      id: 'dividend-meaning',
      prompt: '배당수익률은 무엇인가요?',
      choices: ['현재 가격 대비 배당이 어느 정도인지', '배당이 계속 늘어난다는 약속', '주가가 오른 비율'],
      answerIndex: 0,
      explanation:
          '배당수익률은 주당 배당 ÷ 가격입니다. 높아 보여도 배당이 이어진다는 뜻은 아니고, 매수·매도 신호가 아닙니다.',
    ),
    DailyQuestion(
      id: 'rank-change',
      prompt: '순위 변화는 무엇을 뜻하나요?',
      choices: ['이전 계산과 현재 계산의 상대 순위 차이', '앞으로의 수익률', '주문이 체결됐다는 기록'],
      answerIndex: 0,
      explanation: '순위 변화는 지표와 표본의 상대 비교이며 미래 성과가 아닙니다.',
    ),
    DailyQuestion(
      id: 'score-meaning',
      prompt: '이 앱의 지표 점수는 어떻게 만들어지나요?',
      choices: [
        '단위가 다른 지표를 같은 범위로 바꾼 뒤 비중을 곱합니다',
        '다른 앱의 추천 순위를 그대로 가져옵니다',
        '계좌 수익률을 계산합니다',
      ],
      answerIndex: 0,
      explanation: 'PER은 낮을수록, ROE와 배당은 높을수록 좋은 방향으로 정규화한 뒤 비중을 곱합니다. 학습용 비교이며 매수·매도 신호가 아닙니다.',
    ),
    DailyQuestion(
      id: 'per-reading',
      prompt: 'PER이 낮을 때 맞는 설명은 무엇인가요?',
      choices: [
        '저평가처럼 보일 수 있지만 업황이나 이익 감소도 함께 봐야 합니다',
        '가격이 반드시 오릅니다',
        '배당이 확정됩니다',
      ],
      answerIndex: 0,
      explanation: '낮은 PER은 해석의 시작일 뿐입니다. 미래 성과가 아닙니다.',
    ),
    DailyQuestion(
      id: 'sample-change',
      prompt: '비교하는 표본이 바뀌면 어떻게 되나요?',
      choices: [
        '같은 종목도 상대 위치가 달라질 수 있습니다',
        '그 종목의 미래 수익이 확정됩니다',
        '빈 지표가 매수 신호가 됩니다',
      ],
      answerIndex: 0,
      explanation: '표본이 바뀌면 상대 순위도 바뀝니다. 미래 성과가 아닙니다.',
    ),
    DailyQuestion(
      id: 'empty-metric',
      prompt: "지표가 비어 있거나 '지표 없음'이면 무슨 뜻인가요?",
      choices: [
        '이 경로에서 확인되지 않은 값이며, 그 지표는 점수에 넣지 않습니다',
        '그 종목을 팔아야 한다는 신호',
        '앱을 지워야 하는 오류',
      ],
      answerIndex: 0,
      explanation: '미국 종목 PER은 이 앱의 시세 경로에 없을 수 있습니다. 빈 값은 좋은 값도 나쁜 값도 아니고, 매수·매도 신호가 아닙니다.',
    ),
  ];

  static const questionsEn = <DailyQuestion>[
    DailyQuestion(
      id: 'per-meaning',
      prompt: 'What does PER describe?',
      choices: [
        'How price compares with earnings',
        'A signal that the price rises tomorrow',
        'The return of an account',
      ],
      answerIndex: 0,
      explanation: 'PER is price ÷ earnings per share. A low reading can still reflect weaker earnings. It is not a future result or a buy or sell signal.',
    ),
    DailyQuestion(
      id: 'roe-meaning',
      prompt: 'What does ROE describe?',
      choices: [
        'How efficiently equity produced earnings',
        'Whether to buy the symbol today',
        'The day a dividend is paid',
      ],
      answerIndex: 0,
      explanation: 'ROE is earnings ÷ equity. A high reading is not an instruction to buy. One-off gains and debt still need a separate look.',
    ),
    DailyQuestion(
      id: 'dividend-meaning',
      prompt: 'What is dividend yield?',
      choices: [
        'The dividend compared with the current price',
        'A promise that the dividend keeps growing',
        'How much the price rose',
      ],
      answerIndex: 0,
      explanation: 'Dividend yield is dividend per share ÷ price. A high reading does not mean the dividend continues, and it is not a buy or sell signal.',
    ),
    DailyQuestion(
      id: 'rank-change',
      prompt: 'What does a rank change mean?',
      choices: [
        'The difference in relative rank between two calculations',
        'A future rate of return',
        'A filled order',
      ],
      answerIndex: 0,
      explanation: 'A rank change compares metrics and the sample. It is not a future result.',
    ),
    DailyQuestion(
      id: 'score-meaning',
      prompt: 'How does this app build an indicator score?',
      choices: [
        'It rescales different units, then multiplies by the weights',
        'It copies a recommendation ranking from somewhere else',
        'It calculates account profit',
      ],
      answerIndex: 0,
      explanation: 'Lower PER and higher ROE or dividend yield score higher after scaling, then the weights are applied. It is a learning comparison, not a buy or sell signal.',
    ),
    DailyQuestion(
      id: 'per-reading',
      prompt: 'Which reading of a low PER fits this app?',
      choices: [
        'It can look inexpensive, but weaker business conditions or earnings still matter',
        'The price must rise',
        'The dividend is guaranteed',
      ],
      answerIndex: 0,
      explanation: 'A low PER is only the start of a reading. It is not a future result.',
    ),
    DailyQuestion(
      id: 'sample-change',
      prompt: 'What happens when the comparison sample changes?',
      choices: [
        'The same symbol can move to a different relative place',
        'That symbol’s future profit becomes certain',
        'An empty metric becomes a buy signal',
      ],
      answerIndex: 0,
      explanation: 'A different sample can change the relative rank. It is not a future result.',
    ),
    DailyQuestion(
      id: 'empty-metric',
      prompt: 'What does an empty metric, or “no metric”, mean?',
      choices: [
        'The value was not confirmed on this path, so it is not added to the score',
        'A signal to sell that symbol',
        'An error that means the app should be deleted',
      ],
      answerIndex: 0,
      explanation: 'US PER can be missing on this app’s quote path. An empty value is neither good nor bad, and it is not a buy or sell signal.',
    ),
  ];

  static DailyQuestion forDate(DateTime now, {bool korean = true}) {
    final questions = korean ? questionsKo : questionsEn;
    final day = learningDay(now);
    final index =
        day.difference(DateTime(2026, 1, 1)).inDays.abs() % questions.length;
    return questions[index];
  }
}
