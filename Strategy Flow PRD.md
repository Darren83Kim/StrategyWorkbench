---

# **📑 \[최종 PRD\] Global Strategy Workbench**

**버전:** 1.0

**상태:** 개발 대기 (Ready for Dev)

**기본 철학:** "서버 없이, 데이터로 투자하고, 전략으로 승리한다."

---

## **1\. 제품 개요 및 목표**

* **제품명:** 미정 (가칭: Strategy Flow)  
* **목적:** 사용자가 직접 설정한 퀀트/기술적 전략을 기반으로 한국/미국 주식을 분석하고, 개인 포트폴리오의 전략 부합 여부를 관리함.  
* **핵심 가치:** \* 서버 비용 없는 로컬 기반 데이터 처리.  
  * 복합 필터를 통한 고도화된 종목 발굴.  
  * '전략 이탈 알림'을 통한 매도 시점 가이드.

---

## **2\. 주요 기능 명세 (Features)**

### **① 데이터 자동 갱신 엔진**

* **로직:** 앱 실행 시 Local\_Last\_Update\_Date와 현재 날짜를 비교.  
* **동작:** 날짜가 다를 경우 무료 API(한투, Yahoo 등)를 호출하여 로컬 DB(Hive) 갱신.  
* **최적화:** 호출 횟수 제한을 고려하여 종목 정보는 하루 1회, 현재가는 앱 활성화 시 갱신(캐싱 활용).

### **② 2-Track 복합 필터 (Composite Filter)**

* **초보자 모드:** 검증된 투자 대가들의 프리셋 제공 (클릭 한 번으로 설정).  
* **전문가 모드:** PER, ROE, 배당률, 모멘텀 가중치를 슬라이더로 직접 조절.  
* **네이밍:** 나만의 전략 이름을 지정하고 대시보드에 고정.

### **③ 스마트 포트폴리오 관리**

* **평단가 계산:** 추가 매수 시 가중 평균 방식을 통한 자동 평단 갱신.  
* **전략 매칭:** 보유 종목이 현재 내 복합 필터 순위(Top 50 등)에 있는지 실시간 확인.  
* **이탈 경고:** 순위가 급락하거나 지표가 악화되면 ⚠️ 아이콘 및 로컬 알림 발송.

---

## **3\. UI/UX 디자인 가이드**

* **스타일:** Dark Mode 기반의 **Glassmorphism**.  
* **애니메이션:** Implicit Animations를 이용한 리스트 순위 교체 및 숫자 카운팅.  
* **광고 배치:** 하단 고정 배너 및 필터 저장 시 전면 광고(AdMob).

---

## **4\. 기술 스택 (Tech Stack)**

* **Framework:** Flutter  
* **State:** Riverpod  
* **Database:** Hive (고속 캐싱), SQLite (거래 이력 관리)  
* **API:** Finnhub + FMP(US), KRX Open API + DART(KR), 한국투자증권(KR 폴백)
* **Ads:** Google Mobile Ads (AdMob)

---

## **5\. 단계별 테스트 코드 작성 및 QA 전략**

서버가 없는 로컬 앱일수록 **데이터 계산의 정확성**이 생명입니다. 다음 3단계 테스트를 수행합니다.

### **\[1단계\] Unit Test (단위 테스트)**

비즈니스 로직의 수치 계산이 정확한지 검증합니다.

* **평단가 계산 테스트:** 여러 번의 추가 매수 시 산출되는 평단가가 수식과 일치하는가?  
* **스코어링 로직 테스트:** 사용자가 설정한 가중치(가치 6대 성장 4)에 따라 종목 순위가 올바르게 정렬되는가?  
* **날짜 비교 테스트:** 하루가 지났을 때 자동 갱신 플래그가 정상적으로 true가 되는가?

### **\[2단계\] Widget Test (UI 테스트)**

사용자 인터페이스가 의도대로 반응하는지 검증합니다.

* **슬라이더 반응 테스트:** 전문가 모드에서 슬라이더 조절 시 하단 종목 수가 즉각 변하는가?  
* **시장 스위칭 테스트:** KR/US 버튼 클릭 시 테마색과 지표 단위(₩/$)가 정상 변경되는가?  
* **광고 호출 테스트:** 특정 액션(필터 저장) 후 광고 로드 함수가 호출되는가?

### **\[3단계\] Integration Test (통합 및 시나리오 테스트)**

실제 데이터 흐름을 끝에서 끝까지 검증합니다.

* **시나리오:** "앱 실행 → 자동 데이터 갱신 → 복합 필터 생성 → 종목 상세 확인 → 매수 입력 → 대시보드 반영".  
* **백그라운드 테스트:** WorkManager가 정해진 시간에 깨어나 로컬 알림을 정상적으로 띄우는가?

