# Strategy Workbench - 작업 진행 현황

**프로젝트**: Strategy Workbench (Flutter 기반 주식 전략 분석 앱)
**마지막 업데이트**: 2026년 3월 10일
**현재 Phase**: Phase E (통합 & 연결) ✅ 완료 → 실기기 테스트 준비

---

## 📋 전체 Phase 진행 현황

| Phase | 내용 | 상태 |
|-------|------|------|
| A | API 인프라 구축 | ✅ 완료 |
| B | UI 화면 구현 | ✅ 완료 |
| C | API 재설계 & 안정화 | ✅ 완료 |
| D | Riverpod 상태 관리 통합 | ✅ 완료 |
| E | 통합 & 연결 (Integration) | ✅ 완료 |

---

## Phase D: Riverpod 상태 관리 통합 ✅ (2026-03-10 완료)

### Riverpod 3.1.0 마이그레이션 (Breaking Changes 대응)
- `StateProvider` 제거됨 → 커스텀 `Notifier` + `NotifierProvider` 패턴으로 교체
- `valueOrNull` 제거됨 → `.value` (nullable) 사용
- 각 Notifier에 `.set()` 메서드로 상태 업데이트

### Provider 파일 구조

**`lib/core/providers/stock_providers.dart`**
- `hybridRepositoryProvider`: HybridStockRepository 싱글턴
- `marketFilterProvider`: MarketFilter (us/korea/hybrid) - NotifierProvider
- `weightsProvider`: 가중치 Map - NotifierProvider
- `stockListProvider`: FutureProvider.autoDispose (Hive 캐시 → API 폴백)
- `scoredStockListProvider`: ScoringEngine 적용 결과
- `dataSourceStatusProvider`: API 소스 상태

**`lib/core/providers/filter_providers.dart`**
- `presetsProvider`: 4가지 프리셋 (Warren Buffett, Growth, Value, Dividend)
- `savedFiltersProvider`: AsyncNotifier + SharedPreferences 연동
- `activeFilterProvider`: NotifierProvider

**`lib/core/providers/portfolio_providers.dart`**
- `portfolioProvider`: 포트폴리오 Notifier (buy/sell/updatePrice)
- `transactionHistoryProvider`: AsyncNotifier + SQLite(DatabaseHelper) 연동
- `portfolioSummaryProvider`: 계산된 요약 (총비용/총가치/손익/손익률)
- 매수/매도 시 Hive settings에 ticker 자동 동기화

### 화면 Riverpod 전환

**DashboardScreen** (StatefulWidget → ConsumerWidget)
- `scoredStockListProvider` 로 순위 목록 표시
- `portfolioSummaryProvider` 로 포트폴리오 요약
- `marketFilterProvider` 로 필터 탭 (US/Korea/Hybrid)
- `ref.invalidate()` 로 새로고침

**FilterCreationScreen** (StatefulWidget → ConsumerStatefulWidget)
- `weightsProvider` 와 실시간 연동 (슬라이더 변경 → 즉시 스코어 업데이트)
- `scoredStockListProvider` 로 Top 10 미리보기
- `savedFiltersProvider.notifier.addFilter()` 로 실제 필터 저장
- `presetsProvider` 프리셋 적용

**PortfolioScreen** (StatefulWidget → ConsumerStatefulWidget)
- `portfolioProvider` 실제 포트폴리오 데이터 (Mock 하드코딩 제거)
- `transactionHistoryProvider` SQLite 거래내역
- Buy More / Sell 다이얼로그 → 실제 Riverpod 상태 업데이트 + 거래 기록

**MarketScreen** (StatelessWidget → ConsumerWidget)
- `stockListProvider` 로 비동기 데이터 로드
- `.when()` 패턴 (loading/error/data)
- PER/ROE 태그 표시

---

## Phase E: 통합 & 연결 ✅ (2026-03-10 완료)

### 발견된 문제 & 해결

| # | 문제 | 해결 |
|---|------|------|
| 1 | main.dart DataSync가 MockStockRepository 사용 | ✅ HybridStockRepository로 교체 |
| 2 | MarketScreen이 MockStockRepository 직접 사용 | ✅ Riverpod ConsumerWidget으로 전환 |
| 3 | BackgroundService가 모든 Mock 데이터 사용 | ✅ Hive/SharedPreferences 실 데이터 연동 |
| 4 | HybridStockRepository가 StockRepository 미구현 | ✅ implements StockRepository 추가 |
| 5 | Hive 캐시가 Riverpod providers와 미연결 | ✅ stockListProvider에 캐시-퍼스트 전략 추가 |
| 6 | 포트폴리오 변경이 BackgroundService에 미전달 | ✅ Hive settings에 ticker 자동 동기화 |

