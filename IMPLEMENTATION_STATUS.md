# Strategy Workbench Implementation Status

- Last updated: 2026-07-06
- Purpose: `phase1~6.md`를 매번 다시 읽지 않아도 현재 구현 상태를 빠르게 확인하기 위한 문서
- Update rule: 구현 또는 리뷰 작업을 한 뒤에는 이 파일의 날짜와 상태부터 먼저 갱신한다.
- Execution plan: `PHASE3_5_EXECUTION_PLAN.md`
- Release prep checklist: `RELEASE_PREP_CHECKLIST.md`

## Quick Check

| Phase | Status | Quick summary |
|------|------|------|
| Phase 1 | 대체로 구현 | 앱 셸, 라우팅, 테마, GlassContainer, 디버그 라우트 존재 |
| Phase 2 | 대체로 구현 | Hive/SQLite, Mock/Hybrid repository, 평단가 계산, 일일 sync, 실데이터 fetch/폴백, KIS 토큰 안전장치, Naver/Nasdaq 키 없는 quote fallback 반영 |
| Phase 3 | 대체로 구현 | 민감도 저장, 활성 전략, 전략 UI, 퍼센트 기반 백그라운드 알림 연결 완료 |
| Phase 4 | 대체로 구현 | 상세 화면 위젯 테스트, 포트폴리오→상세 UX 정리, 포트폴리오 금액 가독성 개선까지 반영됨 |
| Phase 5 | 부분 구현 | 테스트 광고 기준 배너/전면 광고/Fail-safe 연결 완료, 개발 빌드 시작 지연 완화와 debug 광고 비활성 스위치 반영 |
| Phase 6 | 부분 구현 | 오늘의 브리프, 전략 설명, 리밸런싱 코치, 전략 비교, 시장별 전략 리스트, 스냅샷 계산 최적화 반영 |

## Detailed Status

### Phase 1. Foundation & App Shell

**Implemented**

- `AppTheme.darkTheme`와 다크 배경이 존재한다.
- `GlassContainer`가 `BackdropFilter` 기반으로 구현되어 있다.
- 디버그 빌드에서는 `GlassContainer`가 blur 대신 반투명 패널 fallback을 사용해 에뮬레이터 입력 반응성을 우선한다.
- 앱 시작 직후 무거운 서비스 초기화는 지연 실행되고, 활성 전략이 없으면 알림/백그라운드 런타임을 올리지 않도록 최적화되었다.
- 디버그 빌드에서는 알림 런타임과 데이터 sync를 더 늦춰 첫 화면 반응성을 우선한다.
- `go_router` 기반 라우팅과 앱 셸이 존재한다.
- 앱 시작 경로는 `dashboard`이며 `DebugScreen`은 별도 `/debug` 라우트로 분리되어 있다.

**Notable gaps**

- 문서 초안에 있던 "DebugScreen을 시작 화면으로 사용"은 현재 구현과 다르다.
- 움직이는 컬러 원 기반 blur 검증 화면은 구현되어 있지 않다.
- 디버그 에뮬레이터에서는 시작 직후 큰 skipped frame이 1회 남아 있어, 실제 성능은 profile/release 기준 추가 검증이 필요하다.

**Primary evidence**

- `lib/main.dart`
- `lib/core/router/app_router.dart`
- `lib/core/theme/app_theme.dart`
- `lib/shared/widgets/glass_container.dart`

### Phase 2. Data Layer & Local Persistence

**Implemented**

- 전략 주식 모델과 거래 이력 모델이 존재한다.
- Hive `stock_cache`, `settings`와 SQLite `transactions`가 초기화된다.
- 포트폴리오는 거래 내역(SQLite) 기준으로 재구성되고 Hive snapshot으로도 복원된다.
- `StockRepository`, `MockStockRepository`, `HybridStockRepository` 구조가 존재한다.
- `PortfolioService.calculateAveragePrice()`와 단위 테스트가 존재한다.
- `DataSyncService`와 provider 캐시 우선 조회가 존재한다.
- `HybridStockRepository` 기본 경로에 한국투자증권 fallback 주입이 연결되었다.
- `FmpStockRepository`가 추가되어 `Finnhub → FMP → Yahoo` 순서의 미국 폴백 구조가 실제 구현되었다.
- `NasdaqStockRepository`가 추가되어 Yahoo가 차단/실패하는 release 테스트 환경에서도 미국 종목 현재가와 이름을 공개 quote endpoint로 보완한다.
- `NaverStockRepository`가 추가되어 KRX/KIS 키가 없는 release 테스트 환경에서도 국내 주식/ETF 현재가와 이름을 공개 quote endpoint로 보완한다.
- 미국/한국 리포지토리가 공용 종목 유니버스를 사용하도록 정리되었다.
- 한국투자증권 기본 표본이 5개에서 10개로 확장되었다.
- 한국투자증권은 debug 런타임에서 자동 토큰 발급을 막고, 운영/profile에서는 발급 토큰과 만료 시각을 SharedPreferences에 저장해 재사용한다.
- debug 런타임에서도 실기기 최신 한국 시세 확인이 필요하면 `ENABLE_KOR_INVESTMENT_DEBUG=true`로 한국투자증권 조회를 명시적으로 켤 수 있다.
- 한국투자증권 인증은 최초 동시 요청이 몰려도 in-flight 인증 Future를 공유해 접근 토큰 발급 요청이 중복되지 않도록 보강했다.
- release/profile 런타임에서는 `KOR_INVESTMENT_*` 값이 있어도 한국투자증권 직접 호출이 켜지지 않도록 차단했다.
- `HybridStockRepository`는 소스를 첫 성공에서 바로 반환하지 않고, 우선순위에 따라 병합해 누락 종목과 빈 지표를 보완한다.
- debug에서 한국투자 fallback이 비활성화되면 한국 종목은 가능한 KRX/DART 또는 Mock/cached 데이터로 동작한다.
- `DioClient`의 짧은 JSON 응답 로깅 예외가 수정되어 실데이터 요청이 정상 처리된다.
- `strategySnapshotProvider`는 같은 날 비어 있는 스냅샷 캐시를 그대로 신뢰하지 않고 재계산한다.
- `strategySnapshotProvider`의 점수 계산은 `compute()` 기반 background isolate로 이동했다.
- 전략/마켓 새로고침은 전략 스냅샷뿐 아니라 같은 날 종목 캐시 날짜도 함께 무효화해 오래된 가격이 계속 재사용되는 문제를 줄인다.
- 주식 캐시 버전과 전략 스냅샷 캐시 키를 분리/갱신해 오래된 mock 가격이 release 테스트에 남는 문제를 줄였다.
- 진단 도구 `tool/live_data_probe.dart`가 추가되어 런타임 기준 실데이터 응답 수를 빠르게 확인할 수 있다.
- 2026-04-20 기준 진단 실행에서 실런타임 데이터가 `US 10`, `KR 10`, `ALL 20`으로 확인되었다.

