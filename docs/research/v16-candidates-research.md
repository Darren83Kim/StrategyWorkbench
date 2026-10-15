# v16 후보 조사

- 작성일: 2026-10-15
- 대상: Strategy Workbench `1.0.1+15` (`pubspec.yaml`)
- 성격: 코드 변경 없는 리서치 초안. 구현 지시가 아니다.
- 범위: 학습 도구 위치를 유지하는 편의·학습·리텐션·스토어 노출 후보. 매매 권유, 계좌, 수익률 관리는 범위 밖이다.

수치는 출처가 있는 것만 적었다. 콘솔을 다시 열지 못했거나 유사 앱의 다운로드·매출·리텐션처럼 공개 페이지에서 확인하지 못한 값은 **미확인**이다.

## 1. 현재 앱 (저장소 기준)

개인 출시 빌드(`STORE_VARIANT=personal`)는 포트폴리오 탭, `/portfolio`, 보유 기반 알림을 끈다. `lib/core/config/store_policy.dart`가 이 분기를 맡는다. 2026-07-06 Play 거절은 개인 개발자 계정과 주식 거래·포트폴리오 관리 선언의 조합이었다 (`RELEASE_PREP_CHECKLIST.md`).

v15에 이미 있는 학습 흐름:

| 영역 | 있는 것 | 코드 위치 |
| --- | --- | --- |
| 첫 실행 | 3장 온보딩(기준, 별표, 지표 사전). 건너뛰기 가능 | `lib/features/onboarding/onboarding_screen.dart` |
| 기준 | PER·ROE·배당 비중, 프리셋 4개(가치주, 배당주, 퀀트, 급등주) | `lib/core/providers/filter_providers.dart` |
| 랭킹 | 한국·미국·전체 샘플. 별표 관심 종목은 전략별 로컬 저장 | `watchlistProvider` |
| 해설 | 지표가 점수에 미친 기여, 지표 사전 6항목, 데이터 출처·누락 표시 | `metric_dictionary_screen.dart`, `SampleMetricPolicy` |
| 비교·기록 | 최대 3종목 비교, 기준 비교, 실험 기록 최근 20건, 관찰 메모 300자 | learning 화면, `IMPLEMENTATION_STATUS.md` |
| 광고 | 하단 배너. 전략 저장 시 전면 광고 시도 | `banner_ad_widget.dart`, `ad_service.dart` |
| 레이아웃 | 하단 탭 2개(대시보드, 전략). 창 너비 분기 없음 | `lib/shared/widgets/root_layout.dart` |
| 계정 | 없음. 기록은 기기 안 | SharedPreferences, Hive |

표본은 미국 10종목, 한국 29종목이다 (`stock_universe.dart`). 출시·개인 모드에서는 출처가 `샘플 데이터`인 지표를 점수에서 뺀다.

미국 PER이 비는 이유는 제품 정책이 아니라 데이터 경로다. `nasdaq_stock_repository.dart`는 미국 종목 `per`를 0으로 두고, Nasdaq 공개 응답에서는 배당수익률과 After Tax ROE만 읽는다 (`keyless_fundamentals.dart`). 한국은 네이버 공개 응답에서 PER·배당·ROE를 채운다.

Android 품질 관련 저장소 상태:

- `android/app/build.gradle.kts`의 release 타입에 `isMinifyEnabled`, `isShrinkResources`가 없다. AGP는 `8.7.0` (`android/settings.gradle.kts`). `targetSdk`는 `flutter.targetSdkVersion`이라 저장소만으로는 숫자가 **미확인**이다.
- 런처 PNG는 밀도별로 약 2–12KB다. `pubspec.yaml`에 `assets` 선언이 없어 `assets/store`의 스토어 JPG·피처 그래픽은 앱 번들에 들어가지 않는다.
- 과거 릴리스 빌드 기록은 `--no-tree-shake-icons`를 썼다 (`RELEASE_PREP_CHECKLIST.md`). 아이콘 폰트 축소가 꺼진 빌드였다는 뜻이다.

스토어 문구 초안은 `PLAY_STORE_LISTING_PERSONAL_KO.md`(2026-07-10)에 있다. 앱 이름은 `Strategy Workbench`, 짧은 설명은 “PER, ROE, 배당 조건으로 한국/미국 종목 샘플 랭킹을 비교하는 지표 학습 앱”이다. 2026-10-14 한국 출시본의 실제 등록정보와 이 초안이 같은지는 **미확인**이다. 다운로드 약 10회, 3세 이상, Play Console의 넓은 화면·비트맵·R8 권장도 이번 조사에서 콘솔로 재확인하지 못했다. 아래 Play 의견은 그 전달 내용을 공식 문서에 대어 본 것이다.

## 2. 유지할 경계

v16 후보는 아래를 만족할 때만 후보로 올렸다.

