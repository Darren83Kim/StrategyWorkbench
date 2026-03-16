import '../../domain/entities/stock.dart';
import '../../domain/repositories/stock_repository.dart';

class MockStockRepository implements StockRepository {
  @override
  Future<List<Stock>> getStocks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    return [
      // ── 한국 주식 (가치주 성향 강함: 낮은 PER) ──
      Stock(ticker: '005930', name: '삼성전자',      price: 74800,  per: 12.5, roe: 11.2, dividendYield: 2.9, lastUpdated: now),
      Stock(ticker: '000270', name: '기아',          price: 96200,  per:  6.2, roe: 23.4, dividendYield: 4.5, lastUpdated: now),
      Stock(ticker: '005380', name: '현대차',        price: 232000, per:  7.1, roe: 14.8, dividendYield: 3.8, lastUpdated: now),
      Stock(ticker: '055550', name: '신한지주',      price: 52800,  per:  5.8, roe: 10.1, dividendYield: 5.6, lastUpdated: now),
      Stock(ticker: '105560', name: 'KB금융',        price: 87500,  per:  6.4, roe:  9.8, dividendYield: 5.2, lastUpdated: now),
      Stock(ticker: '000810', name: '삼성화재',      price: 368000, per:  8.3, roe: 12.3, dividendYield: 4.7, lastUpdated: now),
      Stock(ticker: '017670', name: 'SK텔레콤',      price: 58700,  per: 11.2, roe:  9.5, dividendYield: 6.2, lastUpdated: now),
      Stock(ticker: '030200', name: 'KT',            price: 43200,  per:  9.3, roe:  8.7, dividendYield: 5.8, lastUpdated: now),
      Stock(ticker: '015760', name: '한국전력',      price: 21350,  per:   0.0, roe: -3.2, dividendYield: 0.0, lastUpdated: now),
      Stock(ticker: '096770', name: 'SK이노베이션',  price: 115500, per: 14.2, roe:  6.8, dividendYield: 1.2, lastUpdated: now),

      // ── 한국 주식 (배당주 성향 강함: 높은 배당) ──
      Stock(ticker: '033780', name: 'KT&G',          price: 111500, per: 10.5, roe: 14.2, dividendYield: 7.8, lastUpdated: now),
      Stock(ticker: '009150', name: '삼성전기',      price: 155000, per: 17.3, roe: 18.5, dividendYield: 1.4, lastUpdated: now),
      Stock(ticker: '068270', name: '셀트리온',      price: 178000, per: 45.2, roe: 12.1, dividendYield: 0.3, lastUpdated: now),
      Stock(ticker: '207940', name: '삼성바이오로직스', price: 875000, per: 88.0, roe:  8.5, dividendYield: 0.1, lastUpdated: now),
      Stock(ticker: '006400', name: '삼성SDI',       price: 362000, per: 22.5, roe: 10.2, dividendYield: 0.4, lastUpdated: now),
      Stock(ticker: '051910', name: 'LG화학',        price: 392000, per: 19.8, roe:  7.3, dividendYield: 0.8, lastUpdated: now),
      Stock(ticker: '000100', name: '유한양행',      price: 78400,  per: 28.1, roe:  6.4, dividendYield: 0.6, lastUpdated: now),
      Stock(ticker: '316140', name: '우리금융지주',  price: 16850,  per:  4.8, roe:  9.2, dividendYield: 7.1, lastUpdated: now),
      Stock(ticker: '086790', name: '하나금융지주',  price: 64900,  per:  5.5, roe: 10.4, dividendYield: 6.5, lastUpdated: now),
      Stock(ticker: '001040', name: 'CJ',            price: 87000,  per:  7.9, roe:  7.1, dividendYield: 2.1, lastUpdated: now),

      // ── 한국 주식 (급등주 성향: 높은 ROE) ──
      Stock(ticker: '000660', name: 'SK하이닉스',    price: 196000, per: 13.1, roe: 38.5, dividendYield: 0.9, lastUpdated: now),
      Stock(ticker: '035420', name: 'NAVER',         price: 183500, per: 24.3, roe: 16.8, dividendYield: 0.3, lastUpdated: now),
      Stock(ticker: '035720', name: '카카오',        price: 42550,  per:  0.0,  roe: -2.1, dividendYield: 0.0, lastUpdated: now),
      Stock(ticker: '247540', name: '에코프로비엠',  price: 152500, per: 32.8, roe: 28.6, dividendYield: 0.1, lastUpdated: now),
      Stock(ticker: '091990', name: '셀트리온헬스케어', price: 62400, per: 38.1, roe: 22.4, dividendYield: 0.0, lastUpdated: now),

      // ── 미국 주식 (가치주: 낮은 PER) ──
      Stock(ticker: 'BRK.B',  name: 'Berkshire Hathaway', price: 416.2,  per:  8.9, roe: 12.4, dividendYield: 0.0, lastUpdated: now),
      Stock(ticker: 'JPM',    name: 'JPMorgan Chase',     price: 234.5,  per: 10.2, roe: 15.8, dividendYield: 2.4, lastUpdated: now),
      Stock(ticker: 'BAC',    name: 'Bank of America',    price: 44.8,   per: 11.5, roe: 10.6, dividendYield: 2.6, lastUpdated: now),
      Stock(ticker: 'C',      name: 'Citigroup',          price: 72.3,   per:  8.6, roe:  7.2, dividendYield: 3.2, lastUpdated: now),
      Stock(ticker: 'WFC',    name: 'Wells Fargo',        price: 71.9,   per: 12.1, roe: 11.3, dividendYield: 2.8, lastUpdated: now),
      Stock(ticker: 'XOM',    name: 'ExxonMobil',         price: 110.4,  per: 13.8, roe: 18.2, dividendYield: 3.5, lastUpdated: now),
      Stock(ticker: 'CVX',    name: 'Chevron',            price: 156.7,  per: 12.3, roe: 14.5, dividendYield: 4.1, lastUpdated: now),
      Stock(ticker: 'VZ',     name: 'Verizon',            price: 41.2,   per:  9.4, roe: 21.3, dividendYield: 6.8, lastUpdated: now),
      Stock(ticker: 'T',      name: 'AT&T',               price: 22.6,   per:  9.8, roe: 13.7, dividendYield: 6.5, lastUpdated: now),
      Stock(ticker: 'MO',     name: 'Altria Group',       price: 44.1,   per: 10.3, roe:  0.0,  dividendYield: 8.9, lastUpdated: now),

      // ── 미국 주식 (배당주: 높은 배당수익률) ──
      Stock(ticker: 'KO',     name: 'Coca-Cola',          price: 63.2,   per: 22.4, roe: 42.8, dividendYield: 3.1, lastUpdated: now),
      Stock(ticker: 'PG',     name: 'Procter & Gamble',   price: 167.3,  per: 25.1, roe: 30.2, dividendYield: 2.4, lastUpdated: now),
      Stock(ticker: 'JNJ',    name: 'Johnson & Johnson',  price: 147.8,  per: 15.2, roe: 22.5, dividendYield: 3.3, lastUpdated: now),
      Stock(ticker: 'PFE',    name: 'Pfizer',             price: 26.5,   per:  9.1, roe:  8.4, dividendYield: 6.4, lastUpdated: now),
      Stock(ticker: 'MRK',    name: 'Merck & Co.',        price: 128.4,  per: 14.7, roe: 60.2, dividendYield: 2.6, lastUpdated: now),
      Stock(ticker: 'ABBV',   name: 'AbbVie',             price: 189.2,  per: 17.3, roe:  0.0,  dividendYield: 3.4, lastUpdated: now),

      // ── 미국 주식 (급등주: 높은 ROE) ──
      Stock(ticker: 'AAPL',   name: 'Apple Inc.',         price: 228.5,  per: 32.1, roe: 147.0, dividendYield: 0.4, lastUpdated: now),
      Stock(ticker: 'MSFT',   name: 'Microsoft Corp.',    price: 415.3,  per: 35.2, roe:  43.1, dividendYield: 0.7, lastUpdated: now),
      Stock(ticker: 'NVDA',   name: 'NVIDIA Corp.',       price: 875.4,  per: 62.3, roe:  91.5, dividendYield: 0.0, lastUpdated: now),
      Stock(ticker: 'META',   name: 'Meta Platforms',     price: 512.8,  per: 26.4, roe:  35.7, dividendYield: 0.4, lastUpdated: now),
      Stock(ticker: 'GOOGL',  name: 'Alphabet Inc.',      price: 178.2,  per: 23.1, roe:  28.9, dividendYield: 0.5, lastUpdated: now),
      Stock(ticker: 'AMZN',   name: 'Amazon.com',         price: 198.7,  per: 42.5, roe:  22.4, dividendYield: 0.0, lastUpdated: now),
      Stock(ticker: 'TSLA',   name: 'Tesla Inc.',         price: 248.3,  per: 55.8, roe:  17.3, dividendYield: 0.0, lastUpdated: now),
      Stock(ticker: 'V',      name: 'Visa Inc.',          price: 284.6,  per: 30.2, roe:  44.8, dividendYield: 0.8, lastUpdated: now),
      Stock(ticker: 'MA',     name: 'Mastercard',         price: 488.1,  per: 36.5, roe:  185.0, dividendYield: 0.5, lastUpdated: now),
      Stock(ticker: 'UNH',    name: 'UnitedHealth',       price: 542.3,  per: 22.8, roe:   28.4, dividendYield: 1.5, lastUpdated: now),
    ];
  }

  @override
  Future<Stock?> getStockByTicker(String ticker) async {
    final stocks = await getStocks();
    try {
      return stocks.firstWhere((s) => s.ticker == ticker);
    } catch (_) {
      return null;
    }
  }
}
