# Strategy Workbench Release Prep Checklist

- Last updated: 2026-07-06
- Purpose: 배포 전 남은 외부 계정, API 키, AdMob, Play Store 준비물을 빠르게 확인하기 위한 체크리스트

## Current Code State

- 테스트 광고 기준 AdMob 배너/전면 광고 흐름은 구현되어 있다.
- 2026-07-06 기준 내부 테스트 확인용 빌드는 `1.0.0+3`이며, 포트폴리오 금액 가독성 개선과 테스트 광고 강제 설정(`FORCE_ADMOB_TEST_IDS=true`)을 포함한다.
- 2026-07-06 기준 정식 광고 확인용 출시 후보 빌드는 `1.0.0+4`이며, `FORCE_ADMOB_TEST_IDS=true`를 제거하고 실제 Android AdMob App ID / banner ID / interstitial ID를 `--dart-define`으로 주입해 AAB를 생성했다.
- 개발 빌드에서 AdMob 테스트 ID가 기본 사용된다.
- 실제 운영용 AdMob App ID / ad unit ID는 아직 `.env`에 넣어야 한다.
- Android AdMob App ID / banner ID / interstitial ID는 2026-06-25 기준 로컬 `.env`에 반영했다. 실제 값은 Git에 커밋하지 않는다.
- 실데이터 API 키는 `.env.example` 기준으로 `FINNHUB_API_KEY`, `FMP_API_KEY`, `KRX_API_KEY`, `DART_API_KEY`, `KOR_INVESTMENT_APP_KEY`, `KOR_INVESTMENT_SECRET`, `KOR_INVESTMENT_ACCOUNT`를 사용한다.
- 한국투자증권 자동 토큰 발급은 debug 런타임에서 기본 차단되고, `ENABLE_KOR_INVESTMENT_DEBUG=true`일 때만 실기기 테스트용으로 허용한다.
- 출시 빌드에 개발자 개인 `KOR_INVESTMENT_APP_KEY` / `KOR_INVESTMENT_SECRET`을 포함하면 안 된다. 앱 설치자들이 같은 키로 토큰을 발급하게 되어 키 유출, 토큰 발급 제한, 계정/서비스 제한 리스크가 생긴다.
- Play Store 출시 전에는 KIS client 직접 호출을 release/profile에서 비활성화하거나, KIS를 앱이 아닌 서버/정식 제휴 백엔드 뒤로 이동해야 한다.
- 2026-06-26 기준 release/profile KIS 직접 호출은 코드상 차단했고, `.env`는 Flutter asset에서 제거했다. 개인 KIS 키는 debug `--dart-define` 테스트 전용으로만 사용해야 한다.
- 2026-06-29 기준 release 테스트 APK는 KIS 없이도 국내 종목 현재가/종목명을 확인할 수 있도록 Naver quote fallback을 사용한다.
- 2026-06-29 기준 release 테스트 APK는 Yahoo 실패 시 미국 종목 현재가/종목명을 Nasdaq quote fallback으로 보완한다.
- Naver/Nasdaq 공개 quote fallback은 출시 전 확인용 안정화 수단이다. 장기 운영 출시 전에는 공식/상용 API, 서버 캐시, 사용량 제한, 약관 리스크를 따로 확정해야 한다.

## User-Owned Tasks

### 1. API Keys

- Finnhub 계정 생성 후 `FINNHUB_API_KEY` 발급
- FMP 계정 생성 후 `FMP_API_KEY` 발급
- 공공데이터포털에서 KRX 주식시세정보 API 활용신청 후 `KRX_API_KEY` 발급
- OpenDART에서 `DART_API_KEY` 발급
- 한국투자증권 KIS Developers에서 `KOR_INVESTMENT_APP_KEY`, `KOR_INVESTMENT_SECRET`, `KOR_INVESTMENT_ACCOUNT` 준비
- 실제 값은 `.env`에만 넣고 Git에는 커밋하지 않는다.

