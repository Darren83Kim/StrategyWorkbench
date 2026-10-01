# Strategy Workbench Personal Developer Release Plan

- Last updated: 2026-07-10
- Purpose: 개인 개발자 계정으로 Google Play 출시를 유지하기 위해 필요한 정책 대응 사유와 구현 계획을 기록한다.
- Status: Wave A~C 내부 테스트 완료. 기능 변경 없이 실제 AdMob 설정을 적용한 `1.0.0+13` 비공개 알파 후보 생성 완료.

## 1. Background

2026-07-06 Play Console 검토에서 `Play Console Requirements` 위반으로 앱이 거절되었다.

거절 사유는 앱 품질, 크래시, 광고 구현 문제가 아니라 개발자 계정 유형과 앱 선언의 불일치다. Play Console의 `앱 콘텐츠 > 금융 기능`에서 `주식 거래 및 포트폴리오 관리`가 선택되어 있었고, Google은 이 유형의 앱을 개인 개발자 계정이 아닌 조직 개발자 계정으로 제출해야 하는 앱으로 분류했다.

공식 정책상 Google Play는 금융 상품/서비스를 돈과 암호화폐의 관리 또는 투자와 관련된 기능, 개인화된 조언까지 포함하는 범위로 본다. 또한 개발자 계정 유형 안내에서는 주식 거래, 투자 펀드 등 금융 상품/서비스를 제공하는 경우 조직 계정을 선택해야 한다고 안내한다.

References:

- Google Play Financial Services policy: https://support.google.com/googleplay/android-developer/answer/9876821
- Choose a developer account type: https://support.google.com/googleplay/android-developer/answer/13634885
- Required information for organization accounts: https://support.google.com/googleplay/android-developer/answer/13628312

## 2. Decision

사업자등록과 D-U-N-S 기반 조직 계정 준비가 현재는 어렵기 때문에, 단기 출시 목표는 개인 개발자 계정에서 허용 가능성이 높은 형태로 앱을 축소하는 것이다.

기존 앱의 장기 방향은 보존한다. 단기 Play 출시용으로는 `Personal Store Mode`를 추가해 금융/투자 관리로 해석될 수 있는 기능을 빌드 단에서 숨기고, 앱 성격을 `포트폴리오/투자 관리 앱`에서 `시장 지표 학습 및 전략 시뮬레이션 앱`으로 낮춘다.

## 3. Non-Negotiable Rules

- Play Console 선언만 바꾸고 앱 기능을 그대로 두는 방식은 사용하지 않는다.
- 개인 출시 빌드에서는 실제/가상 보유 수량, 매입가, 평가금액, 손익, 매수/매도 기록을 노출하지 않는다.
- 개인 출시 빌드에서는 `리밸런싱 코치`, `추천 액션`, `편입 후보`, `리스크 보유 종목`처럼 개인 투자 판단으로 보이는 문구와 UI를 노출하지 않는다.
- 개인 출시 빌드에서는 특정 종목의 매수/매도 또는 편입을 권유하는 문구를 사용하지 않는다.
- 스토어 설명, 앱 내 문구, 개인정보처리방침, Play Console 앱 콘텐츠 선언이 서로 충돌하지 않게 맞춘다.
- Google이 여전히 금융 상품/서비스 앱으로 판단하면 개인 계정 출시는 중단하고 조직 계정 또는 기능 축소 범위를 재검토한다.

## 4. Product Pivot

### Before

- 전략 기반 종목 랭킹
- 활성 전략 선택
- 포트폴리오 보유 종목 관리
- 매수/매도 거래 기록
- 현재 평가금액과 손익률
- 리밸런싱 코치
- 보유 종목 기준 편입/점검 제안

### After: Personal Store Mode

- 전략 기반 지표 랭킹 학습
- PER/ROE/배당 등 지표 설명
- 한국/미국 시장별 샘플 비교
- 전략 비교
- 관심 종목 표시 수준의 watchlist
- 종목 상세의 지표 해설
- 분석 기준 비교 인사이트
- 광고 기반 무료 정보 제공

## 4-1. Personal Mode Value Add