**Notable gaps**

- 날짜를 "내일"로 강제하는 자동화 테스트는 없다.
- SQLite 스키마는 기본 수준이며 foreign key/migration 설계는 아직 약하다.
- Mock-first 검증은 있었지만, 현재 런타임 기본 흐름은 이미 Hybrid/API 중심이라 문서와 표현 차이가 있었다.
- Yahoo Finance 폴백은 환경에 따라 401/429 응답으로 기대대로 동작하지 않을 수 있어 Nasdaq quote fallback으로 보완한다.
- Nasdaq/Naver 공개 quote fallback은 출시 전 실기기 확인용 안정화 수단이며, 장기 운영용 데이터 정책은 공식/상용 API 또는 서버 캐시 구조로 별도 확정이 필요하다.
- `KRX_API_KEY`가 비어 있고 debug 한국투자 조회 opt-in도 꺼져 있으면 한국 데이터는 Mock/cached 데이터 중심으로 동작한다.
- FMP free tier는 현재 `profile` 응답은 가능하지만 일부 상세 펀더멘탈 endpoint는 401이라, FMP는 가격/이름 중심 보조 소스로 동작한다.

**Primary evidence**

- `lib/core/network/hive_service.dart`
- `lib/core/network/database_helper.dart`
- `lib/features/strategy/domain/services/data_sync_service.dart`
- `lib/core/providers/stock_providers.dart`
- `lib/core/providers/snapshot_providers.dart`
- `lib/core/network/dio_client.dart`
- `lib/features/strategy/data/repositories/fmp_stock_repository.dart`
- `lib/features/strategy/data/repositories/nasdaq_stock_repository.dart`
- `lib/features/strategy/data/repositories/naver_stock_repository.dart`
- `lib/features/strategy/data/repositories/kor_investment_repository.dart`
- `lib/features/strategy/data/repositories/stock_universe.dart`
- `lib/core/cache/stock_cache_keys.dart`
- `tool/live_data_probe.dart`
- `test/portfolio_service_test.dart`

### Phase 3. Strategy Engine & Alerts

**Implemented**

- Min-Max 기반 스코어링 엔진이 존재한다.
- `SavedFilter`가 `weights`, `topN`, `sensitivity`를 저장한다.
- `activeStrategyNameProvider`, `activeStrategyProvider`로 활성 전략을 영속 관리한다.
- 전략 저장 화면이 민감도 선택을 저장하고, 저장 직후 해당 전략을 활성 전략으로 설정한다.
- 전략 목록 화면에서 현재 활성 전략이 보이고, 전략별 활성화 전환이 가능하다.
- Top N 변경, 저장, 삭제 시 전략 스냅샷 캐시를 정리한다.
- WorkManager 백그라운드 작업이 `active_strategy_name` + `saved_filters`를 읽어 실제 활성 전략을 복원한다.
- 민감도 임계값이 고정 rank가 아니라 상위 `10% / 20% / 30%` 비율로 계산된다.
- `AlertRuntimeService`가 도입되어 활성 전략이 없을 때는 알림/백그라운드 초기화를 건너뛰고, 전략이 활성화될 때만 등록한다.
- Phase 3 회귀 테스트가 추가되었다.

**Notable gaps**

- WorkManager 실제 디바이스 실행 기준 end-to-end 검증은 아직 못 했다.
- 활성 전략이 없을 때 background isolate 전체 흐름을 검증하는 테스트는 아직 없다.
- 알림 중복 제어와 장기 빈도 정책은 기본 수준이다.

**Primary evidence**

- `lib/core/scoring/scoring_engine.dart`
- `lib/core/services/notification_service.dart`
- `lib/core/services/background_service.dart`
- `lib/core/providers/filter_providers.dart`
- `lib/features/strategy/presentation/filter_creation_screen.dart`
- `lib/features/strategy/presentation/strategy_screen.dart`
- `test/filter_providers_test.dart`
- `test/background_service_test.dart`

### Phase 4. Strategy UX & Detail Experience

**Implemented**

