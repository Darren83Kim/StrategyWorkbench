## 📄 phase2.md: Hybrid Data Layer & Local Persistence

현재 구현 상태는 `IMPLEMENTATION_STATUS.md`에서 관리합니다.

### 1. 목표 및 설계 원칙

- **Goal:** PRD의 자동 갱신 엔진과 로컬 DB 전략(Hive + SQLite)을 실제 코드 구조로 만든다.
- **Hybrid Storage:** 시세 캐시는 Hive, 거래 이력은 SQLite에 저장한다.
- **Correction:** Mock 데이터는 개발/테스트용 검증 수단이며, 실제 런타임 기본 흐름은 Hybrid repository + Cache-first다.

### 2. 세부 수행 작업

1. 데이터 모델을 설계한다.
   - `Stock`: `ticker`, `name`, `price`, `per`, `roe`, `dividendYield`, `lastUpdated`
   - `Transaction`: `id`, `ticker`, `type(BUY/SELL)`, `price`, `quantity`, `dateTime`
2. 로컬 저장소를 초기화한다.
   - `HiveService`: `stock_cache`, `settings`
   - `DatabaseHelper`: `transactions`
3. Repository 계층을 정리한다.
   - `StockRepository` 인터페이스
   - `MockStockRepository`
   - `HybridStockRepository`
4. 포트폴리오 평단가 계산 엔진을 구현한다.
5. 일일 데이터 동기화 로직을 구현한다.
   - `last_update_date` 비교
   - 당일이면 캐시 사용
   - 날짜가 바뀌면 Hybrid repository로 갱신
6. Provider 레이어에서 캐시 우선 조회를 연결한다.
7. 한국투자증권 API 토큰을 안전하게 관리한다.
   - debug 런타임에서는 자동 토큰 발급을 막고 캐시/Mock/다른 KR 소스를 우선한다.
   - 운영/profile 런타임에서는 접근 토큰과 만료 시각을 로컬에 저장해 24시간 내 재발급을 줄인다.

### 3. 검증 및 디버깅

- 날짜를 강제로 변경했을 때 동기화 로그가 정상적으로 찍혀야 한다.
- Hive와 SQLite에 실제 데이터가 저장되어야 한다.
- 평단가 계산이 단위 테스트로 검증되어야 한다.
- 네트워크 오류가 나도 마지막 캐시 데이터로 앱이 동작해야 한다.
- 개발 중 앱 재실행만으로 한국투자 `oauth2/tokenP`가 반복 호출되지 않아야 한다.
