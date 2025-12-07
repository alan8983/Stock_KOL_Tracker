# Stock KOL Tracker - Project Master Plan

這份文件是 `Stock_KOL_Tracker` 專案的唯一真理來源 (Single Source of Truth)，所有的開發 Agent 請務必遵守此處定義的架構與規範。

## 1. 專案概述 (Overview)
本專案為一個本地部署的行動應用程式 (iOS/Android)，旨在協助投資者記錄網紅 (KOL) 的投資觀點，並透過股價回測驗證其準確度 (勝率)。

### 技術堆疊 (Tech Stack)
*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod (with Code Generation annotations preferred)
*   **Local Database**: Drift (SQLite abstraction)
*   **Network Client**: Dio
*   **Charts**: fl_chart or candlesticks
*   **Environment Variables**: flutter_dotenv

### 外部服務 (External Services)
*   **Market Data**: Alpha Vantage API
    *   用途：取得個股歷史股價 (Daily/Intraday)。
    *   Key Management: `.env` 檔案中 `ALPHA_VANTAGE_KEY`。
*   **LLM Intelligence**: Google Gemini API
    *   用途：分析輸入文本的情緒 (Sentiment) 與提及的標的 (Ticker)。
    *   Key Management: `.env` 檔案中 `GEMINI_API_KEY`。
    *   SDK: `google_generative_ai`

---

## 2. 資料庫架構 (Drift Schema)

請在 `lib/data/database/database.dart` (或相應路徑) 實作以下 Tables。

### Table 1: KOLs
| Column | Type | Description |
| :--- | :--- | :--- |
| id | Int (AutoIncrement) | Primary Key |
| name | Text | KOL 名稱 |
| bio | Text (Nullable) | 簡介 |
| socialLink | Text (Nullable) | 主要社群連結 |
| createdAt | DateTime | 建立時間 |

### Table 2: Stocks
| Column | Type | Description |
| :--- | :--- | :--- |
| ticker | Text | Primary Key (e.g., "AAPL", "TSLA") |
| name | Text (Nullable) | 公司名稱 |
| exchange | Text (Nullable) | 交易所 (e.g., "NASDAQ") |
| lastUpdated | DateTime | 最後更新時間 |

### Table 3: Posts (草稿/文檔)
| Column | Type | Description |
| :--- | :--- | :--- |
| id | Int (AutoIncrement) | Primary Key |
| kolId | Int | Foreign Key -> KOLs.id |
| stockTicker | Text | Foreign Key -> Stocks.ticker |
| content | Text | 原始文本內容 |
| sentiment | Text | "Bullish" (看多), "Bearish" (看空), "Neutral" (中立) |
| postedAt | DateTime | KOL 發文時間 |
| createdAt | DateTime | 建檔時間 |
| status | Text | "Draft" (草稿), "Published" (已確認) |

### Table 4: StockPrices (歷史股價快取)
| Column | Type | Description |
| :--- | :--- | :--- |
| id | Int (AutoIncrement) | Primary Key |
| ticker | Text | Foreign Key -> Stocks.ticker |
| date | DateTime | 股價日期 |
| open | Real | 開盤價 |
| close | Real | 收盤價 |
| high | Real | 最高價 |
| low | Real | 最低價 |
| volume | Int | 交易量 |

---

## 3. 開發階段與任務 (Development Roadmap)

### Phase 1: Foundation (地基建設)
1.  **Project Init**: 執行 `flutter create .` 初始化專案。
2.  **Dependencies**: 安裝 `flutter_riverpod`, `riverpod_annotation`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`, `dio`, `google_generative_ai`, `flutter_dotenv`.
3.  **Dev Dependencies**: 安裝 `build_runner`, `riverpod_generator`, `drift_dev`.
4.  **Database Setup**: 建立 Drift 資料庫連線與 Table 定義。

### Phase 2: Infrastructure (核心服務)
1.  **AlphaVantageService**:
    *   實作 `fetchDailyPrices(String ticker)`。
    *   實作快取機制：先查 DB，若無資料或過期才打 API。
2.  **GeminiService**:
    *   實作 `analyzeText(String text)`。
    *   Prompt 設計：「你是一個金融分析助手，請分析以下文字的情緒 (Bullish/Bearish/Neutral) 並提取美股代號 (Ticker)。請以 JSON 格式回傳...」

### Phase 3: Input Flow (輸入功能)
1.  **Draft Page**: 簡單的 Text Field 供貼上文字。
2.  **Auto-Fill Logic**: 呼叫 `GeminiService` 填入 Ticker 與 Sentiment。
3.  **Review UI**: 讓使用者修正 Ticker 與 Sentiment，並選擇關聯的 KOL。
4.  **Save**: 寫入 `Posts` Table。

### Phase 4: Output Flow (分析與檢視)
1.  **KOL List**: 顯示所有 KOL 與其勝率摘要。
2.  **Stock Chart**: 使用 `fl_chart` 繪製 K 線圖。
3.  **Marker**: 在 K 線圖對應 `postedAt` 的時間點上，畫出 Buy (Bullish) 或 Sell (Bearish) 的標記。
4.  **Backtest**: 計算該時間點後 5日、30日、90日的股價變化百分比。

### Phase 5: Refinement (優化)
1.  Error Handling (API 失敗處理)。
2.  UI 美化。

---

## 4. 檔案結構建議 (Directory Structure)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/ (Env, Constants)
│   ├── network/ (Dio client)
│   └── utils/
├── data/
│   ├── database/ (Drift DB)
│   ├── models/
│   ├── repositories/
│   └── services/ (AlphaVantage, Gemini)
├── domain/
│   └── providers/ (Riverpod Providers)
└── presentation/
    ├── screens/
    │   ├── home/
    │   ├── input/
    │   └── kol_detail/
    └── widgets/
```