---

## **API 전략 변경 이력 (2026-03-09)**

### 변경 사유

프로젝트의 핵심 목표는 **"서버 없이, 사용자가 직접 퀀트 결과를 뽑아 보는 앱"**입니다.
기존 API 구성(Yahoo Finance + Alpha Vantage)을 검토한 결과, 이 목표에 부적합하다고 판단하여 전면 교체합니다.

### 기존 구성의 문제점

| API | 문제점 |
|-----|--------|
| **Yahoo Finance** | 비공식 API로 문서화된 한도 없음. 2024년 하반기부터 Rate Limit 강화(429 에러 빈발), 언제든 차단 가능. 안정적인 서비스 불가 |
| **Alpha Vantage** | 무료 한도가 **하루 25회**로 대폭 축소(과거 500→100→25). 종목 5개의 PER/ROE/배당만 조회해도 소진. 서버 없는 클라이언트 앱에 치명적 |
| **한국투자증권** | OAuth 2.0 기반으로 사용자별 키 발급 필수. 보조 소스로는 유효하나 단독 의존 불가 |

### 새로운 API 전략

#### 미국 주식 데이터
| 우선순위 | API | 무료 한도 | 용도 |
|---------|-----|----------|------|
| 1순위 | **Finnhub** | 60회/분 (사실상 무제한) | 실시간 시세 + 펀더멘탈(PER, ROE, 배당) |
| 2순위 | **FMP (Financial Modeling Prep)** | 250회/일 | 재무비율, 재무제표 보조 |
| 폴백 | Yahoo Finance (비공식) | 불안정 | 위 2개 실패 시에만 사용 |

#### 한국 주식 데이터
| 우선순위 | API | 무료 한도 | 용도 |
|---------|-----|----------|------|
| 1순위 | **KRX Open API** | 10,000회/일 | 시세, 종목 정보 |
| 2순위 | **DART (OpenDART)** | 넉넉 (공공데이터) | 재무제표, PER, ROE 등 펀더멘탈 |
| 폴백 | 한국투자증권 | 사용자 키 등록 시 | 실시간 시세 보조 |

#### 캐싱 전략 (API 호출 최소화)
```
앱 실행 → Hive에서 마지막 갱신일(last_update_date) 확인
  ├─ 오늘 이미 갱신됨 → 로컬 데이터 사용 (API 호출 0회)
  └─ 하루 이상 경과 → API 배치 호출 1회 → Hive에 저장 → 날짜 갱신
```
- 하루 1회 갱신 원칙으로 Finnhub 60회/분 한도 내 수백 종목 처리 가능
- 네트워크 실패 시 마지막 캐시 데이터로 계속 동작 (Fail-safe)

### 영향 범위
- `lib/features/strategy/data/repositories/yahoo_stock_repository.dart` → Finnhub Repository로 교체
- `API_SPECS.md` → Finnhub, KRX, DART 명세 추가, Alpha Vantage 폐기 표기
- `.env` → Finnhub API Key 추가 필요
- `HybridStockRepository` → 새 데이터 소스 우선순위 반영

---

## **Implementation Addendum (Phase4 & Phase5 반영 내용)**

**목적:** Phase4/5에서 구현한 핵심 기술적 결정과 PRD에 새로 반영해야 할 세부사항을 명시합니다.

