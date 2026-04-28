## 📄 phase6.md: Insight Layer & Daily Intelligence

현재 구현 상태는 `IMPLEMENTATION_STATUS.md`에서 관리합니다.

### 1. 개요 및 설계 원칙

- **Goal:** StrategyWorkbench를 단순 관리 툴에서 `인사이트를 주는 앱`으로 확장한다.
- **Focus:** 사용자가 데이터를 "찾아보는" 앱이 아니라, 앱이 먼저 요약과 제안을 제공하는 흐름을 만든다.
- **Principle:** 기존 `전략`, `포트폴리오`, `상세 화면`을 재활용하면서 인사이트 레이어를 얹는다.
- **Tone:** 추천은 강압적 투자 조언이 아니라, 사용자가 빠르게 판단할 수 있게 돕는 설명형 안내여야 한다.

### 2. 제품 목표

1. 앱을 열자마자 "오늘 무엇이 달라졌는지" 알 수 있어야 한다.
2. 전략 결과가 `무엇이 좋은지`뿐 아니라 `왜 그런지` 설명되어야 한다.
3. 포트폴리오와 전략 간의 간극을 자동으로 찾아서 행동 후보를 제안해야 한다.
4. 사용자가 자신만의 매수/매도 기준을 돌아볼 수 있도록 거래 맥락을 남길 수 있어야 한다.

### 3. 핵심 기능 묶음

#### A. 오늘의 브리프

- 위치: `Dashboard` 상단 Hero card
- 목적:
  - 앱 첫 진입 시 사용자가 오늘 봐야 할 핵심 변화 3~5개를 즉시 이해하게 한다.
- 포함 항목:
  - 활성 전략 기준 신규 진입 종목
  - 활성 전략 기준 이탈 종목
  - 보유 종목 중 전략 순위권 이탈 위험 종목
  - 상위 점수 종목 Top 3
  - 전일 대비 순위 급상승/급하락 종목

#### B. 왜 이 종목인가

- 위치: `Strategy card`, `Stock detail`, `Dashboard spotlight`
- 목적:
  - 전략 결과를 숫자 나열이 아니라 설명 가능한 추천으로 바꾼다.
- 포함 항목:
  - `PER 저평가`, `ROE 우수`, `배당 매력`, `전략 적합도 상위` 같은 이유 태그
  - 전일 대비 순위가 변한 이유 요약
  - 활성 전략 가중치 기준 어떤 지표가 점수에 가장 크게 기여했는지 표시

#### C. 리밸런싱 코치

- 위치: `Portfolio` 상단 또는 별도 섹션
- 목적:
  - 포트폴리오와 활성 전략 사이의 불일치를 자동으로 탐지한다.
- 포함 항목:
  - 전략 밖 보유 종목
  - 전략 상위권인데 아직 보유하지 않은 종목
  - 비중이 과도한 종목
  - 손익과 전략 순위를 함께 본 추가 매수/비중 축소 후보

#### D. 전략 비교

- 위치: `Strategy` 화면의 비교 모드
- 목적:
  - 사용자 전략과 프리셋 전략의 차이를 쉽게 이해하게 한다.
- 포함 항목:
  - Top N 겹치는 종목
  - 서로 다른 종목
  - 종목별 점수 차이
  - 전략별 성향 요약

#### E. 거래 저널

- 위치: `Portfolio` 거래 추가/매도 플로우
- 목적:
  - 거래를 단순 수량 기록에서 판단 기록으로 확장한다.
- 포함 항목:
  - 매수/매도 이유 메모
  - 어떤 전략 기준으로 거래했는지 선택
  - 거래 후 회고 상태값

### 4. 상세 구현 우선순위

#### Priority 1. 오늘의 브리프

- 가장 빠르게 체감 가치를 만든다.
- 이미 있는 `strategySnapshotProvider`, `watchlist`, `activeStrategyProvider`, `portfolioProvider`를 재사용할 수 있다.

#### Priority 2. 왜 이 종목인가

- 현재 있는 `Normalizer`, `SmartTagger`, 스코어링 결과를 설명 레이어로 재조합한다.
- 구현 대비 체감 가치가 높다.

#### Priority 3. 리밸런싱 코치

- 전략과 포트폴리오를 이어주는 기능이라 제품 정체성을 강화한다.

#### Priority 4. 전략 비교

- 파워유저용 기능으로, 전략 커스터마이즈의 의미를 키운다.

#### Priority 5. 거래 저널

- 장기 유지율과 회고 가치에 도움이 되지만, 앞선 세 기능보다는 후순위다.

### 5. 데이터/상태 설계

#### New view models

- `DailyBrief`
  - `entered`
  - `exited`
  - `riskHoldings`
  - `topPicks`
  - `movers`
- `InsightReason`
  - `title`
  - `summary`
  - `metricDrivers`
  - `tags`
- `RebalanceSuggestion`
  - `type`
  - `ticker`
  - `reason`
  - `priority`
- `StrategyComparison`
  - `overlap`
  - `onlyLeft`
  - `onlyRight`
  - `scoreDiffs`

#### Suggested providers

