# Stock KOL Tracker - Project Master Plan

這份文件是 `Stock_KOL_Tracker` 專案的唯一真理來源 (Single Source of Truth)，所有的開發 Agent 請務必遵守此處定義的架構與規範。

> **最後更新**: 2025-12-26  
> **版本**: v1.1

---

## 1. 專案概述 (Overview)
本專案為一個本地部署的行動應用程式 (iOS/Android/Web)，旨在協助投資者記錄網紅 (KOL) 的投資觀點，並透過股價回測驗證其準確度 (勝率)。

### 技術堆疊 (Tech Stack)
*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod (with Code Generation annotations preferred)
*   **Local Database**: Drift (SQLite abstraction)
*   **Network Client**: Dio
*   **Charts**: flutter_chen_kchart (K線圖套件)
*   **Environment Variables**: flutter_dotenv

### 外部服務 (External Services)
*   **Market Data**: Tiingo API
    *   用途：取得個股歷史股價 (Daily Adjusted)。
    *   Key Management: `.env` 檔案中 `TIINGO_API_TOKEN`。
*   **LLM Intelligence**: Google Gemini API
    *   用途：分析輸入文本的情緒 (Sentiment)、提及的標的 (Ticker)、KOL 名稱辨識、發文時間辨識、核心論述摘要、冗餘文字識別。
    *   Key Management: `.env` 檔案中 `GEMINI_API_KEY`。
    *   SDK: `google_generative_ai`
    *   Model: `gemini-2.5-flash`

---

## 2. 系統架構總覽 (System Architecture)

### 2.1 分層架構圖

