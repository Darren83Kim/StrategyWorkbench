# Phase 3-5 Execution Plan

- Last updated: 2026-04-21
- Scope: `Phase 3`, `Phase 4`, `Phase 5`
- Purpose: 의도와 다르게 구현된 부분, 아직 미구현인 부분을 실제 작업 단위로 쪼개어 바로 실행 가능한 계획으로 정리한다.

## 1. Progress Snapshot

| Phase | Progress | Note |
|------|------|------|
| Phase 3 | 대부분 반영 | 민감도 저장, 활성 전략, 전략 UI, 퍼센트 기반 백그라운드 판정, 회귀 테스트 추가 완료 |
| Phase 4 | 거의 마감 | 실데이터 provider, not found 처리, 거래 타임라인, 위젯 테스트, 포트폴리오 UX 정리 완료 |
| Phase 5 | 부분 반영 | 테스트 광고 기준 의존성, 배너, 전면 광고 fail-safe, 저장 버튼 연결, 개발 빌드 광고 지연 로딩 완료 |

### Cross-cutting data hotfix completed in current turn

1. `DioClient` 응답 로깅이 짧은 JSON에서 예외를 내던 문제를 수정했다.
2. `HybridStockRepository` 기본 경로에 한국투자 fallback을 연결했다.
3. `KorInvestmentRepository` 현재가 조회를 공식 샘플 형식(`tr_id=FHKST01010100`, `FID_COND_MRKT_DIV_CODE=J`)에 맞췄다.
4. `strategySnapshotProvider`가 same-day empty cache를 재계산하도록 수정했다.
5. `DataSyncService`가 빈 fetch 결과로 기존 캐시를 지우지 않도록 수정했다.
6. `tool/live_data_probe.dart`를 추가했고, 에뮬레이터 런타임에서 `US 10`, `KR 5`, `ALL 15`를 확인했다.

### Additional data-layer strengthening completed in current turn

1. `FmpStockRepository`를 추가해 미국 데이터 2차 폴백을 실제 구현했다.
2. 미국/한국 리포지토리의 기본 추적 종목 유니버스를 공용 상수로 정리했다.
3. `HybridStockRepository`가 첫 성공 결과를 바로 반환하지 않고, 우선순위 소스를 병합해 누락 종목과 빈 지표를 보완하도록 바꿨다.
4. 한국투자 기본 종목 집합을 5개에서 10개로 확대했다.
5. 에뮬레이터 런타임 진단에서 `US 10`, `KR 10`, `ALL 20`을 확인했다.

### Phase 3 completed in current turn

1. `SavedFilter`에 `sensitivity`를 추가하고 저장 구조를 확장했다.
2. `active_strategy_name` 기반 활성 전략 영속화를 도입했다.
3. 전략 저장 화면에서 민감도를 선택하고 저장 직후 활성 전략으로 설정하도록 연결했다.
4. 전략 목록에서 활성 전략 표시와 전환 액션을 추가했다.
5. 백그라운드 작업이 `saved_filters` + `active_strategy_name`을 읽도록 수정했다.
6. 민감도 threshold를 상위 `10% / 20% / 30%` 기준으로 계산하도록 수정했다.
7. `filter_providers_test.dart`, `background_service_test.dart`를 추가하고 통과를 확인했다.
8. `AlertRuntimeService`를 도입해 활성 전략이 없을 때 알림/백그라운드 초기화를 생략하고, 활성화 시점에만 런타임을 등록하도록 최적화했다.

### Remaining Phase 3 hardening

- 활성 전략이 없을 때 background isolate 전체 흐름을 검증하는 테스트 추가
- WorkManager 실제 디바이스 동작 확인
- 알림 중복 방지 및 빈도 정책 세분화 검토
- 디버그/에뮬레이터 기준 실제 체감 성능 재확인

### Phase 4 completed in current turn

