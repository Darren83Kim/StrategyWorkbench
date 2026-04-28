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
  final String dailyBriefTitle;
  final String activeStrategy;
  final String dailyBriefNoActive;
  final String dailyBriefChanges;
  final String dailyBriefNewIn;
  final String dailyBriefExited;
  final String dailyBriefRiskHoldings;
  final String dailyBriefTopPicks;
  final String dailyBriefMovers;
  final String dailyBriefNoChanges;
  final String dailyBriefRecentlyExited;
  final String dailyBriefOutsideStrategy;
  final String watchlistRadarTitle;
  final String watchlistEmptyMessage;

  // Market
  final String marketTitle;
  final String stockDetailTitle;
  final String whyThisStockTitle;
  final String whyThisStockNoActiveStrategy;
  final String whyThisStockDriversTitle;

  // Strategy / Filter
  final String strategyTitle;
  final String strategyCompareAction;
  final String strategyCompareTitle;
  final String strategyCompareLeft;
  final String strategyCompareRight;
  final String strategyCompareNeedTwo;
  final String strategyCompareSameSelection;
  final String strategyCompareOverlap;
  final String strategyCompareOnlyLeft;
  final String strategyCompareOnlyRight;
  final String strategyCompareTopDiffs;
  final String strategyCompareNoOverlap;
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
  final String rebalanceCoachTitle;
  final String rebalanceCoachNoActiveStrategy;
  final String rebalanceCoachAligned;
  final String rebalanceCoachOutsideHoldings;
  final String rebalanceCoachMissingTopPicks;
  final String rebalanceCoachTrimCandidates;
  final String rebalanceCoachSuggestions;
  final String buyMore;
  final String sell;
  final String addStock;
  final String quantity;
  final String price;
  final String cancel;
  final String confirm;
  final String noTransactions;
  final String buy;
  final String viewDetails;
  final String quickActions;

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
    required this.dailyBriefTitle,
    required this.activeStrategy,
    required this.dailyBriefNoActive,
    required this.dailyBriefChanges,
    required this.dailyBriefNewIn,
    required this.dailyBriefExited,
    required this.dailyBriefRiskHoldings,
    required this.dailyBriefTopPicks,
    required this.dailyBriefMovers,
    required this.dailyBriefNoChanges,
    required this.dailyBriefRecentlyExited,
    required this.dailyBriefOutsideStrategy,
    required this.watchlistRadarTitle,
    required this.watchlistEmptyMessage,
    required this.marketTitle,
    required this.stockDetailTitle,
    required this.whyThisStockTitle,
    required this.whyThisStockNoActiveStrategy,
    required this.whyThisStockDriversTitle,
    required this.strategyTitle,
    required this.strategyCompareAction,
    required this.strategyCompareTitle,
    required this.strategyCompareLeft,
    required this.strategyCompareRight,
    required this.strategyCompareNeedTwo,
    required this.strategyCompareSameSelection,
    required this.strategyCompareOverlap,
    required this.strategyCompareOnlyLeft,
    required this.strategyCompareOnlyRight,
    required this.strategyCompareTopDiffs,
    required this.strategyCompareNoOverlap,
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
    required this.rebalanceCoachTitle,
    required this.rebalanceCoachNoActiveStrategy,
    required this.rebalanceCoachAligned,
    required this.rebalanceCoachOutsideHoldings,
    required this.rebalanceCoachMissingTopPicks,
    required this.rebalanceCoachTrimCandidates,
    required this.rebalanceCoachSuggestions,
    required this.buyMore,
    required this.sell,
    required this.addStock,
    required this.quantity,
    required this.price,
    required this.cancel,
    required this.confirm,
    required this.noTransactions,
    required this.buy,
    required this.viewDetails,
    required this.quickActions,
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
    dailyBriefTitle: "Today's Brief",
    activeStrategy: 'Active Strategy',
    dailyBriefNoActive:
        'Set an active strategy in the Strategy tab to unlock daily insights.',
    dailyBriefChanges: "What's Changed",
    dailyBriefNewIn: 'New In',
    dailyBriefExited: 'Exited',
    dailyBriefRiskHoldings: 'Risk Holdings',
    dailyBriefTopPicks: 'Top Picks',
    dailyBriefMovers: 'Movers',
    dailyBriefNoChanges: 'No major changes yet. Top picks are still holding.',
    dailyBriefRecentlyExited: 'Recently exited from the strategy snapshot',
    dailyBriefOutsideStrategy: 'Currently outside the active strategy Top N',
    watchlistRadarTitle: 'Watchlist Radar',
    watchlistEmptyMessage:
        'No watchlisted stocks yet.\nStar stocks in the Strategy tab.',
    marketTitle: 'Market',
    stockDetailTitle: 'Stock Detail',
    whyThisStockTitle: 'Why This Stock',
    whyThisStockNoActiveStrategy:
        'Set an active strategy to see explanation-based insights here.',
    whyThisStockDriversTitle: 'Key Drivers',
    strategyTitle: 'Strategy Filter',
    strategyCompareAction: 'Compare',
    strategyCompareTitle: 'Strategy Comparison',
    strategyCompareLeft: 'Left Strategy',
    strategyCompareRight: 'Right Strategy',
    strategyCompareNeedTwo: 'Choose at least two strategies to compare.',
    strategyCompareSameSelection: 'Select two different strategies.',
    strategyCompareOverlap: 'Overlap',
    strategyCompareOnlyLeft: 'Only Left',
    strategyCompareOnlyRight: 'Only Right',
    strategyCompareTopDiffs: 'Largest Rank Gaps',
    strategyCompareNoOverlap: 'No overlapping stocks in the current Top N.',
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
    rebalanceCoachTitle: 'Rebalance Coach',
    rebalanceCoachNoActiveStrategy:
        'Set an active strategy to receive portfolio alignment suggestions.',
    rebalanceCoachAligned:
        'Your holdings are broadly aligned with the active strategy.',
    rebalanceCoachOutsideHoldings: 'Outside Strategy',
    rebalanceCoachMissingTopPicks: 'Missing Top Picks',
    rebalanceCoachTrimCandidates: 'Trim Candidates',
    rebalanceCoachSuggestions: 'Suggested Actions',
    buyMore: 'Buy More',
    sell: 'Sell',
    addStock: 'Add Stock',
    quantity: 'Quantity',
    price: 'Price',
    cancel: 'Cancel',
    confirm: 'Confirm',
    noTransactions: 'No transactions yet.',
    buy: 'Buy',
    viewDetails: 'View Details',
    quickActions: 'Quick Actions',
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
    dailyBriefTitle: '오늘의 브리프',
    activeStrategy: '현재 활성 전략',
    dailyBriefNoActive: '전략 탭에서 활성 전략을 설정하면 오늘의 인사이트가 열립니다.',
    dailyBriefChanges: '오늘의 변화',
    dailyBriefNewIn: '신규 진입',
    dailyBriefExited: '이탈',
    dailyBriefRiskHoldings: '리스크 보유 종목',
    dailyBriefTopPicks: '오늘의 Top Picks',
    dailyBriefMovers: '순위 변동',
    dailyBriefNoChanges: '큰 변화는 없지만 상위 추천 종목은 유지되고 있습니다.',
    dailyBriefRecentlyExited: '최근 전략 스냅샷에서 이탈한 보유 종목',
    dailyBriefOutsideStrategy: '현재 활성 전략 Top N 밖에 있는 보유 종목',
    watchlistRadarTitle: '관심 종목 레이더',
    watchlistEmptyMessage: '관심 종목이 없습니다.\n전략 탭에서 ★ 표시로 종목을 선택하세요.',
    marketTitle: '마켓',
    stockDetailTitle: '종목 상세',
    whyThisStockTitle: '왜 이 종목인가',
    whyThisStockNoActiveStrategy: '활성 전략을 설정하면 전략 기준 설명이 여기에 표시됩니다.',
    whyThisStockDriversTitle: '핵심 드라이버',
    strategyTitle: '전략 필터',
    strategyCompareAction: '비교',
    strategyCompareTitle: '전략 비교',
    strategyCompareLeft: '왼쪽 전략',
    strategyCompareRight: '오른쪽 전략',
    strategyCompareNeedTwo: '비교하려면 전략이 2개 이상 필요합니다.',
    strategyCompareSameSelection: '서로 다른 두 전략을 선택해주세요.',
    strategyCompareOverlap: '겹치는 종목',
    strategyCompareOnlyLeft: '왼쪽만 보유',
    strategyCompareOnlyRight: '오른쪽만 보유',
    strategyCompareTopDiffs: '순위 차이 큰 종목',
    strategyCompareNoOverlap: '현재 Top N 기준 겹치는 종목이 없습니다.',
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
    rebalanceCoachTitle: '리밸런싱 코치',
    rebalanceCoachNoActiveStrategy: '활성 전략을 설정하면 포트폴리오 정렬 제안이 여기에 표시됩니다.',
    rebalanceCoachAligned: '현재 보유 종목은 활성 전략과 대체로 잘 맞고 있습니다.',
    rebalanceCoachOutsideHoldings: '전략 밖 보유',
    rebalanceCoachMissingTopPicks: '미보유 상위 종목',
    rebalanceCoachTrimCandidates: '비중 점검',
    rebalanceCoachSuggestions: '추천 액션',
    buyMore: '추가 매수',
    sell: '매도',
    addStock: '종목 추가',
    quantity: '수량',
    price: '가격',
    cancel: '취소',
    confirm: '확인',
    noTransactions: '거래 내역이 없습니다.',
    buy: '매수',
    viewDetails: '상세 보기',
    quickActions: '빠른 액션',
    filterTabUs: '미국',
    filterTabKor: '한국',
    filterTabBlend: '혼합',
    loading: '로딩 중...',
    error: '오류',
    langToggle: 'EN',
  );
}