```
┌────────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Screens (Pages)                                              │  │
│  │  ├─ HomeScreen (底部導覽容器)                                  │  │
│  │  ├─ QuickInputScreen / AnalysisResultScreen / DraftEditScreen │  │
│  │  ├─ KOLListScreen / KOLViewScreen                            │  │
│  │  ├─ StockListScreen / StockViewScreen                        │  │
│  │  ├─ PostDetailScreen / PostListScreen                        │  │
│  │  └─ MoreScreen / DiagnosticScreen                            │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │  Widgets                                                      │  │
│  │  ├─ StockChartWidget (K線圖主組件)                            │  │
│  │  ├─ KChartSentimentMarkersPainter (情緒標記繪製)              │  │
│  │  ├─ SentimentMarker / SentimentSelector                      │  │
│  │  ├─ TickerAutocompleteField / KOLSelector                    │  │
│  │  ├─ RelativeTimePicker / DateTimePickerField                 │  │
│  │  └─ PulsingBorderCard / ConfirmDialog / PostCard             │  │
│  └──────────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────────┤
│                       Domain Layer                                 │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Providers (Riverpod State Management)                        │  │
│  │  ├─ Service Providers: geminiServiceProvider, tiingoService   │  │
│  │  ├─ Repository Providers: postRepository, kolRepository, etc  │  │
│  │  ├─ State Providers: draftStateProvider, stockPriceProvider   │  │
│  │  └─ Computed Providers: priceChangeProvider, winRateProvider  │  │
│  └──────────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────────┤
│                        Data Layer                                  │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │   Services     │  │ Repositories │  │      Database          │  │
│  │ ├─ Gemini      │  │ ├─ Post      │  │   AppDatabase (Drift)  │  │
│  │ └─ Tiingo      │  │ ├─ KOL       │  │   ├─ KOLs              │  │
│  │                │  │ ├─ Stock     │  │   ├─ Stocks            │  │
│  │                │  │ ├─ StockPrice│  │   ├─ Posts             │  │
│  │                │  │ └─ Diagnostic│  │   └─ StockPrices       │  │
│  └────────────────┘  └──────────────┘  └────────────────────────┘  │
├────────────────────────────────────────────────────────────────────┤
│                        Core Layer                                  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Utils                                                        │  │
│  │  ├─ PriceChangeCalculator (漲跌幅計算)                        │  │
│  │  ├─ WinRateCalculator (勝率計算，門檻 ±2%)                    │  │
│  │  ├─ TimeParser (時間解析：相對/絕對)                          │  │
│  │  ├─ KOLMatcher (KOL 名稱模糊匹配)                             │  │
│  │  └─ DateTimeFormatter (日期格式化)                            │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. 關鍵模塊詳解 (Key Modules)

### 3.1 API Call 模塊

#### GeminiService (`lib/data/services/Gemini/gemini_service.dart`)
| 功能 | 說明 |
| :--- | :--- |
| `analyzeText(String text)` | 分析輸入文本，返回 `AnalysisResult` |
| **返回內容** | sentiment, tickers[], kolName, postedAtText, summary[], redundantText |
| **JSON 解析** | 支援 Markdown code block 解析、JSON 修復、部分資料提取 |
| **錯誤處理** | `JsonParseException` 用於 JSON 解析失敗 |

#### TiingoService (`lib/data/services/Tiingo/tiingo_service.dart`)
| 功能 | 說明 |
| :--- | :--- |
| `fetchDailyPrices(String ticker)` | 取得股價資料，返回 `List<StockPricesCompanion>` |
| **資料內容** | date, open, close (adjClose), high, low, volume |
| **預設範圍** | 從 2023-01-01 至今 |

### 3.2 K線圖渲染模塊

| 組件 | 說明 |
| :--- | :--- |
| `StockChartWidget` | K線圖主組件，整合股價和情緒標記 |
| `KChartStateAdapter` | 狀態適配器，追蹤可見範圍、縮放狀態，提供座標轉換 |
| `KChartSentimentMarkersPainter` | CustomPainter，繪製書籤形狀的情緒標記 |
| `ChartIntervalSelector` | K線間隔和時間範圍選擇器 (日/週/月, 1M/3M/6M/1Y) |
| `CandleAggregator` | K線聚合邏輯 (日K→週K→月K) |
| `KChartDataConverter` | StockPrice → KLineEntity 轉換 |

**K線圖套件**: `flutter_chen_kchart` v2.4.1

### 3.3 Marker 渲染模塊

情緒標記 (Sentiment Marker) 設計：
- **形狀**: 書籤形 (正方形 + 等腰直角三角形)
- **顏色**: Bullish=綠色, Bearish=紅色, Neutral=灰色
- **位置**: Bullish/Neutral 在 K線下方, Bearish 在 K線上方
- **標籤**: L (Long), S (Short), N (Neutral)
- **輔助線**: 虛線連接標記與 K線

### 3.4 文檔管理模塊

| 組件 | 說明 |
| :--- | :--- |
| `PostRepository` | 文檔 CRUD、草稿管理、狀態轉換 |
| `DraftStateNotifier` | 草稿狀態管理 (Riverpod StateNotifier) |
| `DraftFormState` | 草稿表單狀態模型 |
| **狀態流程** | Draft → Published |
| **自動儲存** | 每 30 秒自動暫存、App 背景時立即儲存 |

### 3.5 回測計算模塊

| 組件 | 說明 |
| :--- | :--- |
| `PriceChangeCalculator` | 計算 5/30/90/365 日漲跌幅 |
| `WinRateCalculator` | 勝率計算 (門檻 ±2%) |
| `price_change_provider` | 漲跌幅 Provider (含快取) |
| `kol_win_rate_provider` | KOL 勝率統計 Provider |

**勝率判定規則**:
- 漲幅 > +2%: 實際看漲
- 跌幅 < -2%: 實際看跌
- -2% ~ +2%: 震盪 (不計入勝率)
- Neutral 情緒: 不計入勝率

---

## 4. 資料庫架構 (Drift Schema)

位置: `lib/data/database/database.dart`

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
| kolId | Int | Foreign Key → KOLs.id |
| stockTicker | Text | Foreign Key → Stocks.ticker |
| content | Text | 原始文本內容 |
| sentiment | Text | "Bullish", "Bearish", "Neutral" |
| postedAt | DateTime | KOL 發文時間 |
| createdAt | DateTime | 建檔時間 |
| status | Text | "Draft", "Published" |
| aiAnalysisJson | Text (Nullable) | AI 分析結果 (JSON 格式) |

### Table 4: StockPrices (歷史股價快取)
| Column | Type | Description |
| :--- | :--- | :--- |
| id | Int (AutoIncrement) | Primary Key |
| ticker | Text | Foreign Key → Stocks.ticker |
| date | DateTime | 股價日期 |
| open | Real | 開盤價 |
| close | Real | 收盤價 (Adjusted) |
| high | Real | 最高價 |
| low | Real | 最低價 |
| volume | Int | 交易量 |

**唯一索引**: `idx_stock_prices_ticker_date` (ticker, date)

---

## 5. 模塊連接關係 (Module Connections)

### 5.1 輸入流程 (Input Flow)

```
用戶輸入文字
     ↓
QuickInputScreen (Tab 1)
     ↓ [分析按鈕]
GeminiService.analyzeText()
     ↓
AnalysisResult (情緒/Ticker/KOL/時間/摘要/冗餘文字)
     ↓
DraftStateNotifier 狀態更新
     ├─ KOLMatcher.findBestMatch() → kolId
     ├─ TimeParser.parse() → postedAt
     └─ StockRepository.upsertStock() → 確保 Ticker 存在
     ↓