포트폴리오/매매/리밸런싱 기능을 숨긴 뒤에도 앱이 비어 보이지 않도록, 개인 출시 모드의 중심 가치를 `기준 비교를 통한 지표 학습`으로 둔다.

- 전략 비교는 특정 종목 추천이 아니라 두 분석 기준이 어떤 지표 축을 더 크게 보는지, 공통 샘플과 기준별 전용 샘플이 얼마나 다른지 설명한다.
- 종목 상세는 `왜 사야 하는가`가 아니라 선택한 기준에서 어떤 지표가 설명력을 만들고 어떤 지표를 추가 확인해야 하는지 보여준다.
- 관심 종목은 보유/금액/손익이 없는 별표 표시로만 유지한다.
- 스토어 문구와 앱 내 문구는 `추천`, `편입 후보`, `포트폴리오 관리`, `매수/매도` 대신 `샘플`, `지표 해설`, `기준 비교`, `관심 종목`을 사용한다.

## 4-2. Policy-Safe Feature Priority

개인 개발자 계정으로 유지하는 동안 추가 기능은 금융 서비스, 포트폴리오 관리, 투자 자문으로 보이지 않는 범위에서만 진행한다. 우선순위는 다음 기준으로 정한다.

1. 지표 기여도 보기
   - 사유: 사용자가 `왜 이 샘플이 이 위치에 있는지`를 이해할 수 있어 앱의 학습 가치가 가장 크게 오른다.
   - 정책 관점: 특정 행동을 권유하지 않고, 이미 선택한 분석 기준의 계산 근거만 설명한다.
   - 구현 위치: 종목 상세 `지표 해설` 영역.
   - 상태: 구현 완료. 지표별 비중, 상대 지표값, 기여 점수를 시각화한다.
2. 지표 사전
   - 사유: PER, ROE, 배당, 표본, 순위 변화 같은 용어를 앱 안에서 바로 이해할 수 있게 한다.
   - 정책 관점: 교육/정보 제공 성격이 명확하며 추천/거래/보유 관리와 분리된다.
   - 구현 위치: 별도 `지표 사전` 화면과 대시보드/전략 진입점.
   - 상태: 구현 완료.
3. 분석 기준 시뮬레이터
   - 사유: 가중치 변화가 샘플 순위에 주는 영향을 사용자가 실험할 수 있다.
   - 정책 관점: 특정 종목 추천이 아니라 조건 변화에 따른 상대 비교 실험으로 제한해야 한다.
   - 상태: 후보. 1~2번 검증 후 진행한다.
4. 비교 리포트 강화
   - 사유: 두 기준의 공통/전용 샘플과 순위 차이를 더 읽기 쉽게 만든다.
   - 정책 관점: 비교 해설 중심으로 유지하면 안전하다.
   - 상태: 일부 구현됨. 추가 개선 후보.
5. 관찰 메모와 데이터 신뢰도 배지
   - 사유: 사용자 학습 기록과 데이터 해석 주의점을 보강한다.
   - 정책 관점: 개인 투자 판단 또는 포트폴리오 관리처럼 보이지 않도록 `관찰 메모` 수준으로 제한한다.
   - 상태: 후보.

## 4-3. Reviewed Implementation Waves

2026-07-10 코드 구조를 기준으로 다음 여섯 기능을 모두 구현할 수 있다. 다만 데이터 모델 변경과 화면 복잡도를 통제하기 위해 세 번의 내부 테스트 빌드로 나눈다. 비공개 테스트 트랙과 테스터 목록은 유지하고, 각 묶음이 내부 테스트를 통과한 뒤 같은 비공개 트랙에 단계적으로 업데이트한다.

### Wave A - Analysis Simulator and Data Confidence (`1.0.0+10` candidate)

- 상태: 코드 구현, 자동 검증, `1.0.0+10` AAB 생성 및 Play 내부 테스트 설치 확인 완료.

