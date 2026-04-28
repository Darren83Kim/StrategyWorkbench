## 📄 phase1.md: Foundation & App Shell

현재 구현 상태는 `IMPLEMENTATION_STATUS.md`에서 관리합니다.

### 1. 목표 및 설계 원칙

- **Goal:** 실제 서비스 화면을 띄울 수 있는 앱 셸, 라우팅, 공통 테마, 디버그 보조 진입점을 만든다.
- **Design:** Dark Mode 기반 Glassmorphism을 공통 위젯과 테마로 정리한다.
- **Correction:** DebugScreen은 개발용 검증 화면이며, 프로덕션 시작 화면은 대시보드 기준으로 잡는다.

### 2. 세부 수행 작업

1. Flutter 프로젝트와 공통 의존성을 정리한다.
   - `flutter_riverpod`, `dio`, `hive_flutter`, `sqflite`, `fl_chart`, `flutter_local_notifications`, `workmanager`, `go_router`, `shared_preferences`, `path_provider` 등을 포함한다.
   - 광고 SDK(`google_mobile_ads`)는 Phase 5에서 실제 연동 시점에 추가한다.
2. 기능 중심 디렉토리 구조를 만든다.
   - `lib/core`, `lib/features`, `lib/shared/widgets`를 기준으로 정리한다.
3. 다크 테마와 공용 GlassContainer를 구현한다.
4. `go_router` 기반 앱 셸과 루트 네비게이션을 구현한다.
   - `dashboard`, `strategy`, `portfolio`, `market/:symbol`, `debug` 라우트를 둔다.
5. 디버그 화면을 구현한다.
   - 스코어링, 백그라운드 태스크, API 상태 확인 등 개발 검증 기능을 모은다.

### 3. 검증 및 디버깅

- `flutter pub get` 및 기본 빌드가 실패하지 않아야 한다.
- 앱 시작 시 대시보드가 열리고, `/debug` 라우트로 개발 검증 화면에 진입할 수 있어야 한다.
- Glass blur가 실제 기기/에뮬레이터에서 시각적으로 깨지지 않아야 한다.
- 블러 적용 시 렌더링 문제가 있는지 로그와 체감 성능으로 확인한다.