- 대시보드/전략/포트폴리오/상세 화면이 존재한다.
- 레이더 차트와 정규화 로직이 존재한다.
- 스마트 태그 규칙과 관련 테스트가 존재한다.
- `stockDetailProvider`가 실데이터 기준으로 현재 종목, 정규화 지표, 태그를 계산한다.
- 종목 상세 화면이 `MockStockRepository` 직접 의존 없이 provider 기반으로 동작한다.
- 거래 이력 타임라인이 종목 상세 화면에 ticker 기준으로 연결되었다.
- 거래 이력 UI가 `TransactionTimelineList` 공용 위젯으로 분리되어 포트폴리오와 상세 화면에서 재사용된다.
- 종목이 없을 때 첫 종목 fallback 대신 명시적인 not found 상태를 보여준다.
- `phase4_ui_test.dart`로 상세 화면 렌더링과 not found 상태를 검증한다.
- 포트폴리오 카드는 탭 시 전체 상세 라우트로 이동하고, 바텀시트는 빠른 액션 시트 역할로 정리되었다.
- 빠른 액션 시트에서도 상세 보기, 추가 매수, 매도 흐름을 제공한다.
- 국내 주식 코드는 6자리 종목코드를 ticker 내부값처럼 사용하며, 입력 시 누락된 앞자리 0을 보정한다.
- 포트폴리오에 직접 추가된 종목은 전략/마켓 유니버스에 없어도 상세 화면에서 보유 정보 기반 fallback 상세를 표시한다.
- 상세/전략 리스트 가격 표시는 국내 6자리 코드는 원화, 미국 티커는 달러 형식으로 구분한다.
- 포트폴리오 요약/보유 상세/리밸런싱 코치 금액 표시는 천 단위 구분과 시장별 통화 표기를 사용한다.
- 리밸런싱 코치의 보조 금액 정보는 본문 아래 칩 형태로 정리해 긴 원화 금액이 제목/설명과 겹치지 않도록 개선했다.
- 종목 상세는 같은 날 캐시보다 repository live 조회를 먼저 시도해, 실시간 소스가 가능한 경우 stale/mock 가격 대신 최신 가격을 우선 표시한다.
- 한국투자증권 live 응답에서 종목명이 비거나 코드로만 올 때도 기본 국내 종목 유니버스 이름으로 보강해 상세/대시보드 이름 표시를 안정화했다.

**Notable gaps**

- 상세/포트폴리오 액션 시트의 일부 문구는 아직 하드코딩이 남아 있다.
- 포트폴리오의 quick action sheet 자체에 대한 시각적 위젯 회귀 범위는 기본 수준이다.
- 포트폴리오 전체 합계는 KRW/USD 환산 기준이 아직 없어 혼합 통화 포트폴리오에서는 해석 주의가 필요하다.

**Primary evidence**

- `lib/features/market/presentation/stock_detail.dart`
- `lib/core/providers/stock_detail_providers.dart`
- `lib/shared/widgets/transaction_timeline_list.dart`
- `lib/core/visualization/normalizer.dart`
- `lib/core/tags/smart_tag.dart`
- `lib/features/portfolio/presentation/portfolio_screen.dart`
- `test/normalizer_test.dart`
- `test/smart_tag_test.dart`
- `test/stock_detail_providers_test.dart`
- `test/phase4_ui_test.dart`
- `test/market_classification_test.dart`

### Phase 5. Monetization & Final Fail-safe

**Implemented**

- `google_mobile_ads` 의존성이 추가되었다.
- `AdService`가 `MobileAds.instance.initialize()`, 1시간 frequency cap, 500ms timeout fail-safe를 포함한 전면 광고 로직을 제공한다.
- `BannerAdWidget`가 실제 배너 광고를 로드하고 `RootLayout` 하단에 렌더링된다.
- 광고 SDK는 앱 시작 즉시 강제 초기화하지 않고, 배너/전면 광고가 필요한 시점에 초기화된다.
- 개발 빌드에서는 배너 로드를 첫 프레임 이후 지연시켜 시작 구간 jank를 줄인다.
- debug 런타임에서는 실제 `.env` 값이 있어도 Google 테스트 광고 ID가 강제 사용되며, 성능 진단이 필요할 때는 `--dart-define=DISABLE_DEBUG_ADS=true`로 광고 초기화/로드를 끌 수 있다.
- Android AdMob App ID는 `AndroidManifest.xml` 하드코딩 대신 Gradle manifest placeholder로 주입된다.
- Android 운영용 AdMob App ID / 배너 / 전면 광고 단위 ID는 로컬 `.env`에 반영되었고, 실제 값은 Git에 커밋하지 않는다.
- 개인 `.env`는 Flutter asset에서 제거되어 debug/release 앱 번들에 그대로 포함되지 않는다. 앱 런타임 키는 `--dart-define` 또는 서버/상용 데이터 소스 구조로 주입해야 한다.
- 전략 저장 버튼이 전면 광고 시도를 거친 뒤 저장 완료 흐름으로 이어지도록 연결되었다.
- Android Manifest는 debug 테스트 App ID와 profile/release 실제 App ID를 빌드 설정에서 주입받고, iOS Info.plist에는 아직 Google 테스트 App ID가 등록되어 있다.
- `.env.example`와 `ApiKeys`가 Android/iOS별 AdMob ID 구조를 지원하도록 갱신되었다.
- `ad_service_test.dart`가 추가되었다.

**Notable gaps**

- 현재는 Google 테스트 App ID / 테스트 ad unit ID 기준 구현이다.
- iOS 운영용 App ID와 실제 ad unit ID는 아직 사용자 값으로 교체되지 않았다.
- `app-ads.txt`, developer website, 릴리즈 정책 점검은 아직 남아 있다.
- iOS 실기기 광고 동작과 전략 저장 시 실제 전면 광고 수동 검증은 아직 하지 않았다.

**Primary evidence**