1. `stock_detail.dart`에서 `MockStockRepository` 직접 의존을 제거했다.
2. `stock_detail_providers.dart`를 추가해 실데이터 조회, 정규화, 태그 계산을 provider로 이동했다.
3. 종목이 없을 때 첫 종목 fallback 대신 not found 상태를 보여주도록 수정했다.
4. `transactionsByTickerProvider`로 ticker 기준 거래 이력을 연결했다.
5. `TransactionTimelineList` 공용 위젯을 추가해 포트폴리오와 상세 화면에서 재사용하게 했다.
6. `stock_detail_providers_test.dart`를 추가하고 통과를 확인했다.

### Remaining Phase 4 hardening

- 액션 시트와 상세 화면의 남은 하드코딩 문구 정리
- 필요 시 quick action sheet 세부 위젯 회귀 추가

## 2. Execution Summary

### Core corrections to make next

1. Phase 5를 운영 광고 기준으로 마감한다.
2. Phase 3는 실기기 검증과 보강 테스트 중심으로 마무리한다.
3. Phase 4는 문자열 정리와 소규모 회귀 보강 정도만 남겨둔다.

### Recommended execution order

1. `Done` Phase 3 데이터 모델 정리
2. `Done` Phase 3 Provider/UI/백그라운드 연결
3. `Done` Phase 4 상세 화면 Provider 도입
4. `Done` Phase 4 SQLite 타임라인 연결
5. `Done` Phase 5 AdMob 의존성/초기화 추가
6. `Done` Phase 5 배너/전면 광고 UI 연결
7. Phase 5 운영 ID 교체 및 배포 준비
8. Phase 3~5 회귀 검증

## 3. Phase 3 Plan: Strategy Engine & Alerts

### Current result

- 전략 저장 구조가 `weights + topN + sensitivity`를 보존한다.
- 활성 전략은 `active_strategy_name`으로 관리된다.
- 저장 화면과 전략 화면이 같은 활성 전략 상태를 공유한다.
- 백그라운드 알림은 실제 활성 전략을 복원해 퍼센트 기준 threshold를 계산한다.

### Remaining follow-up

- background isolate end-to-end 테스트 추가
- snapshot/background가 같은 전략을 읽는 흐름의 확장 검증
- 실제 기기에서 알림 발생 조건 확인

### Files edited

- `lib/core/providers/filter_providers.dart`
- `lib/features/strategy/presentation/filter_creation_screen.dart`
- `lib/features/strategy/presentation/strategy_screen.dart`
- `lib/core/services/background_service.dart`
- `test/filter_providers_test.dart`
- `test/background_service_test.dart`

### Current exit criteria status

- `active_filter` 문자열 의존 제거: 완료
- 저장된 전략마다 민감도 유지: 완료
- 백그라운드 알림 퍼센트 기준 동작: 완료
- 전략 화면에서 활성 전략 표시: 완료
- 실기기 WorkManager 검증: 미완

## 4. Phase 4 Plan: Strategy UX & Detail Experience

### Current gap

- 상세/포트폴리오 액션 시트의 일부 문구가 하드코딩되어 있다.
- quick action sheet에 대한 세부 위젯 회귀는 최소 수준이다.

### Target behavior

- 종목 상세 화면은 라우트의 `symbol`을 기준으로 실제 현재 종목 데이터를 읽는다.
- 정규화는 실제 조회된 종목 집합 기준으로 계산한다.
- 하단에 해당 종목의 실제 거래 이력 타임라인이 보인다.
- 종목을 찾지 못하면 fallback 대신 명시적인 not found 상태를 보여준다.

### View model design

#### New provider

- New file:
  - `lib/core/providers/stock_detail_providers.dart`

#### Suggested provider set

- `stockDetailProvider(symbol)`
  - 데이터 소스: `stockListProvider` 또는 `allStocksForSnapshotProvider`
  - 역할:
    - 현재 종목 조회
    - peer 목록 확보
    - `Normalizer` 실행
    - `SmartTagger` 실행
    - 화면용 view model 반환
- `transactionsByTickerProvider(symbol)`
  - 데이터 소스: `transactionHistoryProvider`
  - 역할:
    - SQLite 거래 이력을 ticker 기준으로 필터링
    - 최신순 정렬

### Screen changes

#### Edit

- `lib/features/market/presentation/stock_detail.dart`

