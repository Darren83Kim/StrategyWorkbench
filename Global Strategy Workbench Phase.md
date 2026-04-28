# Global Strategy Workbench Phase Guide

- Last updated: 2026-04-21
- Purpose: `Strategy Flow PRD.md`의 제품 의도를 기준으로 `phase1~5.md`의 실행 방향을 정렬하는 마스터 문서
- Current status tracking: 실제 구현 현황은 `IMPLEMENTATION_STATUS.md`에서 관리

## 1. Document Rules

- `Strategy Flow PRD.md`: 왜 이 제품을 만드는지, 어떤 사용자 가치를 지키는지 정의하는 문서
- `Global Strategy Workbench Phase.md`: PRD를 실제 구현 단계로 나누는 마스터 가이드
- `phase1.md` ~ `phase6.md`: 각 단계의 상세 실행 문서
- `IMPLEMENTATION_STATUS.md`: 현재 코드 기준 구현 완료/부분 구현/미구현 상태를 빠르게 확인하는 문서

## 2. Product Intent To Keep

- 로컬 우선(Local-first): 서버 없이도 앱의 핵심 경험이 성립해야 한다.
- 캐시 우선(Cache-first): 일 단위 시세 갱신과 로컬 캐시 재사용이 기본 흐름이어야 한다.
- 전략 중심(Strategy-centric): 프리셋 + 사용자 정의 가중치 전략이 앱의 중심 도메인이다.
- 포트폴리오 연동(Portfolio-aware): 보유 종목, 평단가, 거래 이력, 전략 이탈 알림이 연결되어야 한다.
- 점진적 수익화(Monetize last): 광고는 핵심 사용자 흐름이 안정화된 뒤 붙인다.

## 3. Master Phase Map

| Phase | Theme | PRD mapping | Core outcome |
|------|------|------|------|
| 1 | Foundation & App Shell | 다크 글래스 UI, 앱 구조, 기본 내비게이션 | 앱이 실제 사용자 플로우 기준으로 기동되고 디버그 진입점이 분리됨 |
| 2 | Data Layer & Local Persistence | 자동 데이터 갱신, Hive/SQLite, Mock 검증 | 캐시/저장소/평단가 계산/일일 동기화 기반 확보 |
| 3 | Strategy Engine & Alerts | 복합 필터, 전략 순위, 이탈 경고 | 스코어링, 스냅샷, 민감도, 알림 파이프라인 완성 |
| 4 | Strategy UX & Detail Experience | 상세 화면, 태그, 차트, 거래 이력 | 실제 데이터 기반 전략/상세 UI 완성 |
| 5 | Monetization & Release Hardening | 배너/전면 광고, Fail-safe, 배포 준비 | 광고가 핵심 흐름을 막지 않는 상태로 릴리즈 준비 완료 |
| 6 | Insight Layer & Daily Intelligence | 브리프, 설명 가능한 전략, 리밸런싱 제안 | 앱이 단순 조회 도구에서 인사이트를 제안하는 제품으로 확장됨 |

## 4. Detailed Direction

### Phase 1. Foundation & App Shell

**Intent**

- PRD의 다크모드 Glassmorphism을 실제 앱 전체에 적용할 수 있는 토대를 만든다.
- 이 단계의 목적은 "디버그용 시작 화면"이 아니라 "실사용 앱 셸 + 디버그 보조 진입점"을 만드는 것이다.

**Detailed Tasks**

1. Flutter 프로젝트와 공통 의존성을 정리한다.
   - `flutter_riverpod`, `dio`, `hive_flutter`, `sqflite`, `fl_chart`, `flutter_local_notifications`, `workmanager`, `go_router`, `shared_preferences`, `path_provider` 등을 포함한다.
   - `google_mobile_ads`는 Phase 5에서 실제 연동 시점에 추가한다.
2. 기능 중심 디렉토리 구조와 공용 레이어를 정리한다.
   - `lib/core`, `lib/features`, `lib/shared/widgets` 기준으로 정리한다.
3. 다크 테마와 공용 GlassContainer를 만든다.
4. 앱 셸과 라우팅을 만든다.
   - 실제 시작 경로는 `dashboard`로 두고, `DebugScreen`은 `/debug` 라우트로 분리한다.
5. 디버그 도구 화면을 만든다.
   - 스코어링, 백그라운드 작업, API 상태 확인 같은 개발 검증용 기능을 둔다.

**Verification**