1. 분석 기준 시뮬레이터
   - 기존 `ScoringEngine`과 전체 샘플 provider를 재사용한다.
   - 저장된 분석 기준을 기준값으로 두고 PER/ROE/배당 가중치를 임시 조절한다.
   - 변경 전/후 순위, 공통 샘플, 순위 변화, 지표 기여도 변화를 표시한다.
   - 실험값은 자동으로 분석 기준에 저장하거나 활성화하지 않는다.
   - 슬라이더 변경은 debounce하고 점수 계산은 UI 프레임을 막지 않도록 isolate/사전 계산 경로를 재사용한다.
   - 문구는 `추천`, `최적`, `매수` 대신 `실험 결과`, `상대 순위`, `기여도 변화`를 사용한다.
2. 데이터 신뢰도 배지
   - 현재 `Stock`에는 `lastUpdated`만 있고 가격/펀더멘탈의 실제 출처가 보존되지 않으므로 출처 메타데이터 확장이 선행되어야 한다.
   - 가격 출처, 지표 출처, 갱신 시각, 샘플 지표 사용 여부, 누락 지표를 구분한다.
   - Hybrid 병합 과정에서 가격과 지표 출처가 다를 수 있으므로 단일 `source` 문자열로 합치지 않는다.
   - 기존 Hive 캐시 호환을 위해 새 필드는 optional/default 방식으로 추가하고 캐시 버전을 올린다.
   - UI는 `가격 데이터`, `지표 데이터`, `갱신 시각`, `샘플/지연/누락` 상태를 사실 그대로 표시한다.

### Wave B - Stock Comparison and Comparison Report (`1.0.0+11` candidate)

- 상태: 소스 구현, 자동 검증, `1.0.0+11` AAB 생성 및 Play 내부 테스트 확인 완료.

3. 종목 간 지표 비교
   - 관심 종목 또는 검색 결과에서 최대 3개 샘플을 선택한다.
   - PER, ROE, 배당, 정규화 점수, 지표 기여도를 표와 레이더 차트로 비교한다.
   - 통화가 다른 시장을 함께 비교할 때 가격 우열을 계산하지 않고 지표 비교만 제공한다.
   - 종목 상세와 관심 종목 목록에서 비교 화면으로 진입할 수 있게 한다.
4. 비교 리포트 강화
   - 현재 `StrategyComparisonViewModel`의 공통/전용 샘플과 순위 차이 계산을 재사용한다.
   - 공통 샘플 행을 누르면 양쪽 기준의 순위와 지표별 기여도 차이를 펼쳐 보여준다.
   - 기준별 가중치 차이, 가장 큰 순위 변화, 결과를 만든 핵심 지표를 한 화면에 정리한다.
   - `우수`, `추천` 대신 `차이`, `민감도`, `설명력` 중심으로 표현한다.

### Wave C - Observation Notes and Analysis History (`1.0.0+12` candidate)

- 상태: 코드 구현, 자동 검증과 `1.0.0+12` Play 내부 테스트 확인 완료.

5. 관찰 메모
   - 종목별 짧은 텍스트와 확인할 지표 태그만 로컬에 저장한다.
   - 수량, 매입가, 목표가, 손익, 매수/매도 상태는 저장하지 않는다.
   - 메모 삭제와 전체 삭제 기능을 제공하고 개인정보처리방침에 로컬 저장임을 명시한다.
6. 분석 기준 히스토리
   - 시뮬레이터에서 사용한 가중치와 당시 상위 샘플 순위만 기록한다.
   - 투자 성과, 수익률, 포트폴리오 변화는 추적하지 않는다.
   - 최근 20개로 제한하고 개별 삭제/전체 삭제를 제공한다.

### Shared Acceptance Criteria

- Personal Store Mode에서만 사용하는 문구와 전체 기능 모드 문구를 `StorePolicy`로 분리한다.
- 각 Wave마다 provider 단위 테스트, 위젯 테스트, `flutter analyze`, 내부 테스트 설치 검증을 통과한다.
- 새 로컬 데이터가 추가되면 삭제 경로와 개인정보처리방침 문구를 함께 갱신한다.
- 스토어 설명과 스크린샷에는 실제 출시 빌드에서 보이는 기능만 반영한다.
- 비공개 테스트 중에는 검증되지 않은 기능을 바로 올리지 않고 내부 테스트를 통과한 빌드만 승격한다.

### Wave A Verification Record