AnalysisResultScreen (顯示/編輯)
     ↓ [建檔按鈕]
PostRepository.createDraft() + publishPost()
     ↓
AppDatabase (Drift SQLite)
```

### 5.2 股價資料流程 (Stock Data Flow)

```
頁面請求股價 (StockViewScreen, PostDetailScreen)
     ↓
stockPricesProvider(ticker)
     ↓
StockPriceRepository.getStockPrices()
     ├─ [Cache Hit] 返回本地資料
     └─ [Cache Miss/Expired]
            ↓
         TiingoService.fetchDailyPrices()
            ↓
         批次寫入 AppDatabase (INSERT OR REPLACE)
            ↓
         返回更新後的本地資料
```

### 5.3 K線圖渲染流程 (Chart Rendering Flow)

```
StockChartWidget
     ↓
stockFullRangePricesProvider(ticker) → List<StockPrice>
stockPostsProvider(ticker) → List<Post>
     ↓
CandleAggregator.aggregate() (依選擇的間隔聚合)
     ↓
KChartStateAdapter.updateData() → List<KLineEntity>
     ↓
┌─────────────────────────────────────────┐
│  Stack                                  │
│  ├─ KChartWidget (flutter_chen_kchart)  │
│  │    ├─ 手勢處理 (縮放/平移)           │
│  │    └─ K線繪製                        │
│  └─ CustomPaint                         │
│       └─ KChartSentimentMarkersPainter  │
│            ├─ 座標轉換 (indexToX, priceToY) │
│            └─ 繪製書籤標記               │
└─────────────────────────────────────────┘
```

### 5.4 回測計算流程 (Backtest Flow)

```
PostDetailScreen / KOLViewScreen
     ↓
postPriceChangeProvider(postId)
     ↓
PostRepository.getPostById() → Post (postedAt, stockTicker)
     ↓
StockPriceRepository.getStockPrices()
     ↓
PriceChangeCalculator.calculateMultiplePeriods()
     ├─ 5日漲跌幅
     ├─ 30日漲跌幅
     ├─ 90日漲跌幅
     └─ 365日漲跌幅
     ↓
PriceChangeResult
     ↓
