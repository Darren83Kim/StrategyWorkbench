## **📄 phase2.md: Hybrid Data Layer & Mock-First Logic**

### **1\. 목표 및 설계 원칙**

* **Hybrid Storage:** 고속 시세 캐싱(Hive) \+ 거래 이력 영구 저장(SQLite).  
* **Mock-First:** 실제 API 호출 전, 가짜 데이터를 통해 비즈니스 로직의 완결성을 100% 검증함.

### **2\. 세부 수행 작업 (Detailed Tasks)**

1. **데이터 모델 설계:**  
   * Stock: ticker, name, price, per, roe, dividendYield, lastUpdated 필드 포함.  
   * Transaction: id, ticker, type(BUY/SELL), price, quantity, dateTime 필드 포함.  
2. **데이터베이스 초기화:**  
   * HiveService: 주식 시세 저장용 Box(stock\_cache) 및 마지막 갱신일 저장용 Box(settings) 초기화.  
   * DatabaseHelper: SQLite 테이블(transactions) 생성 (Auto-increment ID, Foreign Key 고려).  
3. **MockStockRepository 구현:** StockRepository 인터페이스를 만들고, 이를 상속받은 MockStockRepository를 구현. 삼성전자, SK하이닉스, 애플, 테슬라 등 5개 이상의 샘플 데이터를 리턴하도록 설정.  
4. **평단가 계산 엔진 구현:** PortfolioService 내에 새로운 매수 발생 시 (기존수량\*기존평단 \+ 신규수량\*신규단가) / 전체수량을 계산하는 함수 작성.  
5. **자동 갱신 로직:** 앱 실행 시 settings Box의 last\_update\_date를 읽어와 현재 날짜와 다를 경우 MockStockRepository에서 데이터를 새로 가져오고 날짜를 업데이트하는 로직 구현.

### **3\. 검증 및 디버깅 (Verification & Debugging)**

* **날짜 조작 테스트:** 현재 날짜를 강제로 **내일 날짜**로 시뮬레이션하여 자동 갱신 로직이 로그를 찍으며 트리거되는지 확인.  
* **계산기 유닛 테스트:** PortfolioService에 (10주, 100,000원) 보유 중 (5주, 130,000원) 추가 매수 시 평단가가 정확히 110,000원이 되는지 유닛 테스트 코드로 검증.  
* **로컬 DB 확인:** 실제 데이터가 Hive와 SQLite에 물리적으로 저장되는지 로그로 확인.