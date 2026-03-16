/// 앱 전체 UI 문자열 (한국어 / 영어)
class AppStrings {
  final String appTitle;

  // 하단 네비게이션
  final String navDashboard;
  final String navMarket;
  final String navStrategy;
  final String navPortfolio;

  // Dashboard
  final String dashboardTitle;
  final String filterStrategy;
  final String refresh;
  final String noStocksAvailable;
  final String loadFailed;
  final String retry;
  final String totalValue;
  final String gainLoss;
  final String holdings;

  // Market
  final String marketTitle;

  // Strategy / Filter
  final String strategyTitle;
  final String filterName;
  final String filterNameHint;
  final String presets;
  final String weights;
  final String preview;
  final String saveFilter;
  final String filterNameEmpty;
  final String filterSaved;

  // Portfolio
  final String portfolioTitle;
  final String totalInvestment;
  final String currentValue;
  final String holdingsList;
  final String transactions;
  final String buyMore;
  final String sell;
  final String addStock;
  final String quantity;
  final String price;
  final String cancel;
  final String confirm;
  final String noTransactions;
  final String buy;

  // Market Filter Tabs
  final String filterTabUs;
  final String filterTabKor;
  final String filterTabBlend;

  // Common
  final String loading;
  final String error;
  final String langToggle;

  const AppStrings({
    required this.appTitle,
    required this.navDashboard,
    required this.navMarket,
    required this.navStrategy,
    required this.navPortfolio,
    required this.dashboardTitle,
    required this.filterStrategy,
    required this.refresh,
    required this.noStocksAvailable,
    required this.loadFailed,
    required this.retry,
    required this.totalValue,
    required this.gainLoss,
    required this.holdings,
    required this.marketTitle,
    required this.strategyTitle,
    required this.filterName,
    required this.filterNameHint,
    required this.presets,
    required this.weights,
    required this.preview,
    required this.saveFilter,
    required this.filterNameEmpty,
    required this.filterSaved,
    required this.portfolioTitle,
    required this.totalInvestment,
    required this.currentValue,
    required this.holdingsList,
    required this.transactions,
    required this.buyMore,
    required this.sell,
    required this.addStock,
    required this.quantity,
    required this.price,
    required this.cancel,
    required this.confirm,
    required this.noTransactions,
    required this.buy,
    required this.filterTabUs,
    required this.filterTabKor,
    required this.filterTabBlend,
    required this.loading,
    required this.error,
    required this.langToggle,
  });

  static const en = AppStrings(
    appTitle: 'Strategy Workbench',
    navDashboard: 'Dashboard',
    navMarket: 'Market',
    navStrategy: 'Strategy',
    navPortfolio: 'Portfolio',
    dashboardTitle: 'Strategy Dashboard',
    filterStrategy: 'Filter',
    refresh: 'Refresh',
    noStocksAvailable: 'No stocks available',
    loadFailed: 'Failed to load:',
    retry: 'Retry',
    totalValue: 'Total Value',
    gainLoss: 'Gain / Loss',
    holdings: 'Holdings',
    marketTitle: 'Market',
    strategyTitle: 'Strategy Filter',
    filterName: 'Filter Name',
    filterNameHint: 'e.g. My Value Strategy',
    presets: 'Presets',
    weights: 'Weights',
    preview: 'Top 10 Preview',
    saveFilter: 'Save Filter',
    filterNameEmpty: 'Please enter a filter name.',
    filterSaved: 'Filter saved!',
    portfolioTitle: 'Portfolio',
    totalInvestment: 'Total Investment',
    currentValue: 'Current Value',
    holdingsList: 'Holdings',
    transactions: 'Transactions',
    buyMore: 'Buy More',
    sell: 'Sell',
    addStock: 'Add Stock',
    quantity: 'Quantity',
    price: 'Price',
    cancel: 'Cancel',
    confirm: 'Confirm',
    noTransactions: 'No transactions yet.',
    buy: 'Buy',
    filterTabUs: 'US',
    filterTabKor: 'KOR',
    filterTabBlend: 'BLEND',
    loading: 'Loading...',
    error: 'Error',
    langToggle: 'KO',
  );

  static const ko = AppStrings(
    appTitle: '전략 워크벤치',
    navDashboard: '대시보드',
    navMarket: '마켓',
    navStrategy: '전략',
    navPortfolio: '포트폴리오',
    dashboardTitle: '전략 대시보드',
    filterStrategy: '필터',
    refresh: '새로고침',
    noStocksAvailable: '종목 데이터 없음',
    loadFailed: '로드 실패:',
    retry: '다시 시도',
    totalValue: '총 평가액',
    gainLoss: '손익',
    holdings: '보유 종목',
    marketTitle: '마켓',
    strategyTitle: '전략 필터',
    filterName: '필터 이름',
    filterNameHint: '예: 내 가치주 전략',
    presets: '프리셋',
    weights: '가중치',
    preview: 'Top 10 미리보기',
    saveFilter: '필터 저장',
    filterNameEmpty: '필터 이름을 입력해주세요.',
    filterSaved: '필터가 저장되었습니다!',
    portfolioTitle: '포트폴리오',
    totalInvestment: '총 투자금',
    currentValue: '현재 평가액',
    holdingsList: '보유 종목',
    transactions: '거래 내역',
    buyMore: '추가 매수',
    sell: '매도',
    addStock: '종목 추가',
    quantity: '수량',
    price: '가격',
    cancel: '취소',
    confirm: '확인',
    noTransactions: '거래 내역이 없습니다.',
    buy: '매수',
    filterTabUs: '미국',
    filterTabKor: '한국',
    filterTabBlend: '혼합',
    loading: '로딩 중...',
    error: '오류',
    langToggle: 'EN',
  );
}