### 2. API Key Renewal Notes

- 한국투자증권 접근 토큰은 일반 앱키/시크릿 토큰 발급 흐름에서 24시간 단위로 만료된다는 안내를 받았다. 다만 KIS 문서에는 제휴/인가코드 흐름처럼 더 긴 토큰 흐름도 있으므로, 앱은 고정값보다 응답의 `expires_in`/만료시각을 기준으로 캐시해야 한다.
- 현재 구현은 한국투자증권 토큰 응답의 `expires_in`을 읽고, 만료 60초 전 시각을 `SharedPreferences`에 저장해 재사용한다.
- 토큰 캐시는 기기별 로컬 저장이므로 앱 삭제/재설치, 앱 데이터 삭제, 토큰 만료 후 첫 조회 시 다시 발급될 수 있다.
- 여러 사용자가 출시 앱을 설치하는 경우, 앱에 포함된 동일한 KIS key/secret로 각 기기에서 토큰 발급이 발생한다. 이 구조는 운영용으로 부적합하며 출시 전 반드시 제거/대체해야 한다.
- 사용자가 각자 자신의 KIS key/secret을 입력하는 방식은 기술적으로 가능하지만 일반 사용자용 앱 UX와 보안 책임 측면에서 출시 기본안으로 적합하지 않다.
- 한국투자증권 app key/secret은 access token과 다르다. app key/secret 자체가 매일 만료되는 것은 아니며, 계정별 발급 자격/재발급/정책 변경/유출 여부에 따라 관리한다.
- 공공데이터포털/KRX 키는 활용신청 승인과 트래픽 한도 관리가 중요하다. 재발급 시 기존 키가 폐기될 수 있다.
- OpenDART 인증키는 `crtfc_key` 40자리 인증키를 API 요청에 사용한다. 키 자체 만료보다 계정 상태, 정책 변경, 재발급/유출 관리가 중요하다.
- FMP 무료 플랜은 250 calls/day 기준이다. 무료/유료 플랜 상태에 따라 접근 가능한 endpoint가 달라진다.
- Finnhub 키는 계정/플랜 상태와 rate limit 관리가 중요하다.
- 모든 API 키는 최소 6~12개월 단위로 수동 점검하고, 유출 의심 시 즉시 재발급한다.

### 3. AdMob

- AdMob 계정 생성
- Android 앱 등록 후 Android App ID 발급
- Android 배너 ad unit ID 발급
- Android 전면 ad unit ID 발급
- iOS 출시 계획이 있으면 iOS App ID, iOS 배너/전면 ad unit ID도 발급
- 발급값을 `.env`의 `ADMOB_*` 항목에 반영
- developer website 준비
- `app-ads.txt` 파일을 developer website 루트에 배포
- `app-ads.txt`에는 AdMob의 personalized code snippet 또는 `google.com, pub-..., DIRECT` 형식의 publisher ID가 포함되어야 한다.
- Play Store 앱 등록 후 AdMob 앱 검증과 app readiness review 진행
- AdMob은 앱이 지원 스토어에 게시/등록되고 AdMob에서 해당 스토어와 연결되어야 전체 광고 서빙 리뷰가 시작된다.

### 4. Google Play Store

- Google Play Console 개발자 계정 등록
- 개발자 등록비는 공식 안내 기준 US$25 one-time registration fee이다.
- 계정 유형 선택: 개인 또는 조직
- 이 앱은 투자/주식 데이터를 다루므로 Play Console 계정 유형과 스토어 문구를 신중히 정한다. Google Play는 금융 상품/서비스를 제공하는 경우 조직 계정 선택을 안내한다.
- 신원/연락처 정보 검증
- 결제 수단으로 개발자 등록비 결제
- 앱 패키지명 확정
- 앱 이름, 설명, 아이콘, 스크린샷, 개인정보처리방침 URL 준비
- 데이터 보안 섹션, 광고 포함 여부, 콘텐츠 등급, 타겟 연령, 금융 관련 고지 확인
- 개인 개발자 계정으로 시작하면 Google Play의 개인 계정 테스트/기기 검증 요구사항도 확인한다.
- 내부 테스트 트랙에 AAB 업로드
- 실제 기기에서 광고, 데이터 로드, 포트폴리오, 전략 저장, 알림 흐름 검증
- 현재 Android `applicationId`는 `com.round1studio.strategyworkbench`로 정리했다. Play 업로드 전 이 패키지명을 최종 확정해야 하며, 한 번 Play에 등록하면 바꾸기 어렵다.