- **Normalizer (정규화 알고리즘):** 서로 단위가 다른 지표(PER, ROE, DividendYield)를 0..1 범위로 정규화합니다. PER은 값이 작을수록 유리하므로 정규화 후 역전(inversion)을 적용합니다. 구현 파일: [lib/core/visualization/normalizer.dart](lib/core/visualization/normalizer.dart#L1).
- **Smart Tag 규칙:** Phase4에서 명시한 규칙을 코드화했습니다. 규칙 요약: `PER < 10 => #저평가`, `ROE > 15 => #우량주`, `DividendYield > 4 => #고배당`. 구현 파일: [lib/core/tags/smart_tag.dart](lib/core/tags/smart_tag.dart#L1).
- **Stock 상세 UI:** Glass header, 정규화된 Radar 차트, 스마트 태그, 거래 내역 타임라인(가상화 필요 시 개선) 초안을 추가했습니다. 파일: [lib/features/market/presentation/stock_detail.dart](lib/features/market/presentation/stock_detail.dart#L1).
- **광고 Fail-safe 및 Frequency Cap:** 전면 광고(Interstitial)에 대해 `timeout` 기반 fail-safe(기본 500ms)와 SharedPreferences 기반 1시간 빈도 제한을 적용했습니다. Ad 관련 서비스: [lib/core/services/ad_service.dart](lib/core/services/ad_service.dart#L1). 하단 배너 위젯: [lib/shared/widgets/banner_ad_widget.dart](lib/shared/widgets/banner_ad_widget.dart#L1).
- **로컬 DB / 마이그레이션 주목사항:** Hive 타입 어댑터(`features/strategy/domain/entities/stock.g.dart`)가 존재하므로 모델 변경 시 어댑터 버전 관리 및 마이그레이션 정책(백업/복원)을 문서에 추가해야 합니다.
- **백그라운드 작업 보강:** WorkManager 기반의 백그라운드 스코어링(장 마감 시 1회)과 테스트용 강제 실행 API가 구현되어 있습니다. 파일: [lib/core/services/background_service.dart](lib/core/services/background_service.dart#L1).
- **테스트 보강:** Normalizer와 SmartTag 유닛 테스트를 추가했습니다. 테스트 파일: [test/normalizer_test.dart](test/normalizer_test.dart#L1), [test/smart_tag_test.dart](test/smart_tag_test.dart#L1). 기존 포트폴리오 평단가 테스트도 유지됩니다.

**PRD에 반영해야 할 권장 문구 (삽입 권고 위치: '기술 스택' 또는 '단계별 테스트' 아래)**
- "정규화(Normalization): 서로 다른 단위를 비교할 때는 Min-Max 정규화(0..1)를 사용하며, PER처럼 값이 작을수록 유리한 지표는 정규화 후 역전(inversion)을 적용한다."
- "광고 Fail-safe: 전면 광고 로드는 타임아웃(기본 500ms)을 적용하고, 로드 실패 시 즉시 저장 흐름으로 진행한다. 전면 광고 노출 후 1시간 동안 재노출을 억제한다. (개발 빌드에서는 Google 테스트 광고 ID 사용)"
- "로컬 DB 마이그레이션: Hive 어댑터 타입 변경 시 버전 관리 및 사용자 데이터 백업/복구 절차를 문서화한다."

---

## **검증 결과 요약 (Phase1~5)**

- 코드 기반 검증: `flutter test` 실행 결과 모든 유닛 테스트 통과(현재 4 tests passed). 주요 테스트 목록: 평단가 계산, Normalizer 유닛, SmartTag 유닛, DebugScreen 위젯 로드 테스트.
- 수동/동작 검증: DebugScreen에서 스코어링 엔진 시뮬레이션 및 백그라운드 강제 실행으로 알림 흐름(로직)이 동작함을 확인함.

---

## **다음 권장 작업 (우선순위) - 2026-03-09 갱신**

### Phase C: API 전략 재설계 및 코드 기반 안정화
1. **Finnhub API Repository 구현:** Yahoo Finance Repository를 Finnhub 기반으로 교체. PER, ROE, 배당수익률 추출 로직 포함.
2. **KRX/DART API Repository 구현:** 한국 시세(KRX) + 재무제표(DART) 통합 Repository 구현.
3. **HybridStockRepository 리팩토링:** 새 데이터 소스 우선순위(Finnhub → FMP → Yahoo 폴백) 반영.
4. **stock_detail.dart 버그 수정:** Future 타입 오류(Line 19-20) 및 deprecated 경고 해결.
5. **glass_container.dart deprecated 수정:** `.withOpacity()` → `.withValues()` 변경.

### Phase D: 상태 관리 및 기능 완성
6. **Riverpod 상태 관리 통합:** StatefulWidget 개별 상태 → Provider 공유 상태로 전환.
7. **필터 저장 기능:** FilterCreationScreen에서 SharedPreferences/Hive 통합.
8. **포트폴리오 DB 연동:** PortfolioScreen에서 SQLite 거래 이력 연동.
9. **마이그레이션/백업 정책 문서화:** Hive/SQLite에 대한 버전별 마이그레이션 절차 추가.
10. **성능 검증 및 UI 개선:** Normalizer 실적용, 거래 타임라인 가상화, 차트 애니메이션 최적화.

---

위 변경사항을 PRD 원문에 반영해 두었습니다. 원하시면 이 문서에서 더 자세한 API 템플릿(엔드포인트/쿼리 예제), ERD(엔티티 다이어그램), 그리고 배포 체크리스트를 자동 생성해 드리겠습니다.

---

## **6\. 최종 배포 전 체크리스트**

1. **API 호출 한도 확인:** 무료 API 호출 횟수가 초과되지 않도록 캐싱 로직이 완벽한가?  
2. **데이터 무결성:** 앱 업데이트 시 로컬 DB에 저장된 사용자의 매수 이력이 날아가지 않는가?  
3. **광고 가이드라인:** 배너 광고가 클릭 가능한 버튼을 가리고 있지는 않은가?

