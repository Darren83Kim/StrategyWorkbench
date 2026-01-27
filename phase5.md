## **📄 phase5.md: Ads Optimization & Final Fail-safe**

### **1\. 개요 및 설계 원칙**

* **수익화:** AdMob 연동.  
* **User Experience:** 광고가 앱 사용을 방해하거나 멈추게 하지 않는 'Fail-safe' 로직 적용.

### **2\. 세부 수행 작업 (Detailed Tasks)**

1. **AdMob SDK 설정:** 안드로이드 AndroidManifest.xml과 iOS Info.plist에 App ID 등록 및 SDK 초기화.  
2. **배너 광고 위젯:** 화면 하단에 고정되는 BannerAdWidget 구현.  
3. **전면 광고(Interstitial Ad) 시스템:**  
   * 사용자가 '전략 저장' 버튼을 누를 때 광고를 로드하고 보여주는 함수 작성.  
   * **Fail-safe 로직(중요):** 광고 로드 함수에 timeout을 걸거나 onAdFailedToLoad 리스너를 사용하여, **광고 로드에 실패하면 유저를 기다리게 하지 않고 즉시 다음 화면(저장 완료 화면)으로 이동.**  
4. **빈도 제한(Frequency Cap):** SharedPreferences 등을 활용해 전면 광고 노출 후 1시간 내에는 다시 광고가 뜨지 않게 제어.  
5. **최종 배포 설정:** 앱 아이콘(Launcher Icon) 설정 및 스플래시 화면(Native Splash) 구성.

### **3\. 검증 및 디버깅 (Verification & Debugging)**

* **광고 실패 시뮬레이션:** **비행기 모드(네트워크 차단)** 상태에서 전략 저장 버튼을 눌렀을 때, 앱이 멈추지 않고 0.5초 내에 다음 단계로 넘어가는지 확인.  
* **테스트 ID 확인:** 개발용 빌드에서 반드시 구글 제공 **테스트 전용 광고 ID**가 사용되고 있는지 재확인.  
* **전체 유저 시나리오 테스트:** 앱 설치 \-\> Mock 데이터 로드 \-\> 필터 생성 \-\> 전략 저장(광고 확인) \-\> 알림 수신까지의 전 과정을 에러 없이 수행 가능한지 최종 보고.