- `flutter analyze --no-pub`: 통과.
- 시뮬레이터 계산/화면, 데이터 출처 병합, Hybrid repository, 종목 상세, 스냅샷, 전략 화면 관련 테스트 28개: 통과.
- 시뮬레이터는 250ms debounce와 background isolate 계산을 사용한다.
- 데이터 메타데이터 추가에 따라 `stockCacheVersion`을 3으로 올렸으며 기존 캐시는 다음 동기화 시 재생성한다.
- `STORE_VARIANT=personal`, `FORCE_ADMOB_TEST_IDS=true` 구성으로 `1.0.0+10` release AAB 빌드: 통과.
- 업로드용 복사본: `build/app/outputs/bundle/release/strategy_workbench_1.0.0_10_personal_internal.aab` (60,800,620 bytes).
- Play 내부 테스트 설치본 기본 동작: 확인 완료.
- Wave A 완료. 다음 순서: Wave B `종목 직접 비교 + 비교 리포트` 구현 및 내부 테스트.

### Wave B Verification Record

- 최대 3개 종목 선택, 종목명/티커 검색, 관심 종목 진입, 종목 상세 진입 구현 완료.
- PER/ROE/배당 원지표, 전체 비교군 정규화 점수, 선택 기준의 지표 기여도와 레이더 차트 구현 완료.
- 국내/미국 혼합 선택 시 통화가 다른 가격의 우열을 계산하지 않고 안내만 표시한다.
- 전략 비교 리포트에 기준별 가중치 차이와 공통 종목의 양쪽 지표 기여도 펼침을 추가했다.
- 비교 결과와 선택 종목은 로컬에 저장하지 않으므로 새 사용자 데이터 수집 항목은 없다.
- `flutter analyze --no-pub`: 통과.
- 종목 비교 provider/화면, 전략 비교 provider/화면, 종목 상세 관련 테스트 12개: 통과.
- `STORE_VARIANT=personal`, `FORCE_ADMOB_TEST_IDS=true` 구성으로 `1.0.0+11` release AAB 빌드: 통과.
- 업로드용 복사본: `build/app/outputs/bundle/release/strategy_workbench_1.0.0_11_personal_internal.aab` (60,914,246 bytes).
- 다음 수동 확인: 작은 화면의 레이더/지표 행 가독성, 검색과 최대 3개 제한, 관심 종목·상세 진입, 전략 비교 펼침 동작.
- Play 내부 테스트 설치본 기본 동작: 확인 완료. Wave B 완료.

### Wave C Verification Record

- 종목 상세에 최대 300자의 관찰 메모와 `PER`, `ROE`, `배당`, `데이터` 확인 태그 저장을 추가했다.
- 관찰 메모는 종목별 로컬 저장이며 대시보드의 관리 화면에서 확인, 개별 삭제, 전체 삭제할 수 있다.
- 분석 기준 실험실에 사용자가 직접 누르는 기록 저장 버튼과 최근 20건의 실험 기록 화면을 추가했다.
- 실험 기록은 당시 가중치와 상위 샘플 순위만 저장하며 성과, 수익률, 포트폴리오 변화, 거래 상태는 저장하지 않는다.
- 개인정보처리방침과 개인 개발자용 스토어 문구에 로컬 저장 범위와 삭제 방법을 반영했다.
- 취소 가능한 광고 시작 타이머로 화면 종료 후 지연 작업이 남는 문제를 함께 수정했다.
- `flutter analyze --no-pub`: 통과.
- Wave A/B/C 회귀 테스트 18개: 통과.
- `STORE_VARIANT=personal` 전용 정책 UI와 Wave C 테스트 6개: 통과.
- `STORE_VARIANT=personal`, `FORCE_ADMOB_TEST_IDS=true` 구성으로 `1.0.0+12` release AAB 빌드: 통과.
- 업로드용 복사본: `build/app/outputs/bundle/release/strategy_workbench_1.0.0_12_personal_internal.aab` (61,219,757 bytes, SHA-256 `4B839BFE5DED1342E74329BF9AEA40AC58AA222F721E2E4B194884922B3C1A30`).
- 다음 수동 확인: 종목 상세 메모 저장/수정/삭제, 대시보드 메모 목록, 실험 결과 저장, 최근 기록 펼침/삭제, 앱 재실행 후 유지, 테스트 광고 노출.
- Play 내부 테스트 설치본의 관찰 메모, 분석 실험 기록, 삭제, 재실행 유지와 테스트 광고 노출: 확인 완료. Wave C 완료.
- 기능 변경 없이 `1.0.0+13`으로 버전 코드를 올리고 실제 AdMob 설정을 적용한 비공개 알파 AAB 생성: 통과.
- 비공개 알파 업로드용 복사본: `build/app/outputs/bundle/release/strategy_workbench_1.0.0_13_personal_closed_alpha.aab` (61,223,830 bytes, SHA-256 `B007B5B42D2F249EE24C9A40779393FA2D4DBCF54AC24425F5C697048D13A906`).
- AAB에 `.env`, `key.properties`, upload keystore가 포함되지 않았고 실제 AdMob 배너/전면 광고 ID가 주입되었음을 값 노출 없이 확인했다.