- 지표의 뜻, 비중을 바꾸면 샘플 순서가 어떻게 달라지는지, 값이 왜 비는지 가르친다.
- 특정 종목의 매수·매도·보유를 권하지 않는다.
- 계좌 연결, 주문, 평단가, 수익률, 리밸런싱을 다시 열지 않는다.
- “급등”, “추천”, “수익 내기”를 새 문구에 넣지 않는다. 기존 프리셋 이름 `급등주`는 이미 저장소에 있으므로, 이름을 학습 표현으로 바꾸는 일은 아래 4번 후보에 포함한다.

모의 주문, 가격 알림, 수익률 위젯은 리텐션 사례로는 흔하지만 이 앱의 v16 후보가 아니다. 한국거래소에도 모의증권투자게임이 있으나([KRX 모의증권투자게임](https://main.krxverse.co.kr/_contents/ACA/02/02010400/ACA02010400P1.jsp)), 주문 체험은 이미 거절된 금융 기능 선언과 맞닿는다.

## 3. 유사 제품에서 확인한 패턴

비교 대상은 주식 스크리너, 기업 정보 앱, 투자 학습 콘텐츠, 교육 앱의 반복 학습이다. 가격·플랜 한도·리텐션 배수는 각 출처의 주장이며, 이 앱에서 재현된다고 확인된 값은 아니다.

### 3.1 사용자 편의

- **조건을 저장하고 다시 연다.** 알파스퀘어 종목필터는 시장·업종과 재무·기술·시세 조건을 최대 15개까지 두고, 결과를 미리 본 뒤 저장한다 ([종목필터 알아보기](https://alphasquare.oopy.io/tutorial/pc/screener)). Finviz는 필터 조합을 Screener Preset으로 저장한다. Elite 비교표에는 프리셋이 무료 50개, Elite 200개로 적혀 있다 ([Finviz Elite](https://finviz.com/elite/), [저장 안내 글](https://finviz.com/blog/create-stock-screens-then-save-and-trade-them/)). 이 앱은 분석 기준 저장과 실험 20건이 이미 있다. 없는 것은 “저장한 기준을 수업처럼 다시 밟는 경로”다.
- **관심 목록을 여러 묶음으로 둔다.** 알파스퀘어는 목록 추가, 국내·해외·가상자산 검색 추가, 이름·순서·삭제를 안내한다 ([관심목록 맞춤 세팅하기](https://alphasquare.oopy.io/55ee6d22-3706-45bc-87f8-8f7ea70bf61c)). Simply Wall St 도움말은 플랜에 따라 워치리스트 최대 5개, 목록당 50종목이라고 적는다 ([Getting Started With Watchlist](https://support.simplywall.st/hc/en-us/articles/8273417841935-Getting-Started-With-Watchlist)). 이 앱의 별표는 전략마다 한 묶음이다. 묶음을 늘리는 일은 10회 다운로드 단계에서 우선순위가 낮다.
- **관심 종목에서 비교로 이어진다.** 딥서치 앱 소개는 북마크, 조건 검색, 경쟁사 비교, 세분 알림을 적는다 ([App Store 딥서치](https://apps.apple.com/us/app/%EB%94%A5%EC%84%9C%EC%B9%98/id1547759190)). 웹 가이드는 경쟁사 매출·자산과 PER·PBR 같은 배수를 차트로 비교한다고 설명한다 ([기업 분석](https://help.deepsearch.com/web/guide/undefined-3/undefined-1)). 이 앱은 3종목 비교가 이미 있다.
- **값이 없을 때 이유를 보여 준다.** Simply Wall St Snowflake는 가치·성장·과거·재무건전성·배당 다섯 축의 검사 점수(각 6개, 통과 1점)를 도형으로 줄이고, ETF는 주식과 같은 모형이 아니라고 도움말에 밝혀 둔다 ([How does the Snowflake work](https://support.simplywall.st/hc/en-us/articles/360001740916-How-does-the-Snowflake-work)). 이 앱의 대응 지점은 미국 PER 0이다. 데이터 확인 카드는 있으나, 랭킹 행이 “왜 미국 종목은 PER 점수가 없는지”를 수업처럼 말하진 않는다.
- **넓은 화면은 목록과 본문을 같이 둔다.** 알파스퀘어는 관심종목·차트·스마트 기능을 한 화면에 두는 구성을 제품 소개에 적는다 ([알파스퀘어 제품](https://alphasquare.co.kr/product)). Android 쪽 기준은 아래 5절.

가격·뉴스·공시 알림은 스크리너의 기본 편의다. TradingView는 워치리스트 전체에 같은 조건을 거는 알림을 안내하고, 블로그는 플랜별 활성 개수(Premium 2, Expert 10, Ultimate 15)를 적는다 ([알림 소개](https://www.tradingview.com/support/solutions/43000520149-introduction-to-tradingview-alerts/), [워치리스트 알림 블로그](https://www.tradingview.com/blog/en/watchlist-alerts-on-tradingview-49839/)). 네이버페이 증권 고객센터 목차에는 “증시에서 관심종목 확인 방법”과 알림 항목이 있다 ([고객센터 목차](https://help.naver.com/service/5617/contents/22059?lang=ko&osType=MOBILE)). 도움말 본문 절차는 이 조사에서 확인하지 못했다. 가격 알림은 이 앱에 가져오지 않는다.

### 3.2 학습

- **짧은 사전과 실습이 붙어 있다.** Investopedia 주식 시뮬레이터 안내에는 Research(시세, 기업 정보, 스크리너)와 Answers(질문 후 관련 글)가 Trade와 나란히 있다 ([시뮬레이터 사용법](https://www.investopedia.com/how-to-use-the-investopedia-simulator-5221184), [화면 구성](https://support.investopedia.com/hc/en-us/articles/30224662566551-How-To-Guide-Part-1-Introduction-User-Interface)). 시뮬레이터의 가상 주문·게임·리더보드는 가져오지 않는다. 가져올 조각은 “용어를 본 뒤, 그 용어로 숫자를 만져 보는 순서”다.
- **계산 과정이 드러나는 도구.** 딥서치 쿼리 문서는 `PER < 10 and PBR < 1`처럼 지표 조건을 문장으로 쓰게 한다 ([쿼리 개요](https://help.deepsearch.com/dp/api/inquiry/overview)). 이 앱의 점수는 정규화와 비중 곱이다. 사용자는 PER이 주가/이익인지는 사전에서 읽고, 그 나눗셈을 입력해 보지는 못한다. 미국 PER이 비어 있으므로, 공개 시세를 늘리기 전에 계산기를 두는 편이 데이터 한계와 맞다.
- **공식 교육은 강의·자료·퀴즈 자료형이다.** 한국거래소 아카데미는 초보 투자자 교실 동영상([초보투자자 교실](http://main.krxverse.co.kr/krx-academy/capital/video/beginner))과 ETF 퀴즈 자료([ETF 퀴즈](https://main.krxverse.co.kr/krx-academy/etf/etf-quiz))를 둔다. 퀴즈 페이지에서 확인한 것은 자료 목록이며, 앱형 오답 해설 흐름은 **미확인**이다. 재정경제부 경제배움e+ 목록은 한국거래소 온라인 교육에 교재·애니메이션·게임·퀴즈가 있다고 적는다 ([경제배움e+](https://www.econedu.go.kr/user/plafomIntrod/generEduLean/menu/list)).
- **도형이 점수를 설명하게 한다.** Snowflake 도움말은 점수가 낮아도 투자 제외를 뜻하지 않는다고 적는다. 이 앱의 기여도 막대와 같은 역할이다. v16에서 점수 모형을 늘리기보다, 빈 지표와 비중 변화를 말로 푸는 쪽이 현재 코드와 맞다.

이 앱 지표 사전은 검색·퀴즈·계산 입력이 없는 고정 6카드다.

### 3.3 리텐션

- **하루 1회, 문턱은 낮게.** Duolingo 도움말은 스트릭을 “레슨을 완료한 연속 일수”로 정의하고, 알림으로 연습 시각을 맞출 수 있다고 한다 ([What is a streak?](https://www.duolingo.com/help/what-is-a-streak)). 자사 블로그는 스트릭 7일인 학습자가 다음 날 계속할 가능성이 스트릭 없는 학습자의 2.4배였다고 적는다. 같은 글은 스트릭을 일일 목표와 분리해 “레슨 1개”만으로 이어지게 한 실험에서 Day 14 리텐션이 상대적으로 3.3% 늘었다고 보고한다 ([Improving the streak](https://blog.duolingo.com/improving-the-streak/)). 이 배수는 Duolingo 언어 학습 실험이며, 주식 지표 앱의 기대치로 쓰지 않는다. 구조만 가져온다. 연속 학습은 문제 1개로 이어지고, 많이 풀기는 별도 목표로 둔다.
- **저장된 관심 항목이 다시 방문 이유가 된다.** Simply Wall St 워치리스트 도움말은 뉴스·배당·실적 메일과 주간 메일에 워치리스트가 포함된다고 적는다. 메일은 계정이 필요하다. 이 앱은 계정이 없으므로 대응은 기기 로컬 알림이다. 내용은 가격이 아니라 “오늘 지표 한 문제”여야 한다.
- **첫 세션에 결과물을 남긴다.** 온보딩은 설명 후 건너뛸 수 있고, 분석 기준을 저장해야 끝나는 구조가 아니다. 스크리너들이 첫 저장 화면을 강조하는 이유와 같은 자리다. Finviz 글은 저장 화면에 이름을 붙이라고 안내한다.

리더보드, 가상 화폐, 스트릭 수리 상품은 Duolingo·Investopedia 쪽에 있으나 광고 앱의 학습 루프와 목적 선언을 흐린다. v16 후보에서 뺀다.

### 3.4 스토어 노출 (ASO)

Google Play 기본 등록정보 제한은 앱 이름 30자, 짧은 설명 80자, 전체 설명 4,000자다. 전각·반각 모두 1자로 센다 ([앱 만들기](https://support.google.com/googleplay/android-developer/answer/9859152)). Play에는 App Store식 키워드 필드가 없다. 검색에 쓰이는 문구는 이름, 짧은 설명, 전체 설명이다. 키워드를 반복하거나 앱과 무관한 단어를 넣으면 정지될 수 있다고 같은 문서가 적는다.

이름·미리보기 자산 관행 ([스토어 등록정보 권장사항](https://support.google.com/googleplay/android-developer/answer/13393723?hl=en), [미리보기 자산](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en)):

- 이름은 기능을 정확히 말하고, 30자 이하다. “무료”, “최고”, “1위”, 이모지, 특수문자 나열은 피한다.
- 짧은 설명은 이름 반복보다 핵심 이점을 말한다. 여러 문장이 아니면 마침표를 남발하지 않는다.
- 스크린샷·그래픽은 앱에 있는 기능만 보여 준다. 순위·후기·가격 문구는 피한다.
- 등록정보와 실제 앱이 다르면 거절될 수 있다 ([게시 안내](https://support.google.com/googleplay/android-developer/answer/15191715?hl=en)).

카테고리 예시에서 Education은 시험 준비, 학습 보조, 용어이고 Finance는 뱅킹, 금융 뉴스, 포트폴리오·트레이딩이다 ([카테고리와 태그](https://support.google.com/googleplay/android-developer/answer/9859673?hl=en)). 태그는 최대 5개이며 목록은 콘솔이 제공한다. 이 앱의 현재 카테고리·태그는 **미확인**이다.

맞춤 스토어 등록정보는 검색 키워드·국가·이탈 사용자 등으로 이름·아이콘·설명·그래픽을 나눌 수 있다 ([맞춤 등록정보](https://support.google.com/googleplay/android-developer/answer/9867158?hl=en)). 스토어 등록정보 실험은 아이콘·스크린샷·문구의 A/B이고, 안내 페이지는 한 번에 자산 하나, 최소 1주를 권한다 ([실험 소개](https://play.google.com/console/about/store-listing-experiments/)). Google 개발자 블로그는 맞춤 등록정보 내부 비교에서 MAU가 평균 3.5% 이상 늘었다는 각주를 달았다 ([2023-09 블로그](https://android-developers.googleblog.com/2023/09/grow-user-acquisition-and-store-conversions-with-updated-play-store-listing-certificate-course.html)). 설치 약 10회에서는 실험의 표본이 되지 않는다. 문구를 먼저 고치고, 실험은 노출이 생긴 뒤로 미룬다.

## 4. v16 후보

난이도는 현재 코드 기준이다.

- **낮음:** 기존 화면·문구·`SampleMetricPolicy`·프리셋에 카드나 입력 하나를 더한다. 새 서버·계정이 없다.
- **중간:** 새 라우트, SharedPreferences, 기존 알림 플러그인을 학습 문구로만 다시 쓴다.
- **중상:** 앱 셸을 창 너비로 나누고, 하단 시트·탭이 있는 화면을 태블릿에서 다시 본다.

효과는 상대 평가다. 설치 수가 한 자릿수이므로 노출(검색 문구)이 리텐션 기능보다 먼저다. 리텐션 수치는 이 앱에서 **미확인**이다.

| 순위 | 후보 | 리텐션 | 노출 | 학습 | 난이도 | Play 3개 | 의견 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 스토어 이름·짧은 설명·전체 설명·스크린샷 문구 | 낮음 | 높음 | 간접 | 낮음 (콘솔) | 해당 없음 | v16에 포함. 코드 없이 가능 |
| 2 | 미국 PER 등 빈 지표를 랭킹에서 설명 | 중간 | 낮음 | 높음 | 낮음 | 해당 없음 | v16에 포함 |
| 3 | PER·ROE·배당 계산기 | 중간 | 중간 | 높음 | 낮음 | 해당 없음 | v16에 포함 |
| 4 | 프리셋 따라 하기 (가치주·배당주·퀀트) | 중간 | 낮음 | 높음 | 낮음 | 해당 없음 | v16에 포함. `급등주` 이름은 학습 표현으로 교체 검토 |
| 5 | 오늘의 한 문제와 기기 안 연속 학습 | 높음 | 낮음 | 높음 | 중간 | 해당 없음 | v16 후반. 문제 1개면 연속으로 인정 |
| 6 | 학습 리마인더 (가격·매매 문구 없음, 기본 꺼짐) | 높음 | 낮음 | 중간 | 중간 | 해당 없음 | 5번 이후에만. 권한 요청은 가치를 보여 준 뒤 |
| 7 | 넓은 화면에서 목록과 해설을 나란히 | 낮음~중간 | 중간 | 중간 | 중상 | 넓은 화면 | v16에 포함. Phone 레이아웃은 유지 |
| 8 | R8·비트맵은 수치 확인 후 필요한 것만 | 없음 | 간접 | 없음 | 중간 | R8, 비트맵 | 기능 릴리스와 분리. 아래 5절 |

### 1. 스토어 문구

초안은 7절. 기대 효과는 “Strategy Workbench”만으로는 잡히지 않는 검색어(PER, ROE, 배당, 지표 학습)를 30자 이름 안에 넣는 것이다. 학습 효과는 간접이다. 설치 전에 매매 앱이 아님을 알려 조기 이탈을 줄인다. 난이도가 낮은 이유: 앱 버전 코드 변경이 필수는 아니다. 스크린샷이 새 화면을 약속하면 앱과 어긋나므로, 스크린샷은 지금 있는 비중 조절·랭킹·해설만 찍는다.

### 2. 빈 지표 설명

미국 종목은 PER이 구조적으로 0이다. 출시 빌드는 표본 지표를 점수에서 빼고, 표시 문구는 `지표 없음`이다 (`sample_metric_policy.dart`). 사용자는 이를 데이터 오류로 읽을 수 있다. 랭킹과 종목 상세에 “이 경로의 미국 시세에는 PER이 없고, PER 비중은 그 종목 점수에 들어가지 않는다”는 한 줄을 둔다. 새 시세 업체는 범위 밖이다. 약관·키·지연을 이 조사에서 확정하지 않았다.

### 3. 계산기

가격과 주당이익으로 PER, 이익과 자기자본으로 ROE, 주당 배당과 가격으로 배당수익률을 보이게 한다. 결과는 “입력값의 계산”이며 시장 데이터나 매수 신호가 아니다. 사전 카드의 `appUsage` 문장과 연결하면 기존 카피 톤을 유지할 수 있다. 검색 노출은 스토어 설명에 “직접 계산”을 넣을 때 생긴다. 계산기만 추가하고 설명을 그대로 두면 노출 효과는 작다.

### 4. 프리셋 따라 하기

프리셋 비중은 이미 있다. 가치주 PER 0.70·ROE 0.30, 배당주 배당 0.60, 퀀트는 세 지표가 거의 같다. 없는 것은 “이 비중을 적용하면 어떤 축이 순서를 바꾸는지”를 한 화면에서 끝내는 경로다. 분석 기준 실험실이 전후 순위를 이미 계산하므로 새 엔진은 필요 없다. `급등주`(ROE 0.80)는 기능은 두고 표시 이름을 수익성 비중 쪽으로 바꾸는 편이 학습 앱 문장과 맞다. 저장된 기존 이름과의 마이그레이션이 작은 위험이다.

### 5. 오늘의 한 문제

문항은 지표 사전 6장의 정의·읽는 법·“미래 성과가 아니다”에서만 만든다. 정답이 “이 종목을 사라”인 문제는 만들지 않는다. 연속 일수는 SharedPreferences에 둔다. Duolingo가 공개한 실험 구조대로, 하루 1문제면 연속이 이어지게 한다. 전면 광고는 전략 저장에 이미 연결되어 있으므로 문제 완료마다 전면 광고를 추가하지 않는다.

### 6. 학습 리마인더

`flutter_local_notifications`와 알림 권한은 저장소에 있다. 개인 모드는 포트폴리오 백그라운드 알림을 건너뛴다 (`StorePolicy.enablePortfolioAlerts`). 학습 알림은 그 경로를 다시 켜는 일이 아니다. 별도 로컬 스케줄이고, 기본값은 꺼짐, 문구는 “오늘 지표 한 문제”다. 가격, 등락, 매수 시점은 넣지 않는다. 권한 대화상자는 1문제를 끝낸 뒤에 띄운다.

### 7. 넓은 화면

`RootLayout`은 `BottomNavigationBar`만 있다. `LayoutBuilder`나 600dp 분기가 없다. 넓은 창에서는 전략 목록과 종목 해설을 좌우로 두는 구성이 학습에 직접 도움이 된다. 알파스퀘어식 차트 3단은 범위가 크다. 1차는 너비 약 600dp 이상에서 내비게이션 레일과 목록·상세 2열이다. 바텀시트는 넓은 창에서 화면 전체를 덮지 않게 폭을 제한한다. Android 품질 기준의 키보드·마우스·트랙패드까지 한 번에 맞추는 일은 이 후보보다 크다.

### 8. R8과 비트맵

사용자 기능이 아니다. 5절의 이유로 “고친다”가 아니라 “올린 AAB의 DEX 크기와 최적화 비율, 비트맵 메모리 항목을 먼저 본다”가 일이다. AdMob·Firebase·WorkManager가 있어 keep 규칙을 넓히면 최적화 비율이 오히려 떨어질 수 있다. 측정 전에 `isMinifyEnabled`를 임의로 켜지 않는다.

## 5. Play Console 권장 3개

콘솔에 뜬 문장 원문은 **미확인**이다. 아래는 같은 이름으로 공개된 품질 기준이다.

### 넓은 화면: v16에 넣는다

Adaptive App 품질 가이드는 예전 큰 화면 가이드를 대체한다. Tier 2는 창 크기 등급에 따른 레이아웃, 큰 화면의 다중 창, 넓은 창에서 버튼·입력 칸이 끝에서 끝까지 늘어나지 않는 구성을 요구한다 ([Adaptive app quality](https://developer.android.com/docs/quality-guidelines/adaptive-app-quality), [Tier 2](https://developer.android.com/develop/adaptive-apps/quality-guidelines/adaptive-app-quality/tier-2)).

Android 16(API 36)은 최소 너비 600dp 이상(태블릿, 큰 폴더블 안쪽 화면, 데스크톱 창)에서 앱의 방향·화면 비·리사이즈 제한을 무시한다. API 37에서는 그 예외도 없어진다. 문서에는 Google Play가 2026년 8월부터 API 36 타깃을 요구한다고 적혀 있다 ([방향·비율·리사이즈](https://developer.android.com/develop/adaptive-apps/guides/app-orientation-aspect-ratio-resizability)). 오늘(2026-10-15)은 그 시점 이후다. 이 저장소의 실제 `targetSdk` 숫자는 **미확인**이다.

포함 이유: 품질 항목이면서, 목록과 해설을 나란히 보여주는 학습 효과가 있다. 폰 레이아웃을 태블릿에 늘리기만 하는 작업으로는 부족하다.

### 비트맵: 기능 후보로 넣지 않는다. 측정만 한다

Play의 비트맵 관련 항목은 두 가지라, 콘솔 문구가 어느 쪽인지 **미확인**이다.

1. 패키지 안 이미지 용량. Flutter 크기 문서는 PNG·JPEG 압축과 미사용 리소스 제거를 크기 절감 수단으로 적는다 ([Measuring your app's size](https://docs.flutter.dev/perf/app-size)).
2. 비트맵 메모리 바이탈. 사용자에게 보이는 서비스·백그라운드 상태의 P90이 200MB를 넘거나, 캐시 상태가 400MB를 넘으면 기준 초과다. 포그라운드 기준값은 표에 비어 있다. 메모리·비트맵·코드 최적화 초과는 2027년 2월부터 스토어 노출에 영향을 줄 수 있다고 적혀 있다 ([Play Console 기술 품질](https://support.google.com/googleplay/android-developer/answer/17492799?hl=en), [Android vitals](https://developer.android.com/google/play/vitals)).

이 저장소의 런처 아이콘은 밀도별로 수 KB이고, 스토어용 JPG는 앱 자산이 아니다. 네트워크 시세 이미지도 현재 학습 화면에 없다. 패키지 이미지 축소의 체감 효과는 작을 가능성이 크다. 다만 가능성이지, Play가 측정한 이 앱의 비트맵 P90은 **미확인**이다. v16에서는 App Bundle Explorer와 Android vitals의 비트맵 항목을 읽고, 수치가 기준 아래이면 코드를 바꾸지 않는다.

### R8: 사용자 기능과 분리해, 수치를 보고 결정한다

Flutter 배포 문서는 릴리스 APK·AAB에서 R8 축소가 기본이고, `--no-shrink`는 효과가 없으며 릴리스에서는 축소가 항상 켜진다고 적는다 ([Build and release an Android app](https://docs.flutter.dev/deployment/android)). Dart `--obfuscate`는 `libapp.so`의 Dart 심벌이고, R8은 Java/Kotlin DEX다. 둘은 같은 스위치가 아니다.

Play는 2027년 2월 업로드부터, 비압축 DEX가 앱 기준 10MB를 넘을 때 최적화·난독화·축소 각각 25% 이상을 요구한다. 10MB 이하는 그 의무 대상이 아니다 ([기술 품질 요구사항](https://support.google.com/googleplay/android-developer/answer/17492799?hl=en), [DEX code optimization](https://developer.android.com/google/play/vitals/code-optimization)). 이 앱의 DEX 용량과 세 비율은 **미확인**이다. 과거 AAB가 약 57–61MB였다는 기록은 네이티브·리소스를 포함한 크기라 DEX 10MB 판정에 쓸 수 없다.

앱 모듈 gradle에 minify 스위치가 없는 것은 Flutter 플러그인이 릴리스에서 넣는 설정과 별개로 확인해야 한다. 2023년 Flutter 이슈는 플러그인이 최적화가 꺼진 `proguard-android.txt`를 쓰던 문제를 다뤘고, hello world DEX가 25% 줄었다는 측정이 있다 ([flutter/flutter#136879](https://github.com/flutter/flutter/issues/136879)). 그 감소율이 이 저장소의 현재 SDK·AGP 8.7.0 빌드에 적용되는지는 **미확인**이다.

의견: R8을 “v16 학습 기능”에 넣지 않는다. 다음 업로드 전에 올린 AAB의 DEX 크기와 세 비율을 본다. 10MB 이하이거나 25%를 이미 넘으면 플러그인 keep 규칙을 건드리지 않는다. 미달일 때만 `proguard-android-optimize.txt`와 광고·Firebase·WorkManager 규칙을 최소로 조정하고, 배너·저장·랭킹을 릴리스 빌드에서 다시 확인한다.

## 6. 범위 밖으로 둔 것

| 아이디어 | 이유 |
| --- | --- |
| 미국 PER 실데이터 추가 | 새 출처의 약관·키·지연이 미확정. 빈 값 설명과 계산기가 학습 공백을 먼저 메운다 |
| 가격·등락·공시 알림, 시세 위젯 | 스크리너 리텐션의 중심이지만 매매 보조로 읽힌다. 개인 모드는 보유 알림을 이미 껐다 |
| 모의 주문, 리더보드, 수익률 | 2026-07-06 거절 경계와 겹친다 |
| 계정·클라우드 동기화 | 로컬 저장 고지와 개인정보 범위가 커진다. 설치 규모 대비 난이도가 높다 |
| 관심 목록을 여러 그룹으로 확장 | 알파스퀘어·Simply Wall St에는 있으나, 전략별 별표가 이미 있다 |
| 홈 화면 위젯 | Flutter 쪽 네이티브 위젯 경로가 없고, 시세 위젯은 위 알림과 같은 경계다 |
| 스토어 A/B 실험 | 설치 약 10회에서는 1주 실험의 표본이 되지 않는다 |

## 7. ASO 초안

글자 수는 Python `len`으로 2026-10-15에 세었다. 게시 전 Play Console 카운터로 다시 확인한다. 중간점(·)과 이모지는 넣지 않았다.

현재 초안 이름 `Strategy Workbench`는 18자다. 영문 브랜드만 있어 한국어 검색어가 이름에 없다. 설치 수가 적어 브랜드 검색 의존도는 낮다고 보는 편이 맞다. 실제 검색 유입 비중은 **미확인**이다.

### 앱 이름 (30자)

권장: `PER ROE 배당 지표학습` (15자)

기능을 그대로 말한다. “추천”, “수익”, “무료”, “1위”가 없다.

기존 영문 이름을 검색하는 설치 사용자를 남기려면: `Strategy Workbench 지표학습` (23자). 한국어 검색어는 `지표학습`만 들어간다. 노출 목적은 첫 안이 낫다.

### 짧은 설명 (80자)

권장 (46자):

`PER, ROE, 배당 비중으로 한국과 미국 샘플 종목 순서를 배우는 지표 학습 앱`

한 문장이므로 끝에 마침표를 두지 않았다. 매매·수익 약속이 없다.

### 전체 설명에 넣을 순서

4,000자 안에 자연문으로 쓴다. 같은 키워드를 줄마다 반복하지 않는다.

1. 첫 두 문장: 한국·미국 샘플로 PER, ROE, 배당수익률 비중을 배우는 지표 학습 앱이다. 비중을 바꾸면 샘플 순서가 달라지는 것을 본다.
2. 있는 기능만: 분석 기준, 시장 필터, 기여 해설, 지표 사전, 기준 비교, 최대 3종목 비교, 별표, 관찰 메모, 실험 기록 20건.
3. 데이터 한계를 숨기지 않는다. 공개 시세 기준이며 미국 종목은 PER이 없을 수 있다. 가격·지표는 지연되거나 다를 수 있다.
4. 경계 문장: 교육·정보 제공. 거래·가입·운용 권유가 아니다. 계좌·거래 기록·수익률을 관리하지 않는다. 판단 전에는 거래소·공시·증권사 자료를 본다.
5. 광고가 있다. 메모와 실험 기록은 기기에만 있고 앱에서 지울 수 있다.
6. 검색에 도움이 되도록 본문에 한 번씩만 녹인다: 주식 지표, 재무 비율, PER 뜻, ROE 뜻, 배당수익률, 종목 비교, 관심 종목. 아동·초등·용돈 표현은 넣지 않는다. 전달된 “3세 이상”이 콘텐츠 등급인지 타겟층인지는 **미확인**이다. 저장소 초안은 성인 학습자를 권했고, 주식 지표 앱을 아동 앱으로 보이게 하지 않는다.

### 그래픽

- 첫 스크린샷은 검색 결과에서 바로 보인다. 비중 슬라이더와 “지표 학습” 문구가 보이게 찍는다. Play 스크린샷에는 별도 캡션 필드가 없으므로 글자는 이미지 안에 둔다.
- 종목 상세 스크린샷에는 기여 해설이 보여야 한다. 포트폴리오, 매수, 매도, 수익률 화면은 쓰지 않는다.
- 피처 그래픽은 저장소의 `assets/store/feature_graphic_1024x500.png`를 쓰되, 문구가 7절 이름·짧은 설명과 같은지 출시본과 대조한다. 대조 결과는 **미확인**.
- 카테고리는 Education이 학습 위치와 맞다. Finance 예시에는 포트폴리오·트레이딩이 들어 있다. 현재 선택이 **미확인**이므로, Finance라면 Education 변경을 검토한다. 태그는 콘솔 제안 목록에서 학습 보조·용어에 가까운 것 최대 5개다. 목록에 없는 태그를 이 문서에서 지정하지 않는다.
- 맞춤 등록정보와 A/B는 노출이 늘어난 뒤 “PER”, “주식 지표” 검색 사용자를 분리할 때 검토한다.

## 8. 권장 순서

코드 릴리스 하나에 7개를 넣지 않는다.

1. 콘솔 문구와 스크린샷 (후보 1). 앱 바이너리와 무관하게 먼저 할 수 있다.
2. 빈 지표 설명, 계산기, 프리셋 따라 하기 (후보 2–4). 기존 점수·사전·실험실 재사용이다.
3. 문제 1개와 연속 학습, 그 다음 선택적 리마인더 (후보 5–6).
4. 넓은 화면 2열 (후보 7). 폰 회귀를 따로 본다.
5. 다음 AAB를 올리기 전에 DEX·비트맵 수치만 확인 (후보 8). 미달일 때만 R8 규칙을 조정한다.

## 9. 출처

앱 내부:

- `pubspec.yaml` (`1.0.1+15`)
- `PLAY_STORE_LISTING_PERSONAL_KO.md`, `RELEASE_PREP_CHECKLIST.md`, `IMPLEMENTATION_STATUS.md`
- `lib/core/config/store_policy.dart`
- `lib/core/metrics/sample_metric_policy.dart`
- `lib/features/strategy/data/repositories/stock_universe.dart`
- `lib/features/strategy/data/repositories/nasdaq_stock_repository.dart`
- `lib/features/strategy/data/repositories/keyless_fundamentals.dart`
- `lib/shared/widgets/root_layout.dart`
- `android/app/build.gradle.kts`, `android/settings.gradle.kts`

유사 제품·학습:

- 알파스퀘어 종목필터: https://alphasquare.oopy.io/tutorial/pc/screener
- 알파스퀘어 관심목록: https://alphasquare.oopy.io/55ee6d22-3706-45bc-87f8-8f7ea70bf61c
- 알파스퀘어 제품 소개: https://alphasquare.co.kr/product
- Finviz Elite 한도표: https://finviz.com/elite/
- Finviz 화면 저장 글: https://finviz.com/blog/create-stock-screens-then-save-and-trade-them/
- Simply Wall St Snowflake: https://support.simplywall.st/hc/en-us/articles/360001740916-How-does-the-Snowflake-work
- Simply Wall St 워치리스트: https://support.simplywall.st/hc/en-us/articles/8273417841935-Getting-Started-With-Watchlist
- 딥서치 App Store 소개: https://apps.apple.com/us/app/%EB%94%A5%EC%84%9C%EC%B9%98/id1547759190
- 딥서치 기업 분석: https://help.deepsearch.com/web/guide/undefined-3/undefined-1
- 딥서치 쿼리: https://help.deepsearch.com/dp/api/inquiry/overview
- Investopedia 시뮬레이터: https://www.investopedia.com/how-to-use-the-investopedia-simulator-5221184
- Investopedia 화면 안내: https://support.investopedia.com/hc/en-us/articles/30224662566551-How-To-Guide-Part-1-Introduction-User-Interface
- TradingView 알림: https://www.tradingview.com/support/solutions/43000520149-introduction-to-tradingview-alerts/
- TradingView 워치리스트 알림: https://www.tradingview.com/blog/en/watchlist-alerts-on-tradingview-49839/
- 네이버페이 증권 고객센터 목차: https://help.naver.com/service/5617/contents/22059?lang=ko&osType=MOBILE
- KRX 초보투자자 교실: http://main.krxverse.co.kr/krx-academy/capital/video/beginner
- KRX ETF 퀴즈: https://main.krxverse.co.kr/krx-academy/etf/etf-quiz
- KRX 모의증권투자게임 (범위 밖 사례): https://main.krxverse.co.kr/_contents/ACA/02/02010400/ACA02010400P1.jsp
- 경제배움e+: https://www.econedu.go.kr/user/plafomIntrod/generEduLean/menu/list
- Duolingo 스트릭 정의: https://www.duolingo.com/help/what-is-a-streak
- Duolingo 스트릭 실험 보고: https://blog.duolingo.com/improving-the-streak/

ASO·Play 품질:

- 등록정보 글자 제한: https://support.google.com/googleplay/android-developer/answer/9859152
- 등록정보 권장사항: https://support.google.com/googleplay/android-developer/answer/13393723?hl=en
- 미리보기 자산: https://support.google.com/googleplay/android-developer/answer/9866151?hl=en
- 게시 안내: https://support.google.com/googleplay/android-developer/answer/15191715?hl=en
- 카테고리·태그: https://support.google.com/googleplay/android-developer/answer/9859673?hl=en
- 맞춤 등록정보: https://support.google.com/googleplay/android-developer/answer/9867158?hl=en
- 스토어 등록정보 실험: https://play.google.com/console/about/store-listing-experiments/
- 맞춤 등록정보 MAU 내부 비교: https://android-developers.googleblog.com/2023/09/grow-user-acquisition-and-store-conversions-with-updated-play-store-listing-certificate-course.html
- Adaptive App 품질: https://developer.android.com/docs/quality-guidelines/adaptive-app-quality
- Tier 2: https://developer.android.com/develop/adaptive-apps/quality-guidelines/adaptive-app-quality/tier-2
- 방향·비율·리사이즈: https://developer.android.com/develop/adaptive-apps/guides/app-orientation-aspect-ratio-resizability
- Play 기술 품질: https://support.google.com/googleplay/android-developer/answer/17492799?hl=en
- Android vitals: https://developer.android.com/google/play/vitals
- DEX 최적화: https://developer.android.com/google/play/vitals/code-optimization
- Flutter Android 릴리스·R8: https://docs.flutter.dev/deployment/android
- Flutter 앱 크기: https://docs.flutter.dev/perf/app-size
- Flutter R8 규칙 이슈: https://github.com/flutter/flutter/issues/136879