#### Required changes

1. `MockStockRepository` 제거
2. `FutureBuilder` 기반 직접 로딩을 provider 기반으로 교체
3. 존재하지 않는 종목이면 첫 종목 fallback 대신 에러/empty 상태 표시
4. 하단에 ticker 기준 거래 이력 타임라인 추가
5. 거래가 없을 때 empty state 표시

### Shared logic reuse

- 거래 이력 카드 UI는 `portfolio_screen.dart`의 타임라인 표시 방식을 재사용하거나 공통 위젯으로 분리한다.
- 필요 시 새 공용 위젯:
  - `lib/shared/widgets/transaction_timeline_list.dart`

### Files to edit/add

- `lib/core/providers/stock_detail_providers.dart` 신규
- `lib/features/market/presentation/stock_detail.dart`
- `lib/core/providers/portfolio_providers.dart`
- `lib/shared/widgets/transaction_timeline_list.dart` 신규 가능

### Tests to add

- `stockDetailProvider(symbol)`가 정확한 종목을 반환하는 테스트
- 없는 symbol 요청 시 not found 상태를 반환하는 테스트
- `transactionsByTickerProvider(symbol)`가 ticker 기준으로 정확히 필터링하는 테스트
- 상세 화면에서 실제 타임라인이 렌더링되는 위젯 테스트

### Exit criteria

- 종목 상세 화면에서 Mock 직접 조회가 제거된다.
- 라우트 symbol과 화면 데이터가 일치한다.
- 종목 상세 하단에 실제 거래 타임라인이 표시된다.
- 종목이 없을 때 잘못된 fallback이 사라진다.
- 회귀 테스트가 provider 레벨에서 보강된다.
- 상세 화면 위젯 테스트와 포트폴리오 상세 진입 UX가 정리된다.

## 5. Phase 5 Plan: Monetization & Final Fail-safe

### Current gap

- 현재는 Google 테스트 광고 기준으로만 동작한다.
- 운영용 Android/iOS App ID와 실제 ad unit ID는 아직 반영되지 않았다.
- `app-ads.txt`와 developer website 기반 운영 준비가 남아 있다.

### Target behavior

- 앱 시작 직후 첫 화면을 막지 않고 광고가 필요한 시점에 AdMob가 초기화된다.
- 하단에 실제 배너 광고가 표시된다.
- 전략 저장 시 전면 광고를 시도한다.
- 광고 로드 실패 또는 타임아웃 시 500ms 안에 저장 완료 흐름이 이어진다.
- 1시간 내 반복 노출이 제한된다.

### Completed in current turn

1. `google_mobile_ads` 의존성을 추가했다.
2. `AdService`가 `MobileAds.instance.initialize()`, frequency cap, 500ms fail-safe를 포함하도록 구현되었다.
3. `BannerAdWidget`가 실제 테스트 배너를 로드하도록 구현되었다.
4. `RootLayout` 하단에 배너와 bottom navigation을 함께 배치했다.
5. `FilterCreationScreen` 저장 버튼이 전면 광고 시도를 거친 뒤 저장 완료 흐름으로 이어지도록 수정되었다.
6. Android Manifest와 iOS Info.plist에 Google 테스트 App ID를 등록했다.
7. `ad_service_test.dart`를 추가했고 테스트를 통과했다.
8. Pixel 7 에뮬레이터에서 `Test Ad` 배너 렌더링을 확인했다.
9. 개발 빌드에서 배너 광고 로드를 첫 프레임 이후로 지연하고, 앱 시작 시 강제 AdMob 초기화를 제거했다.

### Configuration changes

#### Edit