## 5. Feature Classification

### Remove or Hide in Personal Store Mode

- Bottom navigation의 `포트폴리오` 탭
- `/portfolio` 라우트 진입
- 포트폴리오 요약 카드
- 보유 종목 목록
- 매수/매도/추가 매수/매도 다이얼로그
- 거래 내역
- `PortfolioItem`, `portfolioProvider` 기반 UI 노출
- `rebalanceCoachProvider` 기반 UI 노출
- 대시보드의 `리스크 보유 종목`
- 대시보드의 보유 종목 기반 `신규 진입`, `이탈`, `점검` 표현
- 종목 상세의 거래 타임라인
- 백그라운드 알림 중 보유 포트폴리오 기반 비교 알림

### Rename or Reframe

- `오늘의 Top Picks` -> `오늘의 샘플 랭킹`
- `편입 후보` -> 사용 금지
- `추천 액션` -> 사용 금지
- `리밸런싱 코치` -> 사용 금지
- `활성 전략` -> `분석 기준`
- `전략 점수` -> `지표 점수`
- `투자 판단` -> `지표 학습`
- `포트폴리오` -> 개인 출시 모드에서는 사용 금지

### Keep With Caution

- 종목 현재가 표시: 정보 제공 목적임을 명확히 하고, 개인 보유/손익과 연결하지 않는다.
- 전략 랭킹: 매수 추천이 아니라 지표 조합별 샘플 정렬임을 표시한다.
- 관심 종목: 수량/금액/평가손익 없이 별표 저장만 허용한다.
- 종목 상세: `왜 이 종목인가`는 `지표 해설`로 바꾸고, 추천/편입 문맥을 제거한다.

## 6. Implementation Plan

### Step 1. Build Flag and Policy Mode

- Add `StorePolicyMode` or equivalent config.
- Add compile-time flag:

```text
--dart-define=STORE_VARIANT=personal
```

- Default development behavior can keep full functionality.
- Personal Play build must use `STORE_VARIANT=personal`.
- Add a visible debug/profile indicator only in non-release if useful.

Primary files:

- `lib/core/constants/api_keys.dart` or new `lib/core/config/store_policy.dart`
- `lib/main.dart`

### Step 2. Navigation and Routes

- Hide `포트폴리오` tab when `STORE_VARIANT=personal`.
- Prevent direct `/portfolio` route from showing financial UI.
- If `/portfolio` is opened directly, redirect to `/dashboard` or show a policy-safe placeholder.

Primary files:

- `lib/shared/widgets/root_layout.dart`
- `lib/core/router/app_router.dart`

### Step 3. Dashboard Reframe

- Remove portfolio-dependent daily brief sections.
- Replace current brief with a policy-safe learning summary:
  - active learning strategy name
  - number of stocks in sample universe
  - top 3 sample rankings
  - indicator driver summary
- Remove `리스크 보유 종목`, `신규 진입`, `이탈`, `보유` terms.
- Add short disclaimer: "지표 학습용 정보이며 매수/매도 권유가 아닙니다."

Primary files:

- `lib/features/dashboard/presentation/dashboard_screen.dart`
- `lib/core/providers/daily_brief_providers.dart`
- `lib/core/l10n/app_strings.dart`

### Step 4. Strategy Screen Reframe

- Keep strategy creation and ranking, but rename UI copy to learning/simulation language.
- Remove or hide alert activation if it can be interpreted as personalized investment monitoring.
- Keep market filters `미국 / 국내 / 전체`.
- Keep star watchlist only as a non-financial interest marker.
- Avoid "Top Picks" and "활성 전략" investment wording in release copy.

Primary files:

- `lib/features/strategy/presentation/strategy_screen.dart`
- `lib/features/strategy/presentation/filter_creation_screen.dart`
- `lib/core/providers/filter_providers.dart`
- `lib/core/l10n/app_strings.dart`

### Step 5. Stock Detail Reframe

- Remove transaction timeline from personal build.
- Change `왜 이 종목인가` to `지표 해설`.
- Remove `상위 추천 종목`, `편입`, `보유` wording.
- Keep PER/ROE/dividend explanation and normalized indicator chart if presented as education.

Primary files:

- `lib/features/market/presentation/stock_detail.dart`
- `lib/core/providers/stock_detail_providers.dart`
- `lib/shared/widgets/transaction_timeline_list.dart`

### Step 6. Disable Portfolio and Rebalance Runtime Paths

- Ensure personal release build does not call or display:
  - `rebalanceCoachProvider`
  - `livePortfolioProvider`
  - `livePortfolioSummaryProvider`
  - buy/sell transaction flows
- Background service should not load `portfolio_tickers` or send portfolio alignment alerts in personal mode.

Primary files:

- `lib/core/providers/portfolio_providers.dart`
- `lib/core/providers/rebalance_providers.dart`
- `lib/core/services/background_service.dart`
- `lib/core/services/alert_runtime_service.dart`
- `lib/features/portfolio/presentation/portfolio_screen.dart`

### Step 7. Store Listing and App Content

- Rewrite `PLAY_STORE_LISTING_KO.md` for personal mode.
- Remove phrases:
  - `포트폴리오`
  - `투자 도구`
  - `리밸런싱`
  - `보유 종목`
  - `매수`
  - `매도`
  - `추천`
  - `금융 정보`
- Use phrases:
  - `시장 지표 학습`
  - `전략 조건 비교`
  - `샘플 랭킹`
  - `PER/ROE/배당 지표 설명`
  - `교육/정보 제공`
- Play Console financial features declaration should be updated only after the app UI and store copy no longer provide portfolio/trading/investment management features.

Primary files:

- `PLAY_STORE_LISTING_KO.md`
- `PRIVACY_POLICY_DRAFT_KO.md`
- `docs/privacy-policy/index.md`

### Step 8. Tests and Verification

- Add tests for policy mode config.
- Add UI tests verifying portfolio tab is hidden in personal mode.
- Add copy audit using `rg` against personal-mode strings.
- Build a new AAB with a new version code, for example `1.0.0+7`.

Suggested checks:

```powershell
flutter analyze
flutter test
flutter build appbundle --release --no-tree-shake-icons --dart-define=STORE_VARIANT=personal
```

Manual checks:

- Bottom navigation has no `포트폴리오`.
- Dashboard has no holdings, gain/loss, rebalance, buy/sell wording.
- Strategy screen says sample/learning/ranking, not recommendation.
- Stock detail has no transaction timeline.
- Play Store screenshots do not show removed financial features.

## 7. Play Console Re-Submission Plan

1. Do not resubmit the rejected `1.0.0+4` full financial build.
2. Implement `Personal Store Mode`.
3. Create new release candidate `1.0.0+7` or higher.
4. Upload to internal test first and verify actual device behavior.
5. Update store listing copy and screenshots to match personal mode.
6. Update app content declarations:
   - Ads: yes.
   - Data safety: AdMob/device/app activity declarations remain needed.
   - Financial features: only change away from finance after the shipped UI no longer provides portfolio/trading/investment management features.
   - Target age: keep adult-focused if stock market content remains.
7. Submit closed test again.

