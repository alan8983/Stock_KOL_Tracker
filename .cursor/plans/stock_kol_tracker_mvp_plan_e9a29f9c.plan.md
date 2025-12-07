---
name: Stock_KOL_Tracker_MVP_Plan
overview: 建立詳細的專案執行計畫文檔 (PROJECT_MASTER_PLAN.md)，定義 Flutter 架構、資料庫 Schema、以及整合 Gemini 和 Alpha Vantage 的具體步驟，作為開發團隊的唯一依據。
todos:
  - id: create_master_plan
    content: 撰寫並建立 PROJECT_MASTER_PLAN.md
    status: completed
  - id: init_project
    content: 依據 Master Plan 初始化 Flutter 專案結構
    status: completed
    dependencies:
      - create_master_plan
---

# Stock KOL Tracker MVP 專案執行計畫

作為 TPM，我將建立一份名為 `PROJECT_MASTER_PLAN.md` 的核心文檔，將整個開發流程標準化與模組化。

## 1. 產出核心文檔 `PROJECT_MASTER_PLAN.md`

此檔案將包含以下章節，供後續 Agent 調用：

### A. 技術架構規範 (Tech Stack)

-   **Framework**: Flutter (支援 iOS/Android)
-   **State Management**: Riverpod (推薦) 或 Provider
-   **Local Database**: Drift (基於 SQLite，強型別，適合複雜查詢)
-   **Network**: Dio (處理 API 請求與攔截器)
-   **External Services**:
    -   **Market Data**: Alpha Vantage API (Env var: `ALPHA_VANTAGE_KEY`)
    -   **LLM**: Google Gemini (Env var: `GEMINI_API_KEY`) via `google_generative_ai` SDK

### B. 資料庫設計 (Schema Design)

定義三個核心 Table：

1.  **KOLs**: 儲存網紅基本資料 (Name, Social Links)。
2.  **Stocks**: 儲存關注的個股 (Ticker, Exchange)。
3.  **Posts**: 儲存觀點文章 (Content, Sentiment, Timestamp, Linked KOL, Linked Ticker)。
4.  **StockPrices**: 儲存快取的歷史股價 (Ticker, Date, ClosePrice)，用於回測與畫圖。

### C. 開發階段與任務清單 (Phased Roadmap)

將 User Story 轉化為具體的 Dev Tasks：

-   **Phase 1: Foundation (地基)**
    -   專案初始化 (Flutter create)。
    -   設定環境變數 (.env) 管理 API Keys。
    -   建立 Drift Database 與 Tables。
-   **Phase 2: Infrastructure (管線)**
    -   實作 `AlphaVantageService`：包含 Fetch & Cache 機制 (避免頻繁打 API)。
    -   實作 `GeminiService`：Prompt Engineering (輸入文字 -> 輸出 JSON: {sentiment, ticker, summary})。
-   **Phase 3: Core Feature - Input (輸入流)**
    -   UI: 草稿輸入介面 (Paste text)。
    -   Logic: 呼叫 Gemini 自動填入 Ticker 與 Sentiment。
    -   UI: 確認與儲存 (Save to DB)。
-   **Phase 4: Core Feature - Analysis & UI (輸出流)**
    -   UI: KOL 列表與詳情頁。
    -   UI: K 線圖整合 (使用 `fl_chart` 或 `candlesticks` 套件)。
    -   Logic: 計算 5/30/90 日後漲跌幅 (Win Rate)。
-   **Phase 5: Refinement**
    -   UI 優化與錯誤處理。

## 2. 執行方式

確認計畫後，我將：

1.  建立 `PROJECT_MASTER_PLAN.md` 檔案。
2.  將上述詳細內容寫入該檔案。
3.  該檔案將作為後續所有 Agent 的 "Single Source of Truth"。