- `flutter pub get` 및 기본 빌드가 실패하지 않아야 한다.
- 대시보드, 전략, 포트폴리오, 디버그 라우트 이동이 가능해야 한다.
- Glass blur가 실제 기기/에뮬레이터에서 시각적으로 깨지지 않아야 한다.

### Phase 2. Data Layer & Local Persistence

**Intent**

- PRD의 자동 갱신 엔진과 로컬 DB 전략(Hive + SQLite)을 구현한다.
- Mock 데이터는 "초기 검증 도구"이며, 최종 런타임 기본 흐름은 Hybrid/API + Cache-first 여야 한다.

**Detailed Tasks**

1. 전략 주식 모델과 거래 이력 모델을 정의한다.
2. Hive `stock_cache`, `settings`와 SQLite `transactions`를 초기화한다.
3. Repository 추상화를 만든다.
   - `StockRepository` 인터페이스
   - 개발/테스트용 `MockStockRepository`
   - 실제 런타임용 `HybridStockRepository`
4. 포트폴리오 평단가 계산 엔진을 만들고 단위 테스트로 검증한다.
5. 일일 동기화 로직을 만든다.
   - `last_update_date` 비교
   - 당일 데이터면 캐시 사용
   - 날짜가 바뀌면 Hybrid repository로 갱신
6. Provider 레이어에서 캐시 우선 조회를 연결한다.

**Verification**

- 날짜 변경 시 동기화 로그가 남아야 한다.
- Hive/SQLite에 실제 데이터가 저장되어야 한다.
- 평단가 계산 테스트가 존재해야 한다.
- 네트워크 실패 시 마지막 캐시로 동작해야 한다.

### Phase 3. Strategy Engine & Alerts

**Intent**

- PRD의 2-Track 복합 필터와 전략 이탈 알림을 실제 도메인 흐름으로 완성한다.
- 알림 민감도는 전략 설정과 연결된 상태로 저장되어야 하며, 고정 rank 숫자보다 전략 풀 대비 비율 기준을 우선한다.

**Detailed Tasks**

1. 스코어링 엔진을 구현한다.
   - Min-Max 정규화
   - 가중치 합산
   - 데이터 누락/이상치에 대한 fail-safe
2. 전략 스냅샷과 순위 변동 비교 로직을 만든다.
3. 활성 전략 모델을 정의한다.
   - 가중치
   - `topN`
   - 민감도(`High`, `Medium`, `Low`)
4. 민감도 로직을 구현한다.
   - `High = 상위 10%`
   - `Medium = 상위 20%`
   - `Low = 상위 30%`
5. 로컬 알림 서비스를 구현하고 WorkManager와 연결한다.
6. 백그라운드 작업이 실제 활성 전략/관심 종목/포트폴리오 상태를 사용하도록 연결한다.

**Verification**

- PER 0, ROE null 같은 비정상 데이터에서도 스코어링이 중단되지 않아야 한다.
- 같은 하락 상황에서 민감도에 따라 알림 여부가 달라져야 한다.
- 백그라운드 강제 실행 시 실제 알림 파이프라인이 동작해야 한다.

### Phase 4. Strategy UX & Detail Experience

**Intent**

- PRD의 전략 탐색/상세/포트폴리오 경험을 실제 데이터 기반 화면으로 연결한다.
- 상세 화면은 Mock 전용 화면이 아니라 선택한 종목과 거래 이력에 연결된 화면이어야 한다.

**Detailed Tasks**

1. 전략 목록, 대시보드, 종목 상세 화면을 provider 기반으로 연결한다.
2. 상세 화면 상단 카드, 레이더 차트, 스마트 태그를 구현한다.
3. 정규화 로직을 차트와 연결한다.
   - PER은 반전(inversion)
   - ROE, Dividend는 정방향 정규화
4. 거래 이력 타임라인을 종목 상세 화면에 연결한다.
   - SQLite 거래 내역을 ticker 기준으로 필터링한다.
5. 스크롤/차트 성능과 시각적 정합성을 개선한다.

**Verification**

- 단위가 다른 지표를 비교할 때 차트가 한쪽으로 찌그러지지 않아야 한다.
- 태그가 중복 없이 보기 좋게 노출되어야 한다.
- 상세 화면은 실제 선택 종목 데이터와 거래 이력을 보여줘야 한다.

### Phase 5. Monetization & Release Hardening

**Intent**