### BackgroundService 리팩토링 (실 데이터 연동)
- **이전**: `_getMockStockData()`, `_getMockUserPortfolio()`, `_getMockUserStrategy()`
- **이후**:
  - Hive `stock_cache` → 캐시된 주식 데이터 로드
  - Hive `settings.portfolio_tickers` → 포트폴리오 종목 로드
  - SharedPreferences `active_filter` → 활성 필터 가중치 로드
  - 별도 Isolate에서 Hive 재초기화 (WorkManager 요구사항)

### Hive 캐시 레이어 추가
- `stockListProvider`: Hive `stock_cache` → 오늘 날짜 데이터 있으면 캐시 사용
- 캐시 미스 시 API 호출 (HybridStockRepository)
- 필터 (US/Korea/Hybrid) 캐시 데이터에서도 적용

---

## 🗂️ 핵심 파일 맵 (Phase E 기준)

```
lib/
├── main.dart
│   ├── MyApp (MaterialApp.router + AppTheme.darkTheme)
│   ├── 초기화: HiveService → NotificationService → BackgroundService → DataSync
│   └── DebugScreen (API 테스트 유지)
├── core/
│   ├── constants/api_keys.dart (flutter_dotenv 기반)
│   ├── extensions/stock_extension.dart (strategy.Stock → market.Stock)
│   ├── network/
│   │   ├── dio_client.dart (HTTP 클라이언트)
│   │   ├── hive_service.dart (Hive 초기화, stock_cache + settings 박스)
│   │   └── database_helper.dart (SQLite, 거래 내역)
│   ├── providers/
│   │   ├── stock_providers.dart ⭐ (Hive 캐시 + API + ScoringEngine)
│   │   ├── filter_providers.dart (SharedPreferences 필터 저장)
│   │   └── portfolio_providers.dart ⭐ (Hive ticker 동기화 포함)
│   ├── router/app_router.dart (GoRouter + ShellRoute)
│   ├── scoring/scoring_engine.dart (Min-Max + 가중합)
│   ├── services/
│   │   ├── background_service.dart ⭐ (Hive/SharedPreferences 실 데이터)
│   │   ├── notification_service.dart (전략 이탈 알림)
│   │   └── ad_service.dart (구현됨, 미연결)
│   └── theme/app_theme.dart (Dark Glassmorphism)
├── features/
│   ├── dashboard/presentation/dashboard_screen.dart (ConsumerWidget)
│   ├── strategy/
│   │   ├── data/repositories/
│   │   │   ├── hybrid_stock_repository.dart (implements StockRepository)
│   │   │   ├── finnhub_stock_repository.dart
│   │   │   ├── yahoo_stock_repository.dart
│   │   │   ├── krx_dart_stock_repository.dart
│   │   │   ├── kor_investment_repository.dart
│   │   │   └── mock_stock_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/stock.dart (HiveObject, TypeId: 0)
│   │   │   ├── repositories/stock_repository.dart (interface)
│   │   │   └── services/data_sync_service.dart (일 1회 동기화)
│   │   └── presentation/filter_creation_screen.dart (ConsumerStatefulWidget)
│   ├── portfolio/
│   │   ├── domain/entities/transaction.dart (BUY/SELL)
│   │   ├── domain/services/portfolio_service.dart (평단가 계산)
│   │   └── presentation/portfolio_screen.dart (ConsumerStatefulWidget)
│   └── market/
│       ├── models/stock.dart (JsonSerializable)
│       └── presentation/
│           ├── market_screen.dart (ConsumerWidget)
│           └── stock_detail.dart
├── shared/widgets/
│   ├── glass_container.dart
│   ├── root_layout.dart (ShellRoute BottomNavigationBar)
│   └── banner_ad_widget.dart (구현됨, 미연결)

.env (실제 API 키 등록 완료)
pubspec.yaml (assets: [.env] 추가됨)
```

---

## 📡 API 데이터 소스 우선순위