- `pubspec.yaml`
- `lib/shared/widgets/banner_ad_widget.dart`
- `lib/core/services/ad_service.dart`
- `lib/features/strategy/presentation/filter_creation_screen.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `.env.example`
- `test/ad_service_test.dart`

### Phase 6. Insight Layer & Daily Intelligence

**Implemented**

- `phase6.md`와 마스터 문서에 인사이트 중심 확장 방향이 정리되었다.
- `오늘의 브리프`, `왜 이 종목인가`, `리밸런싱 코치`, `전략 비교`, `거래 저널` 우선순위가 정의되었다.
- `dailyBriefProvider`가 활성 전략, 전략 스냅샷, 포트폴리오를 조합해 `신규 진입`, `이탈`, `리스크 보유 종목`, `Top Picks`, `순위 변동`을 계산한다.
- 대시보드 상단에 `오늘의 브리프` Hero card가 추가되어, 활성 전략 기준 핵심 변화를 먼저 요약해서 보여준다.
- 대시보드의 오늘의 브리프, 리스크 보유 종목, 관심 종목 레이더 가격 표시는 스냅샷 fallback을 유지하되 `stockDetailProvider`의 live-first 값으로 화면에서 보강한다.
- 전략 카드 확장 목록에서 종목별 `왜 이 종목인가` 한 줄 요약이 보인다.
- 종목 상세 화면에 활성 전략 기준 `왜 이 종목인가` 설명 카드가 추가되었다.
- 설명 카드는 전략 순위, 순위 변동, 핵심 지표 드라이버를 함께 보여준다.
- `rebalanceCoachProvider`와 포트폴리오 상단 `리밸런싱 코치` 카드가 추가되어 `전략 밖 보유`, `미보유 상위 종목`, `비중 점검` 후보를 보여준다.
- 전략 화면에서 최소 버전 `전략 비교` 시트를 열어 겹치는 종목, 각 전략에만 있는 종목, 순위 차이가 큰 종목을 볼 수 있다.
- 전략 화면에 `전체/국내/미국` 시장 필터가 추가되어, 같은 전략도 시장별 Top N을 별도 스냅샷으로 계산한다.
- 시장별 전략 스냅샷은 캐시 키를 분리해 전체/국내/미국 결과가 서로 섞이지 않도록 했다.
- 전략 카드 종목 설명은 `strategyStockInsightsProvider`에서 전략 단위로 배치 계산되도록 바뀌어, 행 단위 provider 반복을 줄였다.
- 시장별 전략 카드 종목 설명은 해당 시장 스냅샷 기준으로 rank와 설명을 계산한다.
- 대시보드는 첫 프레임 직후 바로 `dailyBriefProvider`를 계산하지 않고, 디버그 빌드에서는 더 긴 지연 후 로드해 시작 체감을 완화한다.
- 전략 스냅샷 점수 계산은 background isolate로 이동해 UI isolate 직접 점유를 줄였다.
- `daily_brief_provider_test.dart`와 `phase6_ui_test.dart`가 추가되었다.
- `stock_detail_providers_test.dart`와 `phase4_ui_test.dart`가 설명 레이어까지 검증하도록 확장되었다.
- `rebalance_coach_provider_test.dart`와 `strategy_screen_test.dart`가 새 인사이트와 전략 카드 요약을 검증한다.
- `strategy_comparison_provider_test.dart`가 추가되었다.

**Notable gaps**

- 거래 저널과 거래 메모도 아직 미구현이다.
- 리밸런싱 코치는 현재 1차 규칙 기반이며, 비중 과다 기준과 추천 우선순위는 추가 튜닝 여지가 있다.
- 전략 비교는 최소 버전만 반영됐고, 점수 차이와 성향 요약은 아직 없다.
- ETF/ETN은 아직 전략 점수 대상 자산 타입으로 정식 분리되지 않았다. 포트폴리오에는 직접 추가할 수 있지만, PER/ROE 기반 전략 설명과 상세 지표는 제한적이다.
- 성능 측면에서는 전략 카드 설명 배치화, 브리프 지연 로딩, 광고 지연 초기화, 스냅샷 isolate 계산으로 완화했지만, 디버그 에뮬레이터 시작 직후 skipped frame은 아직 남아 있다.

**Primary evidence**

- `lib/core/providers/daily_brief_providers.dart`
- `lib/core/providers/stock_detail_providers.dart`
- `lib/core/providers/rebalance_providers.dart`
- `lib/core/providers/strategy_comparison_providers.dart`
- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/features/strategy/presentation/strategy_screen.dart`
- `lib/features/market/presentation/stock_detail.dart`
- `lib/features/portfolio/presentation/portfolio_screen.dart`
- `test/daily_brief_provider_test.dart`
- `test/phase6_ui_test.dart`
- `test/stock_detail_providers_test.dart`
- `test/rebalance_coach_provider_test.dart`
- `test/strategy_comparison_provider_test.dart`
- `test/strategy_screen_test.dart`
- `phase6.md`
- `Global Strategy Workbench Phase.md`

## Intent Alignment Check

### Aligned with original product intent

- 로컬 우선 데이터 처리
- Hive + SQLite 이중 저장 구조
- 전략 가중치 기반 점수 계산
- 포트폴리오와 전략 이탈 알림 연결
- Glassmorphism 기반 다크 UI 방향

### Diverged or only partially aligned