## Codex-Owned Follow-Up Tasks

- Release Blocker 1 - 출시용 데이터 소스 정리
- [x] release/profile 빌드에서 `KOR_INVESTMENT_*` 직접 호출을 차단한다.
- [x] release/profile 앱 번들에 개인 `.env` 파일이 그대로 포함되지 않도록 출시용 env asset을 분리한다.
- [ ] KIS는 개인 debug 테스트 전용으로 유지하고, 출시용 한국 시세는 KRX/DART 또는 서버/상용 데이터 소스로 대체한다. 현재 release 테스트 APK는 Naver quote fallback으로 임시 보완한다.
- [x] `flutter analyze`와 KIS runtime guard 관련 테스트로 release 안전장치를 검증한다.
- 운영용 런타임 값은 `--dart-define`/CI secret으로 주입하고 debug/profile/release별 동작을 확인한다.
- Android AdMob App ID는 `AndroidManifest.xml` 하드코딩이 아니라 Gradle manifest placeholder로 주입된다.
- debug 빌드는 Google 테스트 광고 ID를 강제하고, profile/release 빌드는 `--dart-define`/CI secret의 실제 AdMob ID를 사용한다. Android manifest placeholder는 Gradle이 로컬 `.env` 또는 환경변수에서 읽을 수 있지만, 이 파일은 앱 asset으로 포함하지 않는다.
- [x] Android release build/AAB 생성 경로 정리
- 2026-06-26 기준 프로젝트 로컬 Android SDK에 `cmdline-tools/latest`를 설치해 native debug symbol strip 검증 실패를 해결했다.
- 2026-06-26 기준 `flutter build appbundle --release --no-tree-shake-icons` 성공. 산출물: `build/app/outputs/bundle/release/app-release.aab` (57.5MB).
- release AAB 및 `build` 산출물에서 `.env` 파일과 `KOR_INVESTMENT_*`/주요 API 키 식별자가 잡히지 않음을 확인했다.
- 2026-06-29 기준 출시 전 실기기 확인용 `flutter build apk --release --no-tree-shake-icons` 성공. 광고는 `FORCE_ADMOB_TEST_IDS=true`만 주입하고, 시세는 키 없는 Naver quote fallback을 사용한다.
- 2026-06-29 기준 release APK를 `17aca220` 기기의 `/sdcard/Download/strategy_workbench_release.apk`에 복사했다. ADB 설치는 MIUI/기기 정책의 `INSTALL_FAILED_USER_RESTRICTED`로 막혀 수동 설치 확인이 필요하다.
- 2026-06-29 기준 KRX 키가 없는 release 테스트에서도 한국 종목 현재가/종목명을 확인할 수 있도록 Naver quote fallback을 추가했다. 기존 mock 캐시를 피하기 위해 주식 캐시/스냅샷 캐시 버전을 갱신했다.
- 2026-06-29 기준 `089030`은 `테크윙`, `486450`은 `SOL 미국AI전력인프라`로 표시되도록 종목명 매핑과 포트폴리오 live 가격 보강을 반영했다.
- 2026-06-29 기준 수정 후 `flutter test test/portfolio_providers_test.dart test/stock_detail_providers_test.dart test/hybrid_stock_repository_test.dart test/phase6_ui_test.dart`, `flutter analyze`, `flutter build apk --release --no-tree-shake-icons` 통과. clean release APK에는 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 확인했고, 새 APK를 `/sdcard/Download/strategy_workbench_release.apk`에 다시 복사했다.
- 2026-06-29 기준 Yahoo가 429로 실패하는 환경에서 미국 종목이 mock 가격으로 떨어지는 문제가 확인되어 Nasdaq quote fallback을 추가했다. `GOOGL` 등 미국 종목은 Finnhub/FMP/Yahoo 실패 시 Nasdaq 공개 quote 현재가를 사용한다.
- 2026-06-29 기준 Nasdaq fallback 반영 후 `flutter test test/hybrid_stock_repository_test.dart test/portfolio_providers_test.dart test/stock_detail_providers_test.dart test/phase6_ui_test.dart`, `flutter analyze`, `flutter build apk --release --no-tree-shake-icons --dart-define=FORCE_ADMOB_TEST_IDS=true` 통과. clean release APK에는 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 확인했고, 새 APK를 `/sdcard/Download/strategy_workbench_release.apk`에 다시 복사했다.
- [x] Android 패키지명을 `com.round1studio.strategyworkbench`로 정리
- 2026-06-29 기준 패키지명 변경 후 `flutter analyze`, `flutter build apk --release --no-tree-shake-icons --dart-define=FORCE_ADMOB_TEST_IDS=true`, `aapt dump badging` 검증을 통과했다. APK package는 `com.round1studio.strategyworkbench`, label은 `Strategy Workbench`로 확인했다.
- [ ] Play Console 업로드 전 Android 패키지명 최종 확정
- [x] Play upload key 생성 및 `android/key.properties` 기반 release signing 적용
- 2026-06-29 기준 `android/app/upload-keystore.jks`와 `android/key.properties`를 로컬 생성했다. 둘 다 Git ignore 대상이며, `android/key.properties.example`만 커밋 대상으로 둔다.
- 2026-06-29 기준 `flutter build appbundle --release --no-tree-shake-icons --dart-define=FORCE_ADMOB_TEST_IDS=true`로 내부 테스트용 AAB 생성에 성공했다. 산출물: `build/app/outputs/bundle/release/app-release.aab` (약 57.5MB).
- 2026-06-29 기준 `jarsigner -verify`로 AAB 서명을 확인했고, 서명 주체는 `CN=Strategy Workbench, OU=Round1Studio, O=Round1Studio, L=Seoul, ST=Seoul, C=KR`이다. AAB 안에 `.env` 파일과 운영/개인 API 키 값이 포함되지 않음을 확인했다.
- [ ] `android/app/upload-keystore.jks`와 `android/key.properties`를 안전한 외부 저장소에 백업
- [ ] 내부 테스트 업로드 후 Play App Signing/업로드 키 상태 확인
- [x] Android 런처 아이콘 생성 및 기본 Flutter 아이콘 교체
- 2026-06-29 기준 `mipmap-mdpi`부터 `mipmap-xxxhdpi`까지 Android launcher icon을 교체했고, Play 등록용 512px 아이콘 `assets/store/icon_512.png`를 생성했다.
- 2026-06-29 기준 아이콘 반영을 위해 `pubspec.yaml` 버전을 `1.0.0+2`로 올렸고, 내부 테스트용 AAB를 다시 빌드했다. 산출물은 동일 경로 `build/app/outputs/bundle/release/app-release.aab`이며, packaged manifest 기준 `versionCode=2`, `versionName=1.0.0`을 확인했다.
- 2026-07-06 기준 포트폴리오 금액 가독성 개선 후 `pubspec.yaml` 버전을 `1.0.0+3`으로 올렸고, 내부 테스트용 AAB/APK를 다시 빌드했다. 산출물은 `build/app/outputs/bundle/release/app-release.aab`와 `build/app/outputs/flutter-apk/app-release.apk`이며, 테스트 광고 ID 강제 설정을 포함한다.
- 2026-07-06 기준 정식 광고 확인용 `1.0.0+4` AAB 빌드 성공. 산출물: `build/app/outputs/bundle/release/app-release.aab` (약 57.6MB). 이 빌드는 내부/비공개 테스트에서 실제 광고 서빙 상태를 확인하기 위한 후보이며, AdMob/Play 검토 상태에 따라 실제 광고 노출까지 시간이 걸릴 수 있다.
- [x] Play Console 기본 스토어 등록정보 초안 작성
- 2026-06-30 기준 `PLAY_STORE_LISTING_KO.md`에 앱 이름, 짧은 설명, 전체 설명, 출시 노트, 스크린샷 준비 목록, 금융/광고/데이터 고지 문구를 정리했다.
- 2026-06-30 기준 `PRIVACY_POLICY_DRAFT_KO.md`에 개인정보처리방침 초안을 작성했다. 실제 게시 전 운영자 연락처와 공개 URL을 확정해야 한다.
- 2026-06-30 기준 Play 등록용 피처 그래픽 `assets/store/feature_graphic_1024x500.png`를 생성했다.
- 2026-07-03 기준 Play 피처 그래픽의 pill 텍스트 overflow와 오른쪽 카드 문구 겹침을 수정했다. 재생성 스크립트는 `tool/generate_store_feature_graphic.ps1`에 둔다.
- 2026-07-03 기준 GitHub Pages 게시용 개인정보처리방침 `docs/privacy-policy.md`와 안내 페이지 `docs/index.md`를 추가했다. Pages URL은 보통 `https://darren83kim.github.io/StrategyWorkbench/privacy-policy/`이다.
- [ ] Play Console 스토어 등록정보에 `assets/store/icon_512.png` 업로드
- [ ] Play Console 스토어 등록정보에 `assets/store/feature_graphic_1024x500.png` 업로드
- [ ] Play Console 스토어 등록정보에 스크린샷 업로드
- [ ] GitHub Pages를 활성화한 뒤 개인정보처리방침 URL을 Play Console에 입력
- [ ] Gradle 8.14+, Android Gradle Plugin 8.11.1+, Kotlin 2.2.20+ 업그레이드 경고 정리
- 앱 아이콘/스플래시 최종 정리
- 개인정보처리방침에 API/광고/로컬 저장/알림 내용을 반영할 초안 작성
- WorkManager 알림 실제 디바이스 end-to-end 검증
- AdMob 실제 ID 적용 후 테스트 광고 ID가 릴리즈에 남지 않았는지 확인
- Phase 6 거래 저널/메모, 전략 비교 고도화 설계 및 구현
- 출시 전 KIS 운영 정책 확정: `KOR_INVESTMENT_*`를 release/profile 앱 번들에서 제거하거나, 서버 프록시/정식 제휴 API 구조로 전환한다.
- 출시 전 가격 데이터 소스 정책 확정: 공개/상용 시세 API(KRX/FMP/Finnhub 등)와 캐시 정책을 정하고, KIS는 개인 테스트 전용으로 분리한다. Naver/Nasdaq fallback은 테스트 안정화용으로 두되 운영 약관/한도 리스크를 검토한다.

## Reference Links

- Google Play Console 시작: https://support.google.com/googleplay/android-developer/answer/6112435
- Play Console 계정 생성 필요 정보: https://support.google.com/googleplay/android-developer/answer/13628312
- AdMob App ID / ad unit ID 찾기: https://support.google.com/admob/answer/7356431
- AdMob app-ads.txt 검증: https://support.google.com/admob/answer/14538460
- AdMob app-ads.txt 설정: https://support.google.com/admob/answer/9363762
- 공공데이터포털 이용가이드: https://www.data.go.kr/ugs/selectPublicDataUseGuideView.do
- OpenDART 개발가이드: https://opendart.fss.or.kr/guide/detail.do?apiGrpCd=DS001&apiId=2019001
- FMP pricing: https://site.financialmodelingprep.com/pricing-plans
- KIS Developers: https://apiportal.koreainvestment.com/