```
US: Finnhub(1순위, 60회/분) → Yahoo(폴백) → Mock
KR: KRX+DART(1순위, 10,000회/일) → 한국투자증권(폴백) → Mock
```

### .env 등록 현황
| 키 | 상태 |
|----|------|
| FINNHUB_API_KEY | ✅ 등록 완료 |
| FMP_API_KEY | ✅ 등록 완료 |
| DART_API_KEY | ✅ 등록 완료 |
| KRX_API_KEY | ⏳ 신청 중 (KRX+DART 사용 시 필요) |
| KOR_INVESTMENT_APP_KEY | ✅ 기존 유지 |
| KOR_INVESTMENT_SECRET | ✅ 기존 유지 |

---

## 🔄 데이터 흐름

```
[앱 시작]
  main.dart → HiveService.init() → DataSyncService.syncStocksIfNeeded()
    ↓ (오늘 날짜 != last_update_date)
  HybridStockRepository.getAllStocks() → API 호출
    ↓
  Hive stock_cache에 저장 (ticker → Stock)
    ↓
  settings.put('last_update_date', today)

[화면 표시]
  stockListProvider
    ↓ (Hive 캐시 오늘 날짜?)
  YES → Hive stock_cache에서 로드 (빠름)
  NO  → HybridStockRepository → API 호출

[백그라운드 체크 (오후 4시)]
  callbackDispatcher (별도 Isolate)
    ↓
  Hive stock_cache → 주식 데이터
  Hive settings.portfolio_tickers → 보유 종목
  SharedPreferences.active_filter → 가중치/감도
    ↓
  ScoringEngine → 순위 이탈 감지 → 알림
```

---

## 💡 기술 스택

| 항목 | 기술 | 버전 | 상태 |
|------|------|------|------|
| 프레임워크 | Flutter | 3.0+ | ✅ |
| 언어 | Dart | 3.0+ | ✅ |
| HTTP | Dio | 5.9.0 | ✅ |
| 라우팅 | go_router | 17.0.0 | ✅ |
| 상태관리 | Riverpod | 3.1.0 | ✅ 통합 완료 |
| 로컬 캐시 | Hive | - | ✅ 연동 완료 |
| 트랜잭션 DB | SQLite (sqflite) | - | ✅ 연동 완료 |
| 설정 저장 | SharedPreferences | - | ✅ 연동 완료 |
| 백그라운드 | WorkManager | - | ✅ 실 데이터 연동 |
| 알림 | flutter_local_notifications | - | ✅ |
| 디자인 | Glassmorphism | Dark Mode | ✅ |
| 환경설정 | flutter_dotenv | 5.1.0 | ✅ |

---

## ✅ 최종 검증 결과 (2026-03-10)

```
flutter analyze: 에러 0개, 경고 0개, info 13개 (코드 스타일 권장)
```

Info 항목 (동작에 영향 없음):
- library_prefixes (strategyStock, marketStock 네이밍 컨벤션)
- constant_identifier_names (BUY, SELL enum)
- prefer_const_declarations (1건)
- avoid_print (data_sync_service.dart, developer.log로 교체 권장)
- prefer_interpolation_to_compose_strings (main.dart DebugScreen)

---

## 📝 미해결 & 향후 작업

### 낮은 우선순위
- [ ] Ad 서비스 연결 (ad_service.dart, banner_ad_widget.dart 구현됨, 미연결)
- [ ] data_sync_service.dart print → developer.log 교체
- [ ] Stock 모델 통일 (strategy.Stock / market.Stock 이중 구조)

### 실기기 테스트 시 확인 항목
- [ ] Finnhub API 실제 데이터 수신 확인
- [ ] KRX+DART or 한국투자증권 API 데이터 확인
- [ ] Hive 캐시 동작 확인 (앱 재시작 시 빠른 로드)
- [ ] 포트폴리오 매수/매도 → SQLite 거래내역 기록 확인
- [ ] 필터 저장 → SharedPreferences 영속성 확인
- [ ] BackgroundService 알림 테스트 (forceRunTask)
- [ ] 네비게이션 (Dashboard ↔ Market ↔ Strategy ↔ Portfolio)

---

**마지막 코드 수정**: 2026-03-10 Phase E 완료 (통합 & 연결)
**검증**: flutter analyze 에러 0개, 경고 0개
**다음 작업**: 실기기 테스트 → 이슈 수정 → 출시 준비
