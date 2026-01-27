# API 명세서 (API Specifications)

이 문서는 `Strategy Workbench` 프로젝트에서 사용하는 외부 API의 상세 명세를 정의합니다.

---

## 1. Yahoo Finance API (미국 주식 시세)

- **제공자:** Yahoo
- **인증 방식:** 없음 (공개 API, RapidAPI 등을 통한 구독 기반 Key 사용 가능)
- **주요 특징:** 비교적 간단하며, 별도 인증 없이 기본적인 시세 정보를 가져오기 용이합니다. 단, 비공식 API이므로 안정성 및 속도 제한에 유의해야 합니다.

### **엔드포인트: 종목 검색 (Search)**
- **URL:** `https://query1.finance.yahoo.com/v1/finance/search`
- **HTTP Method:** `GET`
- **파라미터:**
  - `q`: 검색할 종목명 또는 티커 (예: `AAPL`)
- **샘플 응답 (JSON):**
```json
{
  "quotes": [
    {
      "exchange": "NMS",
      "shortname": "Apple Inc.",
      "quoteType": "EQUITY",
      "symbol": "AAPL",
      "longname": "Apple Inc.",
      "isYahooFinance": true
    }
  ]
}
```

### **엔드포인트: 종목 요약 (Quote Summary)**
- **URL:** `https://query1.finance.yahoo.com/v10/finance/quoteSummary/{symbol}`
- **HTTP Method:** `GET`
- **파라미터:**
  - `modules`: 가져올 데이터 모듈 (예: `price`, `summaryDetail`, `defaultKeyStatistics`)
- **샘플 URL:** `https://query1.finance.yahoo.com/v10/finance/quoteSummary/AAPL?modules=price,summaryDetail`
- **샘플 응답 (JSON):**
```json
{
  "quoteSummary": {
    "result": [
      {
        "price": {
          "regularMarketPrice": { "raw": 195.89, "fmt": "195.89" },
          "regularMarketChangePercent": { "raw": -0.003, "fmt": "-0.30%" },
          "marketCap": { "raw": 3001834184704, "fmt": "3.00T" }
        },
        "summaryDetail": {
          "dividendYield": { "raw": 0.005, "fmt": "0.50%" },
          "trailingPE": { "raw": 32.6483, "fmt": "32.65" },
          "forwardPE": { "raw": 29.89, "fmt": "29.89" }
        }
      }
    ]
  }
}
```

---

## 2. 한국투자증권 API (국내 주식 시세)

- **제공자:** 한국투자증권 (KIS)
- **인증 방식:** `OAuth 2.0` 기반 **API Key 및 Access Token**
- **주요 특징:** 국내 주식에 대한 신뢰성 높은 실시간 데이터를 제공합니다. API 사용을 위해 사전 신청 및 키 발급이 필수입니다.
- **문서:** [한국투자증권 API 공식 문서](https://apiportal.koreainvestment.com/)

### **엔드포인트: 접속 토큰 발급 (Authentication)**
- **URL:** `https://openapi.koreainvestment.com:9443/oauth2/tokenP`
- **HTTP Method:** `POST`
- **헤더:**
  - `Content-Type`: `application/json`
- **바디 (Body):**
```json
{
  "grant_type": "client_credentials",
  "appkey": "YOUR_APP_KEY",
  "appsecret": "YOUR_APP_SECRET"
}
```
- **샘플 응답 (JSON):**
```json
{
  "access_token": "ACCESS_TOKEN_VALUE",
  "token_type": "Bearer",
  "expires_in": 86400
}
```

### **엔드포인트: 주식 현재가 시세 (Quote)**
- **URL:** `https://openapi.koreainvestment.com:9443/uapi/domestic-stock/v1/quotations/inquire-price`
- **HTTP Method:** `GET`
- **헤더:**
  - `Content-Type`: `application/json`
  - `Authorization`: `Bearer {ACCESS_TOKEN}`
  - `appkey`: `YOUR_APP_KEY`
  - `appsecret`: `YOUR_APP_SECRET`
  - `tr_id`: `FHKST01010100` (주식현재가)
- **파라미터:**
  - `fid_cond_mrkt_div_code`: `J` (주식)
  - `fid_input_iscd`: `005930` (삼성전자 종목코드)
- **샘플 응답 (JSON):**
```json
{
  "output": {
    "stck_prpr": "75000",  // 주식 현재가
    "prdy_vrss_sign": "2", // 전일 대비 부호
    "stck_oprc": "74800",  // 시가
    "stck_hgpr": "75500",  // 고가
    "stck_lwpr": "74700",  // 저가
    "per": "15.20",        // PER
    "pbr": "1.80"          // PBR
  },
  "msg_cd": "MRCR0001",
  "msg1": "정상처리 되었습니다."
}
```

---

## 3. Alpha Vantage API (미국 주식 시세 대안)

- **제공자:** Alpha Vantage
- **인증 방식:** **API Key**
- **주요 특징:** 다양한 기술적 지표와 과거 데이터를 제공하며, 무료 플랜은 호출 한도(예: 분당 5회, 하루 500회)가 엄격합니다.
- **문서:** [Alpha Vantage 공식 문서](https://www.alphavantage.co/documentation/)

### **엔드포인트: 일별 시세 (Time Series Daily)**
- **URL:** `https://www.alphavantage.co/query`
- **HTTP Method:** `GET`
- **파라미터:**
  - `function`: `TIME_SERIES_DAILY`
  - `symbol`: `IBM`
  - `apikey`: `YOUR_ALPHA_VANTAGE_API_KEY`
- **샘플 응답 (JSON):**
```json
{
    "Meta Data": {
        "1. Information": "Daily Prices (open, high, low, close) and Volumes",
        "2. Symbol": "IBM",
        "3. Last Refreshed": "2024-05-28",
        "4. Output Size": "Compact",
        "5. Time Zone": "US/Eastern"
    },
    "Time Series (Daily)": {
        "2024-05-28": {
            "1. open": "167.38",
            "2. high": "168.32",
            "3. low": "166.41",
            "4. close": "167.92",
            "5. volume": "3498900"
        },
        "2024-05-27": {
            "1. open": "168.15",
            "2. high": "169.10",
            "3. low": "167.85",
            "4. close": "168.99",
            "5. volume": "2987600"
        }
    }
}
```

---