## 8. Acceptance Criteria

- Play Console does not show the `Play Console Requirements` organization-account rejection for the personal mode submission.
- The installed Play test build does not expose portfolio management, trading records, holdings, rebalancing, or personalized investment suggestions.
- Store listing and screenshots match the actual personal mode UI.
- AdMob still works in the personal build.
- No private API keys are packaged in the AAB.
- If Google still classifies the app as requiring an organization account, we stop and re-evaluate rather than making inaccurate declarations.

## 9. Implementation Notes

2026-07-06에 개인 출시 모드 1차 구현을 시작했다.

- `lib/core/config/store_policy.dart`에 `STORE_VARIANT=personal` 빌드 플래그를 추가했다.
- 개인 출시 모드에서는 하단 `포트폴리오` 탭이 표시되지 않는다.
- 개인 출시 모드에서 `/portfolio` 직접 접근은 `/dashboard`로 리다이렉트한다.
- 개인 출시 모드와 release 빌드에서는 `/debug` 내부 점검 라우트도 `/dashboard`로 리다이렉트한다.
- 개인 출시 모드에서는 대시보드가 포트폴리오 기반 Daily Brief 대신 `지표 학습 브리프`를 표시한다.
- 개인 출시 모드에서는 `리스크 보유 종목`, `신규 진입`, `이탈`, 보유 금액 기반 섹션을 대시보드에 표시하지 않는다.
- 개인 출시 모드에서는 전략 선택이 백그라운드 포트폴리오 알림을 등록하지 않는다.
- 개인 출시 모드에서는 종목 상세에서 거래 타임라인을 숨기고 `지표 해설` 중심으로 표시한다.
- 종목 인사이트 문구에서 `상위 추천 종목` 표현을 `상위 지표 샘플`로 낮췄다.
- 개인 출시용 스토어 문구 초안은 `PLAY_STORE_LISTING_PERSONAL_KO.md`에 분리했다.
- `flutter analyze`, 개인 모드 네비게이션 테스트, Phase 4/전략/종목 상세 관련 회귀 테스트를 통과했다.
- `STORE_VARIANT=personal` release AAB 생성까지 확인했고, 스토어 문구 재정리 후 `1.0.0+6` 재빌드를 완료했다. 산출물은 `build/app/outputs/bundle/release/app-release.aab`이다.
- 2026-07-07 기준 분석 기준 비교 인사이트, 종목 상세 지표 해설 강화, 광고 로드 재시도 개선을 포함한 `1.0.0+7` 내부 테스트 후보 AAB를 생성했다. 업로드용 복사본은 `build/app/outputs/bundle/release/strategy_workbench_1.0.0_7_personal_internal.aab`이다.
- 2026-07-10 기준 종목 상세 지표 기여도와 앱 내 지표 사전을 포함한 `1.0.0+9` 내부 테스트 후보 AAB를 생성했다. 업로드용 복사본은 `build/app/outputs/bundle/release/strategy_workbench_1.0.0_9_personal_internal.aab`이다.
- 2026-07-10 `1.0.0+9` 내부 테스트 설치본에서 정책 대응형 기능 구성과 테스트 광고 노출을 확인했다. 다음 단계는 동일 기능 범위로 비공개 테스트를 시작하고 12명 연속 opt-in 요건을 관리하는 것이다.
- 2026-07-10 기준 분석 기준 실험실과 데이터 확인 정보를 포함한 `1.0.0+10` 내부 테스트 후보 AAB를 생성했다. 업로드용 복사본은 `build/app/outputs/bundle/release/strategy_workbench_1.0.0_10_personal_internal.aab`이며 테스트 광고 ID를 강제했다.
- 2026-07-10 `1.0.0+10` Play 내부 테스트 설치본의 기본 동작을 확인해 Wave A를 완료 상태로 전환했다.

## 10. Deferred Full Product Path

The original full product remains valuable and should not be deleted. The full version can return when one of these becomes possible:

- Organization Play Console account is available.
- Business registration and D-U-N-S verification are available.
- App is distributed outside Google Play under a separate compliance strategy.
- A legally reviewed product scope allows financial features under the required account type.