- Phase 1 문서의 "DebugScreen을 시작 화면으로 사용"은 현재 제품 방향과 맞지 않아 수정 필요했다.
- Phase 2 문서의 "Mock-first"는 검증 수단으로는 맞지만, 현재 구현은 이미 Hybrid/API 중심이라 표현 보정이 필요했다.
- Phase 5의 광고는 테스트 광고 기준으로는 연결됐지만, 운영 수익화 단계는 아직 아니다.
- Phase 6의 인사이트 레이어는 브리프, 설명형 전략, 리밸런싱 코치, 전략 비교 최소 버전까지 반영됐지만 거래 저널과 비교 고도화는 아직 남아 있다.

## Implementation Design Priorities

1. Phase 6를 계속 확장한다.
   - 거래 저널 / 메모
   - 전략 비교의 점수 차이/성향 요약 추가
   - 리밸런싱 코치 규칙 튜닝
2. 체감 성능을 개선한다.
   - 활성 전략 스냅샷을 앱 시작 후 더 늦은 타이밍에 사전 캐시하는 구조 검토
   - Daily Brief 계산 결과를 더 직접적으로 재사용할 캐시 구조 검토
   - 에뮬레이터/디버그 기준 병목 구간을 다시 측정
3. Phase 5를 운영 기준으로 마감한다.
   - 실제 Android/iOS App ID 반영
   - 실제 배너/전면 광고 unit ID 교체
   - `app-ads.txt`와 배포 전 점검
4. Phase 3 검증을 강화한다.
   - 활성 전략 없음 상태 background 테스트
   - 디바이스에서 WorkManager 실동작 확인
   - 알림 중복/빈도 제어 보강
5. Phase 4 마감을 위한 문자열/회귀 범위를 보강한다.
   - 액션 시트 하드코딩 문구 정리
   - 필요 시 quick action sheet 세부 위젯 테스트 보강
6. 검증 체계를 계속 안정화한다.
   - 전체 `flutter test` 스위트 재검증
   - 문서의 검증 결과는 재실행 후 지속 갱신

## Verification Note

