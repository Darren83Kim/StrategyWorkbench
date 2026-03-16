# API 명세서 (API Specifications)

이 문서는 `Strategy Workbench` 프로젝트에서 사용하는 외부 API의 상세 명세를 정의합니다.

> **2026-03-09 변경:** API 전략이 전면 재설계되었습니다. 상세 사유는 `Strategy Flow PRD.md`의 "API 전략 변경 이력" 섹션을 참조하세요.

---

## API 우선순위 요약

| 시장 | 1순위 | 2순위 | 폴백 |
|------|-------|-------|------|
| **미국** | Finnhub (60회/분) | FMP (250회/일) | Yahoo Finance (비공식) |
| **한국** | KRX Open API (10,000회/일) | DART OpenAPI (공공데이터) | 한국투자증권 (사용자 키) |

---

## 1. Finnhub API (미국 주식 - 1순위) ✅ 신규

- **제공자:** Finnhub
- **인증 방식:** API Key (무료 즉시 발급)
- **무료 한도:** 60 calls/minute
- **주요 특징:** 실시간 시세(15분 지연), 펀더멘탈(PER, ROE, 배당), 기업 프로필 제공. 가장 넉넉한 무료 한도.
- **문서:** [Finnhub 공식 문서](https://finnhub.io/docs/api)

### **엔드포인트: 실시간 시세 (Quote)**
- **URL:** `https://finnhub.io/api/v1/quote`
- **HTTP Method:** `GET`
- **파라미터:**
  - `symbol`: 티커 심볼 (예: `AAPL`)
  - `token`: API Key
- **샘플 URL:** `https://finnhub.io/api/v1/quote?symbol=AAPL&token=YOUR_API_KEY`
- **샘플 응답 (JSON):**
```json
{
  "c": 195.89,   // 현재가 (current price)
  "d": -0.58,    // 변동 (change)
  "dp": -0.2953, // 변동률 (percent change)
  "h": 197.00,   // 고가 (high)
  "l": 195.25,   // 저가 (low)
  "o": 196.50,   // 시가 (open)
  "pc": 196.47,  // 전일 종가 (previous close)
  "t": 1709913600 // 타임스탬프
}
```

### **엔드포인트: 기업 기본 재무 (Basic Financials)**
- **URL:** `https://finnhub.io/api/v1/stock/metric`
- **HTTP Method:** `GET`
- **파라미터:**
  - `symbol`: 티커 심볼 (예: `AAPL`)
  - `metric`: `all`
  - `token`: API Key
- **샘플 URL:** `https://finnhub.io/api/v1/stock/metric?symbol=AAPL&metric=all&token=YOUR_API_KEY`
- **샘플 응답 (JSON, 주요 필드만):**
```json
{
  "metric": {
    "peBasicExclExtraTTM": 32.65,      // PER (TTM)
    "roeTTM": 160.58,                   // ROE (TTM, %)
    "dividendYieldIndicatedAnnual": 0.50, // 배당수익률 (%)
    "psTTM": 8.73,                      // PSR
    "pbQuarterly": 50.12,               // PBR
    "currentRatioQuarterly": 1.07,      // 유동비율
    "52WeekHigh": 199.62,               // 52주 최고가
    "52WeekLow": 164.08                 // 52주 최저가
  },
  "symbol": "AAPL"
}
```

### **엔드포인트: 기업 프로필 (Company Profile)**
- **URL:** `https://finnhub.io/api/v1/stock/profile2`
- **HTTP Method:** `GET`
- **파라미터:**
  - `symbol`: 티커 심볼
  - `token`: API Key
- **샘플 응답 (JSON):**
```json
{
  "country": "US",
  "currency": "USD",
  "finnhubIndustry": "Technology",
  "ipo": "1980-12-12",
  "logo": "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png",
  "marketCapitalization": 3001834.18,
  "name": "Apple Inc",
  "ticker": "AAPL",
  "weburl": "https://www.apple.com/"
}
```

---

## 2. FMP - Financial Modeling Prep (미국 주식 - 2순위) ✅ 신규

- **제공자:** Financial Modeling Prep
- **인증 방식:** API Key (무료 발급)
- **무료 한도:** 250 calls/day
- **주요 특징:** 풍부한 재무비율, SEC EDGAR 데이터, 30년 이상 히스토리. Finnhub 보완용.
- **문서:** [FMP 공식 문서](https://site.financialmodelingprep.com/developer/docs)

### **엔드포인트: 기업 재무비율 (Financial Ratios TTM)**
- **URL:** `https://financialmodelingprep.com/api/v3/ratios-ttm/{symbol}`
- **HTTP Method:** `GET`
- **파라미터:**
  - `apikey`: API Key
- **샘플 URL:** `https://financialmodelingprep.com/api/v3/ratios-ttm/AAPL?apikey=YOUR_API_KEY`
- **샘플 응답 (JSON, 주요 필드만):**
```json
[
  {
    "peRatioTTM": 32.65,
    "returnOnEquityTTM": 1.6058,
    "dividendYielTTM": 0.005,
    "priceToBookRatioTTM": 50.12,
    "priceToSalesRatioTTM": 8.73,
    "debtEquityRatioTTM": 1.87
  }
]
```

---

## 3. KRX Open API (한국 주식 시세 - 1순위) ✅ 신규

- **제공자:** 한국거래소 (KRX)
- **인증 방식:** 무료 (공공데이터포털 API Key)
- **무료 한도:** 10,000회/일
- **주요 특징:** 한국거래소 공식 데이터. 상장종목 정보, 시세 제공. 비상업적 사용.
- **문서:** [KRX Data Marketplace](https://data.krx.co.kr/), [공공데이터포털](https://www.data.go.kr/data/15094808/openapi.do)

### **엔드포인트: 주식 시세 정보**
- **URL:** `https://apis.data.go.kr/1160100/service/GetStockSecuritiesInfoService/getStockPriceInfo`
- **HTTP Method:** `GET`
- **파라미터:**
  - `serviceKey`: 공공데이터포털 API Key (URL Encoding)
  - `numOfRows`: 결과 수 (예: `10`)
  - `pageNo`: 페이지 번호
  - `resultType`: `json`
  - `likeSrtnCd`: 종목 단축코드 (예: `005930`)
  - `beginBasDt`: 조회 시작일 (예: `20260301`)
- **샘플 응답 (JSON):**
```json
{
  "response": {
    "body": {
      "items": {
        "item": [
          {
            "basDt": "20260309",
            "srtnCd": "005930",
            "itmsNm": "삼성전자",
            "mrktCtg": "KOSPI",
            "clpr": "75000",
            "vs": "500",
            "fltRt": "0.67",
            "mkp": "74800",
            "hipr": "75500",
            "lopr": "74700",
            "trqu": "12345678",
            "trPrc": "925000000000",
            "mrktTotAmt": "447750000000000"
          }
        ]
      },
      "totalCount": 1
    }
  }
}
```

---

## 4. DART OpenAPI (한국 기업 재무제표 - 2순위) ✅ 신규

- **제공자:** 금융감독원 전자공시시스템 (DART)
- **인증 방식:** API Key (무료 발급)
- **무료 한도:** 넉넉 (공공데이터, 일 10,000회 수준)
- **주요 특징:** 상장기업 재무제표, 주요 재무비율(PER, ROE 등), 배당 정보 제공.
- **문서:** [DART OpenAPI 공식](https://opendart.fss.or.kr/)

### **엔드포인트: 단일회사 주요계정 (재무제표 요약)**
- **URL:** `https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json`
- **HTTP Method:** `GET`
- **파라미터:**
  - `crtfc_key`: API Key
  - `corp_code`: 기업 고유번호 (8자리, DART 코드)
  - `bsns_year`: 사업연도 (예: `2025`)
  - `reprt_code`: 보고서 코드 (`11011`=사업보고서, `11012`=반기, `11013`=1분기, `11014`=3분기)
  - `fs_div`: `OFS`(개별), `CFS`(연결)
- **샘플 응답 (JSON, 주요 필드만):**
```json
{
  "status": "000",
  "message": "정상",
  "list": [
    {
      "rcept_no": "20260315000123",
      "corp_code": "00126380",
      "corp_name": "삼성전자",
      "stock_code": "005930",
      "account_nm": "매출액",
      "thstrm_amount": "302,231,477,000,000",
      "frmtrm_amount": "258,935,022,000,000"
    },
    {
      "account_nm": "당기순이익",
      "thstrm_amount": "34,500,000,000,000"
    }
  ]
}
```

### **엔드포인트: 기업 고유번호 조회 (corp_code 매핑)**
- **URL:** `https://opendart.fss.or.kr/api/corpCode.xml`
- **HTTP Method:** `GET`
- **파라미터:**
  - `crtfc_key`: API Key
- **비고:** 전체 기업 고유번호 XML 파일을 zip으로 반환. 앱 초기화 시 1회 다운로드 후 로컬 캐시.

---

## 5. Yahoo Finance API (미국 주식 - 폴백) ⚠️ 비권장

> **⚠️ 2026-03-09 상태 변경: 1순위 → 폴백(비권장)**
> - 비공식 API로 언제든 차단 가능
> - 2024년 하반기부터 Rate Limit 강화 (yfinance 429 에러 빈발)
> - Finnhub, FMP 실패 시에만 최후 수단으로 사용

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

## 7. Alpha Vantage API (미국 주식) ❌ 폐기

> **❌ 2026-03-09 폐기 결정**
> - 무료 한도가 **하루 25회**로 대폭 축소 (과거 500→100→25)
> - 종목 5개 조회만으로 한도 소진, 서버 없는 클라이언트 앱에 부적합
> - Finnhub(60회/분) + FMP(250회/일)로 완전 대체

- **제공자:** Alpha Vantage
- **인증 방식:** API Key
- **무료 한도:** ~~500회/일~~ → ~~100회/일~~ → **25회/일** (2025년 기준)
- **문서:** [Alpha Vantage 공식 문서](https://www.alphavantage.co/documentation/)
- **코드 영향:** 기존 Alpha Vantage 호출 코드가 있다면 Finnhub으로 교체 필요

---