- `dailyBriefProvider`
- `stockInsightReasonsProvider(symbol)`
- `rebalanceSuggestionsProvider`
- `strategyComparisonProvider((left, right))`

### 6. 화면 반영 계획

#### Dashboard

1. Hero 영역에 `오늘의 브리프`
2. 그 아래 `오늘의 Top picks`
3. 위험 보유 종목이 있으면 별도 경고 블록

#### Strategy

1. 전략 카드에 대표 인사이트 1줄 추가
2. 비교 모드 진입 버튼 추가

#### Portfolio

1. 요약 카드 아래 `리밸런싱 코치`
2. 거래 추가/매도 시 메모 옵션

#### Stock Detail

1. 스마트 태그 아래 `왜 이 종목인가` 카드
2. 점수 기여 지표 시각화

### 7. 테스트/검증

- `dailyBriefProvider`가 entered/exited/risk holdings를 정확히 계산하는지 단위 테스트
- `stockInsightReasonsProvider(symbol)`가 전략 가중치 기준 설명을 안정적으로 생성하는지 테스트
- `rebalanceSuggestionsProvider`가 보유 종목/비보유 종목을 올바르게 분류하는지 테스트
- Dashboard 위젯 테스트로 브리프 카드와 리밸런싱 블록 렌더링 확인

### 8. 완료 기준

1. 대시보드 첫 화면에서 오늘의 변화 요약이 보인다.
2. 전략 결과에 대해 최소 1개 이상의 설명 이유가 표시된다.
3. 포트폴리오 화면에서 전략 대비 리밸런싱 제안이 보인다.
4. 사용자가 데이터를 해석하기 위해 여러 화면을 직접 왕복하지 않아도 된다.

### 9. Current Slice Progress

- `2026-04-20`: Priority 1의 첫 조각으로 `dailyBriefProvider`와 Dashboard Hero card가 구현되었다.
- `2026-04-20`: `왜 이 종목인가` 1차 구현이 종목 상세 화면에 반영되었다.
- `2026-04-21`: 전략 카드 확장 목록에도 종목별 한 줄 설명이 붙었다.
- `2026-04-21`: 포트폴리오 상단에 `리밸런싱 코치` 1차 구현이 반영되었다.
- `2026-04-21`: 전략 화면에 최소 버전 `전략 비교` 시트가 추가되었다.
- `2026-04-21`: 전략 카드 종목 설명 계산은 행 단위 provider 반복 대신 `strategyStockInsightsProvider` 배치 계산으로 최적화되었다.
- `2026-04-21`: Dashboard는 첫 프레임 직후 바로 `dailyBriefProvider`를 당기지 않고, 짧은 지연 후 로드하도록 조정되었다.
- `2026-04-21`: `strategySnapshotProvider`의 점수 계산이 `compute()` 기반 background isolate로 이동했다.
- `2026-04-21`: 디버그 빌드에서는 `dailyBriefProvider`, 알림 런타임, 배너 광고 로드를 더 늦춰 첫 화면 반응성을 우선하도록 조정되었다.
- 현재 브리프는 다음을 계산한다.
  - 활성 전략 기준 신규 진입 종목
  - 활성 전략 기준 이탈 종목
  - 보유 종목 중 활성 전략 Top N 밖 종목
  - 오늘의 Top Picks
  - 전일 대비 순위 변동 종목
- 현재 설명 레이어는 다음을 보여준다.
  - 활성 전략 기준 현재 순위
  - 전일 대비 순위 변동
  - PER / ROE / 배당 중 전략 가중치에 크게 기여한 드라이버
- 현재 리밸런싱 코치는 다음을 보여준다.
  - 전략 밖 보유 종목
  - 활성 전략 상위권인데 아직 미보유인 종목
  - 포트폴리오 비중이 과도한 종목
- 현재 전략 비교는 다음을 보여준다.
  - 두 전략에 공통으로 들어가는 종목 수
  - 각 전략에만 있는 종목
  - 순위 차이가 큰 겹침 종목
- 현재 성능 관찰 메모:
  - 콜드 부팅 직후 디버그 에뮬레이터에서 시작 구간 jank는 아직 1회 남아 있다.
  - 전략 카드 설명 배치화, 브리프 지연 로딩, 알림/광고 지연, 스냅샷 isolate 계산 후 `dumpsys gfxinfo` 기준 `Janky frames`는 `22.92%`에서 `7.63%`까지 내려왔다.
  - 다음 1순위는 활성 전략 스냅샷과 Daily Brief 결과를 UI 진입 전후의 더 늦은 타이밍에 사전 캐시하는 것이다.
- 관련 검증:
  - `test/daily_brief_provider_test.dart`
  - `test/phase6_ui_test.dart`
  - `test/stock_detail_providers_test.dart`
  - `test/phase4_ui_test.dart`
  - `test/rebalance_coach_provider_test.dart`
  - `test/strategy_screen_test.dart`
  - `test/strategy_comparison_provider_test.dart`
- 다음 구현 우선순위:
  1. 거래 저널 / 메모
  2. 전략 비교의 점수 차이 / 성향 요약
  3. 리밸런싱 규칙 튜닝
  4. 활성 전략 스냅샷 / Daily Brief 사전 캐시