- 2026-04-20 기준 `flutter test test/dio_client_test.dart test/data_sync_service_test.dart test/snapshot_providers_test.dart test/filter_providers_test.dart test/background_service_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 `flutter test test/hybrid_stock_repository_test.dart test/dio_client_test.dart test/data_sync_service_test.dart test/snapshot_providers_test.dart test/filter_providers_test.dart test/background_service_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 `flutter analyze lib/core/network/dio_client.dart lib/features/strategy/data/repositories/kor_investment_repository.dart lib/features/strategy/data/repositories/hybrid_stock_repository.dart lib/features/strategy/domain/services/data_sync_service.dart lib/core/providers/snapshot_providers.dart tool/live_data_probe.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter analyze lib/features/strategy/data/repositories/stock_universe.dart lib/features/strategy/data/repositories/fmp_stock_repository.dart lib/features/strategy/data/repositories/hybrid_stock_repository.dart lib/features/strategy/data/repositories/kor_investment_repository.dart lib/features/strategy/data/repositories/krx_dart_stock_repository.dart lib/features/strategy/data/repositories/finnhub_stock_repository.dart lib/features/strategy/data/repositories/yahoo_stock_repository.dart test/hybrid_stock_repository_test.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter analyze lib/core/services/alert_runtime_service.dart lib/core/services/notification_service.dart lib/core/services/background_service.dart lib/main.dart lib/features/strategy/presentation/strategy_screen.dart lib/features/strategy/presentation/filter_creation_screen.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter analyze lib/core/providers/portfolio_providers.dart lib/features/portfolio/presentation/portfolio_screen.dart test/portfolio_providers_test.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter analyze lib/core/constants/api_keys.dart lib/core/services/ad_service.dart lib/shared/widgets/banner_ad_widget.dart lib/shared/widgets/root_layout.dart lib/main.dart lib/features/strategy/presentation/filter_creation_screen.dart test/ad_service_test.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter analyze lib/core/providers/daily_brief_providers.dart lib/core/l10n/app_strings.dart lib/features/dashboard/presentation/dashboard_screen.dart test/daily_brief_provider_test.dart test/phase6_ui_test.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter analyze lib/core/providers/stock_detail_providers.dart lib/core/l10n/app_strings.dart lib/features/market/presentation/stock_detail.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart lib/core/services/alert_runtime_service.dart lib/features/strategy/presentation/strategy_screen.dart lib/features/strategy/presentation/filter_creation_screen.dart test/strategy_screen_test.dart` 결과 이슈가 없었다.
- 2026-04-20 기준 `flutter run -d emulator-5554 --no-resident`로 앱을 다시 빌드/설치했고 대시보드 변경 이후에도 디버그 실행이 정상 완료되었다.
- 2026-04-21 기준 `flutter analyze lib/core/providers/stock_detail_providers.dart lib/core/providers/rebalance_providers.dart lib/core/l10n/app_strings.dart lib/features/strategy/presentation/strategy_screen.dart lib/features/portfolio/presentation/portfolio_screen.dart test/stock_detail_providers_test.dart test/rebalance_coach_provider_test.dart test/strategy_screen_test.dart test/phase4_ui_test.dart` 결과 이슈가 없었다.
- 2026-04-21 기준 `flutter test test/strategy_screen_test.dart test/rebalance_coach_provider_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-21 기준 `flutter run -d emulator-5554 --no-resident`로 앱을 다시 빌드/설치했고 전략 카드/리밸런싱 코치 변경 이후에도 디버그 실행이 정상 완료되었다.
- 2026-04-21 기준 `flutter analyze lib/core/providers/strategy_comparison_providers.dart lib/core/l10n/app_strings.dart lib/features/strategy/presentation/strategy_screen.dart test/strategy_comparison_provider_test.dart test/strategy_screen_test.dart` 결과 이슈가 없었다.
- 2026-04-21 기준 `flutter test test/strategy_comparison_provider_test.dart test/strategy_screen_test.dart test/rebalance_coach_provider_test.dart`를 실행했고 통과했다.
- 2026-04-21 기준 에뮬레이터를 재기동한 뒤 `flutter run -d emulator-5554 --no-resident`로 재설치했고, `dumpsys gfxinfo`에서 `Total frames rendered 126`, `Janky frames 10 (7.94%)`, `99th percentile 150ms`를 확인했다.
- 2026-04-21 기준 `flutter analyze lib/features/dashboard/presentation/dashboard_screen.dart lib/core/providers/daily_brief_providers.dart lib/core/providers/stock_detail_providers.dart lib/core/providers/strategy_comparison_providers.dart lib/features/strategy/presentation/strategy_screen.dart test/phase6_ui_test.dart test/strategy_screen_test.dart test/stock_detail_providers_test.dart test/strategy_comparison_provider_test.dart` 결과 이슈가 없었다.
- 2026-04-21 기준 `flutter test test/phase6_ui_test.dart test/strategy_screen_test.dart test/stock_detail_providers_test.dart test/strategy_comparison_provider_test.dart`를 실행했고 통과했다.
- 2026-04-21 기준 전략 카드 설명 배치화와 브리프 지연 로딩 후 에뮬레이터에서 `flutter run -d emulator-5554 --no-resident`로 재설치했고, 시작 직후 로그에서 `Skipped 70 frames`가 확인되었다.
- 2026-04-21 기준 같은 세션의 `dumpsys gfxinfo`에서는 `Total frames rendered 114`, `Janky frames 20 (17.54%)`, `90th percentile 61ms`, `99th percentile 150ms`가 확인되었다.
- 2026-04-21 기준 `flutter run -d emulator-5554 --profile --no-resident`도 수행했고, profile 모드에서도 시작 직후 `Skipped 110 frames` 로그가 남아 디버그 전용 문제가 아니라는 점을 확인했다.
- 2026-04-21 기준 `flutter analyze lib/main.dart lib/shared/widgets/banner_ad_widget.dart lib/core/services/ad_service.dart lib/core/constants/api_keys.dart lib/features/strategy/data/repositories/hybrid_stock_repository.dart lib/features/strategy/data/repositories/kor_investment_repository.dart lib/core/providers/snapshot_providers.dart test/hybrid_stock_repository_test.dart test/snapshot_providers_test.dart` 결과 이슈가 없었다.
- 2026-04-21 기준 `flutter test test/hybrid_stock_repository_test.dart test/snapshot_providers_test.dart test/ad_service_test.dart test/phase6_ui_test.dart test/strategy_screen_test.dart`를 실행했고 통과했다.
- 2026-04-21 기준 Pixel 7 에뮬레이터를 재기동한 뒤 debug 앱을 다시 실행했고, 로그에서 `KorInvestmentRepository`, `Korea Investment`, `oauth2/tokenP`, `Authenticating with Korea`가 잡히지 않아 debug 자동 토큰 발급 차단을 확인했다.
- 2026-04-21 기준 브리프/알림/광고 지연과 스냅샷 isolate 계산 반영 후 `dumpsys gfxinfo`는 `Total frames rendered 131`, `Janky frames 10 (7.63%)`, `90th percentile 31ms`, `99th percentile 150ms`로 확인되었다.
- 2026-04-21 기준 Pixel 7 에뮬레이터 Quick Boot 이후 검은 화면이 발생했으나, 접근성 트리상 Flutter UI는 살아 있었고 cold boot(`emulator -avd Pixel_7 -no-snapshot-load -gpu host`) 후 정상 표시됨을 확인했다. 검은 화면 원인은 광고가 아니라 에뮬레이터 그래픽 스냅샷 문제로 판단했다.
- 2026-04-21 기준 `flutter analyze lib/core/services/ad_service.dart lib/shared/widgets/banner_ad_widget.dart test/ad_service_test.dart`와 `flutter test test/ad_service_test.dart`를 실행했고 통과했다.
- 2026-04-28 기준 `flutter analyze`를 실행했고 이슈가 없었다.
- 2026-04-28 기준 `flutter test`를 실행했고 전체 테스트가 통과했다. 실행 중 `data_sync_service_test.dart`의 고정 날짜 기대값이 현재 날짜 의존 방식으로 안정화되었다.
- 2026-06-25 기준 Android AdMob App ID manifest placeholder와 debug 테스트 ID 강제 분기를 반영했다.
- 2026-06-25 기준 실제 Android AdMob ID 3종은 ignored `.env`에만 반영했고, `git grep`으로 tracked 파일에 실제 AdMob ID가 남지 않았음을 확인했다.
- 2026-06-25 기준 로컬 Flutter SDK 경로가 불완전해 `flutter analyze/test`와 Android assemble 검증은 수행하지 못했다. `android/local.properties`의 `flutter.sdk=C:\DsDevelop\flutter` 아래에 `packages/flutter_tools`가 없어 Gradle이 중단된다.
- 2026-04-20 기준 `flutter run -d emulator-5554 -t tool/live_data_probe.dart --no-resident`로 런타임 진단을 수행했고 `US 10`, `KR 10`, `ALL 20` 응답을 확인했다.
- 2026-04-20 기준 `flutter test test/alert_runtime_service_test.dart test/filter_providers_test.dart test/background_service_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 `flutter test test/ad_service_test.dart test/filter_providers_test.dart test/background_service_test.dart test/portfolio_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 `flutter test test/daily_brief_provider_test.dart test/phase6_ui_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 `flutter test test/strategy_screen_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 `flutter test test/portfolio_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-20 기준 앱 SharedPreferences 스냅샷에서 `가치주`, `My Strategy11`, `퀀트` 전략의 `current` 목록이 실제 티커로 다시 채워진 것을 확인했다.
- 2026-04-20 기준 에뮬레이터 재실행 후 포트폴리오 화면에서 기존 거래 내역만으로 `보유 종목 (1)`과 `AAPL` 카드가 다시 렌더링되는 것을 확인했다.
- 2026-04-20 기준 Pixel 7 에뮬레이터 하단에 Google `Test Ad` 배너가 실제 렌더링되는 것을 확인했다.
- 2026-04-17 기준 `flutter test test/filter_providers_test.dart test/background_service_test.dart`를 실행했고 통과했다.
- 2026-04-17 기준 `flutter test test/stock_detail_providers_test.dart`를 실행했고 통과했다.
- 2026-04-17 기준 `flutter test test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-17 기준 `flutter test test/filter_providers_test.dart test/background_service_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart`를 실행했고 통과했다.
- 2026-04-17 기준 `flutter analyze lib/core/providers/stock_detail_providers.dart lib/shared/widgets/transaction_timeline_list.dart lib/features/market/presentation/stock_detail.dart lib/features/portfolio/presentation/portfolio_screen.dart` 결과 이슈가 없었다.
- 2026-04-17 기준 `flutter analyze lib/core/l10n/app_strings.dart lib/features/portfolio/presentation/portfolio_screen.dart lib/features/market/presentation/stock_detail.dart test/phase4_ui_test.dart` 결과 이슈가 없었다.
- 2026-04-17 기준 변경 파일에 `dart format`을 적용했다.
- 2026-06-26 기준 시장별 전략 리스트와 포트폴리오 보유 종목 상세 fallback 반영 후 `flutter analyze`를 실행했고 이슈가 없었다.
- 2026-06-26 기준 `flutter test` 전체 스위트를 실행했고 전체 테스트가 통과했다.
- 2026-06-26 기준 한국투자증권 debug opt-in, live-first 종목 상세 조회, 종목 캐시 강제 갱신을 반영한 뒤 `flutter test test/stock_detail_providers_test.dart test/snapshot_providers_test.dart test/strategy_screen_test.dart test/hybrid_stock_repository_test.dart`를 실행했고 통과했다.
- 2026-06-26 기준 같은 변경 후 `flutter analyze`를 실행했고 이슈가 없었다.
- 2026-06-26 기준 debug APK를 다시 빌드했고 `17aca220` 실기기의 `/sdcard/Download/strategy_workbench_debug.apk`로 복사했다.
- 2026-06-26 기준 대시보드 live 가격 표시와 국내 종목명 보강을 반영한 뒤 `flutter test test/phase6_ui_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart test/daily_brief_provider_test.dart`를 실행했고 통과했다.
- 2026-06-26 기준 같은 변경 후 `flutter analyze`를 실행했고 이슈가 없었다.
- 2026-06-26 기준 debug APK를 다시 빌드했고 `17aca220` 실기기의 `/sdcard/Download/strategy_workbench_debug.apk`로 복사했다.
- 2026-06-26 기준 한국투자증권 인증 in-flight dedupe 반영 후 `flutter test test/hybrid_stock_repository_test.dart test/phase6_ui_test.dart test/stock_detail_providers_test.dart test/phase4_ui_test.dart test/daily_brief_provider_test.dart`를 실행했고 통과했다.
- 2026-06-26 기준 같은 변경 후 `flutter analyze`를 실행했고 이슈가 없었다.
- 2026-06-26 기준 debug APK를 다시 빌드했고 `17aca220` 실기기의 `/sdcard/Download/strategy_workbench_debug.apk`로 복사했다.
- 2026-06-26 기준 release/profile KIS runtime guard와 `.env` asset 제거를 반영한 뒤 `flutter test test/api_keys_test.dart test/hybrid_stock_repository_test.dart test/stock_detail_providers_test.dart`를 실행했고 통과했다.
- 2026-06-26 기준 같은 변경 후 `flutter analyze`를 실행했고 이슈가 없었다.
- 2026-06-26 기준 `flutter build apk --debug --no-tree-shake-icons`를 clean 이후 재실행했고 성공했다. 새 build 산출물에서 `.env` 파일과 `KOR_INVESTMENT_*`/주요 API 키 이름이 잡히지 않음을 확인했다.
- 2026-06-26 기준 프로젝트 로컬 Android SDK에 `cmdline-tools/latest`를 설치해 release AAB native debug symbol strip 검증 실패를 해결했다.
- 2026-06-26 기준 `flutter build appbundle --release --no-tree-shake-icons`를 실행했고 `build/app/outputs/bundle/release/app-release.aab` 생성에 성공했다. release AAB 및 `build` 산출물에서 `.env` 파일과 `KOR_INVESTMENT_*`/주요 API 키 식별자가 잡히지 않음을 확인했다.
- 2026-06-26 기준 Android `applicationId`는 아직 `com.example.strategy_workbench`이고 release signing은 debug key를 사용했다. AAB 생성은 성공했지만 Play 제출 전 고유 패키지명과 upload key/release signing 설정이 필요했다.
- 2026-06-26 기준 release AAB 빌드 중 Gradle 8.14+, Android Gradle Plugin 8.11.1+, Kotlin 2.2.20+ 업그레이드 권고가 출력되었다. 현재 빌드는 성공하지만 추후 Flutter 호환성 정리 대상으로 남긴다.
- 2026-06-29 기준 출시 전 실기기 확인용 `flutter build apk --release --no-tree-shake-icons`를 실행했고 `build/app/outputs/flutter-apk/app-release.apk` 생성에 성공했다. 광고는 테스트 ID만 강제하고, 시세는 키 없는 Naver quote fallback을 사용한다.
- 2026-06-29 기준 release APK를 `17aca220` 기기의 `/sdcard/Download/strategy_workbench_release.apk`에 복사했다. ADB 설치는 MIUI/기기 정책의 `INSTALL_FAILED_USER_RESTRICTED`로 막혀 아직 설치 완료 검증은 하지 못했다.
- 2026-06-29 기준 release 실기기 테스트에서 KRX 키 미설정으로 한국 종목이 mock/기존 캐시에 머무는 문제가 확인되어 Naver quote fallback을 추가했다. `000660` 현재가/종목명, `089030` 테크윙, `486450` SOL 미국AI전력인프라 표시를 보강했다.
- 2026-06-29 기준 기존 mock 캐시와 당일 스냅샷 캐시가 계속 사용되지 않도록 주식 캐시 버전과 스냅샷 캐시 키를 갱신했다.
- 2026-06-29 기준 수정 후 `flutter test test/portfolio_providers_test.dart test/stock_detail_providers_test.dart test/hybrid_stock_repository_test.dart test/phase6_ui_test.dart`, `flutter analyze`, `flutter build apk --release --no-tree-shake-icons`를 실행했고 모두 통과했다. clean release APK에는 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 확인했고, 새 release APK를 `17aca220` 기기의 `/sdcard/Download/strategy_workbench_release.apk`에 다시 복사했다.
- 2026-06-29 기준 release 실기기 테스트에서 미국 종목이 Yahoo 실패 후 mock 가격으로 보이는 문제가 확인되어 Nasdaq quote fallback을 추가했다. `GOOGL` 등 미국 종목은 Finnhub/FMP/Yahoo 실패 시 Nasdaq 공개 quote 현재가를 사용하고, 부족한 지표는 mock 기본값으로 보완한다.
- 2026-06-29 기준 Nasdaq fallback 반영 후 `flutter test test/hybrid_stock_repository_test.dart test/portfolio_providers_test.dart test/stock_detail_providers_test.dart test/phase6_ui_test.dart`, `flutter analyze`, `flutter build apk --release --no-tree-shake-icons --dart-define=FORCE_ADMOB_TEST_IDS=true`를 실행했고 모두 통과했다. clean release APK에는 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 확인했고, 새 release APK를 `17aca220` 기기의 `/sdcard/Download/strategy_workbench_release.apk`에 다시 복사했다.
- 2026-06-29 기준 Android `applicationId`와 namespace를 `com.round1studio.strategyworkbench`로 변경했고, 앱 라벨을 `Strategy Workbench`로 정리했다. release signing은 `android/key.properties`가 있으면 upload keystore를 사용하고, 없으면 빌드 테스트용 debug signing fallback을 사용한다.
- 2026-06-29 기준 패키지명 변경 후 `flutter analyze`와 `flutter build apk --release --no-tree-shake-icons --dart-define=FORCE_ADMOB_TEST_IDS=true`를 실행했고 통과했다. `aapt dump badging`으로 APK package `com.round1studio.strategyworkbench`, label `Strategy Workbench`를 확인했으며, APK 안에 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 재확인했다. 새 APK는 `17aca220` 기기의 `/sdcard/Download/strategy_workbench_release.apk`에 다시 복사했다.
- 2026-06-29 기준 Play upload key를 생성해 `android/app/upload-keystore.jks`와 `android/key.properties`에 로컬 저장했다. 둘 다 Git ignore 대상이며, `android/key.properties.example`만 추적 대상으로 둔다.
- 2026-06-29 기준 upload key signing으로 `flutter build appbundle --release --no-tree-shake-icons --dart-define=FORCE_ADMOB_TEST_IDS=true`를 실행했고 `build/app/outputs/bundle/release/app-release.aab` 생성에 성공했다. `jarsigner -verify`로 AAB 서명을 확인했고, AAB 안에 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 확인했다.
- 2026-06-29 기준 Android launcher icon을 새 디자인으로 교체했고 Play 등록용 512px 아이콘 `assets/store/icon_512.png`를 생성했다. 아이콘 반영을 위해 앱 버전을 `1.0.0+2`로 올렸고, 새 내부 테스트용 AAB를 다시 빌드했다. packaged manifest 기준 `versionCode=2`, `versionName=1.0.0`이며 서명 검증과 `.env`/운영 키 미포함 확인을 통과했다.
- 2026-06-30 기준 Play Console 기본 스토어 등록정보 입력용 초안 `PLAY_STORE_LISTING_KO.md`와 개인정보처리방침 초안 `PRIVACY_POLICY_DRAFT_KO.md`를 작성했다.
- 2026-06-30 기준 Play 등록용 피처 그래픽 `assets/store/feature_graphic_1024x500.png`를 생성했다. 스토어 등록정보에는 `assets/store/icon_512.png`와 함께 업로드하면 된다.
- 2026-07-03 기준 Play 피처 그래픽의 pill 텍스트 overflow와 오른쪽 포트폴리오 카드 문구 겹침을 수정했다. 피처 그래픽은 `tool/generate_store_feature_graphic.ps1`로 재생성할 수 있다.
- 2026-07-03 기준 GitHub Pages 게시용 개인정보처리방침 `docs/privacy-policy.md`와 안내 페이지 `docs/index.md`를 추가했다. Play Console에는 GitHub Pages 활성화 후 공개 URL을 입력하면 된다.
- WorkManager 실제 디바이스 동작 검증은 이번 턴에 수행하지 않았다.
