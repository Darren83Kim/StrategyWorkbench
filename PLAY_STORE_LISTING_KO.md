# Strategy Workbench Play Store Listing Draft

- Last updated: 2026-07-10
- Target build: `STORE_VARIANT=personal`
- Purpose: Google Play Console 기본 스토어 등록정보에 바로 입력하기 위한 개인 개발자 계정용 한국어 초안
- Status: 개인 출시 모드 기준 초안. 실제 게시 전 연락처, 개인정보처리방침 URL, 스크린샷, 정책 답변은 최종 확인 필요

## Basic Listing Fields

### App Name

Strategy Workbench

### Short Description

PER, ROE, 배당 조건으로 한국/미국 종목 지표를 비교하고 학습하세요.

### Full Description

Strategy Workbench는 한국/미국 시장의 기본 지표를 비교하며 학습할 수 있는 정보 제공 앱입니다.

PER, ROE, 배당 수익률 같은 지표의 비중을 조정해 나만의 분석 기준을 만들고, 그 기준에 따라 샘플 종목이 어떻게 정렬되는지 확인할 수 있습니다. 종목 상세 화면에서는 선택한 기준에서 어떤 지표가 설명력을 가지는지 간단한 해설로 보여줍니다.

주요 기능

- PER, ROE, 배당 비중을 조정하는 분석 기준 만들기
- 한국/미국/전체 시장별 샘플 랭킹 확인
- 종목별 현재가와 기본 지표 확인
- 선택한 기준에서 지표가 점수에 미친 영향 해설
- 여러 분석 기준의 샘플 결과 비교
- 별표로 관심 종목 표시 후 대시보드에서 다시 보기
- 종목별 확인 지표 태그와 짧은 관찰 메모를 기기에 저장
- 가중치 실험과 당시 상위 샘플을 최근 20건까지 기기에 저장

알아두세요

- 이 앱은 교육 및 정보 제공 목적의 시장 지표 학습 도구입니다.
- 특정 종목이나 금융상품에 대한 거래, 가입, 운용을 권유하지 않습니다.
- 사용자의 자산, 계좌, 거래 기록, 수익률을 관리하지 않습니다.
- 관찰 메모와 분석 실험 기록은 기기 안에만 저장되며 앱에서 개별 또는 전체 삭제할 수 있습니다.
- 표시되는 가격, 종목명, 지표 데이터는 외부 데이터 제공처와 공개 시세 정보를 기반으로 하며 지연되거나 실제 시장 정보와 다를 수 있습니다.
- 중요한 판단 전에는 거래소, 공시, 증권사 등 공식 자료를 직접 확인해 주세요.
- 앱에는 광고가 포함될 수 있습니다.

### Release Notes

개인 개발자 계정 제출 정책에 맞춰 앱을 지표 학습 중심으로 재구성했습니다.

확인 항목:

- 분석 기준 생성 및 기준 설정
- 한국/미국/전체 시장별 샘플 랭킹
- 종목 상세의 지표 해설
- 대시보드 지표 학습 브리프
- 관심 종목 표시와 레이더
- 관찰 메모와 분석 실험 기록의 로컬 저장 및 삭제
- 광고 표시

## Store Assets

### App Icon

- File: `assets/store/icon_512.png`
- Size: 512 x 512 px
- Usage: Play Console 기본 스토어 등록정보의 앱 아이콘에 업로드

### Feature Graphic

- File: `assets/store/feature_graphic_1024x500.png`
- Size: 1024 x 500 px
- Usage: Play Console 기본 스토어 등록정보의 그래픽 이미지에 업로드
- Personal mode requirement: 그래픽에는 시장 지표 비교와 샘플 랭킹 문구만 사용한다.

### Screenshots To Prepare

- 대시보드: 지표 학습 브리프와 관심 종목 레이더가 보이는 화면
- 전략: 분석 기준, 시장 필터, 샘플 랭킹이 보이는 화면
- 종목 상세: 종목명, 가격, 기본 지표, 지표 해설이 보이는 화면

## Console Field Suggestions

- Category: Education 또는 Tools 중 선택 검토
- Tags: 지표 학습, 시장 데이터, 종목 비교
- Contains ads: Yes
- App access: No special login required
- Financial features: 앱에서 금융 기능을 제공하지 않음
- Target audience: 성인 중심 권장
- Contact email: TODO
- Developer website: TODO
- Privacy policy URL: TODO

## Policy-Safe Disclosure Snippets

스토어 설명, 개인정보처리방침, 앱 내부 고지에 같은 방향으로 유지하면 좋다.

- Strategy Workbench는 시장 지표를 비교하고 학습할 수 있도록 돕는 정보 제공 앱입니다.
- 앱에서 제공하는 내용은 거래 권유나 개인 맞춤형 자문이 아닙니다.
- 표시되는 가격과 지표는 지연되거나 실제 시장 데이터와 다를 수 있습니다.
- 앱은 증권 계좌 연결이나 실제 주문 기능을 제공하지 않습니다.
- 광고 제공을 위해 Google AdMob SDK가 사용될 수 있습니다.

## Internal Test Notes

- 내부 테스트 앱 설치는 Play Console 앱이 아니라 내부 테스트 참여 링크 또는 Play Store 테스트 링크에서 진행한다.
- 개인 출시 모드 AAB는 `--dart-define=STORE_VARIANT=personal`로 빌드한다.
- 현재 비공개 알파 후보는 `versionCode=13`, `versionName=1.0.0`이다.
