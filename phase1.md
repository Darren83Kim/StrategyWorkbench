## **📄 phase1.md: Foundation & Glassmorphism Architecture**

### **1\. 목표 및 설계 원칙**

* **Architecture:** Feature-based Clean Architecture (기능별 계층 분리).  
* **Design:** Dark Mode 기반 Glassmorphism. BackdropFilter를 이용한 실시간 배경 블러링 구현.  
* **Color Palette:** Background(\#0F172A), Card/Glass(\#1E293B, 60% Opacity), Point(\#10B981, \#EF4444).

### **2\. 세부 수행 작업 (Detailed Tasks)**

1. **프로젝트 초기화:** flutter create 실행 후 pubspec.yaml에 flutter\_riverpod, dio, hive\_flutter, sqflite, fl\_chart, flutter\_animate, intl, google\_mobile\_ads, flutter\_local\_notifications, workmanager 추가.  
   * (추가 제안) 네비게이션 관리를 위한 **go_router**, 디버깅을 위한 **logger** 패키지 추가.
2. **디렉토리 물리 구조 생성:**  
   * lib/core/theme, lib/core/network, lib/core/constants, **lib/core/router** 생성.  
   * lib/features/ 하위에 dashboard, strategy, portfolio, market 폴더 생성 및 각 폴더 내 data, domain, presentation 하위 폴더 생성.  
   * lib/shared/widgets 생성.  
3. **테마 설정:** core/theme/app\_theme.dart에 다크모드 ThemeData 정의 (Scaffold 배경색 \#0F172A 설정).  
4. **GlassContainer 구현:** shared/widgets/glass\_container.dart에 ClipRRect \-\> BackdropFilter(sigma: 15\) \-\> Container(color: Colors.white.withOpacity(0.1)) 순서로 겹친 공통 위젯 구현.  
5. **디버깅 전용 화면 구축:** lib/main.dart를 수정하여 DebugScreen을 시작 화면으로 설정.

### **3\. 검증 및 디버깅 (Verification & Debugging)**

* **패키지 무결성 검사:** flutter pub get 실행 후 모든 의존성 충돌 여부 확인.  
* **시각적 디버깅(중요):** DebugScreen 배경에 **빨강, 노랑, 파랑색의 큰 원(Circle)들이 움직이는 애니메이션**을 넣고, 그 위에 GlassContainer를 배치하여 배경색이 세련되게 뭉개지는지(Blur) 눈으로 확인 후 보고할 것.  
* **렌더링 성능 체크:** 블러 효과 적용 시 프레임 드랍(Jank)이 발생하는지 디버그 콘솔 확인.