WinRateCalculator.evaluatePrediction() → PredictionResult
```

---

## 6. 開發階段與任務 (Development Roadmap)

### Phase 1: Foundation (地基建設) ✅ 完成
1.  ✅ **Project Init**: Flutter 專案初始化
2.  ✅ **Dependencies**: 安裝必要套件
3.  ✅ **Database Setup**: Drift 資料庫連線與 Table 定義

### Phase 2: Infrastructure (核心服務) ✅ 完成
1.  ✅ **TiingoService**: 股價 API + 快取機制
2.  ✅ **GeminiService**: AI 分析 (情緒/Ticker/KOL/時間/摘要)

### Phase 3: Input Flow (輸入功能) ✅ 完成
1.  ✅ **QuickInputScreen**: 文字輸入 + 自動暫存
2.  ✅ **AnalysisResultScreen**: AI 分析結果展示 + 編輯
3.  ✅ **Auto-Fill Logic**: KOL 匹配、時間解析
4.  ✅ **Draft Management**: 草稿列表、刪除

### Phase 4: Output Flow (分析與檢視) 🔄 進行中
1.  ✅ **KOL List/View**: KOL 列表 + 文檔分組
2.  ✅ **Stock List/View**: 股票列表 + 文檔清單
3.  ✅ **K Chart**: K線圖繪製 + 情緒標記
4.  🔄 **Backtest Display**: 漲跌幅顯示 (部分完成)
5.  ⏳ **Win Rate Stats**: 勝率統計頁面

### Phase 5: Refinement (優化) ⏳ 待處理
1.  ⏳ Error Handling 優化
2.  ⏳ UI 美化
3.  ⏳ Web/iOS 平台適配

---

## 7. 檔案結構 (Directory Structure)

```
lib/
├── main.dart                           # 應用程式入口
├── core/
│   ├── config/                         # 環境設定 (未使用)
│   ├── network/                        # 網路設定 (未使用)
│   └── utils/
│       ├── datetime_formatter.dart     # 日期格式化
│       ├── kol_matcher.dart            # KOL 名稱匹配
│       ├── price_change_calculator.dart # 漲跌幅計算
│       ├── relative_time_parser.dart   # 相對時間解析
│       ├── time_parser.dart            # 時間解析 (主要)
│       └── win_rate_calculator.dart    # 勝率計算
├── data/
│   ├── database/
│   │   ├── database.dart               # Drift DB 定義
│   │   └── database.g.dart             # Drift 生成檔
│   ├── models/
│   │   ├── analysis_result.dart        # AI 分析結果模型
│   │   ├── draft_form_state.dart       # 草稿表單狀態
│   │   ├── post_with_details.dart      # 文檔 + KOL + Stock
│   │   ├── price_change_result.dart    # 漲跌幅結果
│   │   ├── stock_stats.dart            # 股票統計
│   │   └── win_rate_stats.dart         # 勝率統計
│   ├── repositories/
│   │   ├── diagnostic_repository.dart  # API 診斷
│   │   ├── kol_repository.dart         # KOL CRUD
│   │   ├── post_repository.dart        # 文檔 CRUD
│   │   ├── stock_price_repository.dart # 股價 + 快取
│   │   └── stock_repository.dart       # 股票 CRUD
│   └── services/
│       ├── Gemini/
│       │   └── gemini_service.dart     # Gemini AI 服務
│       └── Tiingo/
│           └── tiingo_service.dart     # Tiingo 股價 API
├── domain/
│   └── providers/
│       ├── bookmark_provider.dart      # 書籤管理
│       ├── database_provider.dart      # DB Provider
│       ├── draft_list_provider.dart    # 草稿列表
│       ├── draft_state_provider.dart   # 草稿狀態 (核心)
│       ├── home_tab_provider.dart      # Tab 索引
│       ├── kol_list_provider.dart      # KOL 列表
│       ├── kol_posts_provider.dart     # KOL 文檔
│       ├── kol_win_rate_provider.dart  # KOL 勝率
│       ├── post_list_provider.dart     # 文檔列表
│       ├── price_change_provider.dart  # 漲跌幅計算
│       ├── repository_providers.dart   # Repository Providers
│       ├── service_providers.dart      # Service Providers
│       ├── stock_list_provider.dart    # 股票列表
│       ├── stock_posts_provider.dart   # 股票文檔
│       ├── stock_price_provider.dart   # 股價資料
│       └── stock_stats_provider.dart   # 股票統計
└── presentation/
    ├── screens/
    │   ├── home/
    │   │   └── home_screen.dart        # 底部導覽容器
    │   ├── input/
    │   │   ├── analysis_result_screen.dart
    │   │   ├── draft_edit_screen.dart
    │   │   ├── draft_list_screen.dart
    │   │   ├── preview_screen.dart
    │   │   └── quick_input_screen.dart
    │   ├── kol/
    │   │   ├── kol_list_screen.dart
    │   │   └── kol_view_screen.dart
    │   ├── more/
    │   │   ├── diagnostic_screen.dart
    │   │   └── more_screen.dart
    │   ├── posts/
    │   │   ├── post_detail_screen.dart
    │   │   └── post_list_screen.dart
    │   └── stocks/
    │       ├── stock_list_screen.dart
    │       └── stock_view_screen.dart
    ├── theme/
    │   └── chart_theme_config.dart     # K線圖主題設定
    ├── utils/
    │   ├── candle_aggregator.dart      # K線聚合
    │   ├── candle_data_converter.dart  # 資料轉換
    │   └── kchart_data_converter.dart  # KLineEntity 轉換
    └── widgets/
        ├── chart_gesture_wrapper.dart
        ├── chart_interval_selector.dart
        ├── chart_layout_config.dart
        ├── kchart_sentiment_markers_painter.dart
        ├── kchart_state_adapter.dart
        ├── sentiment_marker.dart
        ├── stock_chart_widget.dart     # K線圖主組件
        └── ... (其他 Widget)
```

---

## 8. 平台支援規劃 (Platform Support)

| 平台 | 狀態 | 備註 |
| :--- | :--- | :--- |
| **Android** | ✅ 已支援 | 主要開發平台 |
| **iOS** | 🔄 部分支援 | 需要 Xcode 環境驗證 |
| **Web** | ⏳ 規劃中 | 需處理 SQLite 替代方案 |
| **Windows** | ⏳ 規劃中 | 桌面版本 |
| **macOS** | ⏳ 規劃中 | 桌面版本 |

### Web 平台特殊考量
1. **資料庫**: 需使用 `drift_web` 或 IndexedDB 替代 SQLite
2. **環境變數**: 需要不同的 .env 載入方式
3. **K線圖**: 確認 `flutter_chen_kchart` Web 支援度

---

## 9. 版本歷史

| 版本 | 日期 | 更新內容 |
| :--- | :--- | :--- |
| v1.0 | 2025-12-07 | 初始版本 |
| v1.1 | 2025-12-26 | 新增模塊詳解、連接關係、完整檔案結構 |

---

**報告生成時間**: 2025-12-26  
**維護者**: Development Agent