- `pubspec.yaml`
- `.env.example`
- `lib/core/constants/api_keys.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

#### Add config keys

- `ADMOB_ANDROID_APP_ID`
- `ADMOB_IOS_APP_ID`
- `ADMOB_ANDROID_BANNER_ID`
- `ADMOB_IOS_BANNER_ID`
- `ADMOB_ANDROID_INTERSTITIAL_ID`
- `ADMOB_IOS_INTERSTITIAL_ID`

### Service design

#### Edit

- `lib/core/services/ad_service.dart`

#### Required changes

1. `MobileAds.instance.initialize()` 연결: 완료
2. Interstitial preload/load/show 구현: 완료
3. timeout + fail-safe 구현: 완료
4. 성공/실패/닫힘 이벤트 모두에서 `onContinue()` 보장: 완료
5. frequency cap는 실제 show 성공 시점 기준으로 갱신: 완료
6. 운영용 ad unit ID와 release 정책 반영: 미완

### Banner design

#### Edit

- `lib/shared/widgets/banner_ad_widget.dart`
- `lib/shared/widgets/root_layout.dart`

#### Layout plan

- `RootLayout.bottomNavigationBar`를 단일 `BottomNavigationBar`에서
  - `Column(mainAxisSize: MainAxisSize.min, children: [...])`
  - `BannerAdWidget`
  - `BottomNavigationBar`
  구조로 변경

### Strategy save flow

#### Edit

- `lib/features/strategy/presentation/filter_creation_screen.dart`

#### Recommended save sequence

1. 입력 검증
2. 전략 저장
3. 활성 전략 설정
4. 광고 시도
5. 광고 성공/실패와 관계없이 저장 완료 UI로 진행

#### Reason

- 저장 자체가 광고 성공 여부에 의해 실패하면 안 된다.
- 광고는 수익화 기능이고 저장은 핵심 사용자 기능이므로 저장을 우선 보장한다.

### App init change

#### Edit

- `lib/main.dart`

#### Required change

- `_initServicesAsync()` 안에 `AdService().init()` 추가

### Files to edit/add

- `pubspec.yaml`
- `.env.example`
- `lib/core/constants/api_keys.dart`
- `lib/core/services/ad_service.dart`
- `lib/shared/widgets/banner_ad_widget.dart`
- `lib/shared/widgets/root_layout.dart`
- `lib/features/strategy/presentation/filter_creation_screen.dart`
- `lib/main.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### Tests to add

- `AdService.canShowInterstitial()` 단위 테스트
- timeout 발생 시 `onContinue()`가 호출되는 테스트
- 전략 저장 버튼이 광고 서비스 경유 후 완료 흐름으로 가는 위젯 테스트
- 개발 빌드 테스트 ID 사용 여부 수동 점검
- 비행기 모드 fail-safe 수동 점검

### Exit criteria

- 배너 광고가 실제 레이아웃에 표시된다: 테스트 광고 기준 완료
- 전략 저장 시 전면 광고를 시도한다: 코드 연결 완료
- 광고 실패 시 500ms 안에 흐름이 이어진다: 단위 테스트 완료
- 플랫폼 App ID와 광고 단위 ID 설정이 문서/코드에 반영된다: 테스트 값 기준 완료
- 운영 App ID / 운영 ad unit ID / app-ads.txt 준비: 미완

## 6. Cross-phase Risks

### Serialization migration risk

- `SavedFilter` 스키마가 바뀌므로 기존 저장 데이터와 호환되어야 한다.
- `fromJson()` 기본값으로 안전하게 마이그레이션해야 한다.

### Background isolate duplication risk

- `BackgroundService`는 isolate에서 실행되므로 provider를 직접 재사용할 수 없다.
- 저장 구조를 단순하게 유지해야 background 쪽 파싱이 안정적이다.

### Test environment risk

- 선택 실행한 Phase 3, Phase 4 테스트는 통과했지만 전체 회귀는 아직 확인하지 않았다.
- WorkManager/알림은 실기기 확인이 남아 있다.

## 7. Definition Of Done

### Done when all of the following are true

1. 전략 저장 구조가 `weights + topN + sensitivity + active strategy`를 안정적으로 저장한다.
2. 백그라운드 알림이 실제 활성 전략을 사용한다.
3. 종목 상세 화면이 실데이터와 ticker 기준 거래 이력을 보여준다.
4. 광고 서비스가 실제 AdMob 흐름과 연결된다.
5. `IMPLEMENTATION_STATUS.md`가 새 구현 상태에 맞게 다시 갱신된다.