- PRD의 광고 전략을 핵심 플로우를 해치지 않는 방식으로 연결한다.
- 광고는 전략 저장 흐름을 막지 않아야 하며, 실패 시 즉시 다음 단계로 진행해야 한다.

**Detailed Tasks**

1. `google_mobile_ads`를 추가하고 플랫폼별 App ID를 등록한다.
2. 하단 배너 광고를 실제 레이아웃에 연결한다.
3. 전략 저장 시 전면 광고를 연결한다.
   - 개발 빌드: 테스트 ID
   - 릴리즈 빌드: 실제 ID
4. 광고 Fail-safe를 구현한다.
   - 타임아웃 기본 500ms
   - 로드 실패 시 즉시 저장 완료 흐름으로 진행
5. 빈도 제한을 구현한다.
   - 최근 1시간 내 재노출 금지
6. 앱 아이콘, 스플래시, 릴리즈 설정을 마무리한다.

**Verification**

- 네트워크 차단 상태에서도 전략 저장이 0.5초 안에 이어져야 한다.
- 테스트 광고 ID가 개발 빌드에서 사용되어야 한다.
- 앱 실행부터 전략 저장, 알림, 광고까지 기본 시나리오가 막힘 없이 이어져야 한다.

### Phase 6. Insight Layer & Daily Intelligence

**Intent**

- 제품을 `기능이 많은 툴`에서 `매일 열어보는 인사이트 앱`으로 확장한다.
- 기존 전략, 포트폴리오, 상세 화면을 연결하는 설명 레이어를 추가한다.

**Detailed Tasks**

1. `오늘의 브리프`를 대시보드 상단에 추가한다.
   - 활성 전략 신규 진입/이탈
   - 보유 종목 중 위험 종목
   - 오늘의 Top pick
2. `왜 이 종목인가` 설명 레이어를 만든다.
   - PER/ROE/배당 기여도
   - 순위 상승/하락 이유 요약
   - 전략 적합도 태그
3. `리밸런싱 코치`를 포트폴리오에 추가한다.
   - 전략 밖 보유 종목
   - 전략 상위권 미보유 종목
   - 비중 과다/축소 후보
4. 전략 비교 모드를 만든다.
   - 프리셋 vs 사용자 전략 비교
   - 종목 overlap / 차이 / 점수 차이 요약
5. 필요 시 거래 메모/저널 기능을 추가해 의사결정 맥락을 남긴다.

**Verification**

- 대시보드 첫 화면에서 "오늘의 변화"를 3초 안에 파악할 수 있어야 한다.
- 전략 결과에 대해 최소 1개 이상의 설명 이유가 표시되어야 한다.
- 포트폴리오에서 전략 대비 리밸런싱 제안이 보이고, 잘못된 종목 분류가 없어야 한다.

## 5. Current Correction Plan

1. `IMPLEMENTATION_STATUS.md`를 기준 문서로 두고 구현/리뷰 때마다 먼저 갱신한다.
2. Phase 3에서 활성 전략/민감도 저장 구조를 정리하고, 백그라운드 알림이 그 상태를 그대로 사용하도록 맞춘다.
3. Phase 4에서 종목 상세 화면의 Mock 직접 의존을 제거하고 실제 provider + SQLite 타임라인으로 전환한다.
4. Phase 5에서 테스트 광고 기준 AdMob 흐름을 연결하고, 이후 운영 App ID / ad unit ID로 교체한다.
5. Phase 6에서 대시보드/전략/포트폴리오를 묶는 인사이트 레이어를 추가한다.
   - 현재는 대시보드 `오늘의 브리프`, 전략 카드 한 줄 설명, 종목 상세 `왜 이 종목인가`, 포트폴리오 `리밸런싱 코치`, 최소 버전 `전략 비교`까지 반영되었고, 다음은 거래 저널과 전략 비교 고도화다.
6. 체감 성능을 계속 점검한다.
   - 전략 카드 설명은 배치형으로 줄였고, `strategySnapshotProvider` 점수 계산은 background isolate로 이동했다.
   - 개발 빌드에서는 `dailyBriefProvider`, 알림 런타임, 광고 배너 로드를 지연시켜 첫 화면 반응성을 우선한다.
   - 다음 최적화 우선순위는 활성 전략 스냅샷과 Daily Brief 결과를 더 늦은 타이밍에 사전 캐시하는 것이다.
7. 테스트 명령이 안정적으로 도는 환경을 정리해 문서의 검증 결과를 다시 신뢰 가능한 상태로 맞춘다.
