const usUniverseTickers = [
  'AAPL',
  'GOOGL',
  'MSFT',
  'AMZN',
  'NVDA',
  'TSLA',
  'META',
  'JPM',
  'V',
  'JNJ',
];

const koreanUniverseTickers = {
  '005930': '삼성전자',
  '000660': 'SK하이닉스',
  '373220': 'LG에너지솔루션',
  '207940': '삼성바이오로직스',
  '005380': '현대자동차',
  '006400': '삼성SDI',
  '051910': 'LG화학',
  '035420': 'NAVER',
  '000270': '기아',
  '035720': '카카오',
};

final koreanUniverseCodes =
    List<String>.unmodifiable(koreanUniverseTickers.keys);
