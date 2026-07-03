# Strategy Workbench Play Store Listing Draft

- Last updated: 2026-06-30
- Purpose: Google Play Console 기본 스토어 등록정보에 바로 입력하기 위한 한국어 초안
- Status: 초안. 실제 게시 전 연락처, 개인정보처리방침 URL, 스크린샷, 정책 답변은 최종 확인 필요

## Basic Listing Fields

### App Name

Strategy Workbench

### Short Description

나만의 투자 전략을 만들고 포트폴리오 변화를 한눈에 확인하세요.

### Full Description

Strategy Workbench는 투자 아이디어를 전략으로 정리하고, 관심 종목과 포트폴리오를 함께 점검할 수 있는 전략 관리 앱입니다.

PER, ROE, 배당 등 주요 지표에 가중치를 주어 나만의 전략을 만들고, 국내/미국 종목을 전략별로 비교할 수 있습니다. 보유 종목과 거래 내역을 기록하면 현재 전략과 얼마나 맞는지, 어떤 종목을 다시 점검해야 하는지 한눈에 확인할 수 있습니다.

주요 기능

- 나만의 투자 전략 생성 및 활성 전략 선택
- 국내/미국 종목 전략 리스트 확인
- 관심 종목 즐겨찾기와 종목 상세 보기
- 포트폴리오 매수/매도 기록 관리
- 오늘의 브리프와 Top Picks 확인
- 리밸런싱 코치로 전략 이탈 종목 점검
- 전략별 핵심 지표와 편입 후보 확인

알아두세요

- 이 앱은 투자 판단을 돕는 정보 제공 도구이며, 특정 종목의 매수/매도 또는 금융상품 가입을 권유하지 않습니다.
- 주가, 종목명, 지표 등 데이터는 외부 데이터 제공처와 공개 시세 정보를 기반으로 표시되며 지연되거나 실제 시장 정보와 다를 수 있습니다.
- 앱 안에서 실제 증권 계좌 연결, 주문, 매수, 매도는 수행하지 않습니다.
- 모든 투자 판단과 결과에 대한 책임은 사용자 본인에게 있습니다.
- 앱에는 광고가 포함될 수 있습니다.

### Release Notes

첫 내부 테스트 빌드입니다.

확인 항목:

- 전략 생성 및 활성 전략 선택
- 국내/미국 전략 리스트와 종목 상세
- 포트폴리오 매수/매도 기록
- 대시보드 오늘의 브리프
- 리밸런싱 코치
- 테스트 광고 표시

## Store Assets

### App Icon

- File: `assets/store/icon_512.png`
- Size: 512 x 512 px
- Usage: Play Console 기본 스토어 등록정보의 앱 아이콘에 업로드

### Feature Graphic

- File: `assets/store/feature_graphic_1024x500.png`
- Size: 1024 x 500 px
- Usage: Play Console 기본 스토어 등록정보의 그래픽 이미지에 업로드

### Screenshots To Prepare

- 대시보드: 오늘의 브리프, Top Picks, 관심 종목 레이더가 보이는 화면
- 전략: 국내/미국 필터, 활성 전략, 종목 리스트가 보이는 화면
- 종목 상세: 종목명, 가격, 전략 적합 이유가 보이는 화면
- 포트폴리오: 보유 종목, 평가액, 리밸런싱 코치가 보이는 화면

## Console Field Suggestions

- Category: Finance
- Tags: 주식, 포트폴리오, 투자 도구, 금융 정보
- Contains ads: Yes
- App access: No special login required
- Target audience: 금융/투자 정보 앱이므로 성인 사용자를 기본 대상으로 설정 권장
- Contact email: TODO
- Developer website: TODO
- Privacy policy URL: TODO

## Policy-Safe Disclosure Snippets

스토어 설명, 개인정보처리방침, 앱 내부 고지에 같은 방향으로 유지하면 좋다.

- Strategy Workbench는 투자 정보 정리와 전략 점검을 돕는 앱입니다.
- 앱에서 제공하는 정보는 투자 자문이 아니며, 매수/매도 추천으로 해석되어서는 안 됩니다.
- 표시되는 가격과 지표는 지연되거나 실제 시장 데이터와 다를 수 있습니다.
- 앱은 증권 계좌 연결이나 실제 주문 기능을 제공하지 않습니다.
- 광고 제공을 위해 Google AdMob SDK가 사용될 수 있습니다.

## Internal Test Notes

- 내부 테스트 앱 설치는 Play Console 앱이 아니라 내부 테스트 참여 링크 또는 Play Store 테스트 링크에서 진행한다.
- 현재 내부 테스트 트랙의 `1.0.0-internal-1`은 최초 업로드 버전이다.
- 런처 아이콘이 반영된 새 AAB는 `versionCode=2`이므로 Play Console에 새 버전으로 업로드해야 내부 테스트 설치본에도 아이콘이 반영된다.
