# Stock KOL Tracker

一個 Flutter 開發的財經 KOL 投資建議回測系統，幫助投資者追蹤和分析 KOL 的投資觀點，驗證其準確性與時效性。

## 📋 專案概述

Stock KOL Tracker 是一個本地部署的移動應用程式，專為忙碌的散戶投資者設計。透過 AI 分析 KOL 發言內容，自動識別投資標的、情緒分析，並提供回測功能來評估 KOL 的預測準確度。

## 🚀 快速開始

### 環境需求
- Flutter SDK (最新穩定版)
- Dart SDK
- Android Studio / Xcode (用於移動端開發)

### 🔐 API Keys 申請

#### 1. Gemini API Key
1. 前往 [Google AI Studio](https://aistudio.google.com/apikey)
2. 登入 Google 帳號
3. 點選 "Create API Key"
4. 複製生成的 API Key

#### 2. Tiingo API Token
1. 前往 [Tiingo](https://www.tiingo.com/)
2. 註冊並登入帳號
3. 在 Dashboard 中找到 API Token
4. 複製您的 Token

### 安裝步驟

1. **克隆專案**
```bash
git clone https://github.com/alan8983/Stock_KOL_Tracker.git
cd Stock_KOL_Tracker
```

2. **安裝依賴**
```bash
flutter pub get
```

3. **設定環境變數**
```bash
cp env.example .env
# 編輯 .env 檔案，填入您的 API Keys
# GEMINI_API_KEY=your_gemini_api_key
# TIINGO_API_TOKEN=your_tiingo_token
```

4. **設置 Git Hooks（重要！防止 API Key 洩露）**

**Linux/Mac:**
```bash
bash scripts/setup-git-hooks.sh
```

**Windows:**
```bash
scripts\setup-git-hooks.bat
```

或手動設置：
```bash
chmod +x .git/hooks/pre-commit
```

5. **執行應用程式**
```bash
flutter run
```

## 📊 Git 推送進展記錄

### 🎯 最新進展 (2025-12-15)

#### 技術改進：K線圖自定義實現
**日期**: 2025-12-15  
**主要變更**:
- ✅ **K線圖完全重構** - 從 `candlesticks` 套件遷移到自定義 CustomPainter 實現
  - 解決 Marker 定位錯誤問題（情緒標記精確顯示在對應 K 線上）
  - 實現縮放/平移完全同步（所有圖層同步移動）
  - 修正日期格式（從 hh:mm 改為 mmm-dd，如 Dec-15）
  - 使用 `FlChartController` 統一管理狀態和座標轉換
  - 分層繪製架構（CandlesPainter、VolumePainter、SentimentMarkersPainter）
  - 智能日期標籤間隔，避免重疊
  - 順延邏輯（發布日無交易時自動順延到下一個交易日）
- ✅ **漲跌幅計算功能** - 在 PostCard 上顯示股價漲跌幅
  - 支援 5、30、90、365 天四個時間區間
  - 左右滑動切換時間區間
  - 交易日對齊邏輯（向前查找最多 7 天）
  - 批次計算與快取機制
- ✅ **勝率統計功能** - KOL 與股票列表統計顯示
  - 門檻版勝率計算（±2% 門檻）
  - 多時間區間統計（5/30/90/365 天）
  - 文檔數量、情緒分布、近期表現顯示
  - 展開型卡片設計
- ✅ **文檔重組** - 所有技術文檔整理至 `docs/` 資料夾
  - 新增文檔索引 (`docs/INDEX.md`)
  - 重新組織文檔結構與分類
  - 更新所有文檔連結路徑
- ✅ **文檔重組** - 所有技術文檔整理至 `docs/` 資料夾
  - 新增文檔索引 (`docs/INDEX.md`)
  - 重新組織文檔結構與分類
  - 更新所有文檔連結路徑

**技術改進**:
- **K線圖自定義實現** - 使用 Flutter CustomPainter 完全自定義實現
  - 移除 `candlesticks` 套件依賴
  - 新增 `intl` 套件用於日期格式化
  - 實現精確的座標映射系統（價格 ↔ Y座標，索引 ↔ X座標）
  - 統一狀態管理（`FlChartController`）
- 實現價格變動計算器與勝率計算器
- 新增多個 Providers（`stock_price_provider`, `price_change_provider`, `win_rate_provider` 等）
- 新增多個 Widgets（`fl_chart_controller`, `candles_painter`, `volume_painter`, `sentiment_markers_painter`, `price_change_indicator`, `kol_stats_card`, `stock_stats_card` 等）

**UI 改進**:
- 專業的 K 線圖顯示與互動
- 漲跌幅視覺化指示器
- 統計卡片設計與展開動畫
- 改善列表頁面的資訊展示

**相關文件**:
- [FL_CHART_IMPLEMENTATION.md](./docs/FL_CHART_IMPLEMENTATION.md) - K線圖自定義實現總結（最新）
- [K_LINE_CHART_IMPLEMENTATION.md](./docs/K_LINE_CHART_IMPLEMENTATION.md) - K線圖功能實作總結（candlesticks 版本）
- [PRICE_CHANGE_IMPLEMENTATION_SUMMARY.md](./docs/PRICE_CHANGE_IMPLEMENTATION_SUMMARY.md) - 漲跌幅計算功能總結
- [WIN_RATE_STATS_IMPLEMENTATION_SUMMARY.md](./docs/WIN_RATE_STATS_IMPLEMENTATION_SUMMARY.md) - 勝率統計功能總結
- [文檔索引](./docs/INDEX.md) - 所有文檔的完整索引

---

### 📅 近期進展 (2025-12-13)

#### 新功能：AI 辨識 KOL 與發文時間
**日期**: 2025-12-13  
**主要變更**:
- ✅ **AI 自動辨識 KOL 名稱** - 從文章內容自動提取 KOL 名稱
- ✅ **AI 自動辨識發文時間** - 支援相對時間（如「3小時前」）和絕對時間（如「12月11日下午2:02」）
- ✅ **時間解析工具** (`time_parser.dart`) - 智能解析各種時間格式
- ✅ **KOL 模糊匹配工具** (`kol_matcher.dart`) - 自動匹配資料庫中的 KOL
- ✅ **視覺 Highlight 效果** - 必填欄位未填寫時顯示紅色脈衝邊框提醒
- ✅ **自動填入功能** - AI 分析結果自動填入對應欄位（KOL、時間、投資標的）
- ✅ **更新 Gemini 模型** - 使用 `gemini-2.5-flash`（開發階段固定使用）
- ✅ **新增分析結果畫面** (`analysis_result_screen.dart`) - 顯示 AI 分析結果並自動填入
- ✅ **新增多個 Providers** - `bookmark_provider`, `kol_posts_provider`, `post_list_provider`, `stock_posts_provider`, `stock_price_provider`
- ✅ **新增 Widgets** - `post_card.dart`, `pulsing_border_card.dart`, `stock_chart_widget.dart`
- ✅ **新增測試** - 完整的單元測試（20/20 通過）

**技術改進**:
- 擴展 `AnalysisResult` 模型，新增 `kolName` 和 `postedAtText` 欄位
- 增強 Gemini Prompt 以支援 KOL 和時間辨識
- 實現智能時間解析（支援中文日期格式）
- 實現 KOL 模糊匹配算法（Levenshtein 距離）

**UI 改進**:
- 新增脈衝邊框視覺效果提醒必填欄位
- 優化分析結果顯示與自動填入流程
- 改善用戶體驗，減少手動輸入需求

**相關文件**:
- [AI_KOL_TIME_RECOGNITION_IMPLEMENTATION.md](./docs/AI_KOL_TIME_RECOGNITION_IMPLEMENTATION.md) - 完整實作總結

---

### 📅 近期進展 (2025-12-11)

#### Commit: `1176c24` - 更新 README 並強化安全機制
**日期**: 2025-12-11  
**主要變更**:
- ✅ 新增詳細的 API Keys 申請指南（Gemini 和 Tiingo）
- ✅ 新增 Git Hooks 設置說明與腳本（`setup-git-hooks.sh` 和 `setup-git-hooks.bat`）
- ✅ 強化安全注意事項專區，包含多層 API Keys 保護措施
- ✅ 新增 AI 分析功能修復總結文件（`docs/AI_ANALYSIS_FIX_SUMMARY.md`）
- ✅ 新增診斷功能（`diagnostic_screen.dart`、`diagnostic_repository.dart`）
- ✅ 改善 Gemini 服務的錯誤處理與日誌輸出
- ✅ 增強草稿編輯畫面功能
- ✅ 遮蔽文件中的舊 API Keys（已撤銷的 Keys）

**安全改進**:
- 實施 Git Pre-commit Hook 自動檢測敏感資訊
- 提供跨平台設置腳本（Linux/Mac/Windows）
- 完善的安全文檔與最佳實踐指南

**功能改進**:
- 新增診斷工具用於 API 連接測試
- 改善 AI 分析的錯誤處理機制
- 優化草稿編輯流程

**UI 改進**:
- ✅ **草稿編輯畫面大幅重構** (`draft_edit_screen.dart` - 581 行變更)
  - 完整的表單驗證與錯誤處理
  - 改善用戶輸入體驗與即時反饋
  - 優化表單欄位布局與互動流程
- ✅ **快速輸入畫面優化** (`quick_input_screen.dart` - 105 行變更)
  - 改善內容處理邏輯
  - 優化分析流程的用戶體驗
  - 增強錯誤提示與狀態顯示
- ✅ **新增診斷畫面** (`diagnostic_screen.dart` - 344 行新增)
  - 完整的 API 連接測試介面
  - 即時顯示診斷結果與狀態
  - 提供詳細的錯誤資訊與解決建議
- ✅ **更多功能頁面更新** (`more_screen.dart`)
  - 新增診斷功能入口
  - 改善選單結構與導航

---

### 📅 近期進展 (2025-12-10)

#### Commit: `00a95b8` - 更新 README 文件
**日期**: 2025-12-10  
**主要變更**:
- ✅ 添加新的文件連結（`docs/IMPLEMENTATION_REPORT.md`、`docs/NAVIGATION_TEST_SUMMARY.md`）
- ✅ 更新已實現功能列表（導覽架構、KOL 管理、股票管理、文檔管理）
- ✅ 更新專案結構文件，包含詳細的目錄樹
- ✅ 更新專案進度統計，標記導覽架構重構完成

---

#### Commit: `5b5390c` - 重構導覽架構並添加新畫面
**日期**: 2025-12-10  
**主要變更**:
- ✅ 實現 4 個底部 Tab 導覽架構（快速輸入、KOL、投資標的、更多）
- ✅ 新增 `KOLListScreen` 與搜尋功能
- ✅ 新增 `StockListScreen` 與搜尋功能
- ✅ 新增 `MoreScreen` 選單頁面
- ✅ 新增 `PostDetailScreen` 與 2 個子頁籤
- ✅ 增強 `KOLViewScreen` 和 `StockViewScreen`，各包含 3 個子頁籤
- ✅ 新增 `kol_list_provider` 和 `stock_list_provider` 進行狀態管理
- ✅ 改善草稿列表流程，使用 Navigator 返回值傳遞資料
- ✅ 更新 Repository 層，新增搜尋和 `getById` 方法
- ✅ 新增實施報告文件（`docs/IMPLEMENTATION_REPORT.md`、`docs/NAVIGATION_TEST_SUMMARY.md`）

**架構改進**:
- 完整的底部導覽架構，支援 4 個主要功能區塊
- 統一的列表頁面設計模式（搜尋 + 卡片列表）
- 統一的詳情頁面設計模式（凍結 Header + 子頁籤）
- 完善的狀態管理架構（Provider 模式）

---

### 📅 近期進展 (2025-12-09)

#### Commit: `294de96` - 測試腳本、安全通知與 Commit Log
**日期**: 2025-12-09  
**主要變更**:
- ✅ 新增測試腳本 (`test_api.sh`, `test/api_connection_test.dart`, `test/gemini_diagnostic_test.dart`)
- ✅ 建立安全通知文件 (`docs/SECURITY_NOTICE.md`) - 處理 API Keys 洩露問題
- ✅ 新增 Commit Log 文件 (`docs/COMMIT_LOG.md`) - 詳細記錄開發進度
- ✅ 移除硬編碼的 API Keys，改為從環境變數讀取
- ✅ 更新依賴套件，改善程式碼結構
- ✅ 將 Sample 檔案轉換為 .txt 格式

**技術改進**:
- 改善環境變數載入與錯誤處理機制
- 更新 Gemini 模型為 `gemini-2.5-flash` (開發階段固定使用)
- 升級 `google_generative_ai` 套件至 `0.4.7`

---

#### Commit: `541d2f9` - 增強快速輸入與草稿編輯
**日期**: 2025-12-09  
**主要變更**:
- ✅ 改善快速輸入頁面的內容處理邏輯
- ✅ 更新 `_onAnalyze` 方法，新增輸入驗證
- ✅ 改善內容同步機制（從快速輸入到草稿編輯頁面）
- ✅ 修復導航狀態檢查問題

**功能改進**:
- 輸入驗證：修剪空白字符，避免空白內容觸發分析
- 狀態同步：確保內容正確傳遞到編輯頁面
- 錯誤處理：改善導航失敗時的錯誤提示

---

#### Commit: `2f8b5ae` - 重構 HomeScreen
**日期**: 2025-12-09  
**主要變更**:
- ✅ 將 HomeScreen 改為 `ConsumerStatefulWidget`，使用 Riverpod 狀態管理
- ✅ 實作文字輸入欄位與分析功能
- ✅ 新增導航到 DraftEditScreen 的功能
- ✅ 使用 `IndexedStack` 實現分頁導航（輸入頁面與草稿列表）

**架構改進**:
- 採用 Riverpod 進行狀態管理
- 使用 IndexedStack 保持 Tab 狀態
- 改善輸入處理與導航流程

---

#### Commit: `6139484` - Flutter 專案結構與核心功能
**日期**: 2025-12-08  
**主要變更**:
- ✅ 建立完整的 Flutter 專案結構
- ✅ 實作核心資料層（Database, Repositories, Services）
- ✅ 整合 Tiingo API 服務（股價資料）
- ✅ 整合 Gemini AI 服務（內容分析）
- ✅ 建立基本 UI 框架

**核心功能**:
- **資料庫**: 使用 Drift (SQLite) 進行本地資料儲存
- **API 整合**: TiingoService (股價資料) + GeminiService (AI 分析)
- **狀態管理**: Riverpod Provider 架構
- **UI 框架**: Material Design 3

---

#### Commit: `9860d5c` - 初始 Commit: Flutter MVP
**日期**: 2025-12-07  
**主要變更**:
- ✅ 初始化 Flutter 專案
- ✅ 建立專案基本結構
- ✅ 設定開發環境與依賴管理

**里程碑**:
- 從 Web 原型轉換為 Flutter 移動應用
- 確立技術架構與開發方向

---

### 📅 早期原型階段 (2025-08)

#### Commit: `1f41773` - 專案結構重組
**日期**: 2025-08-08  
- 將原型檔案移至 `Web_Prototype` 資料夾
- 重新組織專案結構

#### Commit: `27bc9b6` - Web 原型版本
**日期**: 2025-08-08  
- 建立 Github Pages 版本的互動式原型
- 實作基本的前端功能與 UI

#### Commit: `65e6cf9` - 初始專案建立
**日期**: 2025-08-04  
- 建立專案初始結構
- 新增 README 與用戶故事文件

---

## 📈 專案進度統計

### Agent Plans 狀態

根據 `.cursor/plans/stock_kol_tracker_mvp_plan_e9a29f9c.plan.md`：

| 狀態 | 數量 | 百分比 |
|------|------|--------|
| ✅ 已完成 | 6 | 54.5% |
| 🔄 進行中 | 0 | 0% |
| ⏳ 待處理 | 5 | 45.5% |
| **總計** | **11** | **100%** |

### 已完成階段

1. ✅ **Phase 1**: 專案初始化與資料庫架構
   - Flutter 專案初始化
   - Drift Database 設定
   - 資料庫 Schema 設計

2. ✅ **Phase 2**: 基礎設施建立
   - TiingoService 實作（股價資料獲取與快取）
   - GeminiService 實作（AI 內容分析）

3. ✅ **導覽架構重構** (2024-12-08)
   - 實現 4 個底部 Tab 導覽架構
   - 完成所有主要頁面（快速輸入、KOL、投資標的、更多）
   - 實現 KOL 列表、股票列表、文檔列表功能
   - 完成導航流程測試與驗證

4. ✅ **Phase 4**: 核心功能 - 分析與 UI (2025-12-15)
   - K 線圖功能實現（使用 candlesticks 套件）
   - 漲跌幅計算與顯示（多時間區間）
   - 勝率統計功能（門檻版計算）
   - 統計卡片 UI 設計

### 進行中階段

3. ✅ **Phase 3**: 核心功能 - 輸入流
   - UI 輸入頁面：✅ 已完成
   - **自動填入邏輯：✅ 已完成** (2025-12-13)
     - AI 自動辨識 KOL 名稱與發文時間
     - 智能時間解析與 KOL 模糊匹配
     - 自動填入對應欄位
   - Review 與儲存：待處理

### 待處理階段

6. ⏳ **Phase 5**: 優化與完善
   - 錯誤處理
   - UI 優化

---

## 🎯 核心功能

### 已實現功能

- ✅ **快速輸入**: 支援文字輸入與自動暫存
- ✅ **草稿管理**: 自動暫存、手動儲存、草稿列表
- ✅ **AI 分析**: 整合 Gemini AI 進行內容分析
- ✅ **AI 自動辨識**: KOL 名稱與發文時間自動辨識與填入
- ✅ **時間解析**: 智能解析相對時間和中文日期格式
- ✅ **KOL 匹配**: 模糊匹配資料庫中的 KOL
- ✅ **資料庫**: 本地 SQLite 資料儲存
- ✅ **API 整合**: Tiingo (股價) + Gemini (AI 分析)
- ✅ **狀態管理**: Riverpod 狀態管理架構
- ✅ **導覽架構**: 4 個底部 Tab 導覽（快速輸入、KOL、投資標的、更多）
- ✅ **KOL 管理**: KOL 列表、詳情頁面、搜尋功能
- ✅ **投資標的管理**: 股票列表、詳情頁面、搜尋功能
- ✅ **文檔管理**: 文檔列表與詳情頁面
- ✅ **診斷工具**: API 連接測試與診斷功能
- ✅ **安全機制**: Git Pre-commit Hook 防止 API Keys 洩露
- ✅ **視覺提示**: 必填欄位脈衝邊框提醒效果
- ✅ **K線圖**: 自定義實現的專業 K 線圖（CustomPainter，精確 Marker 定位，完全同步縮放/平移）
- ✅ **漲跌幅計算**: 多時間區間漲跌幅顯示（5/30/90/365 天）
- ✅ **勝率統計**: KOL 與股票勝率計算與顯示（門檻版 ±2%）

### 開發中功能

- 🔄 **自動填入**: AI 分析結果自動填入表單
- 🔄 **預覽功能**: 文檔發布前預覽

### 計劃功能

- ⏳ **K 線圖**: 整合股價走勢圖與文檔標記
- ⏳ **回測功能**: 計算 KOL 預測準確率
- ⏳ **勝率統計**: 5/30/90 日後漲跌幅分析

---

## 🛠️ 技術架構

### 技術棧

- **Framework**: Flutter (跨平台移動應用)
- **狀態管理**: Riverpod
- **本地資料庫**: Drift (基於 SQLite)
- **網路請求**: Dio
- **AI 服務**: Google Gemini API
- **股價資料**: Tiingo API

### 專案結構

```
lib/
├── core/              # 核心工具類
│   └── utils/         # 工具函數（日期時間格式化、相對時間解析）
├── data/              # 資料層
│   ├── database/      # 資料庫定義（Drift）
│   ├── models/        # 資料模型
│   ├── repositories/  # 資料存取層（KOL, Post, Stock）
│   └── services/      # 外部服務整合（Tiingo, Gemini）
├── domain/            # 業務邏輯層
│   └── providers/     # Riverpod Providers（狀態管理）
└── presentation/      # UI 層
    ├── screens/        # 頁面
    │   ├── home/      # 主頁（底部導覽容器）
    │   ├── input/     # 輸入相關（快速輸入、草稿列表、編輯、預覽）
    │   ├── kol/       # KOL 相關（列表、詳情）
    │   ├── stocks/    # 股票相關（列表、詳情）
    │   ├── posts/     # 文檔相關（列表、詳情）
    │   └── more/      # 更多功能
    └── widgets/        # 可重用組件
```

---

## 🔐 安全注意事項

### API Keys 保護

本專案已實施多層安全措施來保護 API Keys：

1. **`.env` 檔案隔離**
   - 所有 API Keys 都存放在 `.env` 檔案中
   - `.env` 已加入 `.gitignore`，不會被提交到 Git

2. **Git Pre-commit Hook**
   - 自動檢測並阻止 `.env` 檔案被提交
   - 自動掃描程式碼中的 API Key 模式
   - 發現敏感資訊時會阻止提交並顯示警告

3. **環境變數使用**
   - 所有程式碼都透過 `flutter_dotenv` 讀取環境變數
   - 永不硬編碼 API Keys

### 設置 Git Hooks

**首次 clone 專案後，務必執行：**

**Linux/Mac:**
```bash
bash scripts/setup-git-hooks.sh
```

**Windows:**
```bash
scripts\setup-git-hooks.bat
```

### ⚠️ 重要提醒

- **永遠不要**在程式碼中硬編碼 API Keys
- **永遠不要**使用 `git commit --no-verify` 來繞過安全檢查（除非您非常確定）
- 如果不小心洩露了 API Key，請立即：
  1. 撤銷舊的 API Key
  2. 申請新的 API Key
  3. 更新 `.env` 檔案
  4. 參考 [SECURITY_NOTICE.md](./docs/SECURITY_NOTICE.md) 進行完整處理

---

## 📝 相關文件

所有技術文檔已整理至 [`docs/`](./docs/) 資料夾，請參閱 [文檔索引](./docs/INDEX.md) 查看完整文檔列表。

### 主要文檔

- **[文檔索引](./docs/INDEX.md)** - 所有文檔的完整索引與分類
- [PROJECT_MASTER_PLAN.md](./docs/PROJECT_MASTER_PLAN.md) - 專案主計劃文件（唯一真理來源）
- [BACKLOG.md](./docs/BACKLOG.md) - 產品待辦清單與用戶故事
- [COMMIT_LOG.md](./docs/COMMIT_LOG.md) - 詳細的 Commit 記錄與功能說明
- [SECURITY_NOTICE.md](./docs/SECURITY_NOTICE.md) - 安全注意事項與 API Keys 洩露處理指南

### 實施報告

- [IMPLEMENTATION_REPORT.md](./docs/IMPLEMENTATION_REPORT.md) - APP 導覽架構重構實施報告
- [NAVIGATION_TEST_SUMMARY.md](./docs/NAVIGATION_TEST_SUMMARY.md) - 導航架構測試總結
- [AI_KOL_TIME_RECOGNITION_IMPLEMENTATION.md](./docs/AI_KOL_TIME_RECOGNITION_IMPLEMENTATION.md) - AI 辨識功能實作總結
- [AI_ANALYSIS_FIX_SUMMARY.md](./docs/AI_ANALYSIS_FIX_SUMMARY.md) - AI 分析功能修復總結
- [APP_PAGE_ARCHITECTURE_SUMMARY.md](./docs/APP_PAGE_ARCHITECTURE_SUMMARY.md) - APP 頁面架構總結

### 其他

- [.cursor/plans/](./.cursor/plans/) - Agent 執行計劃

---

## 📄 授權

本專案為個人開發專案。

---

## 👤 作者

- **GitHub**: [@alan8983](https://github.com/alan8983)

---

## 🙏 致謝

- Google Gemini API - AI 內容分析
- Tiingo - 股價資料服務
- Flutter 社群 - 優秀的開源框架與工具
